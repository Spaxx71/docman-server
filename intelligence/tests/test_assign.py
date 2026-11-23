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


def test_kein_quatsch_bei_solcom_aehnlicher_rechnung():
    words = W(
        (".Page", 497, 118, 518, 126),
        ("1", 522, 118, 525, 124),
        ("of", 529, 117, 537, 124),
        ("1", 540, 118, 543, 124),
        ("bintellix", 66, 141, 88, 146),
        ("GmbH", 90, 141, 107, 146),
        ("&", 109, 141, 113, 146),
        ("Co.", 116, 141, 124, 146),
        ("KG", 127, 141, 134, 146),
        ("Geigenbergerstr.", 139, 141, 186, 147),
        ("Rechnung", 417, 225, 457, 234),
        ("BIXI2101-0001001C", 464, 225, 544, 232),
        ("25.02.2021", 500, 141, 543, 148),
        ("Pos", 68, 354, 85, 362),
        ("Leistungsbeschreibung", 106, 354, 217, 364),
        ("Menge", 364, 354, 395, 364),
        ("ME", 410, 354, 424, 362),
        ("Preis", 444, 354, 467, 362),
        ("Gesamtpreis", 487, 354, 546, 363),
        ("01", 76, 375, 84, 382),
        ("Erstellung", 106, 368, 149, 378),
        ("Konzept", 167, 381, 202, 390),
        ("1", 371, 375, 374, 382),
        ("10,00", 377, 375, 400, 383),
        ("h", 423, 375, 427, 382),
        ("100,00", 441, 374, 470, 383),
        ("11", 498, 374, 506, 382),
        (".000,00", 508, 374, 540, 383),
        ("Summe", 76, 455, 110, 462),
        ("Netto", 113, 455, 136, 462),
        ("11", 498, 455, 506, 463),
        (".000,00", 508, 455, 540, 464),
        ("Betrag", 76, 470, 104, 479),
        ("19%", 108, 470, 127, 477),
        ("Mehrwertsteuer", 131, 470, 199, 477),
        ("2.090,00", 502, 470, 540, 479),
        ("Gesamtbetrag", 76, 484, 142, 494),
        ("13.090,00", 497, 485, 540, 494),
        ("USt-IdNr.", 66, 814, 93, 818),
        ("DE251391407", 108, 814, 147, 818),
        ("Gesellschaft:", 237, 737, 273, 741),
        ("Deutsche", 413, 728, 439, 733),
        ("Swift/BIC:", 413, 753, 440, 759),
        ("DEUTDEDBMUC", 463, 754, 507, 758),
        ("IBAN:", 413, 763, 428, 767),
        ("DE58700700240222971400", 463, 762, 540, 767),
    )
    result = assign_words(words)
    assert result["sellerName"]["value"].startswith("bintellix")
    assert "Page" not in result["sellerName"]["value"]
    assert result["payable"]["value"] == "13090.00"
    assert result["vatId"]["value"] == "DE251391407"
    assert result["bic"]["value"] == "DEUTDEDBMUC"
    assert result["iban"]["value"] == "DE58700700240222971400"
    assert result["invoiceNumber"]["value"] == "BIXI2101-0001001C"


def test_iban_ueber_mehrere_woerter():
    words = W(
        ("IBAN", 40, 700, 80, 712),
        ("DE10", 100, 700, 140, 712),
        ("2826", 145, 700, 185, 712),
        ("2254", 190, 700, 230, 712),
        ("5044", 235, 700, 275, 712),
        ("5500", 280, 700, 320, 712),
        ("00", 325, 700, 350, 712),
    )
    result = assign_words(words)
    assert result["iban"]["value"] == "DE10282622545044550000"


def test_fuzzy_name_teichelt_trifft_reichelt():
    words = W(
        ("Teichelt", 40, 40, 100, 52),
        ("elektronik", 105, 40, 180, 52),
        ("GmbH", 185, 40, 230, 52),
        ("Rechnung", 40, 100, 120, 112),
        ("1758276", 140, 100, 220, 112),
        ("Zahlbetrag", 40, 300, 130, 312),
        ("239,95", 160, 300, 220, 312),
    )
    accounts = [{
        "id": "acc-reichelt",
        "classes": "creditor",
        "name": "reichelt elektronik GmbH & Co. KG",
        "company": "reichelt elektronik GmbH & Co. KG",
        "ibans": [],
        "hints": [],
    }]
    result = assign_words(words, accounts)
    assert result["account"]["id"] == "acc-reichelt"
    assert result["account"]["quality"] >= 0.55


def test_kundennummer_matcht_konto():
    words = W(
        ("Kunde", 40, 80, 90, 92),
        ("1052861", 100, 80, 170, 92),
        ("Rechnung", 40, 110, 120, 122),
        ("1758276", 140, 110, 220, 122),
        ("Zahlbetrag", 40, 300, 130, 312),
        ("239,95", 160, 300, 220, 312),
    )
    accounts = [{
        "id": "acc-reichelt",
        "classes": "creditor",
        "name": "Other Supplier",
        "company": "",
        "customerId": "1052861",
        "ibans": [],
        "hints": [],
    }]
    result = assign_words(words, accounts)
    assert result["customerNumber"]["value"] == "1052861"
    assert result["account"]["id"] == "acc-reichelt"
    assert result["account"]["quality"] >= 0.9


def _creditor(id_, name, ibans=(), vat="", hints=()):
    return {"id": id_, "classes": "creditor", "name": name, "company": "", "ibans": list(ibans), "vat": vat, "hints": list(hints)}


def test_namenskollision_bleibt_offen():
    words = W(
        ("Telekom", 40, 40, 100, 52),
        ("Deutschland", 105, 40, 190, 52),
        ("Rechnung", 40, 100, 120, 112),
        ("4711", 140, 100, 200, 112),
    )
    accounts = [
        _creditor("festnetz", "Telekom Deutschland"),
        _creditor("mobil", "Telekom Deutschland Mobilfunk"),
    ]
    result = assign_words(words, accounts)
    assert result["account"]["id"] == ""
    assert result["account"]["ambiguous"]
    assert len(result["account"]["candidates"]) == 2


def test_name_allein_bleibt_unter_sieben_zehnteln():
    words = W(("Reichelt", 40, 40, 100, 52), ("Elektronik", 105, 40, 180, 52))
    result = assign_words(words, [_creditor("r", "Reichelt Elektronik")])
    assert result["account"]["id"] == "r"
    assert result["account"]["quality"] <= 0.7


def test_fremde_iban_senkt_namenstreffer():
    words = W(
        ("Reichelt", 40, 40, 100, 52),
        ("Elektronik", 105, 40, 180, 52),
        ("IBAN", 40, 700, 80, 712),
        (IBAN, 100, 700, 340, 712),
    )
    accounts = [
        _creditor("reichelt", "Reichelt Elektronik", ibans=["DE02120300000000202051"]),
        _creditor("andere", "Andere GmbH", ibans=[IBAN]),
    ]
    result = assign_words(words, accounts)
    assert result["account"]["id"] == "andere"
    reichelt = [item for item in result["account"]["candidates"] if item["id"] == "reichelt"]
    assert not reichelt or "conflict:iban" in reichelt[0]["reasons"]


def test_ust_id_trifft_konto():
    words = W(
        ("Lieferant", 40, 40, 100, 52),
        ("USt-IdNr.", 40, 800, 90, 812),
        ("DE251391407", 100, 800, 170, 812),
    )
    result = assign_words(words, [_creditor("x", "Ganz Anders", vat="DE 251 391 407")])
    assert result["account"]["id"] == "x"
    assert result["account"]["quality"] >= 0.9


def test_glaeubiger_id_trifft_konto():
    words = W(
        ("Lastschrift", 40, 40, 120, 52),
        ("Gläubiger-ID", 40, 600, 120, 612),
        ("DE98ZZZ09999999999", 130, 600, 300, 612),
    )
    account = _creditor("lsv", "Versorger")
    account["creditorIds"] = ["DE98 ZZZ0 9999 9999 99"]
    result = assign_words(words, [account])
    assert result["account"]["id"] == "lsv"
    assert result["account"]["quality"] >= 0.9


def test_ausgangsrechnung_sucht_debitor_im_empfaenger():
    words = W(
        ("bintellix", 40, 40, 100, 52),
        ("GmbH", 105, 40, 150, 52),
        ("Muster", 40, 200, 100, 212),
        ("Kunde", 105, 200, 160, 212),
        ("AG", 165, 200, 190, 212),
        ("IBAN", 40, 700, 80, 712),
        (IBAN, 100, 700, 340, 712),
    )
    accounts = [
        {"id": "self", "classes": "self", "name": "bintellix GmbH", "company": "", "ibans": [IBAN], "hints": []},
        {"id": "kunde", "classes": "debitor", "name": "Muster Kunde AG", "company": "", "ibans": [], "hints": []},
        _creditor("bank", "Irgendwer", ibans=[IBAN]),
    ]
    result = assign_words(words, accounts)
    assert result["account"]["direction"] == "invoice.out"
    assert result["account"]["id"] == "kunde"


def test_kein_skonto_ohne_label():
    words = W(
        ("Bezeichnung", 40, 200, 140, 212),
        ("Menge", 200, 200, 250, 212),
        ("Einzelpreis", 270, 200, 350, 212),
        ("Gesamtpreis", 380, 200, 460, 212),
        ("Raspberry", 40, 224, 120, 236),
        ("4", 210, 224, 230, 236),
        ("49,16", 280, 224, 330, 236),
        ("196,64", 390, 224, 450, 236),
        ("Zahlbetrag", 40, 300, 130, 312),
        ("239,95", 160, 300, 220, 312),
    )
    result = assign_words(words)
    assert result["skonto"]["value"] == ""
    assert result["discountAmount"]["value"] == ""
    assert result["dunning"]["value"] == ""
    assert result["lines"][0]["amount"]["value"] == "196.64"
    assert "Ursprungsland" not in result["lines"][0]["description"]["value"]


def test_artikelname_ohne_ursprungsland():
    from docman_intelligence.assign import clean_article_name

    cleaned = clean_article_name(
        "Raspberry Ursprungsland: Pi4B,4x 1,5 GHz, 4GBRAM, WLAN, OR GB Stat. Waren Nr.: 84718000"
    )
    assert "Ursprungsland" not in cleaned
    assert "84718000" not in cleaned
    assert "Raspberry" in cleaned
    assert "Pi4B" in cleaned
