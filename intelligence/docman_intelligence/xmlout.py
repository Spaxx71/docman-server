"""Schreibt DocmanIntelligence-XML mit dotted FieldIds und Plain-Text."""

from __future__ import annotations

from xml.sax.saxutils import escape

from docman_intelligence.assign import Word, assign_words

# Ergebnis-Keys (intern) → FieldId
FIELD_MAP = (
    ("invoiceNumber", "invoice.id"),
    ("invoiceDate", "invoice.date"),
    ("serviceDate", "invoice.date.service"),
    ("dueDate", "invoice.date.due"),
    ("customerNumber", "invoice.customer.id"),
    ("payable", "invoice.amount.payable"),
    ("gross", "invoice.amount.brutto"),
    ("skonto", "invoice.amount.skonto"),
    ("discountAmount", "invoice.amount.discount"),
    ("dunning", "invoice.amount.dunning"),
    ("skontoRate", "invoice.skonto.rate"),
    ("skontoUntil", "invoice.skonto.until"),
    ("sellerName", "sender.name"),
    ("sellerAddress", "sender.address"),
    ("vatId", "sender.vat"),
    ("iban", "sender.iban"),
    ("bic", "sender.bic"),
    ("paymentMethod", "sender.paymentMethod"),
)

ARTICLE_MAP = (
    ("position", "article.position"),
    ("articleNumber", "article.id"),
    ("description", "article.name"),
    ("quantity", "article.count"),
    ("unit", "article.unit"),
    ("unitPrice", "article.price.unit"),
    ("discount", "article.discount"),
    ("amount", "article.amount.brutto"),
    ("taxRate", "article.tax.rate"),
)


def _attr(value) -> str:
    return escape(str(value if value is not None else ""), {'"': "&quot;"})


def _field_el(field_id: str, item: dict | None) -> str:
    item = item or {"value": "", "quality": 0, "page": 0, "box": ""}
    return (
        f'<Field id="{_attr(field_id)}" value="{_attr(item.get("value", ""))}"'
        f' quality="{_attr(item.get("quality", 0))}"'
        f' page="{_attr(item.get("page", 0))}" box="{_attr(item.get("box", ""))}"/>'
    )


def plain_text(words: list) -> str:
    if not words:
        return ""
    parts = []
    last_page = None
    for word in words:
        page = getattr(word, "page", 1)
        if last_page is not None and page != last_page:
            parts.append("\n")
        parts.append(getattr(word, "text", str(word)))
        last_page = page
    return escape(" ".join(parts).replace(" \n ", "\n").strip())


def render(result: dict) -> str:
    empty = {"value": "", "quality": 0, "page": 0, "box": ""}
    fields = []
    for key, fid in FIELD_MAP:
        fields.append(_field_el(fid, result.get(key) or empty))
    for tax in result.get("taxes", []):
        fields.append(
            _field_el(
                "invoice.tax.rate",
                {"value": tax.get("rate", ""), "quality": tax.get("quality", 0), "page": tax.get("page", 0), "box": tax.get("box", "")},
            )
        )
        fields.append(
            _field_el(
                "invoice.tax.amount",
                {"value": tax.get("amount", ""), "quality": tax.get("quality", 0), "page": tax.get("page", 0), "box": tax.get("box", "")},
            )
        )
    articles = []
    for line in result.get("lines", []):
        parts = [_field_el(fid, line.get(key) or empty) for key, fid in ARTICLE_MAP]
        articles.append(f'<Article quality="{_attr(line.get("quality", 0))}">{"".join(parts)}</Article>')
    account = result.get("account") or {"id": "", "quality": 0}
    words = result.get("words") or []
    text = plain_text(words)
    return (
        "<Intelligence>"
        f'<Source kind="{_attr(result.get("source", "text"))}" origin="{_attr(result.get("origin", "digital"))}" pages="{_attr(result.get("pages", 1))}"/>'
        f'<Account id="{_attr(account.get("id", ""))}" quality="{_attr(account.get("quality", 0))}"/>'
        f'<Fields>{"".join(fields)}</Fields>'
        f'<Articles>{"".join(articles)}</Articles>'
        f"<Text>{text}</Text>"
        "</Intelligence>"
    )


def words_from_pairs(pairs: list[tuple]) -> list[Word]:
    words = []
    for item in pairs:
        text, x0, y0, x1, y1 = item[:5]
        page = item[5] if len(item) > 5 else 1
        words.append(Word(text=text, x0=x0, y0=y0, x1=x1, y1=y1, page=page))
    return words


def read_and_assign(data: bytes, accounts: list[dict] | None = None, meta: dict | None = None) -> str:
    from docman_intelligence.pdf import read_document

    words, _zugferd, kind, origin = read_document(data)
    result = assign_words(words, accounts, meta)
    result["source"] = kind
    result["origin"] = origin
    return render(result)
