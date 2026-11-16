"""Fünf Stufen: Layout, Kandidaten, Konto, Merkmale, gemeinsame Auflösung."""

from __future__ import annotations

import math
import re
from dataclasses import dataclass, field

from docman_intelligence.vocab import HEADER_KEYS, LABEL_KEYS, field_id, region_id

LABELS = {
    "invoiceNumber": LABEL_KEYS.get("invoice.id", ()),
    "invoiceDate": LABEL_KEYS.get("invoice.date", ()),
    "dateGeneric": LABEL_KEYS.get("invoice.date.generic", ()),
    "serviceDate": LABEL_KEYS.get("invoice.date.service", ()),
    "dueDate": LABEL_KEYS.get("invoice.date.due", ()),
    "payable": LABEL_KEYS.get("invoice.amount.payable", ()),
    "gross": LABEL_KEYS.get("invoice.amount.brutto", ()),
    "net": LABEL_KEYS.get("invoice.amount.netto", ()),
    "tax": LABEL_KEYS.get("invoice.tax.rate", ()),
    "skonto": LABEL_KEYS.get("invoice.amount.skonto", ()),
    "discount": LABEL_KEYS.get("invoice.amount.discount", ()),
    "dunning": LABEL_KEYS.get("invoice.amount.dunning", ()),
    "iban": LABEL_KEYS.get("sender.iban", ()),
    "bic": LABEL_KEYS.get("sender.bic", ()),
    "vat": LABEL_KEYS.get("sender.vat", ()),
}

PAGE_NOISE = re.compile(r"^(?:\.?\s*)?(?:page|seite)\b|\bof\s+\d+\b", re.I)
BIC_COUNTRY = ("DE", "AT", "CH", "NL", "FR", "BE", "LU", "IT", "ES", "GB", "IE", "PL", "US")

HEADER = {
    "description": HEADER_KEYS.get("article.name", ()),
    "quantity": HEADER_KEYS.get("article.count", ()),
    "unit": HEADER_KEYS.get("article.unit", ()),
    "unitPrice": HEADER_KEYS.get("article.price.unit", ()),
    "discount": HEADER_KEYS.get("article.discount", ()),
    "amount": HEADER_KEYS.get("article.amount.brutto", ()),
    "taxRate": HEADER_KEYS.get("article.tax.rate", ()),
    "position": HEADER_KEYS.get("article.position", ()),
    "article": HEADER_KEYS.get("article.id", ()),
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
    "skonto": {"bias": -1.0, "same": 1.4, "below": 0.6, "label": 2.2, "role": 0.5, "hint": 1.4, "near": 1.2, "counter": -0.3, "type": 1.1},
    "discount": {"bias": -1.0, "same": 1.4, "below": 0.6, "label": 2.0, "role": 0.4, "hint": 1.3, "near": 1.2, "counter": -0.3, "type": 1.0},
    "dunning": {"bias": -1.0, "same": 1.4, "below": 0.6, "label": 2.2, "role": 0.4, "hint": 1.4, "near": 1.2, "counter": -0.3, "type": 1.0},
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
    shorter, longer = (got, want) if len(got) <= len(want) else (want, got)
    # Nur wenn der kürzere String ein wesentliches Präfix ist (nicht Menge⊂Mengeneinheit)
    if len(shorter) >= 5 and longer.startswith(shorter) and len(shorter) / len(longer) >= 0.55:
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
    compact = text.replace(" ", "").replace("€", "").strip()
    if not compact or compact.startswith(".") or compact.startswith(","):
        return None
    match = re.fullmatch(r"-?\d{1,3}(?:\.\d{3})*,\d{2}|-?\d+,\d{2}|-?\d+\.\d{2}", compact)
    if not match:
        match = re.search(r"-?\d{1,3}(?:\.\d{3})*,\d{2}|-?\d+,\d{2}", compact)
        if not match:
            return None
    raw = match.group(0)
    if raw.startswith(".") or raw.startswith(","):
        return None
    if "," in raw:
        return float(raw.replace(".", "").replace(",", "."))
    return float(raw)


def parse_amount_joined(texts: list[str]) -> float | None:
    """OCR splittet oft 11.000,00 in '11' und '.000,00'."""
    joined = "".join(part.strip() for part in texts if part and part.strip())
    amount = parse_amount(joined)
    if amount is not None:
        return amount
    for part in texts:
        amount = parse_amount(part)
        if amount is not None and amount >= 1:
            return amount
    return None


def parse_quantity(text: str) -> float | None:
    amount = parse_amount(text)
    if amount is not None:
        return amount
    match = re.fullmatch(r"\d+(?:[.,]\d+)?", text.strip())
    if not match:
        return None
    return float(text.strip().replace(",", "."))


def iban_ok(text: str) -> str | None:
    compact = re.sub(r"[\s\-]+", "", text).upper()
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


def find_iban(words: list[Word]) -> tuple[str, Word | None]:
    """IBAN oft über mehrere OCR-Wörter gesplittet (DE10 2826 …)."""
    ordered = sorted(words, key=lambda word: (word.page, word.y0, word.x0))
    for index, word in enumerate(ordered):
        got = iban_ok(word.text)
        if got:
            return got, word
        chunk = re.sub(r"\s+", "", word.text)
        last = word
        for nxt in ordered[index + 1 : index + 8]:
            if nxt.page != word.page or abs(nxt.y0 - word.y0) > 12:
                break
            if nxt.x0 - last.x1 > 80:
                break
            chunk += re.sub(r"\s+", "", nxt.text)
            last = nxt
            got = iban_ok(chunk)
            if got:
                return got, word
    joined = "".join(word.text for word in ordered)
    got = iban_ok(joined)
    return (got or ""), (ordered[0] if got and ordered else None)


def bic_ok(text: str) -> str | None:
    match = re.search(r"\b[A-Z]{4}[A-Z]{2}[A-Z0-9]{2}(?:[A-Z0-9]{3})?\b", text.upper())
    if not match:
        return None
    value = match.group(0)
    if value[4:6] not in BIC_COUNTRY:
        return None
    return value


def vat_ok(text: str) -> str | None:
    compact = text.upper().replace(" ", "")
    match = re.search(r"\b([A-Z]{2})([0-9][0-9A-Z]{7,11})\b", compact)
    if not match:
        return None
    value = match.group(1) + match.group(2)
    if iban_ok(value):
        return None
    if not any(char.isdigit() for char in match.group(2)):
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
        has_description = any(best_label(token, HEADER["description"]) >= 0.8 for token in tokens)
        if header_hits >= 2 and has_description:
            line.role = "table-header"
            table = True
            continue
        if any(token in SKIP_ROW or token.startswith("zwischensumme") for token in tokens) and "bezeichnung" not in text:
            line.role = "amounts"
            table = False
            continue
        if any(best_label(token, LABELS["iban"]) >= 0.9 for token in tokens) or "iban" in text:
            line.role = "payment"
            table = False
            continue
        if any(best_label(token, LABELS[name]) >= 0.9 for name in ("payable", "gross", "net", "tax") for token in tokens):
            line.role = "amounts"
            table = False
            continue
        if any(best_label(token, LABELS[name]) >= 0.9 for name in ("invoiceNumber", "invoiceDate", "dateGeneric") for token in tokens):
            line.role = "invoiceHeader"
            table = False
            continue
        if table:
            line.role = "lines"
            continue
        if PAGE_NOISE.search(line.text):
            line.role = "noise"
            continue
        # Vorläufig letterhead/body; Kuvert-Absender wird nach dem Pass markiert
        if line.y0 < 160:
            line.role = "letterhead"
        else:
            line.role = "body"
    for line in lines:
        if line.role in ("letterhead", "body") and is_envelope_sender(line, []):
            line.role = "envelope"


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
    wanted = field_id(field_name)
    found = []
    for account in accounts:
        for hint in account.get("hints", []):
            hint_field = field_id(hint.get("field") or "")
            if hint_field in (wanted, field_name) or hint.get("field") in (field_name, ""):
                found.append(hint)
    return found


def collect_anchors(lines: list[Line]) -> dict[str, list[Word]]:
    anchors = {name: [] for name in LABELS}
    for line in lines:
        for word in line.words:
            for name, labels in LABELS.items():
                if best_label(word.text, labels) >= 0.9:
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
            raw_field = hint.get("field") or ""
            field_name = field_id(raw_field)
            if field_name == "party.self" or not field_name:
                continue
            if not label:
                continue
            # Map dotted hint types onto interne Anker-Keys
            internal = {
                "invoice.id": "invoiceNumber",
                "invoice.date": "invoiceDate",
                "invoice.date.service": "serviceDate",
                "invoice.date.due": "dueDate",
                "invoice.amount.payable": "payable",
                "invoice.amount.brutto": "gross",
                "sender.vat": "vat",
                "sender.iban": "iban",
                "sender.bic": "bic",
            }.get(field_name, field_name)
            for line in lines:
                for word in line.words:
                    if best_label(word.text, (label,)) >= 0.8:
                        anchors.setdefault(internal, []).append(word)


def active_weights(field_name: str, model: dict | None, account_id: str) -> dict:
    weights = dict(WEIGHTS.get(field_name, {}))
    learned = ((model or {}).get("fields") or {}).get(field_name) or {}
    weights.update(learned)
    extra = (((model or {}).get("accounts") or {}).get(account_id) or {}).get(field_name) or {}
    for name, value in extra.items():
        weights[name] = weights.get(name, 0.0) + value
    return weights


def candidate_features(field_name: str, word: Word, value_ok: bool, anchors: dict[str, list[Word]], role: str, accounts: list[dict], amount: float | None = None, line_text: str = "") -> dict:
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
        region_canon = region_id(region)
        role_from_region = {
            "invoice.header": "invoiceHeader",
            "invoiceHeader": "invoiceHeader",
            "invoice.amounts": "amounts",
            "amounts": "amounts",
            "article.lines": "lines",
            "lines": "lines",
            "sender.payment": "payment",
            "payment": "payment",
        }.get(region_canon or region, "")
        if region and (region == role or region_canon == role or role_from_region == role):
            role_hit = 1.0
        if region_canon in ("near:invoice.id", "near:invoiceNumber") and field_name == "invoiceDate":
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
    # Für Endbeträge große Werte bevorzugen; Tabellen-Zellen (Einzelpreis) stark abwerten.
    magnitude = 0.0
    if amount is not None and field_name in ("payable", "gross"):
        if role == "lines":
            magnitude = -1.4
        elif amount >= 1000:
            magnitude = 1.0 + min(amount, 100000) / 100000
        elif amount >= 100:
            magnitude = 0.35
        elif amount < 20:
            magnitude = -0.85
        else:
            magnitude = -0.2
        normalized_line = norm(line_text)
        if field_name == "payable" and "netto" in normalized_line and "gesamt" not in normalized_line:
            magnitude -= 1.2
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
        "magnitude": magnitude,
    }
    return features


def score_candidate(field_name: str, word: Word, value_ok: bool, anchors: dict[str, list[Word]], role: str, accounts: list[dict], model: dict | None = None, account_id: str = "", amount: float | None = None, line_text: str = "") -> float:
    weights = active_weights(field_name, model, account_id)
    weights.setdefault("magnitude", 1.1 if field_name in ("payable", "gross") else 0.0)
    features = candidate_features(field_name, word, value_ok, anchors, role, accounts, amount, line_text)
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
        amount = None
        try:
            amount = float(value)
        except ValueError:
            amount = None
        role = line_role(lines, word)
        text = next((line.text for line in lines if word in line.words), "")
        score = score_candidate(field_name, word, ok, anchors, role, accounts, model, account_id, amount, text)
        if score > best_score + 1e-9:
            best_score = score
            best = (word, value, score)
        elif best is not None and abs(score - best_score) <= 1e-9 and amount is not None:
            try:
                if amount > float(best[1]):
                    best = (word, value, score)
            except ValueError:
                pass
    if best is None or best_score < 0.45:
        return empty_field()
    used.add(id(best[0]))
    return field_from(best[1], best[2], best[0])


def money_options(words: list[Word]) -> list[tuple[Word, str, bool]]:
    options = []
    ordered = sorted(words, key=lambda word: (word.page, word.y0, word.x0))
    used: set[int] = set()
    for index, word in enumerate(ordered):
        if id(word) in used or parse_date(word.text):
            continue
        amount = parse_amount(word.text)
        partner = None
        # Nur echte OCR-Bruchstücke verbinden: 11 + .000,00
        if amount is None and index + 1 < len(ordered):
            nxt = ordered[index + 1]
            frag = nxt.text.strip()
            if (
                word.page == nxt.page
                and abs(word.y0 - nxt.y0) <= 8
                and nxt.x0 - word.x1 < 40
                and re.match(r"^\.\d{3},\d{2}$", frag)
                and re.fullmatch(r"\d{1,3}", word.text.strip())
            ):
                joined = parse_amount_joined([word.text, frag])
                if joined is not None:
                    amount = joined
                    partner = nxt
        if amount is None or amount <= 0:
            continue
        options.append((word, f"{amount:.2f}", True))
        used.add(id(word))
        if partner is not None:
            used.add(id(partner))
    return options


def date_options(words: list[Word]) -> list[tuple[Word, str, bool]]:
    options = []
    for word in words:
        iso = parse_date(word.text)
        if iso:
            options.append((word, iso, True))
    return options


def number_options(words: list[Word], accounts: list[dict]) -> list[tuple[Word, str, bool]]:
    patterns = [hint.get("pattern") for hint in hints_for(accounts, "invoice.id") if hint.get("pattern")]
    patterns += [hint.get("pattern") for hint in hints_for(accounts, "invoiceNumber") if hint.get("pattern")]
    patterns = [pattern for pattern in patterns if pattern]
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


def clean_article_name(text: str) -> str:
    """OCR mischt oft Ursprungsland/Waren-Nr. in die Bezeichnung."""
    value = text.strip()
    value = re.sub(r"(?i)\s*Ursprungsland\s*:\s*[A-Z]{2}\b", " ", value)
    value = re.sub(r"(?i)\bUrsprungsland\s*:?\s*", " ", value)
    value = re.sub(r"(?i)\s*Stat\.?\s*Waren\s*Nr\.?\s*:?\s*\S+", " ", value)
    value = re.sub(r"(?i)\s*WHG\b", " ", value)
    value = re.sub(r"\s+", " ", value).strip(" ,;/-")
    return value


def extract_lines(lines: list[Line]) -> list[dict]:
    header = next((line for line in lines if line.role == "table-header"), None)
    if header is None:
        return []
    columns = {}
    taken = set()
    for word in header.words:
        if id(word) in taken:
            continue
        ranked = sorted(
            ((name, best_label(word.text, labels)) for name, labels in HEADER.items() if name not in columns),
            key=lambda item: item[1],
            reverse=True,
        )
        if ranked and ranked[0][1] >= 0.8:
            columns[ranked[0][0]] = word
            taken.add(id(word))
    if "description" not in columns or ("amount" not in columns and "unitPrice" not in columns):
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
        amount = parse_amount_joined([word.text for word in amount_words]) if amount_words else None
        description = clean_article_name(" ".join(word.text for word in cells.get("description", [])))
        if amount is None:
            if items and description and not re.search(r"(?i)^ursprungsland|^stat\.?\s*waren", description):
                previous = items[-1]["description"]
                previous["value"] = clean_article_name((previous["value"] + " " + description).strip())
            continue
        quantity = parse_quantity(" ".join(word.text for word in cells.get("quantity", []))) if cells.get("quantity") else None
        unit_price = parse_amount_joined([word.text for word in cells.get("unitPrice", [])]) if cells.get("unitPrice") else None
        discount = parse_amount_joined([word.text for word in cells.get("discount", [])]) if cells.get("discount") else 0.0
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


def self_accounts(accounts: list[dict]) -> list[dict]:
    found = []
    for account in accounts:
        classes = set((account.get("classes") or "").split())
        if "self" in classes or account.get("type") == "self":
            found.append(account)
    return found


def self_markers(accounts: list[dict]) -> list[str]:
    """Namen/Adressen/Hints des eigenen Mandanten — dürfen nicht als Seller gelten."""
    markers = []
    for account in self_accounts(accounts):
        for raw in (account.get("name"), account.get("company"), account.get("address")):
            text = norm(raw or "")
            if len(text) >= 4:
                markers.append(text)
            for part in re.split(r"[\s,;|/]+", text):
                if len(part) >= 5 and not part.isdigit():
                    markers.append(part)
        for hint in account.get("hints", []):
            if field_id(hint.get("field") or "") != "party.self":
                continue
            label = norm(hint.get("label") or "")
            if len(label) >= 4:
                markers.append(label)
    # längere Marker zuerst
    return sorted(set(markers), key=len, reverse=True)


def looks_like_self(text: str, markers: list[str]) -> bool:
    hay = norm(text)
    if len(hay) < 3:
        return False
    for marker in markers:
        if marker in hay:
            return True
        # kurze Firmenbestandteile: mind. ein starker Treffer mit zweitem Token
        if len(marker) >= 8 and sum(1 for token in marker.split() if len(token) >= 4 and token in hay) >= 2:
            return True
    return False


LEGAL_FORM = re.compile(
    r"\b(?:GmbH|AG|UG|Ltd|Inc|GbR|OHG|e\.?\s*K\.?|KG(?:\s*aA)?|&\s*Co\.?\s*KG)\b",
    re.I,
)
ENVELOPE_SEP = re.compile(r"\s[-–—·•|/+]+\s")
POSTAL_CODE = re.compile(r"\b\d{4,5}\b")


def line_height(line: Line) -> float:
    if not line.words:
        return 0.0
    return max(word.y1 - word.y0 for word in line.words)


def is_envelope_sender(line: Line, markers: list[str]) -> bool:
    """Schmale einzeilige Absenderkennung im Sichtfenster (DIN-Kuvert)."""
    if PAGE_NOISE.search(line.text) or looks_like_self(line.text, markers):
        return False
    if not (40 <= line.y0 <= 280):
        return False
    window_words = [word for word in line.words if word.x0 < 340 and not parse_date(word.text)]
    if len(window_words) < 3:
        return False
    if max(word.x1 for word in window_words) > 400:
        return False
    text = " ".join(word.text for word in window_words).strip()
    if len(text) < 20:
        return False
    has_legal = bool(LEGAL_FORM.search(text))
    has_plz = bool(POSTAL_CODE.search(text))
    has_sep = bool(ENVELOPE_SEP.search(text))
    height = line_height(line)
    # Typisch: Firma + Trennzeichen + Straße/PLZ in einer schmalen Zeile
    if has_legal and has_plz and (has_sep or height <= 12):
        return True
    if has_legal and has_sep and has_plz:
        return True
    return False


def split_envelope_sender(text: str) -> tuple[str, str]:
    """Trennt 'Firma GmbH - Straße 1 · 12345 Ort' in Name und Adresse."""
    compact = re.sub(r"\s+", " ", text).strip()
    match = re.search(
        r"^(.*?\b(?:GmbH|AG|UG|Ltd|Inc|GbR|OHG|e\.?\s*K\.?|KG(?:\s*aA)?)"
        r"(?:\s*&\s*Co\.?\s*KG)?)\s*[-–—·•|/+,]+\s*(.+)$",
        compact,
        re.I,
    )
    if match:
        return match.group(1).strip(" ,;"), match.group(2).strip(" ,;")
    plz = POSTAL_CODE.search(compact)
    if plz and plz.start() > 12:
        before = compact[: plz.start()].rstrip(" ,;-·•|/+")
        # Straße oft direkt vor der PLZ
        street = re.search(r"([A-Za-zÄÖÜäöüß][A-Za-zÄÖÜäöüß0-9.\- ]+\s+\d+[a-zA-Z]?)\s*$", before)
        if street:
            name = before[: street.start()].strip(" ,;-·•|/+")
            address = (street.group(1) + " " + compact[plz.start() :]).strip()
            if name:
                return name, address
        return before, compact[plz.start() :].strip()
    return compact, ""


def pick_seller(lines: list[Line], accounts: list[dict] | None = None, matched: dict | None = None) -> tuple[dict, dict]:
    accounts = accounts or []
    markers = self_markers(accounts)
    candidates = [
        line for line in lines
        if line.role in ("letterhead", "body", "envelope") and line.y0 < 280 and not PAGE_NOISE.search(line.text)
        and not looks_like_self(line.text, markers)
    ]
    # Erkannter Kreditor/Debitor schlägt Blindraten aus dem Briefkopf
    matched_id = (matched or {}).get("id") or ""
    if matched_id and (matched or {}).get("quality", 0) >= 0.7:
        for account in accounts:
            if account.get("id") != matched_id:
                continue
            name = (account.get("company") or account.get("name") or "").strip()
            address = (account.get("address") or "").strip()
            if name and not looks_like_self(name, markers):
                return field_from(name, 0.85, None), field_from(address, 0.6 if address else 0.0, None)
    # Kuvert-Absenderkennung hat Vorrang vor Logo/Empfängerblock
    envelope = next((line for line in lines if is_envelope_sender(line, markers)), None)
    if envelope is not None:
        window_words = [word for word in envelope.words if word.x0 < 340 and not parse_date(word.text)]
        raw = " ".join(word.text for word in window_words).strip() or envelope.text
        name, address = split_envelope_sender(raw)
        if name and not looks_like_self(name, markers):
            anchor = window_words[0] if window_words else (envelope.words[0] if envelope.words else None)
            return field_from(name, 0.9, anchor), field_from(address, 0.75 if address else 0.0, anchor)
    preferred = [
        line for line in candidates
        if LEGAL_FORM.search(line.text)
    ]
    chosen = preferred[0] if preferred else (candidates[0] if candidates else None)
    if chosen is None:
        return empty_field(), empty_field()
    # Datum/Seite rechts im Briefkopf weglassen
    left_words = [word for word in chosen.words if word.x0 < 360 and not parse_date(word.text)]
    name = " ".join(word.text for word in left_words).strip() or chosen.text
    if looks_like_self(name, markers):
        return empty_field(), empty_field()
    rest = []
    for line in candidates:
        if line is chosen:
            continue
        piece = " ".join(word.text for word in line.words if word.x0 < 360 and not parse_date(word.text)).strip()
        if piece and not looks_like_self(piece, markers):
            rest.append(piece)
        if len(rest) >= 3:
            break
    return (
        field_from(name, 0.7 if preferred else 0.5, left_words[0] if left_words else (chosen.words[0] if chosen.words else None)),
        field_from(" ".join(rest), 0.4 if rest else 0.0, None),
    )


def _hint_text_or_pattern_hits(text: str, text_norm: str, hint: dict) -> float:
    """Treffer für einen Hint: Text (label) ODER Regex (pattern)."""
    label = (hint.get("label") or "").strip()
    pattern = (hint.get("pattern") or "").strip()
    score = 0.0
    if label and len(norm(label)) >= 3 and norm(label) in text_norm:
        score = max(score, 0.88)
    if pattern:
        try:
            if re.search(pattern, text, re.I):
                score = max(score, 0.9)
        except re.error:
            pass
    return score


def fuzzy_name_hit(name: str, hay: str) -> float:
    """Erkennt OCR-Tippfehler (Teichelt≈Reichelt) und Namensbestandteile."""
    want = norm(name)
    if len(want) < 4:
        return 0.0
    if want in hay:
        return 0.72
    tokens = [token for token in want.split() if len(token) >= 4]
    if not tokens:
        return 0.0
    hay_tokens = hay.split()
    hits = 0
    for token in tokens:
        if token in hay:
            hits += 1
            continue
        if any(similarity(token, other) >= 0.8 for other in hay_tokens if len(other) >= 4):
            hits += 1
    if hits == 0:
        return 0.0
    if hits >= 2 or (hits == 1 and len(tokens) == 1 and len(tokens[0]) >= 6):
        return 0.68
    return 0.55


def match_account(lines: list[Line], accounts: list[dict], iban: str, meta: dict | None, customer_number: str = "") -> dict:
    envelope_text = " ".join(line.text for line in lines if line.role == "envelope")
    head = " ".join(
        line.text for line in lines
        if line.role in ("envelope", "letterhead", "invoiceHeader", "body") and line.y0 < 280
    )
    full = " ".join(line.text for line in lines)
    head_norm = norm(head)
    full_norm = norm(full)
    envelope_norm = norm(envelope_text)
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
            quality = max(quality, fuzzy_name_hit(name, head_norm), fuzzy_name_hit(name, full_norm) * 0.95)
            if envelope_norm:
                envelope_hit = fuzzy_name_hit(name, envelope_norm)
                if envelope_hit > 0:
                    # Absenderzeile im Kuvertfenster ist der stärkste Namenshinweis
                    quality = max(quality, min(1.0, envelope_hit + 0.08))
        for account_iban in account.get("ibans", []):
            cleaned = iban_ok(account_iban) or re.sub(r"\s+", "", account_iban).upper()
            if iban and cleaned == iban:
                quality = max(quality, 0.95)
        email = norm(account.get("email") or "")
        if email:
            if email in mail or email in full_norm:
                quality = max(quality, 0.8)
            domain = email.split("@")[-1] if "@" in email else ""
            if domain and len(domain) >= 4 and (domain in mail or domain in full_norm):
                quality = max(quality, 0.78)
        stored_customer = (account.get("customerId") or "").strip()
        if customer_number and stored_customer and norm(customer_number) == norm(stored_customer):
            quality = max(quality, 0.9)
        for hint in account.get("hints", []):
            hint_type = field_id(hint.get("field") or "")
            hit = _hint_text_or_pattern_hits(full, full_norm, hint)
            if hit <= 0 and hint_type != "invoice.customer.id":
                continue
            if hint_type == "party.self":
                quality = max(quality, hit)
            elif hint_type == "invoice.customer.id" and customer_number:
                pattern = (hint.get("pattern") or "").strip()
                label = (hint.get("label") or "").strip()
                if pattern:
                    try:
                        if re.fullmatch(pattern, customer_number):
                            quality = max(quality, 0.92)
                    except re.error:
                        pass
                elif label and norm(label) == norm(customer_number):
                    quality = max(quality, 0.9)
            elif hit > 0:
                quality = max(quality, min(0.85, hit - 0.05))
        if quality > best["quality"]:
            best = {"id": account.get("id") or "", "quality": round(quality, 2)}
    return best


def extract_customer_number(words: list[Word], lines: list[Line]) -> dict:
    """Kundennummer neben Label 'Kunde' / 'Kundennr'."""
    labels = ("kunde", "kundennr", "kundennr.", "kunden-nr", "customer no", "customer number", "kdnr", "kd-nr")
    anchors: list[Word] = []
    for line in lines:
        for word in line.words:
            if best_label(word.text, labels) >= 0.9 or norm(word.text).rstrip(".:") in ("kunde", "kundennr"):
                anchors.append(word)
    ordered = sorted(words, key=lambda word: (word.page, word.y0, word.x0))
    best = empty_field()
    for anchor in anchors:
        for word in ordered:
            if word.page != anchor.page or id(word) == id(anchor):
                continue
            if abs(word.y0 - anchor.y0) > 14:
                continue
            if word.x0 < anchor.x0 - 5:
                continue
            text = word.text.strip().rstrip(".")
            if re.fullmatch(r"\d{3,12}", text):
                score = 0.9 if word.x0 - anchor.x1 < 120 else 0.7
                if score > best["quality"]:
                    best = field_from(text, score, word)
    if best["value"]:
        return best
    # Fallback Plain: Kunde: 1052861
    blob = " ".join(word.text for word in ordered)
    match = re.search(r"(?i)\bkunde(?:nnr\.?|n-?nr\.?)?\s*[:#]?\s*(\d{3,12})\b", blob)
    if match:
        return field_from(match.group(1), 0.75, None)
    return empty_field()


def assign_words(words: list[Word], accounts: list[dict] | None = None, meta: dict | None = None, model: dict | None = None) -> dict:
    accounts = accounts or []
    lines = group_lines(words)
    mark_roles(lines)
    anchors = collect_anchors(lines)
    add_hint_anchors(lines, anchors, accounts)
    iban_value, iban_word = find_iban(words)
    customer_number = extract_customer_number(words, lines)
    account = match_account(lines, accounts, iban_value, meta, customer_number.get("value") or "")
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
    bic_anchors = anchors.get("bic", [])
    for word in words:
        got = bic_ok(word.text)
        if not got or iban_ok(word.text):
            continue
        if bic_anchors and nearest(word, bic_anchors) > 220:
            continue
        bic_word = word
        bic_value = got
        break
    vat_word = None
    vat_value = ""
    vat_anchors = anchors.get("vat", [])
    for word in words:
        got = vat_ok(word.text)
        if not got:
            continue
        if vat_anchors and nearest(word, vat_anchors) > 240:
            continue
        vat_word = word
        vat_value = got
        break
    seller_name, seller_address = pick_seller(lines, accounts, account)
    # Skonto/Rabatt/Mahngebühr nur bei echtem Label-Anker — sonst Quatsch aus Positionsbeträgen
    skonto = pick("skonto", moneys, lines, anchors, accounts, used, model, account_id) if anchors.get("skonto") else empty_field()
    discount_amount = pick("discount", moneys, lines, anchors, accounts, used, model, account_id) if anchors.get("discount") else empty_field()
    dunning = pick("dunning", moneys, lines, anchors, accounts, used, model, account_id) if anchors.get("dunning") else empty_field()
    taxes = tax_rows(lines)
    if not taxes:
        blob = " ".join(word.text for word in words)
        rate_match = re.search(r"(?i)\b(?:mwst|ust|mehrwertsteuer)\b[^0-9%]{0,12}(19|7|0)\s*[,.]?\s*0?\s*%", blob)
        if not rate_match:
            rate_match = re.search(r"\b(19|7)\s*[,.]?\s*0?\s*%", blob)
        if rate_match:
            taxes = [{"rate": rate_match.group(1), "net": "", "amount": "", "quality": 0.65, "page": 0, "box": ""}]
    result = {
        "source": "text",
        "origin": "digital",
        "pages": max((word.page for word in words), default=1),
        "account": account,
        "invoiceNumber": invoice_number,
        "invoiceDate": invoice_date,
        "serviceDate": service_date,
        "dueDate": due_date,
        "customerNumber": customer_number,
        "sellerName": seller_name,
        "sellerAddress": seller_address,
        "vatId": field_from(vat_value, 0.9 if vat_value else 0.0, vat_word),
        "payable": payable,
        "gross": gross,
        "skonto": skonto,
        "discountAmount": discount_amount,
        "dunning": dunning,
        "skontoRate": empty_field(),
        "skontoUntil": empty_field(),
        "taxes": taxes,
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
