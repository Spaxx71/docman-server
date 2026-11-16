"""Kommando: docman-intelligence read liest stdin und schreibt Intelligence-XML."""

import sys
import xml.etree.ElementTree as ET
from xml.sax.saxutils import escape

from docman_intelligence import __version__
from docman_intelligence.assign import assign_words
from docman_intelligence.pdf import read_document
from docman_intelligence.xmlout import render


def _local(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def parse_accounts(xml_text: str) -> list[dict]:
    if not xml_text.strip():
        return []
    root = ET.fromstring(xml_text)
    accounts = []
    for node in root.iter():
        if _local(node.tag) != "Account":
            continue
        hints = []
        ibans = []
        name = company = email = vat = address = customer_id = ""
        for child in list(node):
            kind = _local(child.tag)
            if kind == "Name":
                name = (child.text or "").strip()
            elif kind == "Company":
                company = (child.text or "").strip()
            elif kind == "Email":
                email = (child.text or "").strip()
            elif kind == "VatId":
                vat = (child.text or "").strip()
            elif kind == "CustomerID":
                customer_id = (child.text or "").strip()
            elif kind == "Address":
                address = (child.text or "").strip()
            elif kind == "IBAN":
                ibans.append((child.text or "").strip())
            elif kind == "Hints":
                for hint in list(child):
                    if _local(hint.tag) != "Hint":
                        continue
                    from docman_intelligence.vocab import field_id, region_id
                    hints.append({
                        "field": field_id(hint.attrib.get("field", "")),
                        "label": hint.attrib.get("label", ""),
                        "region": region_id(hint.attrib.get("region", "")),
                        "pattern": hint.attrib.get("pattern", ""),
                    })
        accounts.append({
            "id": node.attrib.get("id", ""),
            "classes": node.attrib.get("classes", ""),
            "type": node.attrib.get("type", ""),
            "name": name,
            "company": company,
            "email": email,
            "vat": vat,
            "customerId": customer_id,
            "address": address,
            "ibans": ibans,
            "hints": hints,
        })
    return accounts


def parse_stdin(raw: str) -> tuple[dict, str, str, str, bytes]:
    meta = {"from": "", "subject": ""}
    accounts = ""
    model = ""
    examples = ""
    file_b64 = []
    file_path = ""
    section = None
    for line in raw.splitlines():
        if line in ("META", "ACCOUNTS", "MODEL", "EXAMPLES", "FILE", "FILEPATH"):
            section = line
            continue
        if line == "END":
            section = None
            continue
        if section == "META" and ":" in line:
            key, value = line.split(":", 1)
            meta[key.strip().lower()] = value.strip()
        elif section == "ACCOUNTS":
            accounts += line
        elif section == "MODEL":
            model += line
        elif section == "EXAMPLES":
            examples += line
        elif section == "FILEPATH":
            if not file_path:
                file_path = line.strip()
        elif section == "FILE":
            file_b64.append(line.strip())
    if file_path:
        from pathlib import Path
        path = Path(file_path)
        if not path.is_file():
            raise FileNotFoundError(f"FILEPATH nicht gefunden: {file_path}")
        data = path.read_bytes()
        if not data:
            raise ValueError(f"FILEPATH ist leer: {file_path}")
    else:
        import base64
        data = base64.b64decode("".join(file_b64)) if file_b64 else b""
    return meta, accounts, model, examples, data


def run_read(raw: str, path: str = "") -> str:
    meta, accounts_xml, model_xml, _examples, payload = parse_stdin(raw)
    if path:
        from pathlib import Path
        file_path = Path(path)
        if not file_path.is_file():
            return (
                f'<Intelligence><Source kind="error" pages="0"/>'
                f"<Error>PDF-Pfad nicht gefunden: {escape(path)}</Error></Intelligence>"
            )
        payload = file_path.read_bytes()
    accounts = parse_accounts(accounts_xml)
    from docman_intelligence.train import parse_model
    model = parse_model(model_xml)
    if not payload:
        return (
            "<Intelligence><Source kind=\"error\" pages=\"0\"/>"
            "<Error>Keine Datei (Protokoll ohne FILE/FILEPATH und ohne Pfad-Argument). "
            "Version &gt;= 0.1.1 nötig: sh /tmp/docman-intelligence/install-linux.sh</Error>"
            "</Intelligence>"
        )
    words, zugferd, kind, origin = read_document(payload)
    if zugferd:
        zugferd["words"] = words
        zugferd["source"] = "zugferd"
        zugferd["origin"] = "digital"
        if accounts:
            from docman_intelligence.assign import group_lines, mark_roles, match_account
            lines = group_lines(words)
            mark_roles(lines)
            zugferd["account"] = match_account(lines, accounts, zugferd["iban"]["value"], meta)
        return render(zugferd)
    result = assign_words(words, accounts, meta, model)
    result["source"] = kind
    result["origin"] = origin
    return render(result)


def run_train(raw: str) -> str:
    _meta, _accounts, _model, examples, _payload = parse_stdin(raw)
    from docman_intelligence.train import train_xml
    if not examples.strip():
        return '<Model version="1"/>'
    return train_xml(examples)


def main() -> None:
    args = sys.argv[1:]
    if not args or args[0] in ("-h", "--help"):
        print("docman-intelligence read [pdf]  liest Meta von stdin, optional PDF-Pfad")
        print("docman-intelligence train         schätzt Gewichte aus EXAMPLES")
        return
    if args[0] == "--version":
        print(__version__)
        return
    if args[0] not in ("read", "train"):
        print("Unbekanntes Kommando.", file=sys.stderr)
        sys.exit(2)
    raw = sys.stdin.read()
    try:
        if args[0] == "train":
            sys.stdout.write(run_train(raw))
        else:
            pdf_path = args[1] if len(args) > 1 else ""
            sys.stdout.write(run_read(raw, pdf_path))
    except Exception as exc:
        message = escape(str(exc))
        sys.stdout.write(f'<Intelligence><Source kind="error" pages="0"/><Error>{message}</Error></Intelligence>')
        sys.exit(1)
