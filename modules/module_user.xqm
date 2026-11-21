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
@Version: 1.1
========================================================================
:)

xquery version "3.1";

module namespace user = "http://bintellix.com/docman/user";

declare function user:currentUsername() as xs:string {
	string(sm:id()/sm:id/sm:real/sm:username)
};

declare function user:isDba() as xs:boolean {
	sm:id()/sm:id/sm:real/sm:groups/sm:group = 'dba'
};

(: sm:is-account-enabled is only allowed for a DBA or the account itself. :)
declare function user:accountEnabled($username as xs:string) as xs:boolean? {
	let $name := normalize-space($username)
	return
		if ($name = '' or not(user:isDba() or $name = user:currentUsername())) then
			()
		else
			try { sm:user-exists($name) and sm:is-account-enabled($name) } catch * { () }
};

declare function user:accessNode($dm-home-data as xs:string, $tenant as xs:string) as element(Access)? {
	doc($dm-home-data || '/' || $tenant || '/tenant.dm.xml')/Tenant/Access
};

(: Flat Access/Users or nested Access/Group/Users. :)
declare function user:accessUsers($access as element(Access)?) as element(User)* {
	if (empty($access)) then ()
	else if (exists($access/Group/Users/User)) then $access/Group/Users/User
	else $access/Users/User
};

declare function user:groupId($access as element(Access)?, $tenant as xs:string) as xs:string {
	let $configured := normalize-space(string($access/Group/@id))
	return if ($configured != '') then $configured else $tenant
};

declare function user:normalizeRights($raw as xs:string?) as xs:string {
	string-join(
		distinct-values(
			for $token in tokenize(upper-case(replace(normalize-space($raw), ',', ' ')), '\s+')
			where $token = ('SEE', 'ADD', 'CHANGE', 'DELETE')
			return $token
		),
		', '
	)
};

declare function user:hasRightFlag($rights as xs:string?, $flag as xs:string) as xs:boolean {
	upper-case($flag) = tokenize(upper-case(replace(normalize-space($rights), ',', ' ')), '\s+')
};

(: DBA always allowed; missing Permissions = full access (legacy). :)
declare function user:hasPermission(
	$dm-home-data as xs:string,
	$tenant as xs:string,
	$type as xs:string,
	$id as xs:string?,
	$need as xs:string
) as xs:boolean {
	if (user:isDba()) then
		true()
	else
		let $access := user:accessNode($dm-home-data, $tenant)
		let $username := user:currentUsername()
		let $node := user:accessUsers($access)[@id = $username]
		return
			if (empty($node)) then
				false()
			else if (empty($node/Permissions)) then
				true()
			else
				let $perm :=
					if (normalize-space($id) != '') then
						$node/Permissions/Permission[@type = $type and @id = $id]
					else
						$node/Permissions/Permission[@type = $type and (empty(@id) or normalize-space(@id) = '')]
				return
					exists($perm) and user:hasRightFlag(string($perm/@rights), $need)
};

declare function user:requirePermission(
	$dm-home-data as xs:string,
	$tenant as xs:string,
	$type as xs:string,
	$id as xs:string?,
	$need as xs:string
) as empty-sequence() {
	if (user:hasPermission($dm-home-data, $tenant, $type, $id, $need)) then ()
	else error(xs:QName('docman:Forbidden'), concat('Keine Berechtigung: ', $type, '/', $need))
};

declare function user:serializePermissions($permissions as element(Permissions)?) as element(Permissions)? {
	if (empty($permissions) or empty($permissions/Permission)) then ()
	else
		<Permissions>{
			for $p in $permissions/Permission
			let $rights := user:normalizeRights(string($p/@rights))
			let $id := normalize-space(string($p/@id))
			where $rights != ''
			return
				element Permission {
					attribute type { normalize-space(string($p/@type)) },
					attribute rights { $rights },
					if ($id != '') then attribute id { $id } else ()
				}
		}</Permissions>
};

declare function user:userElement($user-node as element(User)) as element(User) {
	<User id="{string($user-node/@id)}">
		{user:serializePermissions($user-node/Permissions)}
	</User>
};

declare function user:buildAccess($group-id as xs:string, $users as element(User)*) as element(Access) {
	<Access>
		<Group id="{$group-id}">
			<Users>{
				for $u in $users
				order by string($u/@id)
				return user:userElement($u)
			}</Users>
		</Group>
	</Access>
};

declare function user:syncGroupMembers($group-id as xs:string, $usernames as xs:string*) {
	if (not(sm:group-exists($group-id))) then sm:create-group($group-id, concat('Docman tenant ', $group-id)) else (),
	for $member in sm:get-group-members($group-id)
	where not($member = $usernames)
	return
		try { sm:remove-group-member($group-id, $member) } catch * { () },
	for $name in $usernames
	where sm:user-exists($name) and not(sm:get-group-members($group-id) = $name)
	return
		try { sm:add-group-member($group-id, $name) } catch * { () }
};

declare function user:storeAccess($dm-home-data as xs:string, $tenant as xs:string, $access as element(Access)) {
	let $path := $dm-home-data || '/' || $tenant
	let $stored := doc($path || '/tenant.dm.xml')/Tenant
	let $group-id := user:groupId($access, $tenant)
	let $users := user:accessUsers($access)
	(: Namen vor xmldb:store sichern — danach sind die alten Knoten ungültig. :)
	let $usernames := for $u in $users return string($u/@id)
	let $normalized := user:buildAccess($group-id, $users)
	let $next :=
		<Tenant id="{$tenant}">
			{$stored/@priority}
			{$stored/Name}
			{$stored/dateFormat}
			{$stored/currency}
			{$stored/currencies}
			{$stored/EmailAccount}
			{$normalized}
		</Tenant>
	let $store := xmldb:store($path, 'tenant.dm.xml', $next)
	let $sync := user:syncGroupMembers($group-id, $usernames)
	return $normalized
};

declare function user:listTenantUsers($dm-home-data as xs:string, $tenant as xs:string) as element(Users) {
	let $access := user:accessNode($dm-home-data, $tenant)
	let $group-id := user:groupId($access, $tenant)
	let $users := user:accessUsers($access)
	return
		<Users version="1.0" tenant="{$tenant}" group="{$group-id}">
		{
			for $u in $users
			let $enabled := user:accountEnabled(string($u/@id))
			order by string($u/@id)
			return
				<User id="{string($u/@id)}">
					{if (exists($enabled)) then attribute enabled { $enabled } else ()}
					<Name>{string($u/@id)}</Name>
					{user:serializePermissions($u/Permissions)}
				</User>
		}
		</Users>
};

declare function user:assignTenantUser(
	$dm-home-data as xs:string,
	$tenant as xs:string,
	$username as xs:string,
	$permissions as element(Permissions)?
) as element(Users) {
	let $_ := user:requirePermission($dm-home-data, $tenant, 'user-access', (), 'CHANGE')
	let $name := normalize-space($username)
	return
		if ($name = '' or not(sm:user-exists($name))) then
			error(xs:QName('docman:UserMissing'), concat('Benutzer fehlt: ', $name))
		else
			let $access := user:accessNode($dm-home-data, $tenant)
			let $group-id := user:groupId($access, $tenant)
			let $existing := user:accessUsers($access)
			let $others := $existing[not(@id = $name)]
			let $node :=
				<User id="{$name}">
					{user:serializePermissions(($permissions, $existing[@id = $name]/Permissions)[1])}
				</User>
			let $store := user:storeAccess($dm-home-data, $tenant, user:buildAccess($group-id, ($others, $node)))
			return user:listTenantUsers($dm-home-data, $tenant)
};

declare function user:updateTenantUserPermissions(
	$dm-home-data as xs:string,
	$tenant as xs:string,
	$username as xs:string,
	$permissions as element(Permissions)?
) as element(Users) {
	let $_ := user:requirePermission($dm-home-data, $tenant, 'user-access', (), 'CHANGE')
	let $name := normalize-space($username)
	let $access := user:accessNode($dm-home-data, $tenant)
	let $group-id := user:groupId($access, $tenant)
	let $existing := user:accessUsers($access)
	return
		if (empty($existing[@id = $name])) then
			error(xs:QName('docman:UserMissing'), concat('Benutzer nicht im Tenant: ', $name))
		else
			let $others := $existing[not(@id = $name)]
			let $node := <User id="{$name}">{user:serializePermissions($permissions)}</User>
			let $store := user:storeAccess($dm-home-data, $tenant, user:buildAccess($group-id, ($others, $node)))
			return user:listTenantUsers($dm-home-data, $tenant)
};

declare function user:removeTenantUser($dm-home-data as xs:string, $tenant as xs:string, $username as xs:string) as element(Users) {
	let $_ := user:requirePermission($dm-home-data, $tenant, 'user-access', (), 'CHANGE')
	let $name := normalize-space($username)
	let $access := user:accessNode($dm-home-data, $tenant)
	let $group-id := user:groupId($access, $tenant)
	let $remaining := user:accessUsers($access)[not(@id = $name)]
	let $store := user:storeAccess($dm-home-data, $tenant, user:buildAccess($group-id, $remaining))
	return user:listTenantUsers($dm-home-data, $tenant)
};

declare function user:listAdminUsers() as element(Users) {
	if (not(user:isDba())) then
		error(xs:QName('docman:Forbidden'), 'Nur Docman-Admin (dba).')
	else
		<Users version="1.0" scope="admin">
		{
			for $name in sm:list-users()
			order by $name
			return
				<User id="{$name}" enabled="{sm:is-account-enabled($name)}">
					<Name>{$name}</Name>
					<Groups>{
						try {
							for $g in sm:get-user-groups($name)
							return <Group id="{$g}"/>
						} catch * {
							for $g in sm:list-groups()
							where sm:get-group-members($g) = $name
							return <Group id="{$g}"/>
						}
					}</Groups>
				</User>
		}
		</Users>
};

declare function user:createAccount($username as xs:string, $password as xs:string, $primary-group as xs:string?) as element(User) {
	if (not(user:isDba())) then
		error(xs:QName('docman:Forbidden'), 'Nur Docman-Admin (dba).')
	else
		let $name := normalize-space($username)
		let $group := if (normalize-space($primary-group) != '') then normalize-space($primary-group) else 'docman'
		return
			if ($name = '' or string-length($password) < 1) then
				error(xs:QName('docman:UserInvalid'), 'Benutzername oder Passwort fehlt.')
			else if (sm:user-exists($name)) then
				error(xs:QName('docman:UserExists'), concat('Benutzer existiert: ', $name))
			else
				let $create :=
					(
						if (not(sm:group-exists($group))) then sm:create-group($group, 'Docman users') else (),
						sm:create-account($name, $password, $group, ())
					)
				return
					<User id="{$name}" enabled="true"/>
};

declare function user:setAccountEnabled($username as xs:string, $enabled as xs:boolean) as element(User) {
	if (not(user:isDba())) then
		error(xs:QName('docman:Forbidden'), 'Nur Docman-Admin (dba).')
	else
		let $name := normalize-space($username)
		return
			if (not(sm:user-exists($name))) then
				error(xs:QName('docman:UserMissing'), concat('Benutzer fehlt: ', $name))
			else
				let $set := sm:set-account-enabled($name, $enabled)
				return <User id="{$name}" enabled="{$enabled}"/>
};

declare function user:resetPassword($username as xs:string, $password as xs:string) as element(User) {
	if (not(user:isDba())) then
		error(xs:QName('docman:Forbidden'), 'Nur Docman-Admin (dba).')
	else
		let $name := normalize-space($username)
		return
			if (not(sm:user-exists($name)) or string-length($password) < 1) then
				error(xs:QName('docman:UserInvalid'), 'Benutzer oder Passwort ungültig.')
			else
				let $set := sm:passwd($name, $password)
				return <User id="{$name}"/>
};

declare function user:deleteAccount($username as xs:string) as element(deleted) {
	if (not(user:isDba())) then
		error(xs:QName('docman:Forbidden'), 'Nur Docman-Admin (dba).')
	else
		let $name := normalize-space($username)
		let $groups :=
			if (not(sm:user-exists($name))) then ()
			else
				try { sm:get-user-groups($name) }
				catch * {
					for $g in sm:list-groups()
					where sm:get-group-members($g) = $name
					return $g
				}
		let $tenant-groups := $groups[not(. = ('dba', 'docman', 'guest', 'nogroup'))]
		return
			if (not(sm:user-exists($name))) then
				error(xs:QName('docman:UserMissing'), concat('Benutzer fehlt: ', $name))
			else if (exists($tenant-groups)) then
				error(xs:QName('docman:UserInTenant'), concat('Benutzer noch in Gruppen: ', string-join($tenant-groups, ', ')))
			else
				let $remove := sm:remove-account($name)
				return <deleted id="{$name}"/>
};

declare function user:getUser($dm-home-data, $tenant) as node()? {
	let $username := user:currentUsername()
	return
	<User version="1.0" id="{$username}" isAuthenticated="{sm:is-authenticated()}" isEnabled="{sm:is-account-enabled($username)}" isDba="{user:isDba()}">
		<Groups>
		{
			for $group in sm:id()/sm:id/sm:real/sm:groups/sm:group
			return <Group id="{$group}"/>
		}
		</Groups>
		{
			let $access := user:accessNode($dm-home-data, $tenant)
			let $node := user:accessUsers($access)[@id = $username]
			return user:serializePermissions($node/Permissions)
		}
	</User>
};

declare function user:getUser($dm-home-data, $tenant, $username) as node()? {
	let $activities := doc($dm-home-data||'/activities.dm.xml')/Activities/Activity[@user=$username]
	let $start-date := current-date() - xs:yearMonthDuration("P3M")
	return
	<User version="1.0" id="{$username}">
		<Groups/>
		<Activities start="{$start-date}">
		{
			for $activity in $activities
			let $d := xs:date(substring($activity/@date,1,10))
			group by $d
			where $d > $start-date
			order by $d
			return
				<Day date="{$d}" count="{count($activity)}" first="{min($activity/@date/substring(.,12))}" last="{max($activity/@date/substring(.,12))}">
				{
					for $act in $activity
					return
						<Activity time="{substring($act/@date,12)}">
							{$act/@tenant}
							{$act/@year}
							{$act/@resource-type}
							{$act/@resource-id}
							{$act/@function}
							{$act/@param}
							{$act/@path}
						</Activity>
				}
				</Day>
		}
		</Activities>
	</User>
};

declare function user:listUsers($dm-home-data, $tenant) as node()? {
	user:listTenantUsers($dm-home-data, $tenant)
};

declare function user:setPassword($dm-home-data, $tenant, $username, $password) as node()? {
	user:resetPassword($username, $password)
};

declare function user:createUser($dm-home-data, $tenant, $username, $password) as node()? {
	user:createAccount($username, $password, $tenant)
};
