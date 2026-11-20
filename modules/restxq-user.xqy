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
:)

xquery version "3.1";

module namespace dmuser="http://exist-db.org/apps/restxq/docman-user";

import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace user="http://bintellix.com/docman/user" at "/db/apps/docman/modules/module_user.xqm";

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http="http://expath.org/ns/http-client";

declare function local:error-response($code as xs:string, $description as xs:string) {
	(
		<rest:response>
			<http:response status="{if ($code = 'docman:Forbidden') then '403' else '400'}" message="{$description}"/>
		</rest:response>
		,
		<error code="{$code}">{$description}</error>
	)
};

declare
	%rest:GET
	%rest:path("/docman/xml/tenants/{$tenant}/users")
	%rest:query-param("user", "{$user}", "Guest")
	%output:media-type("text/xml")
	%output:method("xml")
function dmuser:listTenantUsers($user as xs:string*, $tenant as xs:string) {
	try {
		user:listTenantUsers($main:home-data, $tenant)
	}
	catch * {
		local:error-response(string($err:code), string($err:description))
	}
};

declare
	%rest:GET
	%rest:path("/docman/xml/tenants/{$tenant}/users/me")
	%rest:query-param("user", "{$user}", "Guest")
	%output:media-type("text/xml")
	%output:method("xml")
function dmuser:currentTenantUser($user as xs:string*, $tenant as xs:string) {
	try {
		user:getUser($main:home-data, $tenant)
	}
	catch * {
		local:error-response(string($err:code), string($err:description))
	}
};

declare
	%rest:POST("{$body}")
	%rest:path("/docman/xml/tenants/{$tenant}/users")
	%rest:query-param("user", "{$user}", "Guest")
	%rest:consumes("application/xml", "text/xml")
	%output:media-type("text/xml")
	%output:method("xml")
function dmuser:assignTenantUser($user as xs:string*, $tenant as xs:string, $body) {
	try {
		let $node := if ($body/self::User) then $body else $body/User
		return user:assignTenantUser($main:home-data, $tenant, string($node/@id), $node/Permissions)
	}
	catch * {
		local:error-response(string($err:code), string($err:description))
	}
};

declare
	%rest:PUT("{$body}")
	%rest:path("/docman/xml/tenants/{$tenant}/users/{$username}")
	%rest:query-param("user", "{$user}", "Guest")
	%rest:consumes("application/xml", "text/xml")
	%output:media-type("text/xml")
	%output:method("xml")
function dmuser:updateTenantUser($user as xs:string*, $tenant as xs:string, $username as xs:string, $body) {
	try {
		let $node := if ($body/self::User) then $body else $body/User
		let $perms := if (exists($node/Permissions)) then $node/Permissions else $body/Permissions
		return user:updateTenantUserPermissions($main:home-data, $tenant, $username, $perms)
	}
	catch * {
		local:error-response(string($err:code), string($err:description))
	}
};

declare
	%rest:DELETE
	%rest:path("/docman/xml/tenants/{$tenant}/users/{$username}")
	%rest:query-param("user", "{$user}", "Guest")
	%output:media-type("text/xml")
	%output:method("xml")
function dmuser:removeTenantUser($user as xs:string*, $tenant as xs:string, $username as xs:string) {
	try {
		user:removeTenantUser($main:home-data, $tenant, $username)
	}
	catch * {
		local:error-response(string($err:code), string($err:description))
	}
};

declare
	%rest:GET
	%rest:path("/docman/xml/admin/users")
	%rest:query-param("user", "{$user}", "Guest")
	%output:media-type("text/xml")
	%output:method("xml")
function dmuser:listAdminUsers($user as xs:string*) {
	try {
		user:listAdminUsers()
	}
	catch * {
		local:error-response(string($err:code), string($err:description))
	}
};

declare
	%rest:POST("{$body}")
	%rest:path("/docman/xml/admin/users")
	%rest:query-param("user", "{$user}", "Guest")
	%rest:consumes("application/xml", "text/xml")
	%output:media-type("text/xml")
	%output:method("xml")
function dmuser:createAdminUser($user as xs:string*, $body) {
	try {
		let $node := if ($body/self::User) then $body else $body/User
		return user:createAccount(string($node/@id), string($node/Password), string($node/@group))
	}
	catch * {
		local:error-response(string($err:code), string($err:description))
	}
};

declare
	%rest:PUT("{$body}")
	%rest:path("/docman/xml/admin/users/{$username}")
	%rest:query-param("user", "{$user}", "Guest")
	%rest:consumes("application/xml", "text/xml")
	%output:media-type("text/xml")
	%output:method("xml")
function dmuser:updateAdminUser($user as xs:string*, $username as xs:string, $body) {
	try {
		let $node := if ($body/self::User) then $body else $body/User
		let $enabled := lower-case(normalize-space(string(($node/@enabled, $body/@enabled)[1])))
		let $password := normalize-space(string(($node/Password, $body/Password)[1]))
		return
			(
				if ($enabled = ('true', 'false')) then
					user:setAccountEnabled($username, $enabled = 'true')
				else (),
				if ($password != '') then
					user:resetPassword($username, $password)
				else (),
				user:listAdminUsers()/User[@id = $username]
			)[last()]
	}
	catch * {
		local:error-response(string($err:code), string($err:description))
	}
};

declare
	%rest:DELETE
	%rest:path("/docman/xml/admin/users/{$username}")
	%rest:query-param("user", "{$user}", "Guest")
	%output:media-type("text/xml")
	%output:method("xml")
function dmuser:deleteAdminUser($user as xs:string*, $username as xs:string) {
	try {
		user:deleteAccount($username)
	}
	catch * {
		local:error-response(string($err:code), string($err:description))
	}
};
