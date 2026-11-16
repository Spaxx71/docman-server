"""Lädt FieldIds und Keywords aus vocab.xml; normalisiert Hint-Feldnamen."""

from __future__ import annotations

from pathlib import Path
import xml.etree.ElementTree as ET

_VOCAB_PATH = Path(__file__).with_name("vocab.xml")

# Alte camelCase-Hints → kanonische dotted FieldIds
FIELD_ALIASES = {
    "invoiceNumber": "invoice.id",
    "invoiceDate": "invoice.date",
    "serviceDate": "invoice.date.service",
    "dueDate": "invoice.date.due",
    "dateGeneric": "invoice.date.generic",
    "customerNumber": "invoice.customer.id",
    "payable": "invoice.amount.payable",
    "gross": "invoice.amount.brutto",
    "net": "invoice.amount.netto",
    "vat": "sender.vat",
    "iban": "sender.iban",
    "bic": "sender.bic",
    "sellerName": "sender.name",
    "sellerAddress": "sender.address",
    "paymentMethod": "sender.paymentMethod",
    "tax": "invoice.tax.rate",
    "party.self": "party.self",
}

REGION_ALIASES = {
    "invoiceHeader": "invoice.header",
    "amounts": "invoice.amounts",
    "lines": "article.lines",
    "payment": "sender.payment",
    "near:invoiceNumber": "near:invoice.id",
}

ARTICLE_ALIASES = {
    "position": "article.position",
    "articleNumber": "article.id",
    "description": "article.name",
    "quantity": "article.count",
    "unit": "article.unit",
    "unitPrice": "article.price.unit",
    "discount": "article.discount",
    "amount": "article.amount.brutto",
    "taxRate": "article.tax.rate",
}


def field_id(name: str) -> str:
    raw = (name or "").strip()
    return FIELD_ALIASES.get(raw, raw)


def region_id(name: str) -> str:
    raw = (name or "").strip()
    return REGION_ALIASES.get(raw, raw)


def load_keywords(path: Path | None = None) -> dict[str, tuple[str, ...]]:
    target = path or _VOCAB_PATH
    if not target.is_file():
        return {}
    root = ET.fromstring(target.read_text(encoding="utf-8"))
    out: dict[str, tuple[str, ...]] = {}
    for node in root:
        if node.tag.rsplit("}", 1)[-1] != "Field":
            continue
        fid = field_id(node.attrib.get("id", ""))
        if not fid:
            continue
        words = []
        for child in list(node):
            if child.tag.rsplit("}", 1)[-1] != "Keyword":
                continue
            text = (child.text or "").strip()
            if text:
                words.append(text)
        if words:
            out[fid] = tuple(words)
    return out


KEYWORDS = load_keywords()

# Interne Anker-Keys (assign) → FieldId
LABEL_KEYS = {
    "invoice.id": KEYWORDS.get("invoice.id", ()),
    "invoice.date": KEYWORDS.get("invoice.date", ()),
    "invoice.date.generic": KEYWORDS.get("invoice.date.generic", ()),
    "invoice.date.service": KEYWORDS.get("invoice.date.service", ()),
    "invoice.date.due": KEYWORDS.get("invoice.date.due", ()),
    "invoice.amount.payable": KEYWORDS.get("invoice.amount.payable", ()),
    "invoice.amount.brutto": KEYWORDS.get("invoice.amount.brutto", ()),
    "invoice.amount.netto": KEYWORDS.get("invoice.amount.netto", ()),
    "invoice.amount.skonto": KEYWORDS.get("invoice.amount.skonto", ()),
    "invoice.amount.discount": KEYWORDS.get("invoice.amount.discount", ()),
    "invoice.amount.dunning": KEYWORDS.get("invoice.amount.dunning", ()),
    "invoice.skonto.rate": KEYWORDS.get("invoice.skonto.rate", ()),
    "invoice.skonto.until": KEYWORDS.get("invoice.skonto.until", ()),
    "invoice.tax.rate": KEYWORDS.get("invoice.tax.rate", ()),
    "invoice.tax.amount": KEYWORDS.get("invoice.tax.amount", ()),
    "sender.iban": KEYWORDS.get("sender.iban", ()),
    "sender.bic": KEYWORDS.get("sender.bic", ()),
    "sender.vat": KEYWORDS.get("sender.vat", ()),
    "sender.name": KEYWORDS.get("sender.name", ()),
}

HEADER_KEYS = {
    "article.name": KEYWORDS.get("article.name", ()),
    "article.count": KEYWORDS.get("article.count", ()),
    "article.unit": KEYWORDS.get("article.unit", ()),
    "article.price.unit": KEYWORDS.get("article.price.unit", ()),
    "article.discount": KEYWORDS.get("article.discount", ()),
    "article.amount.brutto": KEYWORDS.get("article.amount.brutto", ()),
    "article.tax.rate": KEYWORDS.get("article.tax.rate", ()),
    "article.position": KEYWORDS.get("article.position", ()),
    "article.id": KEYWORDS.get("article.id", ()),
}
