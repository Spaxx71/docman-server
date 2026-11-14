"""Schreibt das Fields-XML, das eXist in die docman.xml einsetzt."""

from xml.sax.saxutils import escape

from docman_intelligence.assign import Word, assign_words


def _attr(value) -> str:
    return escape(str(value if value is not None else ""), {'"': "&quot;"})


def _field(name: str, item: dict) -> str:
    return (
        f'<{name} value="{_attr(item.get("value", ""))}" quality="{_attr(item.get("quality", 0))}"'
        f' page="{_attr(item.get("page", 0))}" box="{_attr(item.get("box", ""))}"/>'
    )


def render(result: dict) -> str:
    taxes = "\n".join(
        f'<Tax rate="{_attr(tax["rate"])}" net="{_attr(tax.get("net", ""))}" amount="{_attr(tax["amount"])}"'
        f' quality="{_attr(tax["quality"])}" page="{_attr(tax.get("page", 0))}" box="{_attr(tax.get("box", ""))}"/>'
        for tax in result.get("taxes", [])
    )
    lines = []
    for line in result.get("lines", []):
        parts = [
            _field("Position", line["position"]),
            _field("ArticleNumber", line["articleNumber"]),
            _field("Description", line["description"]),
            _field("Quantity", line["quantity"]),
            _field("Unit", line["unit"]),
            _field("UnitPrice", line["unitPrice"]),
            _field("Discount", line["discount"]),
            _field("Amount", line["amount"]),
            _field("TaxRate", line["taxRate"]),
        ]
        lines.append(f'<Line quality="{_attr(line.get("quality", 0))}">' + "".join(parts) + "</Line>")
    words = []
    for word in result.get("words", []):
        words.append(
            f'<W page="{word.page}" box="{_attr(f"{word.x0:.0f} {word.y0:.0f} {word.x1:.0f} {word.y1:.0f}")}">{escape(word.text)}</W>'
        )
    account = result.get("account") or {"id": "", "quality": 0}
    return (
        "<Intelligence>"
        f'<Source kind="{_attr(result.get("source", "text"))}" pages="{_attr(result.get("pages", 1))}"/>'
        f'<Account id="{_attr(account.get("id", ""))}" quality="{_attr(account.get("quality", 0))}"/>'
        "<Fields>"
        + _field("InvoiceNumber", result["invoiceNumber"])
        + _field("InvoiceDate", result["invoiceDate"])
        + _field("ServiceDate", result["serviceDate"])
        + _field("DueDate", result["dueDate"])
        + "<Seller>"
        + _field("Name", result["sellerName"])
        + _field("Address", result["sellerAddress"])
        + _field("VatId", result["vatId"])
        + "</Seller>"
        + _field("PayableAmount", result["payable"])
        + _field("GrossAmount", result["gross"])
        + f"<Taxes>{taxes}</Taxes>"
        + "<Payment>"
        + _field("Method", result["paymentMethod"])
        + _field("IBAN", result["iban"])
        + _field("BIC", result["bic"])
        + "</Payment>"
        + "</Fields>"
        + f'<Lines>{"".join(lines)}</Lines>'
        + f'<Text>{"".join(words)}</Text>'
        + "</Intelligence>"
    )


def words_from_pairs(pairs: list[tuple]) -> list[Word]:
    words = []
    for item in pairs:
        text, x0, y0, x1, y1 = item[:5]
        page = item[5] if len(item) > 5 else 1
        words.append(Word(text=text, x0=x0, y0=y0, x1=x1, y1=y1, page=page))
    return words


def assign_and_render(pairs, accounts=None, meta=None) -> str:
    return render(assign_words(words_from_pairs(pairs), accounts, meta))
