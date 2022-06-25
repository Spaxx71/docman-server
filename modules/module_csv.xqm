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

xquery version "3.1";

module namespace csv = "http://bintellix.com/docman/csv";

(:
https://dev.bintellix.com/exist-backend/rest/db/apps/docman/modules/module_csv.xqy?filename=Kontoumsaetze_220_222971400_20200530_090540.csv&tenant=bintellix
:)


declare function csv:formatValue ($IsHeader as xs:boolean, $Format, $Value as xs:string?)
{
	try {
		if ($IsHeader) then
			$Value
		else if ($Value = ()) then
			$Value
		else if ($Format/@type = 'dateTime') then
			xs:dateTime($Value)
		else if ($Format/@type = 'date') then
			if ($Format/@pattern = '[D00].[M00].[Y0000]') then
				xs:date(substring($Value,7,4)||'-'||substring($Value,4,2)||'-'||substring($Value,1,2))
			else
				xs:date($Value)
		else if ($Format/@type = 'money') then
			if ($Value = '') then
				()
			else if (matches($Value, '[0-9],[0-9][0-9]?$')) then
				xs:decimal(translate($Value,',.','.'))
			else
				xs:decimal($Value)
		else if ($Format/@type = 'boolean') then
			xs:boolean($Value)
		else 
			$Value
	}
	catch * {
		"ERROR: invalid value '"||$Value||"'"
	}	
};

(: base can be either number (for iterate on predefined column number) or name (for iterate based on given column name :)
declare function csv:csv-to-xml ($csv as xs:string, $csv-format-spec as node(), $base as xs:string) 
{
    element { $csv-format-spec/Format/@name }
    {
        let $lines := tokenize($csv, '\n')

        (: let $head := tokenize($lines[1], $csv-format-spec/Format/@separator) :)

        (: iterate over all parts :)
        for $part in $csv-format-spec/Format/Part
        return
            element { $part/@name }
            {
		let $previousLines := sum($part/preceding-sibling::Part/@lines) +1
                for $line at $lineNum in subsequence($lines,$previousLines)
		where not($part/@lines) or ($lineNum <= $part/@lines)
                let $fields := tokenize($line, $csv-format-spec/Format/@separator)
                return
                    <Row line="{$lineNum}">
                    {
			if ($lineNum <= $part/@headerlines) then 
				attribute { "type" } { "HEADER" }
			else
				()
                    }
                    {
			(: "[" || not($part/@lines) || $lineNum || $part/@lines || "]" :)
		    	(: iterate over all columns :)
                        for $column at $pos in $part/Column
		    	order by xs:integer($column/@nr)
		        (: for text elements the double-quotes "..." have to be removed :)
                        let $value := if (matches($fields[$pos],'^"(.*)"$')) then replace($fields[$pos],'^"(.*)"$',"$1") else $fields[$pos]
                        return
                            element { $column/@name } { csv:formatValue($lineNum <= $part/@headerlines, $column, $value) }
                    }
                    </Row>
            } 
    }
};


declare function csv:test() 
{
	let $tenant := request:get-parameter('tenant','')
	let $filename := request:get-parameter('filename','')
	let $format-spec-uri := '/db/apps/docman/modules/banking/banking_csv_format.xml'

	let $csv-file := '/db/apps/docman/data/'||$tenant||'/transfer/'||$filename
	let $csv-format-spec := doc($format-spec-uri)

	let $csv-binary := util:binary-doc($csv-file)
	let $csv := util:binary-to-string($csv-binary)

	let $xml := csv:csv-to-xml($csv, $csv-format-spec, 'number')

	(:
	let $store := xmldb:store('/db/apps/docman/data/'||$tenant||'/', 	'datev_import_csv_tmp.xml', $xml)
	:)

	return
		$xml
};
