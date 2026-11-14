"""Wörter und Kästen aus PDFium, Bildseiten über Tesseract."""

from __future__ import annotations

import subprocess
import tempfile
from pathlib import Path

from docman_intelligence.assign import Word
from docman_intelligence.zugferd import parse_zugferd


def _words_from_page(page, page_number: int) -> list[Word]:
    textpage = page.get_textpage()
    count = textpage.count_chars()
    height = page.get_height()
    chars = []
    for index in range(count):
        piece = textpage.get_text_range(index, 1)
        if not piece or piece == "\x00":
            continue
        left, bottom, right, top = textpage.get_charbox(index)
        chars.append((piece, left, height - top, right, height - bottom))
    words: list[Word] = []
    buffer = ""
    box = None
    for piece, x0, y0, x1, y1 in chars:
        if piece.isspace():
            if buffer and box:
                words.append(Word(buffer, box[0], box[1], box[2], box[3], page_number))
            buffer = ""
            box = None
            continue
        if box and x0 - box[2] > max(2.5, (y1 - y0) * 0.4):
            words.append(Word(buffer, box[0], box[1], box[2], box[3], page_number))
            buffer = ""
            box = None
        buffer += piece
        if box is None:
            box = [x0, y0, x1, y1]
        else:
            box[0] = min(box[0], x0)
            box[1] = min(box[1], y0)
            box[2] = max(box[2], x1)
            box[3] = max(box[3], y1)
    if buffer and box:
        words.append(Word(buffer, box[0], box[1], box[2], box[3], page_number))
    return words


def _ocr_page(page, page_number: int) -> list[Word]:
    bitmap = page.render(scale=2)
    image = bitmap.to_pil()
    with tempfile.TemporaryDirectory() as folder:
        path = Path(folder) / "page.png"
        image.save(path)
        run = subprocess.run(
            ["tesseract", str(path), "stdout", "-l", "deu", "--psm", "6", "tsv"],
            check=False,
            capture_output=True,
            text=True,
        )
    words = []
    for row in run.stdout.splitlines()[1:]:
        cols = row.split("\t")
        if len(cols) < 12 or not cols[11].strip() or cols[11] == "-1":
            continue
        left, top, width, height = (float(cols[i]) / 2 for i in (6, 7, 8, 9))
        words.append(Word(cols[11], left, top, left + width, top + height, page_number))
    return words


def _embedded_xml(pdf) -> bytes | None:
    count = getattr(pdf, "count_attachments", None)
    if count is None:
        return None
    names = ("factur-x.xml", "zugferd-invoice.xml", "zugferd.xml", "xrechnung.xml")
    for index in range(count()):
        attachment = pdf.get_attachment(index)
        name = (getattr(attachment, "name", "") or "").lower()
        if name in names or name.endswith(".xml"):
            data = attachment.get_file()
            if b"CrossIndustryInvoice" in data or b"Invoice" in data:
                return data
    return None


def read_document(data: bytes) -> tuple[list[Word], dict | None, str]:
    import pypdfium2 as pdfium

    pdf = pdfium.PdfDocument(data)
    embedded = _embedded_xml(pdf)
    zugferd = parse_zugferd(embedded) if embedded else None
    words: list[Word] = []
    ocr_used = False
    for index in range(len(pdf)):
        page = pdf[index]
        page_words = _words_from_page(page, index + 1)
        if len(page_words) < 8:
            page_words = _ocr_page(page, index + 1)
            ocr_used = True
        words.extend(page_words)
    kind = "zugferd" if zugferd else ("ocr" if ocr_used else "text")
    return words, zugferd, kind
