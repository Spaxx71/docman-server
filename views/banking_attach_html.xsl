<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:xf="http://www.w3.org/2002/xforms" version="3.1">
	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="home-data" required="yes"/>
	<xsl:param name="home-views"/>
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="year" required="yes"/>
	<xsl:param name="resource-id"/>
	<xsl:param name="path"/>

	<xsl:template match="/">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="result">
		<html>
			<head>
				<xf:model schema="">
					<xf:instance xmlns="" id="documents">
						<data>
							<xsl:copy-of select="BankAccountActivity"/>
						</data>
					</xf:instance>

					<xf:instance xmlns="" id="temp">
						<data>
							<binder>xx</binder>
							<document-id/>
						</data>
					</xf:instance>

					<xf:instance xmlns="" id="task">
						<data>
							<xxx/>
						</data>
					</xf:instance>

					<xf:submission id="save" method="post" ref="instance('task')" replace="none" validate="true">						<!-- indent="true" replace="all / none" -->						<!-- /{$year}/{$binder}/{$document} -->
						<xf:resource value="concat('{$home-web-api}/{$tenant}/',{$year},'/binders/',instance('temp')/binder,'/',instance('temp')/document-id)"/>

						<xf:action ev:event="xforms-submit-done">
							<xf:message>Dokument wurde erfolgreich gespeichert.
								<xf:output value="event('resource-uri')">
									<xf:label>Resource URI: </xf:label>
								</xf:output>
								<xsl:text>
								</xsl:text>
								<xf:output value="event('response-body')">
									<xf:label>Body: </xf:label>
								</xf:output>
							</xf:message>
						</xf:action>

						<xf:action ev:event="xforms-submit-error" if="event('error-type')='validation-error'">
							<xf:message>Validierungsfehler: Es sind noch nicht alle notwendigen Felder mit zulässigen Werten gefüllt.</xf:message>
						</xf:action>

						<xf:action ev:event="xforms-submit-error" if="not(event('error-type')='validation-error')">

							<xf:message>Es ist ein Fehler aufgetreten: 
								<xsl:text>
								</xsl:text>
								<xf:output value="event('error-type')">
									<xf:label>Error type: </xf:label>
								</xf:output>
								<xsl:text>
								</xsl:text>
								<xf:output value="event('resource-uri')">
									<xf:label>
Resource URI: </xf:label>
								</xf:output>
								<xsl:text>
								</xsl:text>
								<xf:output value="event('response-status-code')">
									<xf:label>
Status Code: </xf:label>
								</xf:output>
								<xsl:text>
								</xsl:text>
								<xf:output value="event('response-reason-phrase')">
									<xf:label>
Reason: </xf:label>
								</xf:output>
								<xsl:text>
								</xsl:text>
								<xf:output value="event('response-headers')">
									<xf:label>
Headers: </xf:label>
								</xf:output>
								<xsl:text>
								</xsl:text>
								<xf:output value="event('response-body')">
									<xf:label>
Body: </xf:label>
								</xf:output>
							</xf:message>
						</xf:action>
					</xf:submission>
				</xf:model>
				<style><![CDATA[
					.blue { background-color: #39F;}
					]]>
				</style>
			</head>
			<body>

				<xsl:if test="not(BankAccountActivity//Document)">
					<h3>Bankkonto-Beleg-Ableich</h3>
					<div>Es wurden <xsl:value-of select="count(BankAccountActivity)"/> Bankbewegungen getestet.</div>
					<div>Hierzu wurden <xsl:value-of select="count(BankAccountActivity/Groups/Group)"/> Gruppen getestet.</div>
					<div>Doch es gibt keine Auto-Match Elemente mehr.</div>
				</xsl:if>

				<!-- only when a single object is taken -->
				<xf:repeat id="BankAccountActivity" ref="instance('documents')/BankAccountActivity[Groups/Group/Document]">

					<xf:output ref="Groups/Group/@mapping">
						<xf:label>Mapping Regeln:</xf:label>
					</xf:output>
					<table>
						<thead>
							<tr>
								<th rowspan="2" class="blue">Bank #</th>
								<th>Aktivität</th>
								<th>Betrag</th>
								<th>Datum</th>
								<th>CustomerID</th>
								<th>End to end Ref</th>
								<th>Verwendungszweck</th>
								<th>Begünstigter</th>
								<th>Dokument</th>
							</tr>
						</thead>
						<tbody>
							<tr>
								<td class="blue">
									<a href="{$home-web-gui}/{$tenant}/{$year}/banking/{$resource-id}/{{@id}}/details.html"><xf:output value="position()"/></a>
								</td>
								<td class="blue"/>
								<td class="blue">
									<xf:output ref="@amount"/>
								</td>
								<td class="blue">
									<xf:output ref="@date"/>
								</td>
								<td class="blue">
									<xf:output ref="@customer"/>
								</td>
								<td class="blue">
									<xf:output ref="@endtoend"/>
								</td>
								<td class="blue">
									<xf:output ref="@usage"/>
									<xf:output ref="@paymentDetail"/>
								</td>
								<td class="blue">
									<a href="{$home-web-gui}/{$tenant}/{$year}/banking/{$resource-id}/{{@id}}/details.html"><xf:output ref="@id"/></a>
								</td>
								<td class="blue">
									<xf:output ref="@iban"/><br/>
									<xf:output ref="@creditor"/>
								</td>								
							</tr>
						</tbody>
						<thead>
							<tr>
								<th rowspan="3">Dokument #</th>
								<th>Aktivität</th>
								<th>Betrag</th>
								<th>Datum</th>
								<th>Beleg ID (Rechnungsnr.)</th>
								<th>Vorgang ID (Bestellnr.)</th>
								<th>Beschreibung</th>
								<th>Dokument Owner</th>								
								<th>Dokument</th> 
							</tr>
						</thead>
						<tbody>
							<xf:repeat ref="Groups/Group/Document" id="DocumentList">
								<tr>
									<td>
										<a href="/app/{$tenant}/{$year}/binders/{{@id}}/search.html"><xf:output value="position()"/></a>
									</td>
									<td>
										<!-- <xf:submit id="Save" submission="save">
										</xf:submit> -->
										<xf:trigger>
											<xf:label>Verknüpfen</xf:label>
											<xf:action ev:event="DOMActivate">
												<xf:delete ref="instance('task')/*"/>
												<xf:insert origin="Task" nodeset="instance('task')"/>
												<xf:setvalue ref="instance('temp')/binder" value="current()/@binder"/>
												<xf:setvalue ref="instance('temp')/document-id" value="current()/@id"/>
												<xf:send submission="save"/>
											</xf:action>
										</xf:trigger>
										<br/>
										<a href="/app/{$tenant}/{$year}/banking/{$resource-id}/{{../../../@id}}/assign-document.html?owner={{@owner-kto}}">alle Belege anzeigen</a>
									</td>
									<td class="{{if(number(../../../@amount) = number(@amount),'done','')}}">
										<xf:output ref="@amount"/>
									</td>

									<td class="{{if(../../../@date = Task/Accountings/Accounting/@date,'done','part')}}">
										<xf:output ref="Task/Accountings/Accounting/@date"/>
									</td>

									<td class="{{if((contains(../../../@customer, @ref) or contains(../../../@paymentDetail, @ref)) and string-length(@ref) &gt; 5,'done','')}}">
										<xf:output ref="@ref"/>
									</td>
									<td class="{{if((contains(../../../@customer, @trans) or contains(../../../@paymentDetail, @trans)) and string-length(@trans) &gt; 5,'done','')}}">
										<xf:output ref="@trans"/>
									</td>
									<td class="{{if((contains(../../../@customer, @desc) or contains(../../../@paymentDetail, @desc)) and string-length(@desc) &gt; 5,'done','')}}">
										<xf:output ref="@desc"/>
									</td>						
									<td class="">
										<xf:output ref="@owner"/>
										<br/>
										<xsl:text>(</xsl:text>
										<xf:output ref="@kto"/>
										<xsl:text>)</xsl:text>
									</td>									
									<td>
										<a href="/app/{$tenant}/{$year}/binders/{{@id}}/search.html"><xf:output value="concat(substring(@name,1,50),'...')"/></a>
									</td>
								</tr>
							</xf:repeat>
						</tbody>
					</table>
					<br/>
					<br/>
				</xf:repeat>

				<xf:repeat ref="instance('documents')/BankAccountActivity[count(*)!=1]/Document" id="DocumentErrorList">
					<div>Mehr als ein Treffer für payment <a href="/app/{$tenant}/{$year}/banking/{$resource-id}/{{../@id}}/assign-document.html?owner={{@owner-kto}}"><xf:output ref="../@id"/></a>
					 </div>
				</xf:repeat>
			</body>	
		</html>
	</xsl:template>

	<xsl:template match="Document">
		<div>Dokument</div>
	</xsl:template>
</xsl:stylesheet>