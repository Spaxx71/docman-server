(:
========================================================================
LICENSE AGREEMENT:
This software is distributed WITHOUT ANY WARRANTY and without even the
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
========================================================================
This copy of Docman (a Document managgement an accounting system) 
is licensed under the Server Side Public License (SSPL), v 1 ("the License").

See the License for details about distribution rights, 
modification and transformation of it.

========================================================================
All rights reserved by bintellix GmbH, Germany
========================================================================
@Author: Eduard Huber
@Version: 1.0
======================================================================== 
:)

xquery version "3.0";

(: https://apps.datev.de/dnlexka/document/1080789 :)

import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";


declare function local:csv-to-xml ($csv as xs:string) 
{

let $config := 
<file-import-config>
   <field-separator>;</field-separator>
   <root-element-name>Records</root-element-name>
   <line-element-name>Record</line-element-name>
</file-import-config>


let $lines := tokenize($csv, '\n')
let $head := ("Umsatz","SH-Kennzeichen","WKZ-Umsatz","Kurs","Basis-Umsatz", "WKZ-Basis-Umsatz","Konto","Gegenkonto","BU-Schluessel","Belegdatum",
			"Belegfeld1","Belegfeld2","Skonto","Buchungstext","Postensperre","DiverseAdressnummer","Geschaeftspartnerbank","Sachverhalt","Zinssperre",
			"Beleglink","BeleginfoArt1","BeleginfoInhalt1","BeleginfoArt2","BeleginfoInhalt2","BeleginfoArt3","BeleginfoInhalt3","BeleginfoArt4","BeleginfoInhalt4",
			"BeleginfoArt5","BeleginfoInhalt5","BeleginfoArt6","BeleginfoInhalt6","BeleginfoArt7","BeleginfoInhalt7","BeleginfoArt8","BeleginfoInhalt8",
			"Kostenstelle1","Kostenstelle2","KostenstelleMenge","EU-LandUStID","EU-Steuersatz","AbwVersteuerungsart",
			"SachverhaltLL","FunktionsergaenzungLL","BU49Hauptfunktionstyp","BU49Hauptfunktionsnummer","BU49Funktionsergaenzung",
			"ZusatzinformationArt1","ZusatzinformationInhalt1","ZusatzinformationArt2","ZusatzinformationInhalt2","ZusatzinformationArt3","ZusatzinformationInhalt3","ZusatzinformationArt4","ZusatzinformationInhalt4",
			"ZusatzinformationArt5","ZusatzinformationInhalt5","ZusatzinformationArt6","ZusatzinformationInhalt6","ZusatzinformationArt7","ZusatzinformationInhalt7","ZusatzinformationArt8","ZusatzinformationInhalt8",
			"ZusatzinformationArt9","ZusatzinformationInhalt9","ZusatzinformationArt10","ZusatzinformationInhalt10","ZusatzinformationArt11","ZusatzinformationInhalt11","ZusatzinformationArt12","ZusatzinformationInhalt12",
			"ZusatzinformationArt13","ZusatzinformationInhalt13","ZusatzinformationArt14","ZusatzinformationInhalt14","ZusatzinformationArt15","ZusatzinformationInhalt15","ZusatzinformationArt16","ZusatzinformationInhalt16",
			"ZusatzinformationArt17","ZusatzinformationInhalt17","ZusatzinformationArt18","ZusatzinformationInhalt18","ZusatzinformationArt19","ZusatzinformationInhalt19","ZusatzinformationArt20","ZusatzinformationInhalt20",
			"Stueck","Gewicht","Zahlweise","Forderungsart","Veranlagungsjahr","ZugeordneteFaelligkeit","Skontotyp","Auftragsnummer","BuchungstypAnzahlungen","USt-SchluesselAnzahlungen","EU-LandAnzahlungen","SachverhaltLLAnzahlungen",
			"EU-SteuersatzAnzahlungen","ErloeskontoAnzahlungen","Herkunft-Kz","BuchungsGUID","KOST-Datum","SEPA-Mandatsreferenz","Skontosperre","Gesellschaftername","Beteiligtennummer","Identifikationsnummer","Zeichnernummer",
			"PostensperreBis","BezeichnungSoBil-Sachverhalt","KennzeichenSoBil-Buchung","Festschreibung","Leistungsdatum","DatumZuordSteuerperiode","Faelligkeit","GeneralumkehrGU","Steuersatz","Land")
let $body := $lines
(: 
let $head := tokenize($lines[1], $config/field-separator)
let $body := remove($lines, 1)
:)
return
    element {$config/root-element-name}
        {
            for $line in $body
            let $fields := tokenize($line, $config/field-separator)
            return
                element {$config/line-element-name}
                    {
                        for $key at $pos in $head
                        let $value := if (matches($fields[$pos],'^"(.*)"$')) then replace($fields[$pos],'^"(.*)"$',"$1") else $fields[$pos]
                        return
                            element { $key } { $value }
                    }
        }
};

let $tenant := request:get-attribute('tenant')
let $year := request:get-attribute('year')
let $document := request:get-attribute('document')

let $csv-file := '/db/apps/docman/data/'||$tenant||'/'||$year||'/transfer/'||$document
let $csv-binary := util:binary-doc($csv-file)
let $csv := util:binary-to-string($csv-binary)
let $xml := local:csv-to-xml($csv)
let $store := xmldb:store('/db/apps/docman/data/'||$tenant||'/', 'datev_import_csv_tmp.xml', $xml)

let $param := 	<parameters>
			<param name="home-web-gui" value="{$main:home-web-gui}"/>
			<param name="home-web-api" value="{$main:home-web-api}"/>
			<param name="home-data" value="{$main:home-data}"/>
			<param name="home-views" value="{$main:home-views}"/>
			<param name="tenant" value="{$tenant}"/>
			<param name="filename" value="{$document}"/>
		</parameters>
let $data := transform:transform($xml, xs:anyURI("xmldb:exist:///db/apps/docman/modules/datev/datev_transfer.xsl"), $param)

return
    <fine/>

