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

module namespace user = "http://bintellix.com/docman/user";


declare namespace acl = "http://atomic.exist-db.org/xquery/atomic/acl";


declare function user:listUsers($dm-home-data, $tenant) as node()? {
 	let $tenant-collection := $dm-home-data ||'/'|| $tenant
	let $tenant-group := sm:get-permissions($tenant-collection)//@group/data()
	return
	(: sm:get-account-metadata($user, xs:anyURI('http://axschema.org/namePerson')) :)
	(: sm:get-account-metadata($user, xs:anyURI('http://exist-db.org/security/description')) :)
	<Users version="1.0" group="{$tenant-group}">
	{
		for $user in sm:get-group-members($tenant-group)
		return
		<User id="{$user}">
			<Name>{$user}</Name>
		</User>
	}

<!-- 
<sm:permission xmlns:sm="http://exist-db.org/xquery/securitymanager" 
  owner="SYSTEM" group="dba" mode="rwxrwx- - -" >
  <sm:acl entries="0"/>
</sm:permission>
-->
	</Users>
};


declare function user:getUser($dm-home-data, $tenant, $username) as node()? {
 	let $tenant-collection := $dm-home-data||'/'||$tenant
	return
	<User version="1.0" id="{sm:id()/sm:id/sm:real/sm:username}" isAuthenticated="{sm:is-authenticated()}" isEnabled="{sm:is-account-enabled($username)}">
		<Groups>
		{
			for $group in sm:id()/sm:id/sm:real/sm:groups/sm:group
			return
			<Group id="{$group}"/>
		}
		</Groups>
	</User>
};


declare function user:setPassword($dm-home-data, $tenant, $username, $password) as node()? {
 	let $setPassword := sm:passwd($username, $password)
	return
	<User version="1.0" id="{sm:id()/sm:id/sm:real/sm:username}">

	</User>
};


declare function user:createUser($dm-home-data, $tenant, $username, $password) as node()? {
 	let $newUser := ""
	let $updateRights := sm:chmod(xs:anyURI(concat('/db/system/security/exist/accounts/',$username,'.xml')),'rwxrw---')
	return
	<User version="1.0" id="{sm:id()/sm:id/sm:real/sm:username}">

	</User>
};


(: sm:remove-account :)
(: sm:chgrp($path as xs:anyURI, $group-name as xs:string) :)
(: sm:create-group($group-name as xs:string, $description as xs:string) as item() :)
(: sm:create-account($username as xs:string, $password as xs:string, $primary-group 
as xs:string, $groups as xs:string*) as empty-sequence() :)
(: sm:set-account-enabled :)