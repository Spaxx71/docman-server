xquery version "3.1";

(:
This script might be tested at:

https://docman.bintellix.com/exist-backend/rest/db/apps/docman/validate.xqy

/rest/db/apps/docman/validate.xqy
:)

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:indent "yes";


let $data-collection := "/db/apps/docman/data" || "/bintellix"
return
<result>
{
	for $item at $pos in collection($data-collection)//Process[Tasks/*/Files/File/@src='']
	return
		<Document pos="{$pos}" id="{$item/@id}" name="{$item/@name}">
			<Warning>Does still have File/@src=''</Warning>
			<!-- src="/{$tenant}/{$year}/binders/{$binder}/{$filename}{$fileext}" and no longer uploadSrc="..." -->
		</Document>
}
{
	for $item at $pos in collection($data-collection)//Document[Tasks/Task/Files/File/@uploadSrc='']
	return
		<Document pos="{$pos}" id="{$item/@id}" name="{$item/@name}">
			<Warning>Does still have File/@uploadSrc='...'</Warning>
			<!-- src="/{$tenant}/{$year}/binders/{$binder}/{$filename}{$fileext}" and no longer uploadSrc="..." -->
		</Document>
}
</result>


