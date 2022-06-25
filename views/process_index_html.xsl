<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:xf="http://www.w3.org/2002/xforms" version="3.1">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="home-data" required="yes"/>                
	<xsl:param name="home-views"/>                
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="year" required="yes"/>
	<xsl:param name="resource-id"/>
	<xsl:param name="username"/>
	<xsl:param name="ref"/>

	<xsl:param name="new-document" select="true()"/>

	<xsl:variable name="isReadonly" select="'true()'"/>

	<xsl:template match="/">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="result">
		<page>
			<body>
				<div class="TilesHeader">Rechnungen:</div>
				<ul class="Tiles">
					<li>
						<xsl:attribute name="class">
							<xsl:text>Tile </xsl:text>
							<xsl:choose>
								<xsl:when test="contains($ref, '/transfer/') or contains($ref, '/mail/')">
									<!-- active -->
								</xsl:when>
								<xsl:otherwise>
									<xsl:text>disabled</xsl:text>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:attribute>
						<a href="InvoiceIn.html?ref={$ref}">Rechnung (eingehend)</a>
					</li>
					<li>
						<xsl:attribute name="class">
							<xsl:text>Tile </xsl:text>
							<xsl:choose>
								<xsl:when test="contains($ref, '/transfer/') or contains($ref, '/mail/')">
									<!-- active -->
								</xsl:when>
								<xsl:otherwise>
									<xsl:text>disabled</xsl:text>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:attribute>
						<a href="InvoiceIn.html?ref={$ref}&amp;type=STORNO">Rechnung (eingehend) &lt;STORNO&gt;</a>
					</li>
					<li class="Tile disabled">
						<a href="InvoiceOut.html?ref={$ref}">Rechnung (ausgehend)</a>
					</li>
					<li class="Tile disabled">
						<a href="InvoiceOut.html?ref={$ref}&amp;type=STORNO">Rechnung (ausgehend) &lt;STORNO&gt;</a>
					</li>
					<li class="Tile">
						<a href="Tax.html?ref={$ref}">Steuer-Zahlung</a>
					</li>					
					<li class="Tile">
						<a href="Tax.html?ref={$ref}&amp;type=STORNO">Steuer-Zahlung &lt;STORNO&gt;</a>
					</li>					
					<li>
						<xsl:attribute name="class">
							<xsl:text>Tile </xsl:text>
							<xsl:choose>
								<xsl:when test="contains($ref, '/transfer/') or contains($ref, '/mail/')">
									<!-- active -->
								</xsl:when>
								<xsl:otherwise>
									<xsl:text>disabled</xsl:text>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:attribute>
						<a href="EmployeeSalary.html?ref={$ref}">Lohn / Gehalt</a>
					</li>
				</ul>

				<div class="TilesHeader">Ablage / Archiv:</div>
				<ul class="Tiles">
					<li class="Tile">
						<a href="Document.html?type=undefined&amp;ref={$ref}">Beliebig</a>
					</li>
					<li class="Tile">
						<a href="Document.html?type=contract&amp;ref={$ref}">Antrag / Vertrag / Bestätigung</a>
					</li>
					<li class="Tile">
						<a href="Document.html?type=tax&amp;ref={$ref}">Steuer-Meldungen</a>
					</li>					
				</ul>
				<div class="TilesHeader">Bank:</div>
				<ul class="Tiles">
					<li>
						<xsl:attribute name="class">
							<xsl:text>Tile </xsl:text>
							<xsl:choose>
								<xsl:when test="contains($ref, '/banking/')">
									<!-- active -->
								</xsl:when>
								<xsl:otherwise>
									<xsl:text>disabled</xsl:text>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:attribute>
						<a href="InvoiceIn.html?type=bank-fee&amp;ref={$ref}">Kontogebühren</a>
					</li>
					<li>
						<xsl:attribute name="class">
							<xsl:text>Tile </xsl:text>
							<xsl:choose>
								<xsl:when test="contains($ref, '/transfer/')">
									<!-- active -->
								</xsl:when>
								<xsl:otherwise>
									<xsl:text>disabled</xsl:text>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:attribute>
						<a href="BankBalancing.html?ref={$ref}">Kontoausgleich</a>
					</li>
					<li>
						<xsl:attribute name="class">
							<xsl:text>Tile </xsl:text>
							<xsl:choose>
								<xsl:when test="contains($ref, '/transfer/')">
									<!-- active -->
								</xsl:when>
								<xsl:otherwise>
									<xsl:text>disabled</xsl:text>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:attribute>
						<a href="Document.html?ref={$ref}&amp;type=bank-statement">Kontoauszug</a>
					</li>						
				</ul>
				<div class="TilesHeader">Steuern:</div>
				<ul class="Tiles">
					<li>
						<xsl:attribute name="class">
							<xsl:text>Tile </xsl:text>
							<xsl:choose>
								<xsl:when test="contains($ref, '/transferXXX/')">
									<!-- active -->
								</xsl:when>
								<xsl:otherwise>
									<xsl:text>disabled</xsl:text>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:attribute>
						<a href="xxx.html?ref={$ref}">Steuermeldung</a>
					</li>				
					<li>
						<xsl:attribute name="class">
							<xsl:text>Tile </xsl:text>
							<xsl:choose>
								<xsl:when test="contains($ref, '/bankingXXX/')">
									<!-- active -->
								</xsl:when>
								<xsl:when test="contains($ref, '/transferXXX/')">
									<!-- active -->
								</xsl:when>								
								<xsl:otherwise>
									<xsl:text>disabled</xsl:text>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:attribute>
						<a href="xxx.html?ref={$ref}">Umsatzsteuer Vorauszahlung</a>
					</li>
					<li>
						<xsl:attribute name="class">
							<xsl:text>Tile </xsl:text>
							<xsl:choose>
								<xsl:when test="contains($ref, '/bankingXXX/')">
									<!-- active -->
								</xsl:when>
								<xsl:when test="contains($ref, '/transferXXX/')">
									<!-- active -->
								</xsl:when>								
								<xsl:otherwise>
									<xsl:text>disabled</xsl:text>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:attribute>
						<a href="xxx.html?ref={$ref}">Umsatzsteuer</a>
					</li>
					<li>
						<xsl:attribute name="class">
							<xsl:text>Tile </xsl:text>
							<xsl:choose>
								<xsl:when test="contains($ref, '/bankingXXX/')">
									<!-- active -->
								</xsl:when>
								<xsl:when test="contains($ref, '/transferXXX/')">
									<!-- active -->
								</xsl:when>									
								<xsl:otherwise>
									<xsl:text>disabled</xsl:text>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:attribute>
						<a href="xxx.html?ref={$ref}">Gewerbesteuer Vorauszahlung</a>
					</li>
					<li>
						<xsl:attribute name="class">
							<xsl:text>Tile </xsl:text>
							<xsl:choose>
								<xsl:when test="contains($ref, '/bankingXXX/')">
									<!-- active -->
								</xsl:when>
								<xsl:when test="contains($ref, '/transferXXX/')">
									<!-- active -->
								</xsl:when>									
								<xsl:otherwise>
									<xsl:text>disabled</xsl:text>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:attribute>
						<a href="xxx.html?ref={$ref}">Gewerbesteuer</a>
					</li>					
					<li>
						<xsl:attribute name="class">
							<xsl:text>Tile </xsl:text>
							<xsl:choose>
								<xsl:when test="contains($ref, '/bankingXXX/')">
									<!-- active -->
								</xsl:when>
								<xsl:when test="contains($ref, '/transferXXX/')">
									<!-- active -->
								</xsl:when>									
								<xsl:otherwise>
									<xsl:text>disabled</xsl:text>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:attribute>
						<a href="xxx.html?ref={$ref}">Einkommenssteuer Vorauszahlung</a>
					</li>
					<li>
						<xsl:attribute name="class">
							<xsl:text>Tile </xsl:text>
							<xsl:choose>
								<xsl:when test="contains($ref, '/bankingXXX/')">
									<!-- active -->
								</xsl:when>
								<xsl:when test="contains($ref, '/transferXXX/')">
									<!-- active -->
								</xsl:when>									
								<xsl:otherwise>
									<xsl:text>disabled</xsl:text>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:attribute>
						<a href="xxx.html?ref={$ref}">Einkommenssteuer</a>
					</li>
				</ul>
				<div class="TilesHeader">Spezial:</div>
				<ul class="Tiles">
					<li class="Tile">
						<a href="Simple.html?ref={$ref}">Universalbuchung</a>
					</li>
				</ul>
				<br/>
				<ul class="Nav">
					<li><a href="/app/{$ref}/delete.html">Dokument löschen...</a></li>
				</ul>				
				<br/>
				<iframe src="/app/{$ref}" width="100%" height="550px"/>			
			</body>
		</page>
	</xsl:template>

</xsl:stylesheet>