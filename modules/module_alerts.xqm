(:
Meldungen eines Jahres: alerts.dm.xml
:)

xquery version "3.1";

module namespace alerts = "http://bintellix.com/docman/alerts";

declare function alerts:collection($home as xs:string, $tenant as xs:string, $year as xs:integer) as xs:string {
	$home || '/' || $tenant || '/' || $year
};

declare function alerts:list($home as xs:string, $tenant as xs:string, $year as xs:integer) as element(Alerts) {
	let $path := alerts:collection($home, $tenant, $year) || '/alerts.dm.xml'
	return
		if (doc-available($path)) then
			let $stored := doc($path)/Alerts
			return
				if (exists($stored)) then $stored
				else <Alerts version="1.0"/>
		else
			<Alerts version="1.0"/>
};

declare function alerts:invalid($alerts as element(Alerts)) as xs:boolean {
	(
		some $child in $alerts/*
		satisfies not($child/local-name() = ('Alert', 'Dismissed'))
	)
	or (
		some $alert in $alerts/Alert
		satisfies (
			normalize-space($alert/@id) = ''
			or not($alert/@kind = ('anomalie', 'notiz', 'termin', 'hinweis'))
			or not($alert/@source = ('system', 'user', ''))
			or normalize-space(string($alert)) = ''
		)
	)
	or (
		some $dismissed in $alerts/Dismissed
		satisfies normalize-space($dismissed/@id) = ''
	)
};

declare function alerts:store($home as xs:string, $tenant as xs:string, $year as xs:integer, $body) as element(Alerts) {
	let $alerts :=
		if ($body instance of element(Alerts)) then $body
		else $body/Alerts
	return
		if (empty($alerts)) then
			error(xs:QName('alerts:root'), 'Die Meldungen müssen ein Alerts-Element sein.')
		else if (alerts:invalid($alerts)) then
			error(xs:QName('alerts:invalid'), 'Eine Meldung ist unvollständig oder hat eine unbekannte Art.')
		else
			let $collection := alerts:collection($home, $tenant, $year)
			let $_ := xmldb:store($collection, 'alerts.dm.xml', $alerts)
			return alerts:list($home, $tenant, $year)
};
