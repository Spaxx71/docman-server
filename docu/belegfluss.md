# Belege, Zahlungen und Vorgänge

Docman führt Belege und Kontobewegungen in einem Jahr zusammen. Drei Wege liefern das Material. Personenkonten und Document Intelligence machen daraus lesbare Vorgänge. Die Seite `/{sprache}/{mandant}/{jahr}/matchings` (Beispiel [bintellix 2020](https://docman.bintellix.com/de/bintellix/2020/matchings)) zeigt die Vorschläge, welche Zahlung zu welchem Vorgang gehört. Geschrieben wird eine Verknüpfung nur, wenn sie eindeutig ist, oder auf Klick.

Die Feldregeln der einzelnen Zuordnung stehen in [bank-zuordnung.md](bank-zuordnung.md). Dieser Text beschreibt den Lauf vom Eingang bis zur Planung.

## Drei Wege hinein

**Transfer-Ordner.** Dateien liegen unter `{mandant}/{jahr}/transfer`. Der Ordner ist der Eingangskorb. `transfer:index` in `modules/module_transfer.xqm` listet ihn.

**E-Mail.** Ein Anhang wird ausgewählt und in denselben Transfer-Ordner gelegt (`modules/restxq-mail.xqy`, `modules/functions/mail_transfer.xqy`). Absender und Betreff stehen in `Meta` der Intelligence-Datei. Das Notizfeld `Notes` bleibt beim Lesen erhalten und wandert beim Ablegen in die Beschreibung des Vorgangs (`di:archive`).

**Bank und Kasse.** HBCI/FinTS liest die Umsätze (`banking:updateViaFinTS`). Hibiscus- und CSV-Import tun dasselbe. Ein Konto ohne Online-Banking ist die manuelle Kasse: die Bewegung wird am Konto geführt, die Zuordnung läuft danach über denselben Stapel.

## Eingangskorb

Jede Datei bekommt einen SHA-256-Hash. Derselbe Hash an einem schon abgelegten Beleg ergibt `duplicate="filed"` und einen Verweis `AlreadyFiled`. Derselbe Hash ein zweites Mal im Transfer ergibt `duplicate="transfer"`. Die Oberfläche kennzeichnet beide Fälle. Sidecar-Dateien `*.dm.xml` erscheinen nicht als eigene Belege.

PDF, TIFF und Bilder bekommen eine Intelligence-Datei mit `status="pending"`. Der Job `document_intelligence_process.xqy` liest sie im Hintergrund.

## Personenkonten

Debitoren und Kreditoren stehen in `accounts.dm.xml`. Am Konto liegen Name, IBAN, Bankverbindungen und die Gläubiger-ID. `FieldHints` geben Document Intelligence zusätzliche Anker: Bezeichnung oder Muster, Region und Feld, etwa Rechnungsnummer, IBAN, USt-Id oder der eigene Name (`party.self`), damit eine Ausgangsrechnung von einer Eingangsrechnung zu unterscheiden ist.

Ein Zahlungsintervall (`PeriodicPayment`) trägt:

- Periode (`monthly`, `quarterly`, `annually`), Häufigkeit (`min`, `max`) und Gültigkeit
- Betragsspanne `amount-min` / `amount-max`
- Regeln: IBAN, Gläubiger-ID, Verwendungszweck als Text oder Regex, eigenes Bankkonto
- eine Buchungsvorlage mit Aufwandskonto, Steuer, Belegtext

`PaymentRule/@use` steuert Pflicht (`required`, Vorgabe) und Kann (`optional`). Ein Intervall gilt, wenn alle Pflichtregeln greifen; gibt es nur Kann-Regeln, reicht eine.

## Vorgänge

Ein Vorgang ist eine Eingangsrechnung (`InvoiceInTask`) oder eine Ausgangsrechnung (`InvoiceOutTask`), dazu Gehalt. Darunter hängen Warenposition, Zahlung (`PaymentTask`), bei Bedarf Mahngebühr und Skonto. Die Zahlung referenziert die Kontobewegung über ihre `RefID`. Offen ist, was die gespeicherten Zahlungsbeträge noch nicht decken.

Gutschrift, Mahngebühr, Skonto und ein Dauerbezug aus dem Intervall werden vorgeschlagen und nur auf Klick angelegt. Ein eindeutiger voller Treffer schreibt allein den `PaymentTask`.

## Document Intelligence

Das Programm liest eRechnung, digitales PDF und gescanntes Papier. Der Server übergibt die Personenkonten inklusive IBAN und Hints und das gelernte Modell unter `{mandant}/intelligence/model.xml`. Zurück kommen Herkunft (`Source`, etwa ZUGFeRD), Dokumentenart, Konto, Felder, Positionen und Text.

Die Art `invoice.out` entsteht, wenn der Absender zum eigenen Konto oder zu einem `party.self`-Hint passt. Sonst ist eine Rechnung `invoice.in`.

Beim Ablegen des Belegs wandert die Notiz in die Vorgangsbeschreibung, die Intelligence-Datei in `intelligence/examples`, und `di:learn` trainiert das Modell an den bestätigten Werten Datum, Betrag, Belegnummer, Konto (`Owner`), Richtung und Fälligkeit. Hint-Vorschläge für Kreditoren landen in `accounts.hint-proposals.xml` und ändern den Kontenplan nicht von selbst.

Die Felder füllen den Vorgang noch nicht. `document:getNewDocumentTemplate` legt einen leeren Vorgang an. Die Intelligence hängt erst an der Datei, wenn der Beleg aus dem Transfer in den Ordner gezogen wird.

## Zuordnung: der Stapel unter /matchings

Die Seite eines Jahres ist die Arbeitsliste. Sie spricht `GET /tenants/{mandant}/years/{jahr}/matchings` an (`modules/restxq-bank.xqy`, `match:stack`).

- `side=payment` (Vorgabe) stellt jede Kontobewegung des Jahres in eine Zeile und sucht die Vorgänge dazu.
- `side=process` stellt jeden Vorgang in eine Zeile und sucht die Zahlungen dazu.
- `banks` grenzt auf einzelne Konten ein.

Das Fenster reicht `neighbor` Tage ins Vorjahr und ins Folgejahr (Vorgabe 45), damit eine Zahlung um den Jahreswechsel den Beleg des anderen Jahres findet.

Jede Zeile trägt eine Klasse:

| Klasse | Bedeutung |
| --- | --- |
| `full` | Einziger voller Treffer mit starkem Signal (Gegenkonto oder Belegnummer), keine Einladung, Belegprüfung nicht rot. `auto="true"`. |
| `single` | Der Betrag geht auf einen Posten auf. |
| `group` | Der Betrag geht auf mehrere Vorgänge desselben Gegenkontos auf (Sammelzahlung). |
| `partly` | Teiltreffer. Die Differenz steht in `rest`. |
| `none` | Kein Kandidat. |

Sortiert wird nach Klasse, dann nach offenem Rest, dann nach Datum. Die Summen der Antwort sind `open` (Summe der Beträge), `explained` (was `full`, `single` oder `group` deckt) und `rest` (die Differenz). Zuerst stehen also die Stücke, die aufgehen.

Dieselbe Bewertung bedient die einzelne Bewegung (`…/banks/{konto}/accountings/{PAY}/suggestions`) und den einzelnen Vorgang (`…/binders/{ordner}/documents/{PRO}/payment-suggestions`). Die Bankzeile bleibt die Vorlage. Gefärbt wird die Vorgangszeile: grün ist ein voller Treffer auf diesem Feld, orange ein Teiltreffer. Verglichen werden Betrag, Datum, Belegnummer, Vorgangsnummer, Verwendungszweck und Gegenkonto. Ein Bündel aus zwei oder drei kleineren Belegen desselben Gebers gilt innerhalb der Toleranz (Vorgabe 0,01 EUR). Skonto und Mahngebühr erscheinen als Einladung, sobald Text oder Betrag sie tragen.

Gegenkonto ist grün über Kontonummer, IBAN, Gläubiger-ID oder eine erfüllte Zahlungsregel. Liegt der Betrag außerhalb der Spanne des Kreditors, oder rechnet das Intervall die Zahlung einer anderen Periode zu, nennt der Vorschlag den Grund. Fehlt zum erfüllten Intervall der Vorgang, lautet die Einladung `PeriodicPayment`. Angelegt wird er nur auf Klick.

Geschrieben wird ohne einzelne Bestätigung nur die Klasse `full`. Einzeln über `POST …/suggestions` der Zahlung, jahrweise über `POST …/matchings/apply` (`match:apply-all`). Jede Zeile wird vor dem Schreiben erneut geprüft. Abgelehnte Paare stehen in `{jahr}/matching-rejects.xml` und erscheinen nicht wieder. `GET …/matchings/quality` zählt Auto-Quote und DI-Kontokorrekturen.

## Belegprüfung und Stammdaten-Vorschläge

`document:check-evidence` vergleicht Vorgang und `DocmanIntelligence` (Konto, IBAN, Betrag, Datum, Belegnummer, Richtung) und schreibt `@evidence` am Vorgang. Aufruf beim Speichern und über `GET …/documents/{PRO}/evidence`. Eine rote Belegprüfung verhindert `auto`.

Unter Tools der Portalseite liegt `…/tools/proposals`: Kreditor neu, Bankverbindung ergänzen, Intervall neu/anpassen, Feldhinweise. Die ToDo-Liste daneben zeigt die wichtigsten offenen Vorschläge. Intervall-Anomalien kommen von `GET …/interval-findings` (dieselbe Regelprüfung wie der Matcher) und fließen in `alerts.dm.xml`.

## Was der Stand trägt

1. Der Eingangskorb kennt Doubletten, Absender, Betreff, Notiz und die gelesenen Rechnungsfelder.
2. Personenkonto und Intervall kennen IBAN, Gläubiger-ID, Mandat, Pflicht-/Kann-Regeln und Betragsspanne.
3. Der Matcher liest Beleg-IBAN, Kundennummer, Fälligkeit und Skonto, lernt Schlüssel aus bestätigten Zahlungen und speichert Ablehnungen.
4. Der Stapel unter `/matchings` kennt Klasse, Rest, Stapellauf und Qualitätsmessung.
5. Stammdaten-Vorschläge und Intervall-Befunde stehen auf der Portalseite.
