<!--
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
--><xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:my="http://www.my.com" version="3.0">
	<xsl:output method="xml" version="1.0" encoding="utf-8" indent="no"/>
	<!-- <xsl:preserve-space elements="PaymentDetails"/> -->

	<xsl:param name="kto" select="''"/>
	<xsl:param name="ktoId">
		<xsl:choose>
			<xsl:when test="kto=''">
				<xsl:text/>
			</xsl:when>
			<xsl:otherwise> 
				<xsl:value-of select="/objects/object[@type='de.willuhn.jameica.hbci.server.KontoImpl' and kontonummer=$kto]/@id"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:param>

	<!-- 
SVWZ+ = SEPA Verwendungszweck (bei Überweisungen?) 
https://www.hettwer-beratung.de/sepa-spezialwissen/sepa-technische-anforderungen/sepa-purpose-codes-vs-dta-textschl%C3%BCssel/

https://www.dzbank.de/content/dam/dzbank_de/de/home/produkte_services/Firmenkunden/PDF-Dokumente/transaction%20banking/elektronicBanking/Anhang1_Mapping_GVC-BTC_Anlage3_V082016.pdf

https://www.hettwer-beratung.de/sepa-spezialwissen/sepa-technische-anforderungen/sepa-gesch%C3%A4ftsvorfallcodes-gvc-mt-940/

https://www.sozialbank.de/fileadmin/2015/documents/4_Service/4.2.7_Download_Center/GVC_Code_Stand_2_2016.pdf
-->

	<xsl:template match="/">
		<BankAccounts>
			<xsl:for-each select="/objects/object[@type='de.willuhn.jameica.hbci.server.KontoImpl']">
				<BankAccount id="{@id}" kto="{kontonummer}" origin="Hibiscus">
					<BankAccountDetail>
						<BankName/>
						<AccountName>Konto <xsl:value-of select="@id"/></AccountName>
						<AccountNick><xsl:value-of select="name"/></AccountNick>
						<KTNR><xsl:value-of select="kontonummer"/></KTNR>
						<BLZ><xsl:value-of select="blz"/></BLZ>
						<IBAN><xsl:value-of select="iban"/></IBAN>
						<BIC><xsl:value-of select="bic"/></BIC>
						<CustomerID><xsl:value-of select="kundennummer"/></CustomerID>
						<CustomerName><xsl:value-of select="bezeichnung"/></CustomerName>
						<Type/> <!-- Kontokorrentkonto -->
						<CurrencyUnit>EUR</CurrencyUnit>
						<Notes><xsl:value-of select="notes"/></Notes>
						<HBCIAuthentication>
						<xsl:value-of select="substring-before(substring-after(passport_class, 'de.willuhn.jameica.hbci.passports.'), '.server.PassportImpl')"/>
						</HBCIAuthentication>
					</BankAccountDetail>
					<Accountings saldoInitAmount="">
						<xsl:apply-templates select="../object[@type='de.willuhn.jameica.hbci.server.UmsatzImpl'][konto_id=current()/@id]">
							<xsl:sort select="@id" data-type="number"/>
						</xsl:apply-templates>
					</Accountings>
				</BankAccount>
			</xsl:for-each>
		</BankAccounts>

	</xsl:template>

	<xsl:template match="objects">
		<Accountings kto="">
			<xsl:apply-templates>
				<xsl:sort select="@id" data-type="number"/>
			</xsl:apply-templates>
		</Accountings>
	</xsl:template>


	<xsl:template match="object[@type='de.willuhn.jameica.hbci.server.UmsatzImpl']">

		<xsl:choose>
			<xsl:when test="$ktoId='' or konto_id = $ktoId">

        <!--  SEPA Verwendungszweck: 
        IBAN+ SEPA IBAN Auftraggeber
        BIC+ SEPA BIC Auftraggeber
        EREF+ SEPA End to End-Referenz      (für Überweisung)
        KREF+ oder CREF + Kundenreferenz Customer Reference
        MREF+ SEPA Mandatsreferenz          (für Lastschrift)
        CRED+ SEPA Creditor Identifier      (für Lastschrift)
        DEBT+ Originator Identifier
        ABWA+ Abweichender SEPA Auftraggeber
        ABWE+ Abweichender SEPA Empfänger
        BREF+ Bankreferenz, Instruction ID
        RREF+ Retourenreferenz
        SVWZ+ SEPA Verwendungszweck
        COAM+ Zinskompensationsbetrag
        OAMT+ Ursprünglicher Umsatzbetrag
	OCMT+ Original Amount
        -->
				<xsl:variable name="SEPADetails">
					<xsl:for-each select="tokenize(concat(zweck,'&#xA;',zweck2,'&#xA;',zweck3),'\n')">
					<!-- <xsl:for-each select="tokenize(concat(zweck,zweck2,zweck3),'\n')"> -->
						<xsl:choose>
							<xsl:when test="current()=''">
								<!-- nothing to do -->
							</xsl:when>
							<xsl:otherwise>
								<SEPADetail><xsl:value-of select="."/></SEPADetail>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</xsl:variable>

				<Accounting id="PAY" oid="{@id}" saldoAmount="{saldo}" saldoTimestamp="{concat(substring(datum,7,4),'-',substring(datum,4,2),'-',substring(datum,1,2))}T00:00:00" isStorno="" currencyUnit="EUR" kto="{/objects/object[@type='de.willuhn.jameica.hbci.server.KontoImpl'][@id=current()/konto_id]/kontonummer}">
					<SalesType key="{gvcode}">
						<!-- Mapping GVC-BTC -->
						<!-- 0XX INLANDS - Zahlungsverkehr -->
						<!-- 1XX SEPA - Zahlungsverkehr -->
						<!-- 8XX -->
						<xsl:choose>
							<xsl:when test="gvcode='008'">
								<xsl:text>Dauerauftrag Belastung</xsl:text>
							</xsl:when>
							<xsl:when test="gvcode='082'">
								<!-- PMNT/CNTR/CDPT -->
								<xsl:text>Einzahlungen</xsl:text>
							</xsl:when>
							<xsl:when test="gvcode='083'">
								<!-- PMNT/CNTR/CWDL -->
								<xsl:text>Auszahlungen</xsl:text>
							</xsl:when>
							<xsl:when test="gvcode='105'">
								<!-- PMNT/RDDT/ESDD -->
								<xsl:text>SEPA Direct Debit (Einzelbuchung-Soll, Core)</xsl:text>
							</xsl:when>
							<xsl:when test="gvcode='106'">
								<!-- PMNT/CCRD/CWDL -->
								<!-- PMNT/CCRD/SMRT -->
								<!-- PMNT/CCRD/POSD -->
								<!-- PMNT/MCRD/CHRG -->
								<!-- PMNT/CCRD7OTHR -->
								<xsl:text>SEPA Cards Clearing (Einzelbuchung-Soll)</xsl:text>
							</xsl:when>
							<xsl:when test="gvcode='107'">
								<!-- PMNT/CCRD/OTHR -->
								<xsl:text>SEPA Direct Debit (Einzelbuchung-Soll, mit Karte am PoS)</xsl:text>
							</xsl:when>
							<xsl:when test="gvcode='116'">
								<!-- PMNT/ICDT/ESCT -->
								<xsl:text>SEPA Credit Transfer (Einzelbuchung-Soll)</xsl:text>
							</xsl:when>
							<xsl:when test="gvcode='117'">
								<!-- PMNT/ICDT/STDO -->
								<xsl:text>SEPA Credit Transfer (Dauerauftrag-Soll)</xsl:text>
							</xsl:when>
							<xsl:when test="gvcode='152'">
								<!-- PMNT/RCDT/STDO -->
								<xsl:text>SEPA Dauerauftragsgutschrif</xsl:text>
							</xsl:when>
							<xsl:when test="gvcode='166'">
								<!-- PMNT/RCDT/ESCT -->
								<xsl:text>SEPA Credit Transfer (Einzelbuchung-Haben) </xsl:text>
							</xsl:when>
							<xsl:when test="gvcode='181'">
								<!-- PMNT/RDDT/UPDD -->
								<xsl:text>SEPA Direct Debit (Haben Wiedergutschrift, Core) </xsl:text>
							</xsl:when>
							<xsl:when test="gvcode='805'">
								<!-- ACMT/OPCL/ACCC -->
								<xsl:text>Abschluss</xsl:text>
							</xsl:when>
							<xsl:when test="gvcode='835'">
								<!-- XTND/NTAV/NTAV -->
								<xsl:text>Sonstige nicht definierte GV-Arten</xsl:text>
							</xsl:when>
							<xsl:otherwise>
								<xsl:text>ERROR: unbekannter GV-Code '</xsl:text>
								<xsl:value-of select="gvcode"/>
								<xsl:text>'</xsl:text>
							</xsl:otherwise>
						</xsl:choose>
					</SalesType>

					<BookingDate>
						<xsl:value-of select="concat(substring(datum,7,4),'-',substring(datum,4,2),'-',substring(datum,1,2))"/>
					</BookingDate>
					<ValueDate>
						<xsl:value-of select="concat(substring(valuta,7,4),'-',substring(valuta,4,2),'-',substring(valuta,1,2))"/>
					</ValueDate>

					<xsl:if test="empfaenger_name != ''">
						<Recipient>
							<xsl:value-of select="empfaenger_name"/>
						</Recipient>
					</xsl:if>

					<xsl:if test="empfaenger_konto != ''">
						<IBAN>
							<xsl:value-of select="empfaenger_konto"/>
						</IBAN>
					</xsl:if>

					<xsl:if test="empfaenger_blz != ''">
						<BIC>
							<xsl:value-of select="empfaenger_blz"/>
						</BIC>
					</xsl:if>


					<PaymentDetails>
						<xsl:for-each select="$SEPADetails/SEPADetail">
							<xsl:choose>
								<xsl:when test="starts-with(.,'ABWA+')"/> <!-- already handled -->
								<xsl:when test="starts-with(.,'CHGS+')"/> <!-- already handled -->
								<xsl:when test="starts-with(.,'CRED+')"/> <!-- already handled -->
								<xsl:when test="starts-with(.,'CREF+')"/> <!-- already handled -->
								<xsl:when test="starts-with(.,'EREF+')"/> <!-- already handled -->
								<xsl:when test="starts-with(.,'KREF+')"/> <!-- already handled -->
								<xsl:when test="starts-with(.,'MREF+')"/> <!-- already handled -->
								<xsl:when test="starts-with(.,'OAMT+')"/> <!-- already handled -->
								<xsl:when test="starts-with(.,'SVWZ+')"> <!-- cut of prefix -->
									<PaymentDetail><xsl:value-of select="substring(.,6)"/></PaymentDetail>
								</xsl:when>
								<xsl:otherwise>
									<xsl:choose>
										<xsl:when test="preceding-sibling::SEPADetail[starts-with(.,'SVWZ+')]">
											<PaymentDetail><xsl:value-of select="."/></PaymentDetail>
										</xsl:when>
									</xsl:choose>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:for-each>
					</PaymentDetails>
					<Usages>
						<xsl:for-each select="$SEPADetails/SEPADetail">
							<xsl:choose>
								<xsl:when test="starts-with(.,'ABWA+')"/> <!-- already handled -->
								<xsl:when test="starts-with(.,'CHGS+')"/> <!-- already handled -->
								<xsl:when test="starts-with(.,'CRED+')"/> <!-- already handled -->
								<xsl:when test="starts-with(.,'CREF+')"/> <!-- already handled -->
								<xsl:when test="starts-with(.,'EREF+')"/> <!-- already handled -->
								<xsl:when test="starts-with(.,'KREF+')"/> <!-- already handled -->
								<xsl:when test="starts-with(.,'MREF+')"/> <!-- already handled -->
								<xsl:when test="starts-with(.,'OAMT+')"/> <!-- already handled -->
								<xsl:when test="starts-with(.,'SVWZ+')"/> <!-- already handled -->
								<xsl:otherwise>
									<xsl:choose>
										<xsl:when test="preceding-sibling::SEPADetail[starts-with(.,'SVWZ+')]">
											<!-- already handled -->
										</xsl:when>
										<xsl:otherwise>
											<Usage><xsl:value-of select="."/></Usage>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:for-each>
					</Usages>

					<xsl:choose>
						<xsl:when test="customerref != ''">
							<CustomerRef>
								<xsl:value-of select="customerref/text()"/>
							</CustomerRef>
						</xsl:when>					
						<xsl:when test="$SEPADetails/SEPADetail[starts-with(.,'CREF+')]">
							<CustomerRef type="CREF">
								<xsl:value-of select="substring($SEPADetails/SEPADetail[starts-with(.,'CREF+')],6)"/>
							</CustomerRef>
						</xsl:when>
						<xsl:when test="$SEPADetails/SEPADetail[starts-with(.,'KREF+')]">
							<CustomerRef type="KREF">
								<xsl:value-of select="substring($SEPADetails/SEPADetail[starts-with(.,'KREF+')],6)"/>
							</CustomerRef>
						</xsl:when>
					</xsl:choose>

					<xsl:choose>
						<xsl:when test="endtoendid != ''">
							<EndToEndRef>
								<xsl:value-of select="endtoendid/text()"/>
							</EndToEndRef>
						</xsl:when>					
						<xsl:when test="$SEPADetails/SEPADetail[starts-with(.,'EREF+')]">
							<EndToEndRef type="EREF">
								<xsl:value-of select="substring($SEPADetails/SEPADetail[starts-with(.,'EREF+')],6)"/>
							</EndToEndRef>
						</xsl:when>
					</xsl:choose>

					<xsl:choose>
						<xsl:when test="mandateid != ''">
							<MandantRef>
								<xsl:value-of select="mandateid/text()"/>
							</MandantRef>
						</xsl:when>					
						<xsl:when test="$SEPADetails/SEPADetail[starts-with(.,'MREF+')]">
							<MandantRef type="MREF">
								<xsl:value-of select="substring($SEPADetails/SEPADetail[starts-with(.,'MREF+')],6)"/>
							</MandantRef>
						</xsl:when>
					</xsl:choose>


					<xsl:if test="$SEPADetails/SEPADetail[starts-with(.,'CRED+')]">
						<CreditorID type="CRED">
							<xsl:value-of select="substring($SEPADetails/SEPADetail[starts-with(.,'CRED+')],6)"/>
						</CreditorID>
					</xsl:if>

					<xsl:if test="$SEPADetails/SEPADetail[starts-with(.,'ABWA+')]">
						<DivergentRecepient type="ABWA">
							<xsl:value-of select="substring($SEPADetails/SEPADetail[starts-with(.,'ABWA+')],6)"/>
						</DivergentRecepient>
					</xsl:if>

					<xsl:choose>
						<xsl:when test="betrag &lt; 0"> <!-- and not STORNO -->
							<Amount type="DEBIT">
								<xsl:value-of select="betrag"/>
							</Amount>
						</xsl:when>
						<xsl:otherwise>
							<Amount type="CREDIT">
								<xsl:value-of select="betrag"/>
							</Amount>
						</xsl:otherwise>
					</xsl:choose>
					<CurrencyUnit>EUR</CurrencyUnit>

					<!-- especially for money exchange costs -->
					<xsl:if test="$SEPADetails/SEPADetail[starts-with(.,'CHGS+')]">
						<ExternalCosts>
							<xsl:value-of select="substring($SEPADetails/SEPADetail[starts-with(.,'CHGS+')],6)"/>
						</ExternalCosts>
					</xsl:if>
					<xsl:if test="$SEPADetails/SEPADetail[starts-with(.,'OAMT+')]">
						<OriginalAmount>
							<xsl:value-of select="substring($SEPADetails/SEPADetail[starts-with(.,'OAMT+')],6)"/>
						</OriginalAmount>
					</xsl:if>

					<!--
					<xsl:value-of select="art"/>

					<xsl:value-of select="mandanteid"/>

					<xsl:choose>
						<xsl:when test=".='NONREF'">
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="customerref"/>
						</xsl:otherwise>
					</xsl:choose>
					-->
				</Accounting>

			</xsl:when>
			<xsl:otherwise>
				<xsl:comment>[<xsl:value-of select="kontonummer"/>|<xsl:value-of select="konto_id"/>]</xsl:comment>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

<!--
<xsl:function name="my:factorial">
    <xsl:param name="acc" as="xs:integer?"/>
    <xsl:param name="n" as="xs:integer"/>
    <xsl:sequence as="xs:integer" 
         select="if ($n = 1) 
                 then $acc
                 else 1" />
</xsl:function>
-->

	<xsl:template match="node()" priority="-1">
		<!-- nothing to do -->
	</xsl:template>

</xsl:stylesheet>