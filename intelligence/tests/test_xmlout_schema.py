from docman_intelligence.assign import assign_words
from docman_intelligence.xmlout import render, words_from_pairs


def test_render_uses_dotted_field_ids_and_plain_text():
    words = words_from_pairs([
        ("Rechnungsnummer", 40, 100, 170, 112),
        ("RE-10001", 190, 100, 270, 112),
        ("Datum", 40, 124, 90, 136),
        ("12.10.2026", 190, 124, 270, 136),
    ])
    result = assign_words(words)
    xml = render(result)
    assert 'id="invoice.id"' in xml
    assert 'id="invoice.date"' in xml
    assert "<Articles>" in xml
    assert "<Text>" in xml
    assert "<W " not in xml
    assert "RE-10001" in xml
