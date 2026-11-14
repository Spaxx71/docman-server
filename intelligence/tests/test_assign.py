from docman_intelligence.assign import assign_words
from docman_intelligence.xmlout import words_from_pairs

IBAN = "DE89370400440532013000"


def W(*rows):
    return words_from_pairs(rows)


def test_datum_neben_rechnungsnummer_ist_rechnungsdatum():
    words = W(
        ("Rechnungsnummer", 40, 100, 170, 112),
        ("RE-10001", 190, 100, 270, 112),
        ("Datum", 40, 124, 90, 136),
        ("12.10.2026", 190, 124, 270, 136),
        ("Leistungsdatum", 40, 220, 170, 232),
        ("01.10.2026", 190, 220, 270, 232),
    )
    result = assign_words(words)
    assert result["invoiceDate"]["value"] == "2026-10-12"
    assert result["invoiceDate"]["quality"] > 0.5
    assert result["serviceDate"]["value"] == "2026-10-01"


def test_hinweis_regex_filtert_rechnungsnummer():
    words = W(
        ("Rechnungsnummer", 40, 100, 170, 112),
        ("99999", 180, 100, 230, 112),
        ("RE-10001", 250, 100, 330, 112),
    )
    accounts = [{
        "id": "k1",
        "classes": "creditor",
        "hints": [{"field": "invoiceNumber", "pattern": r"^RE-\d{5}$", "label": "", "region": ""}],
    }]
    result = assign_words(words, accounts)
    assert result["invoiceNumber"]["value"] == "RE-10001"


def test_ungueltige_iban_wird_kein_kandidat():
    words = W(
        ("IBAN", 40, 400, 80, 412),
        ("DE00000000000000000000", 100, 400, 320, 412),
    )
    result = assign_words(words)
    assert result["iban"]["value"] == ""


def test_zwei_steuersaetze_und_zahlbetrag_vor_brutto():
    words = W(
        ("Brutto", 40, 300, 100, 312),
        ("140,00", 180, 300, 240, 312),
        ("MwSt", 40, 320, 90, 332),
        ("19%", 110, 320, 140, 332),
        ("19,00", 180, 320, 240, 332),
        ("MwSt", 40, 340, 90, 352),
        ("7%", 110, 340, 140, 352),
        ("7,00", 180, 340, 240, 352),
        ("Zahlbetrag", 40, 370, 130, 382),
        ("126,00", 180, 370, 240, 382),
    )
    result = assign_words(words)
    assert result["payable"]["value"] == "126.00"
    assert result["gross"]["value"] == "140.00"
    rates = sorted(tax["rate"] for tax in result["taxes"])
    assert rates == ["19", "7"]


def test_fehlende_rechnungsnummer_laesst_datum_und_betrag():
    words = W(
        ("Datum", 40, 100, 90, 112),
        ("12.10.2026", 120, 100, 210, 112),
        ("Zahlbetrag", 40, 140, 130, 152),
        ("119,00", 160, 140, 220, 152),
    )
    result = assign_words(words)
    assert result["invoiceNumber"]["value"] == ""
    assert result["invoiceNumber"]["quality"] == 0
    assert result["invoiceDate"]["value"] == "2026-10-12"
    assert result["payable"]["value"] == "119.00"


def test_zweizeilige_bezeichnung_und_keine_zwischensumme():
    words = W(
        ("Bezeichnung", 40, 200, 140, 212),
        ("Menge", 200, 200, 250, 212),
        ("Einzelpreis", 270, 200, 350, 212),
        ("Betrag", 380, 200, 440, 212),
        ("Beratung", 40, 224, 120, 236),
        ("2", 210, 224, 230, 236),
        ("50,00", 280, 224, 330, 236),
        ("100,00", 390, 224, 450, 236),
        ("vor Ort", 40, 240, 110, 252),
        ("Zwischensumme", 40, 270, 150, 282),
        ("100,00", 390, 270, 450, 282),
    )
    result = assign_words(words)
    assert len(result["lines"]) == 1
    line = result["lines"][0]
    assert line["description"]["value"] == "Beratung vor Ort"
    assert line["quantity"]["value"] == "2.00"
    assert line["unitPrice"]["value"] == "50.00"
    assert line["amount"]["value"] == "100.00"
    assert line["quality"] >= 0.85


def test_gueltige_iban_bleibt():
    words = W(("IBAN", 40, 400, 80, 412), (IBAN, 100, 400, 340, 412))
    result = assign_words(words)
    assert result["iban"]["value"] == IBAN
    assert result["paymentMethod"]["value"] == "transfer"
