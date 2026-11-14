#!/bin/sh
# Richtet Tesseract und die Python-Umgebung auf Debian oder Ubuntu ein.
# Docman liegt als XAR in eXist. Ausführbare Programme gehören auf das Dateisystem.
set -eu

if [ "$(id -u)" -ne 0 ]; then
	echo "Bitte als root ausführen." >&2
	exit 1
fi

SRC=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
DEST=/opt/docman-intelligence

apt-get update
apt-get install -y tesseract-ocr tesseract-ocr-deu python3 python3-venv python3-pip

mkdir -p "$DEST"
cp -a "$SRC/." "$DEST/"
rm -rf "$DEST/.venv"

python3 -m venv "$DEST/.venv"
"$DEST/.venv/bin/pip" install --upgrade pip
"$DEST/.venv/bin/pip" install -e "$DEST"

TESSERACT=$(command -v tesseract)
if ! "$TESSERACT" --list-langs | grep -qx 'deu'; then
	echo "Tesseract hat keine Sprache deu." >&2
	exit 1
fi

"$DEST/.venv/bin/docman-intelligence" --version
echo "Kommando: $DEST/.venv/bin/docman-intelligence"
