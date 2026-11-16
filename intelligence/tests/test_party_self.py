from docman_intelligence.assign import Word, group_lines, mark_roles, match_account


def test_party_self_label_erkennt_konto():
    words = [
        Word(text="Amazon", x0=40, y0=40, x1=100, y1=52, page=1),
        Word(text="Deutschland", x0=110, y0=40, x1=200, y1=52, page=1),
        Word(text="Rechnungsnummer", x0=40, y0=100, x1=170, y1=112, page=1),
        Word(text="RE-1", x0=190, y0=100, x1=240, y1=112, page=1),
    ]
    lines = group_lines(words)
    mark_roles(lines)
    accounts = [{
        "id": "amazon",
        "classes": "creditor",
        "type": "creditor",
        "name": "Amazon EU",
        "company": "",
        "email": "",
        "ibans": [],
        "hints": [
            {"field": "party.self", "label": "amazon deutschland", "pattern": "", "region": ""},
            {"field": "party.self", "label": "amazon sarl", "pattern": "", "region": ""},
        ],
    }]
    result = match_account(lines, accounts, "", {})
    assert result["id"] == "amazon"
    assert result["quality"] >= 0.8


def test_party_self_regex_erkennt_konto():
    words = [
        Word(text="Amazon", x0=40, y0=40, x1=100, y1=52, page=1),
        Word(text="SARL", x0=110, y0=40, x1=160, y1=52, page=1),
    ]
    lines = group_lines(words)
    mark_roles(lines)
    accounts = [{
        "id": "amazon",
        "classes": "creditor",
        "type": "creditor",
        "name": "X",
        "company": "",
        "email": "",
        "ibans": [],
        "hints": [
            {"field": "party.self", "label": "", "pattern": r"(?i)amazon\s*(deutschland|sarl)", "region": ""},
        ],
    }]
    result = match_account(lines, accounts, "", {})
    assert result["id"] == "amazon"
