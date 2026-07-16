xquery version "3.1";

(:
This script might be tested at:

/rest/db/apps/docman/initialize.xqy
:)

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace docman = "http://docman.bintellix.com";

declare option output:indent "yes";

declare function local:list-collections($Collection as xs:string) as xs:string* {

    for $child in xmldb:get-child-collections($Collection)
    let $childCollection := concat($Collection, '/', $child)
    return
	if (xmldb:collection-available($childCollection)) then
        	(local:list-collections($childCollection), $childCollection)
	else
		"Error: Collection " || $childCollection || " is listed but does not exist."
};


declare function local:checkFilename($Collection, $Document, $NewFilename, $DoChange) {
	(
		for $file in $Document//Files/File[not(@type='payment_bank')]
		return
			if (not(xmldb:get-child-resources($Collection) = concat($file/@fileName,$file/@fileExtension))) then
				error(xs:QName('docman:AttachementDoesNotExist'),'The attachement '|| $file/@fileName||$file/@fileExtension || ' of Document ' || $Document/@id/data() || ' does not exist.')
			else if ($file/@fileName = $NewFilename) then
				() 
			else if (xmldb:get-child-resources($Collection) = concat($NewFilename,$file/@fileExtension)) then
				error(xs:QName('docman:AttachementFilenameAlreadyExists'),'The attachement '|| concat($file/@fileName,$file/@fileExtension) || ' of Document ' || $Document/@id/data() || ' is already used.')
			else
				if ($DoChange) then
					<renamedAttachement fileName="{$file/@fileName}" src="{concat(substring-before($file/@src,$file/@fileName), $NewFilename, $file/@fileExtension)}">
						{$file/@*[not(name()=('fileName','src'))]}
						{xmldb:rename($Collection, $file/@fileName||$file/@fileExtension, concat($NewFilename,$file/@fileExtension))}
						{update value $file/@fileName with $NewFilename}
						{update value $file/@src with concat(substring-before($file/@src,$file/@fileName), $NewFilename, $file/@fileExtension)}
					</renamedAttachement>
				else
					()
	,
		if (concat($NewFilename,'.dm.xml') = xmldb:get-child-resources($Collection)) then
			if (doc(concat($Collection,'/',$NewFilename,'.dm.xml'))/Document/@id = $Document/@id) then
				update value $Document/@name with $NewFilename
			else
				error(xs:QName('docman:FileExists'),'Document ' || $Document/@id || ' can not stored too with name ' || concat($NewFilename,'.dm.xml '))
		else
			if ($DoChange) then
				<renamedDocument old="{$Document/@name}" new="{$NewFilename}">
				{
					xmldb:rename($Collection, $Document/@name||'.dm.xml', $NewFilename||'.dm.xml')
				}
				{
					update value $Document/@name with $NewFilename
				}
				</renamedDocument>
			else	
				()
	)
};

let $data-collection := "/db/apps/docman/data/bintellix"
let $accounts := doc(concat($data-collection,'/accounts.dm.xml'))/Accounts
return
<result>
{
	<collections>
	{
		for $Collection in (local:list-collections($data-collection), xs:anyURI($data-collection))
		return
		<collection name="{replace($Collection,'^(.*)/','')}" uri="{$Collection}">
		{
			<docs>
			{
				let $WebUri := substring-after($Collection, $data-collection)
				for $FileName in xmldb:get-child-resources($Collection)
				return 
					<doc name="{$FileName}" web="{$WebUri}">
					{
						if (ends-with($FileName,'.dm.xml')) then
							let $document := doc(concat($Collection,'/',$FileName))/Document
							return 
								if (not($document)) then
									<other id="{$document/@id}" name="{$document/@name}"/>
								else if ($document/@type = 'note') then
									<note id="{$document/@id}" name="{$document/@name}">
									{
										let $filename := concat($document/@date,'_Notiz')
										return
											local:checkFilename($Collection, $document, $filename, true())
									}
									</note>
								else if ($document/@type = 'invoice_in') then
									<invoice_in id="{$document/@id}" name="{$document/@name}">
									{
										let $OwnerKto := $document/Owner/@kto
										let $filename := concat($document/@date,'_Rechnung_(',
											$accounts/Account[@kto=$OwnerKto]/@id,
											')_(',
											replace(translate(substring($document/RefID,1,30),' ','_'),'[^A-Za-z0-9_\-\+]','-'),
											')_(',
											replace(translate(substring($document/TransactionID,1,30),' ','_'),'[^A-Za-z0-9_\-\+]','-'),
											')_',
											replace(translate(substring($document/Description,1,30),' ','_'),'[^A-Za-z0-9_\-\+]','-'))
										return
											local:checkFilename($Collection, $document, $filename, true())
									}
									</invoice_in>
								else if ($document/@type = 'invoice_in_storno') then
									<invoice_in_storno id="{$document/@id}" name="{$document/@name}">
									{
										let $OwnerKto := $document/Owner/@kto
										let $filename := concat($document/@date,'_Rechnung-STORNO_(',
											$accounts/Account[@kto=$OwnerKto]/@id,
											')_(',
											replace(translate(substring($document/RefID,1,30),' ','_'),'[^A-Za-z0-9_\-\+]','-'),
											')_(',
											replace(translate(substring($document/TransactionID,1,30),' ','_'),'[^A-Za-z0-9_\-\+]','-'),
											')_',
											replace(translate(substring($document/Description,1,30),' ','_'),'[^A-Za-z0-9_\-\+]','-'))
										return
											local:checkFilename($Collection, $document, $filename, true())
									}
									</invoice_in_storno>									
								else
									<error id="{$document/@id}" name="{$document/@name}">Unknown document type '{$document/@type/data()}' </error>
						else
							()
					}
					</doc>
			}
			</docs>
		}
		</collection>
	}
	</collections>
}
</result>

(: count(collection($data-collection)//Accountings/Accounting[position() le $pos]/ValueDate[text()=$item/ValueDate/text()]) :)
(: update replace $item/@id with banking:createAccountingID($item/../../BankAccountDetail/IBAN, $item, $dayCount) :)
(: banking:createAccountingID($accounting/../../BankAccountDetail/IBAN, $accounting, $dayCount) :)
(: <data>{$accounting/../../BankAccountDetail/IBAN}</data> :)
(: update insert attribute oid {$accounting/@id/data()} into $accounting :)
(: update value $item with replace($item, '/binders/2019/', '/2019/binders/') :)

