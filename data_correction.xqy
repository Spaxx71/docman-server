xquery version "3.1";

(:
This script might be tested at:

/rest/db/apps/docman/data_correction.xqy

https://docman.bintellix.com/exist-backend/rest/db/apps/docman/data_correction.xqy
:)

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace docman = "http://docman.bintellix.com";

declare option output:indent "yes";

let $data-collection := "/db/apps/docman/data/intersecurity/2023"

return
<results>
{
	for $process in collection($data-collection)/Process
	where $process/Tasks/CommodityTask/Bookings/Booking/@credit/data() = $process/Tasks/CommodityTask/Bookings/Booking/@debit/data()
	return 
		<results>
			<record>updating '{string($process/@name)}' account #{string($process/Tasks/CommodityTask/Bookings/Booking/@debit)} &#160;with&#160; #{string($process/Tasks/InvoiceInTask/Owner/data())}</record>
			<update>{update value $process/Tasks/CommodityTask/Bookings/Booking/@debit with $process/Tasks/InvoiceInTask/Owner/data()}</update>
		</results>
}
</results>
