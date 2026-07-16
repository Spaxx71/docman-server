<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="home-views"/> 
	<xsl:param name="home-data"/>                
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="year" required="yes"/>

	<xsl:variable name="accountings" select="result/Accountings"/>


	<xsl:template match="/">
		<xhtml:html xmlns="http://www.w3.org/1999/xhtml" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:xhtml="http://www.w3.org/1999/xhtml">
			<head>
				<title>Butget-Kategorie Bearbeiten</title>
				<xf:model schema="" id="M">
					<xf:instance xmlns="" id="budget-categories">
						<xsl:copy-of select="result/BudgetCategories"/>
					</xf:instance>

					<!--
					<xf:instance xmlns="" id="budget-categories" src="{concat($home-web-api,'/tenants/',$tenant,'/years/',$year,'/budget-categories')}">
					</xf:instance>
					-->

					<xf:instance xmlns="" id="budget-category-new">
						<data>
							<ProcessTemplate>
								<Section/>
								<Other kto=""/>
								<RefID/>
								<TransactionID/>
								<Description/>
								<Tax key="" region="" type=""/>
								<TotalAmount value="" unit=""/>
								<Appointment date=""/>
								<Notes/>
							</ProcessTemplate>
						</data>
					</xf:instance>
					<xf:bind nodeset="instance('budget-categories')/BudgetCategory/@id" constraint="string-length(.) &gt;= 3" type="xs:string" required="true()"/>
					<xf:bind nodeset="instance('budget-categories')/BudgetCategory/@name" constraint="string-length(.) &gt;= 3" type="xs:string" required="true()"/>


					<xf:submission id="save" method="put" instance="budget-categories" replace="none" validate="true"> <!-- indent="true"  replace="all" --> <!-- /{$year}/{$binder}/{$document} -->
						<xf:resource value="concat('{$home-web-api}/tenants/{$tenant}/years/',{$year},'/categories')"/>
								<xf:action ev:event="xforms-submit-done">
							<xf:message>Erfolgreich gespeichert.
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
						<xf:action ev:event="xforms-submit-error">
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
				
				<style>
	<![CDATA[
					.xforms-label {
						width: inherit !important;
					}
	]]>
				</style>
			</head>
			<body>
				<div style="border:1px solid #999">
					<table>
						<tbody>
							<tr>
								<th>Domäne / Gruppe</th>
								<td>
									<xf:dialog id="error-dialog">
										<xf:output value="'Die Steuerart wird für für diese Periode noch nicht unterstützt.'"/>
										<br/>
										<xf:trigger>
											<xf:label>Close</xf:label>
											<xf:hide ev:event="DOMActivate" dialog="error-dialog"/>
										</xf:trigger>
									</xf:dialog>
									<xf:input ref="instance('budget-categories')/@domain">
										<xf:action ev:event="xforms-value-changed">
											<xf:setvalue ref="." value="upper-case(.)"/>
										</xf:action>
										<xf:action ev:event="xforms-value-changed">
											<xf:show dialog="error-dialog"/>
										</xf:action>
									</xf:input>
								</td>
							</tr>
							<tr>
								<th>Kategorien</th>
								<td>
									<table>
										<tbody>
											<xf:repeat id="ProcessTemplates" nodeset="instance('budget-categories')/BudgetCategory" appearance="full">
												<tr>
													<th>ID</th>
													<td>
														<xf:input ref="@id">
															<xf:action ev:event="xforms-value-changed">
																<xf:setvalue ref="." value="upper-case(.)"/>
															</xf:action>
														</xf:input>
													</td>
													<th>Name</th>
													<td>
														<xf:input ref="@name"/>
													</td>
													<th>
														<xf:trigger>
															<xf:label>X</xf:label>
															<xf:delete nodeset="." at="1" if="count(//.) &gt; 1" ev:event="DOMActivate"/>
														</xf:trigger>
													</th>
												</tr>
											</xf:repeat>
										</tbody>
										<tfoot>
											<tr>
												<th colspan="5">
													<xf:trigger>
														<xf:label>Vorlage hinzufügen</xf:label>
														<xf:insert context="instance('budget-categories')/" origin="instance('budget-category-new')/BudgetCategory" nodeset="BudgetCategory" ev:event="DOMActivate"/>
														<xf:setvalue ref="instance('budget-categories')/BudgetCategory[last()]/@id" value="''" ev:event="DOMActivate"/>
														<xf:setvalue ref="instance('budget-categories')/BudgetCategory[last()]/@name" value="''" ev:event="DOMActivate"/>
													</xf:trigger>
												</th>
											</tr>
										</tfoot>
									</table>
								</td>
							</tr>
						</tbody>
						<tfoot>
							<tr>
								<td colspan="4" style="text-align:right">
									<xf:submit submission="save" id="Save">
										<xf:label>Speichern</xf:label>
									</xf:submit>
								</td>
							</tr>
						</tfoot>
					</table>
				</div>
			</body>
		</xhtml:html>
	</xsl:template>

</xsl:stylesheet>