xquery version "3.1";

(:
This script might be tested at:

https://docman.bintellix.com/exist-backend/rest/db/apps/docman/modules/tools/validate-schema.xqy

/rest/db/apps/docman/modules/tools/validate-schema.xqy
:)

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace banking="http://bintellix.com/docman/banking" at "/db/apps/docman/modules/module_banking.xqm";

(: import module namespace packages = "http://exist-db.org/apps/existdb-packages" at "/db/apps/packageservice/modules/packages.xqm"; :)
import module namespace functx = "http://www.functx.com";
import module namespace apputil = "http://exist-db.org/xquery/apps";

declare namespace docman = "http://docman.bintellix.com";

declare option output:indent "yes";

let $tenant := request:get-attribute('tenant')
let $year := request:get-attribute('year')

let $home-data := '/db/apps/docman/data'
let $collection := $home-data||'/'||$tenant||'/'||$year
let $Accountings := doc(concat($home-data,'/',$tenant,'/accounts.dm.xml'))/Accounts/Account[PeriodicPayments/PeriodicPayment]
let $PaymentList := collection($collection)/Document/RefID
(: let $BankMovements := banking:listAccountings($home-data, $tenant, $bank-account-id, $year) :)

let $document-schema := doc('/db/apps/docman/resources/Process.xsd')
let $bank-schema := doc('/db/apps/docman/resources/Bank.xsd')
let $accounts-schema := doc('/db/apps/docman/resources/Accounts.xsd')
let $budget-categories-schema := doc('/db/apps/docman/resources/BudgetCategories.xsd')
return
<result>
	<ValidateSchema>
		<Collections>
			<Collection tenant="{$tenant}" year="{$year}" collection="{$collection}">
			{
				let $Accounts := doc(concat($collection,'/accounts.dm.xml'))/Accounts
				let $AccountListValidation := for $account in $Accounts/Account
					return
						<Account id="{$account/@id}" kto="{$account/@kto}">
						{
							validation:jaxv-report($account, $accounts-schema)
						}
						</Account>
				return
					
					<Accounts filename="accounts.dm.xml" count="{count($Accounts/Account)}"> <!-- generic validation of overall checks like key or unique -->
					{
						if ($AccountListValidation//report/status = "invalid") then
							$AccountListValidation
						else
							(: validation rules like unique or key :)
							validation:jaxv-report($Accounts, $accounts-schema)
					}				
					</Accounts>
			}
			{
				let $BudgetCategories := doc(concat($collection,'/budget-categories.dm.xml'))
				return
					<BudgetCategories count="{count($BudgetCategories/BudgetCategories/BudgetCategory)}">
					{
						validation:jaxv-report($BudgetCategories, $budget-categories-schema)
					}
					</BudgetCategories>
			}
			{
				let $BankAccounts := for $file in xmldb:get-child-resources($collection) 
					where matches($file, "bank\-account_[0-9A-Za-z]+\.dm\.xml")
					return
						substring(substring($file,1,string-length($file) - string-length(".dm.xml")),string-length("bank-account_") +1)
				return					
					<BankAccounts count="{count($BankAccounts)}"> <!-- generic validation of overall checks like key or unique -->
					{
						for $bank-account-id in $BankAccounts
						let $filename := 'bank-account_' || $bank-account-id || '.dm.xml'
						return
							<BankAccount bank-account-id="{$bank-account-id}" filename="{$filename}">
							{
								let $bank-account := doc($collection || "/" || $filename)/BankAccount						
								return
									validation:jaxv-report($bank-account, $bank-schema)
							}
							</BankAccount>
					}
					</BankAccounts>					
			}
			{
				<Processes>
				{
					let $Processes := xmldb:get-child-collections($collection)
					return
						<Binders count="{count($Processes)}">
						{
							for $binder-name in $Processes
							return
								<Binder name="{$binder-name}">
								{
									for $file in xmldb:get-child-resources($collection || "/" || $binder-name) 
									where matches($file, ".*\.dm\.xml")
									let $document := doc($collection || "/" || $binder-name || "/" || $file)/Process
									return
										<Process id="{$document/@id}" name="{$document/@name}" filename="{$file}">
										{
											validation:jaxv-report($document, $document-schema)
										}
										</Process>
								}
								</Binder>
						}
						</Binders>	
				}
				</Processes>
			}
			</Collection>
		</Collections>
	</ValidateSchema>
</result>