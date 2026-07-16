xquery version "3.1";

(:

This script fixes a common created problem where the @credit account equals the debit account

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
	return 
		for $booking at $pos in $process/Tasks/CommodityTask/Bookings/Booking
		where $booking/@credit/data() = $booking/@debit/data()
		return
			<results>
				<record>updating '{string($process/@name)}' booking #{$pos} account #{string($booking/@debit)} &#160;with&#160; #{string($process/Tasks/InvoiceInTask/Owner/data())}</record>
				<update>{update value $booking/@debit with $process/Tasks/InvoiceInTask/Owner/data()}</update>
			</results>
}
</results>
