# Zuordnung von Kontobewegung und Vorgang

Eine Funktion bewertet offene Bankbewegungen und offene Vorgänge. Dieselbe Antwort bedient beide Seiten:

- `/{sprache}/{mandant}/{jahr}/banks/{konto}/assign/{PAY}` sucht die Vorgänge zu einer Zahlung.
- `/{sprache}/{mandant}/{jahr}/binders/{ordner}/processes/{PRO}/payment` sucht die Zahlungen zu einem Vorgang.

Die Bankzeile ist die Vorlage und bleibt blau (`#39F`). Gefärbt wird nur die Vorgangszeile. Grün `#3C3` ist ein voller Treffer auf diesem Feld, orange `#e61` ein Teiltreffer. Die Spalten liegen untereinander: Betrag, Datum, Belegnummer unter der Kundenreferenz, Vorgangsnummer unter der End-to-End-Referenz, Text unter dem Verwendungszweck, Gegenkonto.

## Wer kandidiert

Offen ist, was die vorhandenen `PaymentTask` noch nicht decken. Der offene Betrag ist der Vorgangs- oder Bewegungsbetrag abzüglich der Summe der schon gespeicherten Zahlungsbeträge. Eine Bewegung, deren Summe den Bewegungsbetrag deckt, und ein Vorgang, dessen Summe den Vorgangsbetrag deckt, fallen heraus. Ein Paar, das bereits über die `RefID` der Zahlung verbunden ist, wird für diese Zahlung nicht erneut vorgeschlagen.

Vorgänge sind `InvoiceInTask` und `InvoiceOutTask`, jeweils mit und ohne Storno, sowie `EmployeeSalaryTask`. Bei Rechnungen zählen `TotalAmount` (sonst der Betrag der Hauptaufgabe), das Vorgangsdatum, `RefID` und `TransactionID`. Beim Gehalt ist `AmountPaid` der Zahlbetrag, ausgehend negativ und bei Storno positiv. Name und Gehaltsmonat ersetzen Beleg- und Vorgangsnummer.

Die Richtung muss zusammenpassen. Ein Zahlungseingang (`CREDIT`, Geld kommt herein) sucht eine ausgehende Rechnung und die Gutschrift einer eingehenden Rechnung. Ein Zahlungsausgang (`DEBIT`, Geld geht hinaus) sucht eine eingehende Rechnung, ein Gehalt und die Gutschrift einer ausgehenden Rechnung. Der Vergleichsbetrag trägt dabei dieses Vorzeichen, unabhängig davon, wie der Beleg ursprünglich gespeichert ist.

Dieselbe absolute Summe in der anderen Richtung wird gezeigt und nicht geschrieben. Der Grund nennt die Richtung. Fehlt die IBAN am Personenkonto, bleibt der Betragstreffer sichtbar, mit dem Hinweis, dass kein gemeinsames Gegenkonto vorliegt. Geschrieben wird eine Gruppe nur, wenn Gegenkonto, Betrag, Datum und Text zusammenpassen.

## Datumsfenster

Die Vorgaben stehen in `modules/module_banking.xqm`:

- `$banking:match-days-before` ist 14. Die Valuta darf bis zu 14 Tage vor dem Vorgangsdatum liegen.
- `$banking:match-days-after` ist 21. Die Valuta darf bis zu 21 Tage nach dem Vorgangsdatum liegen.

`days-before` und `days-after` an den GET- und POST-Aufrufen überschreiben die Vorgaben für diesen Aufruf. Beide Zuordnungsseiten zeigen die Werte als Eingabefelder, vorbelegt mit 14 und 21. „Neu berechnen“ schickt die geänderten Werte mit.

Ein einzelner Betrag gilt als gleich, wenn er um weniger als einen halben Cent abweicht. Das fängt nur Rundung ab und ist keine einstellbare Toleranz.

`tolerance` gilt für den Gesamtbetrag eines Bündels. Vorgabe ist `0.01` Euro. Die Seite zeigt das Feld als `0,01`. Zwei oder drei kleinere Belege desselben Gebers, deren Summe die Zahlung innerhalb dieser Toleranz erreicht, sind ein Bündel. Ein einzelner kleinerer Betrag steht als Teiltreffer. Grün, Gelb und Rot in der Zelle zeigen, ob der Indikator trifft, teilweise trifft oder fehlt. Die Auswahlbox der Zeilengruppe trägt die zusammengefasste Qualität als Hintergrund.

Im Datumsfeld steht der Abstand. Liegt die Zahlung im perfekten Fenster, ist das Datum grün. Im weiteren, potentiellen Fenster ist es gelb. Außerhalb beider Fenster ist es rot.

Die Feldmarken kommen vom Server. Einbezogen werden die Beträge der Warenposition, der Rechnung, des Gehalts, des Skontos und der Mahngebühr. Eine Gutschrift wird nicht mit Kosten addiert. Der Text wird an Wortgrenzen verglichen, Nummern ohne Leerzeichen. Grünes Datum heißt: die Zahlung liegt im perfekten Fenster, gelbes Datum im weiteren Fenster. Automatisch verknüpft wird nur ein Full-Match, in dem jede Marke grün ist. Der Stapel unter `/{jahr}/matchings` zeigt zuerst die Stücke, die aufgehen, und den noch offenen Saldo; weitere Treffer und eine unvollständige Sammelzahlung bleiben mit dem fehlenden Betrag sichtbar. Gutschrift, Mahngebühr, Skonto und Kreditor-Muster werden nur auf Klick angelegt.

## Sichere Zuordnung

Geschrieben wird ohne einzelne Bestätigung nur ein Full-match: jede Feldmarke ist grün, die Gruppe ist die einzige für diese Bewegung und diesen Posten, und sie trägt keine Einladung. Der Betrag trifft auf den halben Cent, bei einem Bündel die Summe innerhalb der Toleranz. Das Datum liegt im Fenster. Belegnummer oder Vorgangsnummer trifft ohne Leerzeichen; beim Gehalt der Mitarbeitername. Der Text trifft an Wortgrenzen. Das Gegenkonto trifft über Konto, IBAN, Gläubiger-ID oder eine erfüllte Zahlungsregel.

Der Dienst hängt dann je Posten einen `PaymentTask` an. Buchungsrichtung und Storno folgen dem Posten. Gutschrift, Mahngebühr, Skonto, Dauerbezug und Kreditor-Muster werden nie automatisch angelegt.

## Vorschläge

Alles andere wird gezeigt und nur auf Klick geschrieben, nachdem `match-check` den Rest mit 0,00 oder eine ausdrückliche Teilzahlung bestätigt.

- Der Betrag geht nicht auf: die Differenz steht in der Zelle. Ohne Posten, Summe oder Kommentar, der sie trägt, gibt es keinen Treffer. Ein Euro Spielraum gibt es nicht.
- Das Datum liegt außerhalb des Fensters: der Abstand in Tagen, rot.
- Der Text trifft ein Wort, aber nicht die ganze Folge: gelb.
- Eine gegenläufige Bewegung hebt sich auf. Verknüpft wird nur die Richtung, die zum Posten passt.
- Mahngebühr, Skonto und fehlende Gutschrift erscheinen als Einladung, nicht als Buchung.

## Schnittstellen

XML und JSON, unter `/api/xml` und `/api/json` beziehungsweise `/exist/restxq/docman/xml` und `…/json`:

- `GET /tenants/{mandant}/years/{jahr}/banks/{konto}/accountings/{PAY}/suggestions`
- `POST` auf demselben Pfad mit einem beliebigen XML-Rumpf schreibt nur Gruppen mit `auto="true"`, und nur wenn sie beim Schreiben noch eindeutig und offen sind.
- `GET /tenants/{mandant}/years/{jahr}/binders/{ordner}/documents/{PRO}/payment-suggestions`

Die Umsetzung steht in `modules/module_match.xqm` und wird über `modules/functions/match_suggestions.xqy` und `match_apply.xqy` aufgerufen.

Zwei Einstiege, jeweils unter `/api/xml` und `/api/json`:

- Kontobewegung: `GET` und `POST` `…/banks/{kto}/accountings/{PAY}/suggestions` in `modules/restxq-bank.xqy`. Ausgangspunkt ist diese Zahlung.
- Vorgang: `GET` `…/binders/{ordner}/documents/{PRO}/payment-suggestions` in `modules/restxq-document.xqy`. Ausgangspunkt ist dieser Vorgang. Derselbe Pfad darf nicht zusätzlich im Bank-Modul stehen.

Die Seiten liegen in `docman-ui` unter `src/Apps/Bank/AssignPayment.tsx` und `src/Apps/Binder/LinkPayment.tsx`.

Antwort:

```xml
<Suggestions days-before="14" days-after="21" cluster="4">
  <Group auto="true" kind="exact" quality="0.8">
    <Payment bank="222971400" id="PAY…" amount="-100.00" date="2021-03-01"
      unit="EUR" customer="…" endtoend="…" purpose="…" iban="…" creditor="…" recipient="…"/>
    <Process id="PRO…" binder="01" name="…" owner="70002" ownerName="…"
      amount="-60.00" date="2021-02-20" ref="…" trans="…" description="…"
      task="InvoiceInTask" storno="false" salary="false" distance="9">
      <Mark field="amount" level="none"/>
      <Mark field="date" level="part" days="9"/>
      <Mark field="reference" level="done"/>
      <Mark field="transaction" level="none"/>
      <Mark field="purpose" level="none"/>
    </Process>
    <Sum amount="-100.00" level="done"/>
  </Group>
  <Group auto="false" kind="near" quality="0">
    <Payment …/>
    <Process …/>
    <Reason field="amount" difference="1,20">Der Betrag geht um 1,20 EUR nicht auf.</Reason>
    <Reason field="date" days="40">Das Datum liegt 40 Tage außerhalb des Fensters.</Reason>
    <Reason field="content">Weder Belegnummer noch Vorgangsnummer steht im Zahlungstext.</Reason>
  </Group>
</Suggestions>
```

`kind` ist `exact`, `bundle`, `part`, `near` oder `direction`. `quality` ist 0.9, 0.8 und 0.7 für eine, zwei und drei Vorgänge einer genauen Gruppe. Ein Bündel aus kleineren Belegen hat 0.45, ein einzelner kleinerer Beleg 0.2. `level` an `Mark` und `Sum` ist `done`, `part` oder `none`. Weitere Gründe sind `unique`, `bundle`, `direction` und `counterparty`. `cluster` ist die Zahl der Gegenüber im Bündel des angefragten Vorgangs oder der angefragten Bewegung. `tolerance` steht an `Suggestions`.

Die Seite trennt direkte Treffer, Bündeltreffer und teilweise Treffer durch eine Linie und erklärt die Farben unter der Tabelle.
