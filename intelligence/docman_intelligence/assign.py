"""Fünf Stufen: Layout, Kandidaten, Konto, Merkmale, gemeinsame Auflösung."""

from __future__ import annotations

import math
import re
from dataclasses import dataclass, field

LABELS = {
    "invoiceNumber": ("rechnungsnummer", "rechnungsnr", "rechnungs-nr", "belegnummer", "belegnr", "beleg-nr", "invoice no", "invoice number"),
    "invoiceDate": ("rechnungsdatum", "invoice date", "belegdatum"),
    "dateGeneric": ("datum", "date"),
    "serviceDate": ("leistungsdatum", "lieferdatum", "leistungszeitraum", "lieferzeitraum"),
    "dueDate": ("faellig", "faelligkeit", "zahlbar bis", "zahlungsziel", "faellig am"),
    "payable": ("zahlbetrag", "zu zahlen", "rechnungsbetrag", "endbetrag", "zahlungsbetrag"),
    "gross": ("brutto", "bruttobetrag", "gesamtbetrag", "gesamtsumme", "gesamt"),
    "net": ("netto", "nettobetrag", "zwischensumme"),
    "tax": ("mwst", "umsatzsteuer", "ust", "mehrwertsteuer"),
    "iban": ("iban",),
    "bic": ("bic", "swift"),
    "vat": ("ust-idnr", "ustid", "ust-id", "umsatzsteuer-id", "vat id"),
}

HEADER = {
    "description": ("bezeichnung", "artikel", "leistung", "beschreibung"),
    "quantity": ("menge", "anzahl", "qty"),
    "unit": ("einheit", "eh"),
    "unitPrice": ("einzelpreis", "preis", "ep"),
    "discount": ("rabatt",),
    "amount": ("betrag", "gesamt", "summe", "gesamtpreis"),
    "taxRate": ("ust", "mwst", "steuer"),
    "position": ("pos", "position"),
    "article": ("artikelnr", "artikelnummer", "art-nr", "artnr"),
}

SKIP_ROW = ("zwischensumme", "uebertrag", "ubertrag", "summe", "gesamt", "zahlbetrag", "netto", "brutto")

FEATURE_NAMES = ("same", "below", "label", "role", "hint", "near", "near_number", "counter", "type")

WEIGHTS = {
    "invoiceNumber": {"bias": -1.1, "same": 1.4, "below": 0.7, "label": 2.0, "role": 0.4, "hint": 2.2, "near": 1.3, "counter": -1.6, "type": 1.2},
    "invoiceDate": {"bias": -1.3, "same": 1.2, "below": 0.8, "label": 2.4, "role": 0.5, "hint": 1.6, "near": 1.5, "near_number": 2.2, "counter": -2.6, "type": 1.1},
    "serviceDate": {"bias": -1.2, "same": 1.3, "below": 0.8, "label": 2.4, "role": 0.3, "hint": 1.2, "near": 1.6, "counter": -1.2, "type": 1.0},
    "dueDate": {"bias": -1.2, "same": 1.3, "below": 0.8, "label": 2.4, "role": 0.3, "hint": 1.2, "near": 1.6, "counter": -1.2, "type": 1.0},
    "payable": {"bias": -0.8, "same": 1.6, "below": 0.6, "label": 2.3, "role": 0.8, "hint": 1.4, "near": 1.4, "counter": -0.4, "type": 1.3},
    "gross": {"bias": -0.8, "same": 1.5, "below": 0.6, "label": 2.2, "role": 0.8, "hint": 1.2, "near": 1.3, "counter": -0.2, "type": 1.2},
    "vat": {"bias": -1.0, "same": 1.4, "below": 0.5, "label": 2.2, "role": 0.4, "hint": 1.2, "near": 1.2, "counter": -0.5, "type": 1.5},
    "iban": {"bias": -0.4, "same": 1.2, "below": 0.4, "label": 1.5, "role": 0.6, "hint": 1.0, "near": 0.8, "counter": 0.0, "type": 2.0},
    "bic": {"bias": -0.6, "same": 1.2, "below": 0.4, "label": 1.6, "role": 0.4, "hint": 1.0, "near": 0.8, "counter": 0.0, "type": 1.6},
}


@dataclass
class Word:
    text: str
    x0: float
    y0: float
    x1: float
    y1: float
    page: int = 1
    size: float = 10.0
    bold: bool = False


@dataclass
class Line:
    page: int
    words: list[Word] = field(default_factory=list)
    role: str = "body"

    @property
    def y0(self) -> float:
        return min(w.y0 for w in self.words)

    @property
    def y1(self) -> float:
        return max(w.y1 for w in self.words)

    @property
    def text(self) -> str:
        return " ".join(w.text for w in self.words)


def norm(text: str) -> str:
    value = text.lower().strip()
    value = value.replace("ä", "ae").replace("ö", "oe").replace("ü", "ue").replace("ß", "ss")
    value = value.replace(".", " ").replace(":", " ").replace("/", " ")
    value = re.sub(r"\s+", " ", value).strip()
    return value


def levenshtein(left: str, right: str) -> int:
    if abs(len(left) - len(right)) > 3:
        return 9
    prev = list(range(len(right) + 1))
    for i, ca in enumerate(left, 1):
        cur = [i]
        for j, cb in enumerate(right, 1):
            cur.append(min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (ca != cb)))
        prev = cur
    return prev[-1]


def similarity(token: str, label: str) -> float:
    got = norm(token).replace(" ", "").replace("-", "")
    want = norm(label).replace(" ", "").replace("-", "")
    if not got or not want:
        return 0.0
    if got == want:
        return 1.0
    if want in got or got in want:
        return 0.92
    distance = levenshtein(got, want)
    if distance <= 1 and len(want) >= 5:
        return 0.8
    if distance <= 2 and len(want) >= 8:
        return 0.72
    return 0.0


def best_label(token: str, names: tuple[str, ...]) -> float:
    return max((similarity(token, name) for name in names), default=0.0)


def parse_date(text: str) -> str | None:
    match = re.search(r"(\d{4})-(\d{2})-(\d{2})", text)
    if match:
        year, month, day = int(match.group(1)), int(match.group(2)), int(match.group(3))
    else:
        match = re.search(r"(\d{1,2})[.\-/](\d{1,2})[.\-/](\d{2,4})", text)
        if not match:
            return None
        day, month, year = int(match.group(1)), int(match.group(2)), int(match.group(3))
        if year < 100:
            year += 2000
    if not (1 <= month <= 12 and 1 <= day <= 31 and 1990 <= year <= 2100):
        return None
    return f"{year:04d}-{month:02d}-{day:02d}"


def parse_amount(text: str) -> float | None:
    match = re.search(r"-?\d{1,3}(?:\.\d{3})*,\d{2}|-?\d+,\d{2}", text.replace(" ", ""))
    if not match:
        return None
    return float(match.group(0).replace(".", "").replace(",", "."))


def parse_quantity(text: str) -> float | None:
    amount = parse_amount(text)
    if amount is not None:
        return amount
    match = re.fullmatch(r"\d+(?:[.,]\d+)?", text.strip())
    if not match:
        return None
    return float(text.strip().replace(",", "."))


def iban_ok(text: str) -> str | None:
    compact = re.sub(r"\s+", "", text).upper()
    match = re.search(r"[A-Z]{2}\d{2}[A-Z0-9]{10,30}", compact)
    if not match:
        return None
    iban = match.group(0)
    if not 15 <= len(iban) <= 34:
        return None
    moved = iban[4:] + iban[:4]
    digits = "".join(str(ord(char) - 55) if char.isalpha() else char for char in moved)
    if int(digits) % 97 != 1:
        return None
    return iban


def bic_ok(text: str) -> str | None:
    match = re.search(r"\b[A-Z]{6}[A-Z0-9]{2}(?:[A-Z0-9]{3})?\b", text.upper())
    return match.group(0) if match else None


def vat_ok(text: str) -> str | None:
    match = re.search(r"\b[A-Z]{2}\s?[0-9A-Z]{8,12}\b", text.upper().replace(" ", ""))
    if not match:
        return None
    value = match.group(0)
    if iban_ok(value):
        return None
    return value


def group_lines(words: list[Word]) -> list[Line]:
    ordered = sorted(words, key=lambda word: (word.page, word.y0, word.x0))
    lines: list[Line] = []
    for word in ordered:
        placed = False
        for line in lines:
            if line.page != word.page:
                continue
            height = max(4.0, (line.y1 - line.y0 + word.y1 - word.y0) / 2)
            if abs(line.y0 - word.y0) <= height * 0.7:
                line.words.append(word)
                placed = True
                break
        if not placed:
            lines.append(Line(page=word.page, words=[word]))
    for line in lines:
        line.words.sort(key=lambda word: word.x0)
    lines.sort(key=lambda line: (line.page, line.y0))
    return lines


def mark_roles(lines: list[Line]) -> None:
    table = False
    for line in lines:
        text = norm(line.text)
        tokens = text.split()
        header_hits = sum(1 for names in HEADER.values() if any(best_label(token, names) >= 0.9 for token in tokens))
        if header_hits >= 2 and best_label(text, HEADER["description"]) >= 0.8:
            line.role = "table-header"
            table = True
            continue
        if any(token in SKIP_ROW or token.startswith("zwischensumme") for token in tokens) and "bezeichnung" not in text:
            line.role = "amounts"
            table = False
            continue
        if best_label(text, LABELS["iban"]) >= 0.9 or "iban" in text:
            line.role = "payment"
            table = False
            continue
        if any(best_label(text, LABELS[name]) >= 0.9 for name in ("payable", "gross", "net", "tax")):
            line.role = "amounts"
            table = False
            continue
        if any(best_label(text, LABELS[name]) >= 0.9 for name in ("invoiceNumber", "invoiceDate", "dateGeneric")):
            line.role = "invoiceHeader"
            table = False
            continue
        if table:
            line.role = "lines"
            continue
        if line.y0 < 160:
            line.role = "letterhead"
        else:
            line.role = "body"


def center(word: Word) -> tuple[float, float]:
    return ((word.x0 + word.x1) / 2, (word.y0 + word.y1) / 2)


def distance(left: Word, right: Word) -> float:
    if left.page != right.page:
        return 9999.0
    ax, ay = center(left)
    bx, by = center(right)
    return math.hypot(ax - bx, ay - by)


def sigmoid(value: float) -> float:
    if value >= 0:
        return 1 / (1 + math.exp(-value))
    ez = math.exp(value)
    return ez / (1 + ez)


def box_of(word: Word) -> str:
    return f"{word.x0:.0f} {word.y0:.0f} {word.x1:.0f} {word.y1:.0f}"


def empty_field() -> dict:
    return {"value": "", "quality": 0.0, "page": 0, "box": ""}


def field_from(value: str, quality: float, word: Word | None) -> dict:
    if word is None:
        return {"value": value, "quality": round(quality, 2), "page": 0, "box": ""}
    return {"value": value, "quality": round(max(0.0, min(1.0, quality)), 2), "page": word.page, "box": box_of(word)}


def hints_for(accounts: list[dict], field_name: str) -> list[dict]:
    found = []
    for account in accounts:
        for hint in account.get("hints", []):
            if hint.get("field") in (field_name, ""):
                found.append(hint)
    return found


def collect_anchors(lines: list[Line]) -> dict[str, list[Word]]:
    anchors = {name: [] for name in LABELS}
    for line in lines:
        for word in line.words:
            for name, labels in LABELS.items():
                if best_label(word.text, labels) >= 0.72:
                    anchors[name].append(word)
        joined = line.text
        for name, labels in LABELS.items():
            if best_label(joined, labels) >= 0.9 and not anchors[name]:
                anchors[name].append(line.words[0])
    return anchors


def nearest(word: Word, anchors: list[Word]) -> float:
    if not anchors:
        return 9999.0
    return min(distance(word, anchor) for anchor in anchors)


def same_line_right(anchor: Word, word: Word) -> bool:
    height = max(4.0, word.y1 - word.y0)
    return anchor.page == word.page and word.x0 >= anchor.x0 - 2 and abs(word.y0 - anchor.y0) <= height * 0.8


def add_hint_anchors(lines: list[Line], anchors: dict[str, list[Word]], accounts: list[dict]) -> None:
    for account in accounts:
        for hint in account.get("hints", []):
            label = hint.get("label") or ""
            field_name = hint.get("field") or ""
            if not label or not field_name:
                continue
            for line in lines:
                for word in line.words:
                    if best_label(word.text, (label,)) >= 0.8:
                        anchors.setdefault(field_name, []).append(word)


def active_weights(field_name: str, model: dict | None, account_id: str) -> dict:
    weights = dict(WEIGHTS.get(field_name, {}))
    learned = ((model or {}).get("fields") or {}).get(field_name) or {}
    weights.update(learned)
    extra = (((model or {}).get("accounts") or {}).get(account_id) or {}).get(field_name) or {}
    for name, value in extra.items():
        weights[name] = weights.get(name, 0.0) + value
    return weights


def candidate_features(field_name: str, word: Word, value_ok: bool, anchors: dict[str, list[Word]], role: str, accounts: list[dict]) -> dict:
    own = anchors.get(field_name, [])
    generic = anchors.get("dateGeneric", []) if field_name == "invoiceDate" else []
    near = nearest(word, own or generic)
    same = 1.0 if any(same_line_right(anchor, word) and distance(anchor, word) < 280 for anchor in (own or generic)) else 0.0
    below = 1.0 if any(anchor.page == word.page and word.y0 >= anchor.y0 and word.y0 - anchor.y1 < 36 and abs(word.x0 - anchor.x0) < 80 for anchor in (own or generic)) else 0.0
    label = 0.0
    if field_name == "invoiceDate":
        label = 1.0 if nearest(word, anchors.get("invoiceDate", [])) < 90 else (0.35 if nearest(word, generic) < 90 else 0.0)
    else:
        label = 1.0 if near < 90 else 0.0
    expected = {
        "invoiceNumber": "invoiceHeader",
        "invoiceDate": "invoiceHeader",
        "payable": "amounts",
        "gross": "amounts",
        "iban": "payment",
        "bic": "payment",
    }.get(field_name, "")
    role_hit = 1.0 if role == expected else 0.0
    near_feature = max(0.0, 1 - min(near, 400) / 400)
    near_number = 0.0
    if field_name == "invoiceDate":
        near_number = max(0.0, 1 - min(nearest(word, anchors.get("invoiceNumber", [])), 400) / 400)
    hint_hit = 0.0
    for hint in hints_for(accounts, field_name):
        pattern = hint.get("pattern") or ""
        if pattern and re.fullmatch(pattern, word.text.strip()):
            hint_hit = 1.0
        label_hint = hint.get("label") or ""
        if label_hint and best_label(word.text, (label_hint,)) < 0.5 and nearest(word, own) < 140:
            hint_hit = max(hint_hit, 0.85)
        region = hint.get("region") or ""
        if region and region == role:
            role_hit = 1.0
        if region == "near:invoiceNumber" and field_name == "invoiceDate":
            near_number = max(near_number, 0.85)
    counters = []
    if field_name == "invoiceDate":
        counters = anchors.get("serviceDate", []) + anchors.get("dueDate", [])
    elif field_name == "invoiceNumber":
        counters = anchors.get("dateGeneric", [])
    counter = 0.0
    if counters and own:
        if nearest(word, counters) + 12 < nearest(word, own or generic or anchors.get("invoiceNumber", [])):
            counter = 1.0
    elif counters and field_name == "invoiceDate":
        number_distance = nearest(word, anchors.get("invoiceNumber", []))
        if nearest(word, counters) + 12 < number_distance:
            counter = 1.0
    features = {
        "same": same,
        "below": below,
        "label": label,
        "role": role_hit,
        "hint": hint_hit,
        "near": near_feature,
        "near_number": near_number,
        "counter": counter,
        "type": 1.0 if value_ok else 0.0,
    }
    return features


def score_candidate(field_name: str, word: Word, value_ok: bool, anchors: dict[str, list[Word]], role: str, accounts: list[dict], model: dict | None = None, account_id: str = "") -> float:
    weights = active_weights(field_name, model, account_id)
    features = candidate_features(field_name, word, value_ok, anchors, role, accounts)
    total = weights.get("bias", -1.0)
    for name, weight in weights.items():
        if name == "bias":
            continue
        total += weight * features.get(name, 0.0)
    if not value_ok:
        return 0.0
    return sigmoid(total)


def line_role(lines: list[Line], word: Word) -> str:
    for line in lines:
        if word in line.words:
            return line.role
    return "body"


def pick(field_name: str, options: list[tuple[Word, str, bool]], lines: list[Line], anchors, accounts, used: set[int], model: dict | None = None, account_id: str = "") -> dict:
    best = None
    best_score = 0.0
    for word, value, ok in options:
        if id(word) in used or not ok:
            continue
        score = score_candidate(field_name, word, ok, anchors, line_role(lines, word), accounts, model, account_id)
        if score > best_score:
            best_score = score
            best = (word, value, score)
    if best is None or best_score < 0.45:
        return empty_field()
    used.add(id(best[0]))
    return field_from(best[1], best[2], best[0])


def money_options(words: list[Word]) -> list[tuple[Word, str, bool]]:
    options = []
    for word in words:
        amount = parse_amount(word.text)
        if amount is not None and parse_date(word.text) is None:
            options.append((word, f"{amount:.2f}", True))
    return options


def date_options(words: list[Word]) -> list[tuple[Word, str, bool]]:
    options = []
    for word in words:
        iso = parse_date(word.text)
        if iso:
            options.append((word, iso, True))
    return options


def number_options(words: list[Word], accounts: list[dict]) -> list[tuple[Word, str, bool]]:
    patterns = [hint.get("pattern") for hint in hints_for(accounts, "invoiceNumber") if hint.get("pattern")]
    options = []
    for word in words:
        text = word.text.strip()
        if parse_date(text) or parse_amount(text) or iban_ok(text) or not re.search(r"\d", text):
            continue
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9\-/.]{2,30}", text):
            continue
        if patterns and not any(re.fullmatch(pattern, text) for pattern in patterns):
            continue
        options.append((word, text, True))
    return options


def adjust_amounts(result: dict, lines_out: list[dict]) -> None:
    payable = _dec(result["payable"]["value"])
    gross = _dec(result["gross"]["value"])
    tax_sum = sum(_dec(tax["amount"]) or 0 for tax in result["taxes"])
    net_sum = sum(_dec(tax["net"]) or 0 for tax in result["taxes"])
    line_sum = sum(_dec(line["amount"]["value"]) or 0 for line in lines_out)
    if payable is not None and (net_sum or line_sum) and tax_sum:
        base = net_sum or line_sum
        if abs((base + tax_sum) - payable) <= 0.05:
            _bump(result["payable"], 0.08)
            for tax in result["taxes"]:
                tax["quality"] = round(min(1.0, tax["quality"] + 0.08), 2)
        else:
            _drop(result["payable"], 0.2)
    if payable is None and gross is not None:
        result["payable"] = dict(result["gross"])
        result["payable"]["quality"] = round(max(0.0, result["gross"]["quality"] - 0.25), 2)
    if result["invoiceDate"]["value"] and result["dueDate"]["value"]:
        if result["invoiceDate"]["value"] > result["dueDate"]["value"]:
            _drop(result["invoiceDate"], 0.2)
            _drop(result["dueDate"], 0.2)


def _dec(value: str) -> float | None:
    if not value:
        return None
    try:
        return float(value)
    except ValueError:
        return None


def _bump(item: dict, amount: float) -> None:
    if item.get("value"):
        item["quality"] = round(min(1.0, item["quality"] + amount), 2)


def _drop(item: dict, amount: float) -> None:
    if item.get("value"):
        item["quality"] = round(max(0.0, item["quality"] - amount), 2)


def extract_lines(lines: list[Line]) -> list[dict]:
    header = next((line for line in lines if line.role == "table-header"), None)
    if header is None:
        return []
    columns = {}
    for word in header.words:
        for name, labels in HEADER.items():
            if best_label(word.text, labels) >= 0.8 and name not in columns:
                columns[name] = word
    if "description" not in columns or "amount" not in columns and "unitPrice" not in columns:
        return []
    ordered = sorted(columns.items(), key=lambda item: item[1].x0)
    spans = {}
    for index, (name, word) in enumerate(ordered):
        right = ordered[index + 1][1].x0 if index + 1 < len(ordered) else word.x1 + 80
        spans[name] = (word.x0 - 8, right - 4)
    items: list[dict] = []
    for line in lines:
        if line.role != "lines":
            continue
        tokens = [norm(word.text) for word in line.words]
        if tokens and (tokens[0] in SKIP_ROW or tokens[0].startswith("zwischen")):
            continue
        cells = {name: [] for name in spans}
        for word in line.words:
            mid = (word.x0 + word.x1) / 2
            for name, (left, right) in spans.items():
                if left <= mid < right:
                    cells[name].append(word)
                    break
        amount_words = cells.get("amount", [])
        amount = parse_amount(" ".join(word.text for word in amount_words)) if amount_words else None
        description = " ".join(word.text for word in cells.get("description", [])).strip()
        if amount is None:
            if items and description:
                previous = items[-1]["description"]
                previous["value"] = (previous["value"] + " " + description).strip()
            continue
        quantity = parse_quantity(" ".join(word.text for word in cells.get("quantity", []))) if cells.get("quantity") else None
        unit_price = parse_amount(" ".join(word.text for word in cells.get("unitPrice", []))) if cells.get("unitPrice") else None
        discount = parse_amount(" ".join(word.text for word in cells.get("discount", []))) if cells.get("discount") else 0.0
        rate_text = " ".join(word.text for word in cells.get("taxRate", []))
        rate = None
        rate_match = re.search(r"(19|7|0)\s*%?", rate_text)
        if rate_match:
            rate = rate_match.group(1)
        quality = 0.62
        if quantity is not None and unit_price is not None and abs(quantity * unit_price - (discount or 0) - amount) <= 0.05:
            quality = 0.9
        elif quantity is None and unit_price is not None and abs(unit_price - amount) <= 0.05:
            quantity = 1.0
            quality = 0.55
        def cell(value: str, words: list[Word], quality: float) -> dict:
            return field_from(value, quality if value else 0.0, words[0] if words else None)

        items.append({
            "position": cell(str(len(items) + 1), cells.get("position", []), quality),
            "articleNumber": cell(" ".join(word.text for word in cells.get("article", [])), cells.get("article", []), quality),
            "description": cell(description, cells.get("description", []), quality if description else 0.0),
            "quantity": cell(f"{quantity:.2f}" if quantity is not None else "", cells.get("quantity", []), quality if quantity is not None else 0.0),
            "unit": cell(" ".join(word.text for word in cells.get("unit", [])), cells.get("unit", []), quality),
            "unitPrice": cell(f"{unit_price:.2f}" if unit_price is not None else "", cells.get("unitPrice", []), quality if unit_price is not None else 0.0),
            "discount": cell(f"{discount:.2f}" if discount else "", cells.get("discount", []), quality if discount else 0.0),
            "amount": cell(f"{amount:.2f}", amount_words, quality),
            "taxRate": cell(rate or "", cells.get("taxRate", []), quality if rate else 0.0),
            "quality": round(quality, 2),
        })
    rates = {line["taxRate"]["value"] for line in items if line["taxRate"]["value"]}
    return items


def tax_rows(lines: list[Line]) -> list[dict]:
    found = []
    for line in lines:
        if line.role not in ("amounts", "body", "payment"):
            continue
        text = line.text
        if best_label(text, LABELS["tax"]) < 0.72 and not re.search(r"\b(19|7)\s*%", text):
            continue
        rate_match = re.search(r"(19|7|0)\s*%", text)
        amounts = []
        for word in line.words:
            amount = parse_amount(word.text)
            if amount is not None:
                amounts.append((word, amount))
        if not rate_match or not amounts:
            continue
        rate = rate_match.group(1)
        tax_amount = amounts[-1][1]
        net = amounts[-2][1] if len(amounts) > 1 else None
        found.append({
            "rate": rate,
            "net": f"{net:.2f}" if net is not None else "",
            "amount": f"{tax_amount:.2f}",
            "quality": 0.7,
            "page": line.page,
            "box": box_of(amounts[-1][0]),
        })
    unique = []
    seen = set()
    for row in found:
        key = (row["rate"], row["amount"])
        if key in seen:
            continue
        seen.add(key)
        unique.append(row)
    return unique


def match_account(lines: list[Line], accounts: list[dict], iban: str, meta: dict | None) -> dict:
    head = " ".join(line.text for line in lines if line.role in ("letterhead", "invoiceHeader", "body") and line.y0 < 220)
    head_norm = norm(head)
    best = {"id": "", "quality": 0.0}
    mail = norm((meta or {}).get("from", ""))
    for account in accounts:
        classes = set((account.get("classes") or "").split())
        if "self" in classes:
            continue
        if not ({"creditor", "debitor"} & classes or account.get("type") in ("creditor", "debitor")):
            continue
        quality = 0.0
        names = [account.get("name") or "", account.get("company") or ""]
        for name in names:
            if len(norm(name)) >= 4 and norm(name) in head_norm:
                quality = max(quality, 0.72)
        for account_iban in account.get("ibans", []):
            if iban and iban_ok(account_iban) == iban:
                quality = max(quality, 0.95)
        email = norm(account.get("email") or "")
        if email and email in mail:
            quality = max(quality, 0.8)
        if quality > best["quality"]:
            best = {"id": account.get("id") or "", "quality": round(quality, 2)}
    return best


def assign_words(words: list[Word], accounts: list[dict] | None = None, meta: dict | None = None, model: dict | None = None) -> dict:
    accounts = accounts or []
    lines = group_lines(words)
    mark_roles(lines)
    anchors = collect_anchors(lines)
    add_hint_anchors(lines, anchors, accounts)
    iban_word = None
    iban_value = ""
    for word in words:
        got = iban_ok(word.text)
        if got:
            iban_word = word
            iban_value = got
            break
    account = match_account(lines, accounts, iban_value, meta)
    account_id = account.get("id") or ""
    used: set[int] = set()
    dates = date_options(words)
    moneys = money_options(words)
    numbers = number_options(words, accounts)
    invoice_date = pick("invoiceDate", dates, lines, anchors, accounts, used, model, account_id)
    service_date = pick("serviceDate", dates, lines, anchors, accounts, used, model, account_id)
    due_date = pick("dueDate", dates, lines, anchors, accounts, used, model, account_id)
    invoice_number = pick("invoiceNumber", numbers, lines, anchors, accounts, used, model, account_id)
    payable = pick("payable", moneys, lines, anchors, accounts, used, model, account_id)
    gross = pick("gross", moneys, lines, anchors, accounts, used, model, account_id)
    bic_word = None
    bic_value = ""
    for word in words:
        got = bic_ok(word.text)
        if got and not iban_ok(word.text):
            bic_word = word
            bic_value = got
            break
    vat_word = None
    vat_value = ""
    for word in words:
        got = vat_ok(word.text)
        if got:
            vat_word = word
            vat_value = got
            break
    seller_lines = [line.text for line in lines if line.role == "letterhead"][:4]
    result = {
        "source": "text",
        "pages": max((word.page for word in words), default=1),
        "account": account,
        "invoiceNumber": invoice_number,
        "invoiceDate": invoice_date,
        "serviceDate": service_date,
        "dueDate": due_date,
        "sellerName": field_from(seller_lines[0] if seller_lines else "", 0.55 if seller_lines else 0.0, None),
        "sellerAddress": field_from(" ".join(seller_lines[1:]) if len(seller_lines) > 1 else "", 0.4 if len(seller_lines) > 1 else 0.0, None),
        "vatId": field_from(vat_value, 0.9 if vat_value else 0.0, vat_word),
        "payable": payable,
        "gross": gross,
        "taxes": tax_rows(lines),
        "iban": field_from(iban_value, 0.95 if iban_value else 0.0, iban_word),
        "bic": field_from(bic_value, 0.8 if bic_value else 0.0, bic_word),
        "paymentMethod": field_from("transfer" if iban_value else "", 0.7 if iban_value else 0.0, iban_word),
        "lines": extract_lines(lines),
        "words": words,
    }
    if not result["taxes"]:
        rates = {line["taxRate"]["value"] for line in result["lines"] if line["taxRate"]["value"]}
        if len(rates) == 1:
            rate = next(iter(rates))
            for line in result["lines"]:
                if not line["taxRate"]["value"]:
                    line["taxRate"]["value"] = rate
                    line["taxRate"]["quality"] = 0.45
    adjust_amounts(result, result["lines"])
    return result
