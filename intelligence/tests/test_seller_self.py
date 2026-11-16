from docman_intelligence.assign import assign_words, split_envelope_sender
from docman_intelligence.xmlout import words_from_pairs


def test_kuvert_absenderzeile_ist_rechnungsgeber():
    # Schmale einzeilige Absenderkennung über dem Empfänger im Sichtfenster
    words = words_from_pairs([
        ("Teichelt", 72, 126, 110, 131),
        ("elektronik", 112, 126, 160, 131),
        ("GmbH", 162, 126, 185, 131),
        ("&", 187, 126, 192, 131),
        ("Co.", 194, 126, 208, 131),
        ("KG", 210, 126, 222, 131),
        ("-", 224, 126, 228, 131),
        ("Elektronikring", 230, 126, 290, 131),
        ("1", 292, 126, 298, 131),
        ("+", 300, 126, 305, 131),
        ("26452", 307, 126, 335, 131),
        ("Sande", 337, 126, 365, 131),
        ("BINTELLIX", 72, 150, 140, 162),
        ("GMBH", 142, 150, 175, 162),
        ("GEIGENBERGERSTR.", 72, 165, 180, 177),
        ("7A", 182, 165, 200, 177),
        ("81477", 72, 180, 110, 192),
        ("MÜNCHEN", 112, 180, 180, 192),
        ("Rechnung", 400, 120, 460, 132),
        ("1758276", 470, 120, 530, 132),
        ("Zahlbetrag", 40, 400, 130, 412),
        ("239,95", 160, 400, 220, 412),
    ])
    accounts = [{
        "id": "self1",
        "classes": "self",
        "type": "self",
        "name": "BINTELLIX GMBH & CO. KG",
        "company": "BINTELLIX GMBH & CO. KG",
        "address": "Geigenbergerstr. 7A 81477 München",
        "email": "",
        "ibans": [],
        "hints": [{"field": "party.self", "label": "bintellix", "pattern": "", "region": ""}],
    }, {
        "id": "reichelt",
        "classes": "creditor",
        "type": "creditor",
        "name": "reichelt elektronik GmbH & Co. KG",
        "company": "reichelt elektronik GmbH & Co. KG",
        "address": "Elektronikring 1 26452 Sande",
        "customerId": "1052861",
        "email": "",
        "ibans": [],
        "hints": [],
    }]
    result = assign_words(words, accounts)
    assert "teichelt" in result["sellerName"]["value"].lower() or "reichelt" in result["sellerName"]["value"].lower()
    assert "bintellix" not in result["sellerName"]["value"].lower()
    assert "26452" in result["sellerAddress"]["value"] or "sande" in result["sellerAddress"]["value"].lower()
    assert "elektronikring" in result["sellerAddress"]["value"].lower()
    assert result["account"]["id"] == "reichelt"


def test_split_envelope_sender_trennt_name_und_adresse():
    name, address = split_envelope_sender(
        "reichelt elektronik GmbH & Co. KG - Elektronikring 1 · 26452 Sande"
    )
    assert "reichelt" in name.lower()
    assert "GmbH" in name
    assert "Elektronikring" in address
    assert "26452" in address


def test_eigene_adresse_ist_kein_seller():
    words = words_from_pairs([
        ("Musterfirma", 40, 40, 140, 52),
        ("GmbH", 145, 40, 190, 52),
        ("Beispielweg", 40, 56, 130, 68),
        ("1", 135, 56, 150, 68),
        ("12345", 40, 72, 90, 84),
        ("Berlin", 95, 72, 150, 84),
        ("Lieferant", 40, 120, 120, 132),
        ("AG", 125, 120, 150, 132),
        ("Rechnungsnummer", 40, 200, 170, 212),
        ("RE-9", 190, 200, 240, 212),
    ])
    accounts = [{
        "id": "self1",
        "classes": "self",
        "type": "self",
        "name": "Musterfirma GmbH",
        "company": "Musterfirma GmbH",
        "address": "Beispielweg 1 12345 Berlin",
        "email": "",
        "ibans": [],
        "hints": [{"field": "party.self", "label": "musterfirma", "pattern": "", "region": ""}],
    }, {
        "id": "lieferant",
        "classes": "creditor",
        "type": "creditor",
        "name": "Lieferant AG",
        "company": "Lieferant AG",
        "address": "",
        "email": "",
        "ibans": [],
        "hints": [{"field": "party.self", "label": "lieferant ag", "pattern": "", "region": ""}],
    }]
    result = assign_words(words, accounts)
    seller = result["sellerName"]["value"].lower()
    assert "musterfirma" not in seller
    assert "beispielweg" not in seller
    assert "lieferant" in seller or result["account"]["id"] == "lieferant"


def test_matched_creditor_wird_als_seller_genommen():
    words = words_from_pairs([
        ("IchSelbst", 40, 40, 140, 52),
        ("GmbH", 145, 40, 190, 52),
        ("Rechnungsnummer", 40, 200, 170, 212),
        ("RE-9", 190, 200, 240, 212),
        ("IBAN", 40, 400, 80, 412),
        ("DE89370400440532013000", 100, 400, 320, 412),
    ])
    accounts = [{
        "id": "self1",
        "classes": "self",
        "type": "self",
        "name": "IchSelbst GmbH",
        "company": "IchSelbst GmbH",
        "address": "Hauptstrasse 1",
        "email": "",
        "ibans": [],
        "hints": [],
    }, {
        "id": "cred1",
        "classes": "creditor",
        "type": "creditor",
        "name": "Supplier Corp",
        "company": "Supplier Corp",
        "address": "Industrieweg 5",
        "email": "",
        "ibans": ["DE89370400440532013000"],
        "hints": [],
    }]
    result = assign_words(words, accounts)
    assert result["account"]["id"] == "cred1"
    assert "supplier" in result["sellerName"]["value"].lower()
    assert "ichselbst" not in result["sellerName"]["value"].lower()
