xquery version "3.0";

(:
https://dev.bintellix.com/exist-backend/rest/db/apps/docman/modules/functions/attach/attach_payment.xqy

/app/bintelix/2019/binders/PRO1f97e590-64fd-479c-97e5-9064fd279c88/attach/payment.xml?ref=PAY0f6a8823-38e3-4994-aa88-2338e35994dd
:)

import module namespace account="http://bintellix.com/docman/account" at "/db/apps/docman/modules/module_account.xqm";
import module namespace banking="http://bintellix.com/docman/banking" at "/db/apps/docman/modules/module_banking.xqm";
import module namespace document="http://bintellix.com/docman/document" at "/db/apps/docman/modules/module_document.xqm";


let $home-web-gui := request:get-attribute('home-web-gui') 
let $home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $year := request:get-attribute('year')
let $binder := request:get-attribute('binder')
let $resource-id := request:get-attribute('resource-id')
let $username := request:get-attribute('username')

let $ref := request:get-parameter('ref','')


(: https://docman.bintellix.com/app/TENANT/2019/binders/PRO1f97e590-64fd-479c-97e5-9064fd279c88/attach/payment.xml?ref=PAY2012ba87-8af0-47fb-92ba-878af097fbf7 :)
(: /app/TENANT/2019/banking/222971400/PAY2012ba87-8af0-47fb-92ba-878af097fbf7/details.pdf :)
let $process := document:getDocument($home-data, $tenant, $year, (), $resource-id)
let $bank := banking:getAccountingById($home-data, $tenant, (), $year, $ref)
let $account :=  account:getAccount($home-data, $tenant, $year, $bank/@kto)
let $isStorno := $process/Tasks/*[1]/@isStorno='true'
let $owner := $process/Tasks/*[1]/Owner
let $amount := if ($process/TotalAmount/@value > 0) then
			min(($process/TotalAmount/@value, $bank/Accounting/Amount))
		else
			max(($process/TotalAmount/@value, $bank/Accounting/Amount))

let $task := <PaymentTask type="payment-bank" id="ACC{util:uuid()}" date="{$bank/Accounting/ValueDate}" created="{current-dateTime()}" isMaster="false" user="{$username}" isStorno="{$isStorno}">
        <Notes/>
		<Files>
			<File src="{concat('/',$tenant,'/',$year,'/banking/',$bank/@kto,'/',$ref,'/details.pdf')}" fileName="{substring(string(current-date()),1,10)}_PaymentBank_{$ref}" fileExtension=".pdf" uploadName="{substring(string(current-date()),1,10)}_PaymentBank_{$ref}" mimeType="application/pdf" type="doc-payment-bank" doctype="digital" archived="true"/>
		</Files>
		<Bookings>
		{
			if (exists($process/Tasks/BankBalancingTask)) then
				(
				if ($account/@kto = $process/Tasks/BankBalancingTask/Owner) then 
					<Booking date="{$bank/Accounting/ValueDate}" quality="3" amountValue="{if ($amount < 0) then $amount * -1.0 else $amount}" amountUnit="{$bank/Accounting/CurrencyUnit}" credit="1460" debit="{$account/@kto}" taxKey="1" taxAmount="0" refID="{$ref}" description="{concat($bank/Accounting/SalesType,' IBAN+',$bank/Accounting/IBAN,' SVWZ+',$bank/Accounting/PaymentDetails)}"/>
				else if ($account/@kto = $process/Tasks/BankBalancingTask/Other) then
					<Booking date="{$bank/Accounting/ValueDate}" quality="3" amountValue="{if ($amount < 0) then $amount * -1.0 else $amount}" amountUnit="{$bank/Accounting/CurrencyUnit}" credit="{$account/@kto}" debit="1460" taxKey="1" taxAmount="0" refID="{$ref}" description="{concat($bank/Accounting/SalesType,' IBAN+',$bank/Accounting/IBAN,' SVWZ+',$bank/Accounting/PaymentDetails)}"/>
				else
					()
				,
				if ($bank/Accounting/ExternalCosts != '' and $bank/Accounting/ExternalCosts != 0) then
					<Booking date="{$bank/Accounting/ValueDate}" quality="3" amountValue="{translate($bank/Accounting/ExternalCosts,',','.')}" amountUnit="EUR" credit="{$account/@kto}" debit="6855" taxKey="1" taxAmount="0" refID="{$ref}" description="External Costs"/>
				else
					()
				)
			else if ($isStorno) then
				(: EmployeeSalaryTask/@credit needs to be set to 3790 :)
				<Booking date="{$bank/Accounting/ValueDate}" quality="3" amountValue="{$amount}" amountUnit="{$bank/Accounting/CurrencyUnit}" credit="{$account/@kto}" debit="{$owner}" taxKey="1" taxAmount="0" refID="{$ref}" description="{concat($bank/Accounting/SalesType,' IBAN+',$bank/Accounting/IBAN,' SVWZ+',$bank/Accounting/PaymentDetails)}"/>
			else
				(: EmployeeSalaryTask/@credit needs to be set to 3790 :)
				<Booking date="{$bank/Accounting/ValueDate}" quality="3" amountValue="{$amount * -1.0}" amountUnit="{$bank/Accounting/CurrencyUnit}" credit="{$owner}" debit="{$account/@kto}" taxKey="1" taxAmount="0" refID="{$ref}" description="{concat($bank/Accounting/SalesType,' IBAN+',$bank/Accounting/IBAN,' SVWZ+',$bank/Accounting/PaymentDetails)}"/>
		}
		</Bookings>
		<Amount value="{$amount}" unit="{$bank/Accounting/CurrencyUnit}"/>
		<RefID>{$ref}</RefID>
		<Description>{concat($bank/Accounting/SalesType,' IBAN+',$bank/Accounting/IBAN,' SVWZ+',$bank/Accounting/PaymentDetails)}</Description>
		<Trigger/>
	</PaymentTask>

return
	if (not(exists($task/Bookings/Booking))) then
		<result resource-id="{$resource-id}" payment="{$ref}">
			<error>No valid booking could be created.</error>
		</result>
	else if (exists($process/Tasks/BankBalancingTask)) then 
		<result resource-id="{$resource-id}" payment="{$ref}">
			{$task}
		</result>
	else if (not($bank)) then
		<result resource-id="{$resource-id}" payment="{$ref}">
			<error>No payment with id='{$ref}' found.</error>
		</result>
	else if (not($task/Bookings/Booking[@credit != @debit])) then
		<result resource-id="{$resource-id}" payment="{$ref}">
			<error>No payment allowed for the sender (@credid={$task/Bookings/Booking/@credit/data()} @debit={$task/Bookings/Booking/@debit/data()}).</error>
		</result>
	else
		(: let $result := document:insertTask($home-data, $tenant, $year, (), $activity, $task) :)
		<result resource-id="{$resource-id}" payment="{$ref}">
			{$task}
		</result>