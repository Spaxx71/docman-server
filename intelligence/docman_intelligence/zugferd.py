"""Liest eingebettetes ZUGFeRD- oder Factur-X-XML über lokale Elementnamen."""

import xml.etree.ElementTree as ET


def local(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def children(node, name: str):
    return [child for child in list(node) if local(child.tag) == name]


def first(node, path: list[str]):
    current = [node]
    for name in path:
        nxt = []
        for item in current:
            nxt.extend(children(item, name))
        current = nxt
        if not current:
            return None
    return current[0]


def text_of(node, path: list[str]) -> str:
    found = first(node, path) if node is not None else None
    if found is None or found.text is None:
        return ""
    return found.text.strip()


def iso_date(value: str) -> str:
    digits = "".join(char for char in value if char.isdigit())
    if len(digits) >= 8:
        return f"{digits[0:4]}-{digits[4:6]}-{digits[6:8]}"
    return value


def money(value: str) -> str:
    if not value:
        return ""
    cleaned = value.replace(" ", "")
    if "," in cleaned and "." not in cleaned:
        cleaned = cleaned.replace(",", ".")
    try:
        return f"{float(cleaned):.2f}"
    except ValueError:
        return ""


def parse_zugferd(xml_bytes: bytes) -> dict | None:
    try:
        root = ET.fromstring(xml_bytes)
    except ET.ParseError:
        return None
    if local(root.tag) not in ("CrossIndustryInvoice", "Invoice"):
        return None
    number = text_of(root, ["ExchangedDocument", "ID"])
    issued = iso_date(text_of(root, ["ExchangedDocument", "IssueDateTime", "DateTimeString"]))
    agreement = first(root, ["SupplyChainTradeTransaction", "ApplicableHeaderTradeAgreement"])
    settlement = first(root, ["SupplyChainTradeTransaction", "ApplicableHeaderTradeSettlement"])
    seller = text_of(agreement, ["SellerTradeParty", "Name"]) if agreement is not None else ""
    vat = text_of(agreement, ["SellerTradeParty", "SpecifiedTaxRegistration", "ID"]) if agreement is not None else ""
    post = first(agreement, ["SellerTradeParty", "PostalTradeAddress"]) if agreement is not None else None
    address = ""
    if post is not None:
        address = ", ".join(
            part for part in (
                text_of(post, ["LineOne"]),
                text_of(post, ["PostcodeCode"]),
                text_of(post, ["CityName"]),
            ) if part
        )
    payable = money(text_of(settlement, ["SpecifiedTradeSettlementHeaderMonetarySummation", "DuePayableAmount"])) if settlement is not None else ""
    gross = money(text_of(settlement, ["SpecifiedTradeSettlementHeaderMonetarySummation", "GrandTotalAmount"])) if settlement is not None else ""
    iban = text_of(settlement, ["SpecifiedTradeSettlementPaymentMeans", "PayeePartyCreditorFinancialAccount", "IBANID"]) if settlement is not None else ""
    taxes = []
    if settlement is not None:
        for tax in children(settlement, "ApplicableTradeTax"):
            taxes.append({
                "rate": text_of(tax, ["RateApplicablePercent"]).replace(".00", "").split(".")[0],
                "net": money(text_of(tax, ["BasisAmount"])),
                "amount": money(text_of(tax, ["CalculatedAmount"])),
                "quality": 1.0,
                "page": 0,
                "box": "",
            })
    lines = []
    transaction = first(root, ["SupplyChainTradeTransaction"])
    if transaction is not None:
        for item in children(transaction, "IncludedSupplyChainTradeLineItem"):
            description = text_of(item, ["SpecifiedTradeProduct", "Name"])
            quantity = money(text_of(item, ["SpecifiedLineTradeDelivery", "BilledQuantity"]))
            unit_price = money(text_of(item, ["SpecifiedLineTradeAgreement", "NetPriceProductTradePrice", "ChargeAmount"]))
            amount = money(text_of(item, ["SpecifiedLineTradeSettlement", "SpecifiedTradeSettlementLineMonetarySummation", "LineTotalAmount"]))
            rate = text_of(item, ["SpecifiedLineTradeSettlement", "ApplicableTradeTax", "RateApplicablePercent"]).split(".")[0]
            article = text_of(item, ["SpecifiedTradeProduct", "SellerAssignedID"])
            position = text_of(item, ["AssociatedDocumentLineDocument", "LineID"])
            def packed(value: str) -> dict:
                return {"value": value, "quality": 1.0 if value else 0.0, "page": 0, "box": ""}
            lines.append({
                "position": packed(position),
                "articleNumber": packed(article),
                "description": packed(description),
                "quantity": packed(quantity),
                "unit": packed(""),
                "unitPrice": packed(unit_price),
                "discount": packed(""),
                "amount": packed(amount),
                "taxRate": packed(rate),
                "quality": 1.0,
            })
    def packed(value: str) -> dict:
        return {"value": value, "quality": 1.0 if value else 0.0, "page": 0, "box": ""}
    return {
        "source": "zugferd",
        "pages": 1,
        "account": {"id": "", "quality": 0.0},
        "invoiceNumber": packed(number),
        "invoiceDate": packed(issued),
        "serviceDate": packed(""),
        "dueDate": packed(""),
        "sellerName": packed(seller),
        "sellerAddress": packed(address),
        "vatId": packed(vat),
        "payable": packed(payable or gross),
        "gross": packed(gross),
        "taxes": taxes,
        "iban": packed(iban.replace(" ", "")),
        "bic": packed(""),
        "paymentMethod": packed("transfer" if iban else ""),
        "lines": lines,
        "words": [],
    }
