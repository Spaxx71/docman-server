from docman_intelligence.pdf import classify_origin


def test_zugferd_ist_digital():
    assert classify_origin(text_pages=0, ocr_pages=0, has_zugferd=True) == ("zugferd", "digital")


def test_eingebetteter_text_ist_digital():
    assert classify_origin(text_pages=3, ocr_pages=0, has_zugferd=False) == ("text", "digital")


def test_nur_ocr_ist_scan():
    assert classify_origin(text_pages=0, ocr_pages=2, has_zugferd=False) == ("ocr", "scan")


def test_gemischt_text_und_ocr():
    assert classify_origin(text_pages=1, ocr_pages=1, has_zugferd=False) == ("mixed", "mixed")
