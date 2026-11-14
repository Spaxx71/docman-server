"""Schätzt Feldgewichte aus abgehefteten Belegen. Erfindet keinen Regex."""

from __future__ import annotations

import re
import warnings
from xml.etree.ElementTree import Element, SubElement, fromstring, tostring

from sklearn.linear_model import LogisticRegression

from docman_intelligence.assign import (
    FEATURE_NAMES,
    Word,
    candidate_features,
    collect_anchors,
    date_options,
    group_lines,
    line_role,
    mark_roles,
    money_options,
    number_options,
    parse_amount,
    parse_date,
)

TRAIN_FIELDS = {
    "invoiceNumber": "number",
    "invoiceDate": "date",
    "serviceDate": "date",
    "dueDate": "date",
    "payable": "money",
    "gross": "money",
}


def _local(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def canonical(field_name: str, value: str) -> str:
    text = (value or "").strip()
    if field_name in ("invoiceDate", "serviceDate", "dueDate"):
        if re.fullmatch(r"\d{4}-\d{2}-\d{2}", text):
            return text
        return parse_date(text) or ""
    if field_name in ("payable", "gross"):
        if re.fullmatch(r"-?\d+\.\d{2}", text):
            return text
        if re.fullmatch(r"-?\d+", text):
            return f"{int(text):.2f}"
        amount = parse_amount(text)
        return f"{amount:.2f}" if amount is not None else ""
    return re.sub(r"\s+", "", text).upper()


def words_of(node: Element) -> list[Word]:
    words = []
    for element in node.iter():
        if _local(element.tag) != "W":
            continue
        parts = (element.attrib.get("box") or "").split()
        if len(parts) < 4:
            continue
        try:
            box = [float(part) for part in parts[:4]]
            page = int(element.attrib.get("page") or 1)
        except ValueError:
            continue
        words.append(Word(text=element.text or "", x0=box[0], y0=box[1], x1=box[2], y1=box[3], page=page))
    return words


def options_for(field_name: str, words: list[Word]) -> list[tuple[Word, str]]:
    kind = TRAIN_FIELDS[field_name]
    if kind == "date":
        return [(word, value) for word, value, _ok in date_options(words)]
    if kind == "money":
        return [(word, value) for word, value, _ok in money_options(words)]
    return [(word, value) for word, value, _ok in number_options(words, [])]


def collect_rows(examples_xml: str) -> dict:
    root = fromstring(examples_xml)
    rows: dict[str, list] = {name: [] for name in TRAIN_FIELDS}
    for document in root.iter():
        if _local(document.tag) not in ("DocmanIntelligence", "Intelligence"):
            continue
        confirmed = {}
        account_id = ""
        for child in document.iter():
            kind = _local(child.tag)
            if kind == "Account" and not account_id:
                account_id = child.attrib.get("id", "")
            if kind == "Confirmed":
                field_name = child.attrib.get("field", "")
                if field_name in TRAIN_FIELDS and child.attrib.get("value"):
                    confirmed[field_name] = child.attrib["value"]
        if not confirmed:
            continue
        words = words_of(document)
        if not words:
            continue
        lines = group_lines(words)
        mark_roles(lines)
        anchors = collect_anchors(lines)
        for field_name, raw in confirmed.items():
            wanted = canonical(field_name, raw)
            if not wanted:
                continue
            choices = options_for(field_name, words)
            positive = [item for item in choices if canonical(field_name, item[1]) == wanted]
            if not positive:
                continue
            for word, value in choices:
                features = candidate_features(field_name, word, True, anchors, line_role(lines, word), [])
                vector = [features[name] for name in FEATURE_NAMES]
                label = 1 if canonical(field_name, value) == wanted else 0
                rows[field_name].append((account_id, vector, label))
    return rows


def fit_weights(samples: list) -> dict | None:
    labels = [label for _account, _vector, label in samples]
    if len(set(labels)) < 2 or len(samples) < 4:
        return None
    matrix = [vector for _account, vector, _label in samples]
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        model = LogisticRegression(max_iter=400, solver="lbfgs")
        model.fit(matrix, labels)
    sign = 1.0 if int(model.classes_[-1]) == 1 else -1.0
    coefficients = [sign * float(value) for value in model.coef_[0]]
    weights = {"bias": sign * float(model.intercept_[0])}
    for name, value in zip(FEATURE_NAMES, coefficients):
        weights[name] = value
    return weights


def linear_score(weights: dict, vector: list[float]) -> float:
    total = weights.get("bias", 0.0)
    for name, value in zip(FEATURE_NAMES, vector):
        total += weights.get(name, 0.0) * value
    return total


def account_surcharge(field_rows: list, weights: dict) -> dict[str, float]:
    grouped: dict[str, list] = {}
    for account_id, vector, label in field_rows:
        if account_id:
            grouped.setdefault(account_id, []).append((vector, label))
    result = {}
    for account_id, samples in grouped.items():
        positives = [linear_score(weights, vector) for vector, label in samples if label == 1]
        if len(positives) < 2:
            continue
        negatives = [linear_score(weights, vector) for vector, label in samples if label == 0]
        if negatives:
            gap = (sum(positives) / len(positives)) - (sum(negatives) / len(negatives))
            bias = max(-1.5, min(1.5, gap / 4))
        else:
            bias = 0.35
        if abs(bias) >= 0.05:
            result[account_id] = bias
    return result


def render_model(field_weights: dict[str, dict], surcharges: dict[str, dict[str, float]]) -> str:
    root = Element("Model", {"version": "1"})
    for field_name, weights in field_weights.items():
        field = SubElement(root, "Field", {"name": field_name})
        for name in ("bias",) + FEATURE_NAMES:
            if name in weights:
                SubElement(field, "Weight", {"name": name, "value": f"{weights[name]:.4f}"})
    for account_id, fields in surcharges.items():
        account = SubElement(root, "Account", {"id": account_id})
        for field_name, bias in fields.items():
            field = SubElement(account, "Field", {"name": field_name})
            SubElement(field, "Weight", {"name": "bias", "value": f"{bias:.4f}"})
    return tostring(root, encoding="unicode")


def train_xml(examples_xml: str) -> str:
    rows = collect_rows(examples_xml)
    field_weights = {}
    surcharges: dict[str, dict[str, float]] = {}
    for field_name, samples in rows.items():
        weights = fit_weights(samples)
        if not weights:
            continue
        field_weights[field_name] = weights
        for account_id, bias in account_surcharge(samples, weights).items():
            surcharges.setdefault(account_id, {})[field_name] = bias
    return render_model(field_weights, surcharges)


def parse_model(xml_text: str) -> dict:
    model = {"fields": {}, "accounts": {}}
    if not xml_text.strip():
        return model
    root = fromstring(xml_text)
    for field in list(root):
        if _local(field.tag) != "Field":
            continue
        name = field.attrib.get("name", "")
        model["fields"][name] = {
            weight.attrib.get("name", ""): float(weight.attrib.get("value") or 0)
            for weight in list(field)
            if _local(weight.tag) == "Weight"
        }
    for account in list(root):
        if _local(account.tag) != "Account":
            continue
        account_id = account.attrib.get("id", "")
        fields = {}
        for field in list(account):
            if _local(field.tag) != "Field":
                continue
            fields[field.attrib.get("name", "")] = {
                weight.attrib.get("name", ""): float(weight.attrib.get("value") or 0)
                for weight in list(field)
                if _local(weight.tag) == "Weight"
            }
        model["accounts"][account_id] = fields
    return model
