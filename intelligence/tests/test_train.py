from docman_intelligence.assign import assign_words
from docman_intelligence.train import train_xml
from docman_intelligence.xmlout import words_from_pairs


def document(account, confirmed, words):
    body = []
    for text, x0, y0, x1, y1 in words:
        body.append(f'<W page="1" box="{x0} {y0} {x1} {y1}">{text}</W>')
    fields = "".join(f'<Confirmed field="{field}" value="{value}"/>' for field, value in confirmed)
    return (
        f'<DocmanIntelligence><Account id="{account}"/>'
        f"<Training>{fields}</Training><Text>{''.join(body)}</Text></DocmanIntelligence>"
    )


HEADER = (
    ("Rechnungsnummer", 40, 80, 170, 92),
    ("RE-10001", 190, 80, 270, 92),
    ("Datum", 40, 110, 90, 122),
    ("12.10.2026", 190, 110, 270, 122),
    ("Leistungsdatum", 40, 300, 160, 312),
    ("01.09.2026", 190, 300, 270, 312),
    ("Zahlbetrag", 40, 360, 130, 372),
    ("119,00", 190, 360, 250, 372),
    ("Brutto", 40, 390, 100, 402),
    ("140,00", 190, 390, 250, 402),
)


def test_training_schreibt_gewichte_und_kontoaufschlag_ohne_regex():
    docs = [
        document("k1", (("invoiceDate", "2026-10-12"), ("payable", "119.00"), ("invoiceNumber", "RE-10001")), HEADER),
        document("k1", (("invoiceDate", "2026-10-12"), ("payable", "119.00"), ("invoiceNumber", "RE-10001")), HEADER),
        document("k2", (("invoiceDate", "2026-10-12"), ("payable", "119.00")), HEADER),
        document("k2", (("invoiceDate", "2026-10-12"), ("payable", "119.00")), HEADER),
    ]
    result = train_xml("<Examples>" + "".join(docs) + "</Examples>")
    assert "pattern" not in result
    assert '<Field name="invoiceDate">' in result
    assert 'name="near_number"' in result
    assert '<Account id="k1">' in result
    assert 'name="bias"' in result


def test_wert_ausserhalb_des_belegs_wird_ausgelassen():
    docs = [
        document("k1", (("invoiceNumber", "steht-nicht-im-text"),), (("Datum", 40, 100, 90, 112), ("12.10.2026", 120, 100, 210, 112))),
        document("k1", (("invoiceNumber", "ebenfalls-frei"),), (("Datum", 40, 100, 90, 112), ("13.10.2026", 120, 100, 210, 112))),
    ]
    result = train_xml("<Examples>" + "".join(docs) + "</Examples>")
    assert "pattern" not in result
    assert "invoiceNumber" not in result


def test_gelerntes_modell_senkt_die_auswahl():
    words = words_from_pairs((
        ("Rechnungsnummer", 40, 100, 170, 112),
        ("RE-10001", 190, 100, 270, 112),
        ("Datum", 40, 124, 90, 136),
        ("12.10.2026", 190, 124, 270, 136),
    ))
    blocked = {name: 0.0 for name in ("same", "below", "label", "role", "hint", "near", "near_number", "counter", "type")}
    blocked["bias"] = -8.0
    result = assign_words(words, model={"fields": {"invoiceDate": blocked}, "accounts": {}})
    assert result["invoiceDate"]["value"] == ""
