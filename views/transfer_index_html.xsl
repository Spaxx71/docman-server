<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="home-data" required="yes"/>                
	<xsl:param name="home-views"/>                
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="year" required="yes"/>
	<xsl:param name="filename"/>
	
	<xsl:decimal-format name="european" decimal-separator="," grouping-separator="."/>

	<xsl:template match="/">
		<page>
			<head>
				<style>

		html
		{
		}
			body
			{
				font-family: Roboto, sans-serif;
				color: #0f3c4b;
				background-color: #e5edf1;
				padding: 5rem 1.25rem; /* 80 20 */
			}

			.container
			{
				width: 100%;
				max-width: 680px; /* 800 */
				text-align: center;
				margin: 0 auto;
			}

				.container h1
				{
					font-size: 42px;
					font-weight: 300;
					color: #0f3c4b;
					margin-bottom: 40px;
				}
				.container h1 a:hover,
				.container h1 a:focus
				{
					color: #39bfd3;
				}

				.container nav
				{
					margin-bottom: 40px;
				}
					.container nav a
					{
						border-bottom: 2px solid #c8dadf;
						display: inline-block;
						padding: 4px 8px;
						margin: 0 5px;
					}
					.container nav a.is-selected
					{
						font-weight: 700;
						color: #39bfd3;
						border-bottom-color: currentColor;
					}
					.container nav a:not( .is-selected ):hover,
					.container nav a:not( .is-selected ):focus
					{
						border-bottom-color: #0f3c4b;
					}

				.container footer
				{
					color: #92b0b3;
					margin-top: 40px;
				}
					.container footer p + p
					{
						margin-top: 1em;
					}
					.container footer a:hover,
					.container footer a:focus
					{
						color: #39bfd3;
					}

				.box
				{
					font-size: 1.25rem; /* 20 */
					background-color: #c8dadf;
					position: relative;
					padding: 100px 20px;
				}
				.box.has-advanced-upload
				{
					outline: 2px dashed #92b0b3;
					outline-offset: -10px;

					-webkit-transition: outline-offset .15s ease-in-out, background-color .15s linear;
					transition: outline-offset .15s ease-in-out, background-color .15s linear;
				}
				.box.is-dragover
				{
					outline-offset: -20px;
					outline-color: #c8dadf;
					background-color: #fff;
				}
					.box__dragndrop,
					.box__icon
					{
						display: none;
					}
					.box.has-advanced-upload .box__dragndrop
					{
						display: inline;
					}
					.box.has-advanced-upload .box__icon
					{
						width: 100%;
						height: 80px;
						fill: #92b0b3;
						display: block;
						margin-bottom: 40px;
					}

					.box.is-uploading .box__input,
					.box.is-success .box__input,
					.box.is-error .box__input
					{
						visibility: hidden;
					}

					.box__uploading,
					.box__success,
					.box__error
					{
						display: none;
					}
					.box.is-uploading .box__uploading,
					.box.is-success .box__success,
					.box.is-error .box__error
					{
						display: block;
						position: absolute;
						top: 50%;
						right: 0;
						left: 0;

						-webkit-transform: translateY( -50% );
						transform: translateY( -50% );
					}
					.box__uploading
					{
						font-style: italic;
					}
					.box__success
					{
						-webkit-animation: appear-from-inside .25s ease-in-out;
						animation: appear-from-inside .25s ease-in-out;
					}
						@-webkit-keyframes appear-from-inside
						{
							from	{ -webkit-transform: translateY( -50% ) scale( 0 ); }
							75%		{ -webkit-transform: translateY( -50% ) scale( 1.1 ); }
							to		{ -webkit-transform: translateY( -50% ) scale( 1 ); }
						}
						@keyframes appear-from-inside
						{
							from	{ transform: translateY( -50% ) scale( 0 ); }
							75%		{ transform: translateY( -50% ) scale( 1.1 ); }
							to		{ transform: translateY( -50% ) scale( 1 ); }
						}

					.box__restart
					{
						font-weight: 700;
					}
					.box__restart:focus,
					.box__restart:hover
					{
						color: #39bfd3;
					}

					.js .box__file
					{
						width: 0.1px;
						height: 0.1px;
						opacity: 0;
						overflow: hidden;
						position: absolute;
						z-index: -1;
					}
					.js .box__file + label
					{
						max-width: 80%;
						text-overflow: ellipsis;
						white-space: nowrap;
						cursor: pointer;
						display: inline-block;
						overflow: hidden;
					}
					.js .box__file + label:hover strong,
					.box__file:focus + label strong,
					.box__file.has-focus + label strong
					{
						color: #39bfd3;
					}
					.js .box__file:focus + label,
					.js .box__file.has-focus + label
					{
						outline: 1px dotted #000;
						outline: -webkit-focus-ring-color auto 5px;
					}
						.js .box__file + label *
						{
							/* pointer-events: none; */ /* in case of FastClick lib use */
						}

					.no-js .box__file + label
					{
						display: none;
					}

					.no-js .box__button
					{
						display: block;
					}
					.box__button
					{
						font-weight: 700;
						color: #e5edf1;
						background-color: #39bfd3;
						display: none;
						padding: 8px 16px;
						margin: 40px auto 0;
					}
						.box__button:hover,
						.box__button:focus
						{
							background-color: #0f3c4b;
						}
				</style>
			</head>
			<body>
				<div class="container" role="main">
					<form class="box" method="post" action="" enctype="multipart/form-data">
						<div class="box__input">
							<input class="box__file" type="file" name="files[]" id="file" data-multiple-caption="{count} files selected" multiple="multiple"/>
							<label for="file"><strong>Choose a file</strong><span class="box__dragndrop"> or drag it here</span>.</label>
							<button class="box__button" type="submit">Upload</button>
						</div>
						<div class="box__uploading">Uploading…</div>
						<div class="box__success">Done!</div>
						<div class="box__error">Error! <span/>.</div>
					</form>
				</div>
				<ul class="nav">
					<li>
						<a href="{$home-web-gui}/{$tenant}/{$year}/binders/enter/index.html">Neues Dokument erstellen…</a>
					</li>
					<li>
						<a href="{$home-web-gui}/{$tenant}/{$year}/transfer/upload_file.html">Datei hochladen…</a>
						<!-- <a href="{$home-web-api}/tenants/{$tenant}/years/{$year}/transfer/uploadSingleFile?display=html">Datei hochladen</a> -->
					</li>
					<li>
						<a href="{$home-web-gui}/{$tenant}/{$year}/transfer/upload_folder.html">Verzeichnis hochladen…</a>
						<!-- <a href="{$home-web-api}/tenants/{$tenant}/years/{$year}/transfer/uploadFolder?display=html">Verzeichnis hochladen</a> -->
					</li>
					<li>
						<!--
						<form action="{$home-web-gui}/{$tenant}/{$year}/transfer/upload_folder_response.html" method="post" enctype="multipart/form-data">
							<fieldset>
								<input type="file" name="document[]" size="40" maxlength="1000" multiple="multiple" accept=".pdf,.tif,.tiff,.png,.gif,.txt,.csv,.xml"/>
								<label for="file"><strong>Select files</strong><span class="ddu_area"> do use drag &amp; drop.</span>.</label>
								<input type="submit" value="Upload"/>
							</fieldset>
						</form>
						-->
					</li>
				</ul>
				<table>
					<tr>
						<th>#</th>
						<th>Dateiname</th>
						<th>Status</th>
						<th>Nummer</th>
						<th>Datum</th>
						<th>Betrag</th>
						<th>Aussteller</th>
						<th>Notiz</th>
						<th>Aktiviät</th>
						<th>Größe</th>
						<th>Erstellt</th>
					</tr>
					<xsl:apply-templates/>
				</table>
<script>
	'use strict';

	;( function ( document, window, index )
	{
		// feature detection for drag and drop upload
		var isAdvancedUpload = function()
			{
				var div = document.createElement( 'div' );
				return ( ( 'draggable' in div ) || ( 'ondragstart' in div &amp;&amp; 'ondrop' in div ) ) &amp;&amp; 'FormData' in window &amp;&amp; 'FileReader' in window;
			}();


		// applying the effect for every form
		var forms = document.querySelectorAll( '.box' );
		Array.prototype.forEach.call( forms, function( form )
		{
			var input		 = form.querySelector( 'input[type="file"]' ),
				label		 = form.querySelector( 'label' ),
				errorMsg	 = form.querySelector( '.box__error span' ),
				restart		 = form.querySelectorAll( '.box__restart' ),
				droppedFiles = false,
				showFiles	 = function( files )
				{
					label.textContent = files.length &gt; 1 ? ( input.getAttribute( 'data-multiple-caption' ) || '' ).replace( '{count}', files.length ) : files[ 0 ].name;
				},
				triggerFormSubmit = function()
				{
					var event = document.createEvent( 'HTMLEvents' );
					event.initEvent( 'submit', true, false );
					form.dispatchEvent( event );
				};

			// letting the server side to know we are going to make an Ajax request
			var ajaxFlag = document.createElement( 'input' );
			ajaxFlag.setAttribute( 'type', 'hidden' );
			ajaxFlag.setAttribute( 'name', 'ajax' );
			ajaxFlag.setAttribute( 'value', 1 );
			form.appendChild( ajaxFlag );

			// automatically submit the form on file select
			input.addEventListener( 'change', function( e )
			{
				showFiles( e.target.files );

				
				triggerFormSubmit();

				
			});

			// drag and drop files if the feature is available
			if( isAdvancedUpload )
			{
				form.classList.add( 'has-advanced-upload' ); // letting the CSS part to know drag and drop is supported by the browser

				[ 'drag', 'dragstart', 'dragend', 'dragover', 'dragenter', 'dragleave', 'drop' ].forEach( function( event )
				{
					form.addEventListener( event, function( e )
					{
						// preventing the unwanted behaviours
						e.preventDefault();
						e.stopPropagation();
					});
				});
				[ 'dragover', 'dragenter' ].forEach( function( event )
				{
					form.addEventListener( event, function()
					{
						form.classList.add( 'is-dragover' );
					});
				});
				[ 'dragleave', 'dragend', 'drop' ].forEach( function( event )
				{
					form.addEventListener( event, function()
					{
						form.classList.remove( 'is-dragover' );
					});
				});
				form.addEventListener( 'drop', function( e )
				{
					droppedFiles = e.dataTransfer.files; // the files that were dropped
					showFiles( droppedFiles );

					
					triggerFormSubmit();

									});
			}


			// if the form was submitted
			form.addEventListener( 'submit', function( e )
			{
				// preventing the duplicate submissions if the current one is in progress
				if( form.classList.contains( 'is-uploading' ) ) return false;

				form.classList.add( 'is-uploading' );
				form.classList.remove( 'is-error' );

				if( isAdvancedUpload ) // ajax file upload for modern browsers
				{
					e.preventDefault();

					// gathering the form data
					var ajaxData = new FormData( form );
					if( droppedFiles )
					{
						Array.prototype.forEach.call( droppedFiles, function( file )
						{
							ajaxData.append( input.getAttribute( 'name' ), file );
						});
					}

					// ajax request
					var ajax = new XMLHttpRequest();
					ajax.open( form.getAttribute( 'method' ), form.getAttribute( 'action' ), true );

					ajax.onload = function()
					{
						form.classList.remove( 'is-uploading' );
						if( ajax.status &gt;= 200 &amp;&amp; ajax.status &lt; 400 )
						{
							var data = JSON.parse( ajax.responseText );
							form.classList.add( data.success == true ? 'is-success' : 'is-error' );
							if( !data.success ) errorMsg.textContent = data.error;
						}
						else alert( 'Error. Please, contact the webmaster!' );
					};

					ajax.onerror = function()
					{
						form.classList.remove( 'is-uploading' );
						alert( 'Error. Please, try again!' );
					};

					ajax.send( ajaxData );
				}
				else // fallback Ajax solution upload for older browsers
				{
					var iframeName	= 'uploadiframe' + new Date().getTime(),
						iframe		= document.createElement( 'iframe' );

						$iframe		= $( '<iframe name="' + iframeName + '" style="display: none;"/>' );

					iframe.setAttribute( 'name', iframeName );
					iframe.style.display = 'none';

					document.body.appendChild( iframe );
					form.setAttribute( 'target', iframeName );

					iframe.addEventListener( 'load', function()
					{
						var data = JSON.parse( iframe.contentDocument.body.innerHTML );
						form.classList.remove( 'is-uploading' )
						form.classList.add( data.success == true ? 'is-success' : 'is-error' )
						form.removeAttribute( 'target' );
						if( !data.success ) errorMsg.textContent = data.error;
						iframe.parentNode.removeChild( iframe );
					});
				}
			});


			// restart the form if has a state of error/success
			Array.prototype.forEach.call( restart, function( entry )
			{
				entry.addEventListener( 'click', function( e )
				{
					e.preventDefault();
					form.classList.remove( 'is-error', 'is-success' );
					input.click();
				});
			});

			// Firefox focus bug fix for file input
			input.addEventListener( 'focus', function(){ input.classList.add( 'has-focus' ); });
			input.addEventListener( 'blur', function(){ input.classList.remove( 'has-focus' ); });

		});
	}( document, window, 0 ));

</script>				
			</body>
		</page>
	</xsl:template>

	<xsl:template match="Transfer">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="Files">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="File">
		<tr>
			<xsl:attribute name="class">
				<xsl:choose>
					<xsl:when test="count(preceding-sibling::*) mod 2 = 0">
						<xsl:text>even</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>odd</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>

			<td>
				<a href="{$home-web-gui}/{$tenant}/{$year}/binders/enter/index.html?ref=/{$tenant}/{$year}/transfer/{@name}">
					<xsl:value-of select="count(preceding-sibling::File)+1"/>
				</a>
			</td>
			<td>
				<a href="{$home-web-gui}/{$tenant}/{$year}/binders/enter/index.html?ref=/{$tenant}/{$year}/transfer/{@name}">
					<xsl:value-of select="@name"/>
				</a>
				 
				<a href="{$home-web-api}/tenants/{$tenant}/years/{$year}/transfer/{@name}">
					<img alt="Dokument download" src="/app/resources/download.svg" height="20px"/>
				</a>
			</td>
			<td><xsl:value-of select="Intelligence/@status"/></td>
			<td>
				<xsl:if test="number(Intelligence/@number-quality) &lt; 0.5 and Intelligence/@number != ''">
					<xsl:attribute name="style">color:#a35</xsl:attribute>
				</xsl:if>
				<xsl:value-of select="Intelligence/@number"/>
			</td>
			<td>
				<xsl:if test="number(Intelligence/@date-quality) &lt; 0.5 and Intelligence/@date != ''">
					<xsl:attribute name="style">color:#a35</xsl:attribute>
				</xsl:if>
				<xsl:value-of select="Intelligence/@date"/>
			</td>
			<td>
				<xsl:if test="number(Intelligence/@amount-quality) &lt; 0.5 and Intelligence/@amount != ''">
					<xsl:attribute name="style">color:#a35</xsl:attribute>
				</xsl:if>
				<xsl:value-of select="Intelligence/@amount"/>
			</td>
			<td><xsl:value-of select="Intelligence/@seller"/></td>
			<td>
				<form method="post" action="{$home-web-gui}/{$tenant}/{$year}/transfer/{@name}/note_response.html">
					<input type="text" name="notes" value="{Intelligence/@note}" size="24"/>
				</form>
			</td>
			<td>
				<ul class="nav">
					<li>
						<a href="{$home-web-gui}/{$tenant}/{$year}/binders/enter/index.html?ref=/{$tenant}/{$year}/transfer/{@name}">abheften…</a>
					</li>
					<li>
						<a href="{$home-web-gui}/{$tenant}/{$year}/binders/attach/index.html?ref=/{$tenant}/{$year}/transfer/{@name}">anhängen…</a>
					</li>
					<xsl:if test="@size!=0">
						<li>
							<a href="{$home-web-gui}/{$tenant}/{$year}/transfer/{@name}/rename.html">umbenennen…</a>
						</li>
					</xsl:if>
					<xsl:if test="(contains(lower-case(@name),'dtvf') or contains(lower-case(@name),'buchungsstapel')) and ends-with(@name,'.csv')">
						<li>
							<a href="{$home-web-gui}/{$tenant}/{$year}/transfer/{@name}/datev_import.html">DATEV Import…</a>
						</li>
					</xsl:if>

					<xsl:if test="(contains(lower-case(@name),'bank') or contains(lower-case(@name),'konto')) and ends-with(@name,'.csv')">
						<li>
							<a href="{$home-web-gui}/{$tenant}/{$year}/transfer/{@name}/banking_import.html">Kontoauszug Import…</a>
						</li>
					</xsl:if>

					<xsl:if test="(contains(lower-case(@name),'hibiscus') or contains(@name,'Konto')) and ends-with(@name,'.xml')">
						<li>
							<a href="{$home-web-gui}/{$tenant}/{$year}/transfer/{@name}/hibiscus_import.html">Hibiscus Import…</a>
						</li>
					</xsl:if>

					<li>
						<!-- https://github.com/SauceCodeFr/RestfulizerJs -->
						<!-- <button onclick="deleteData('{$home-web-api}/tenants/{$tenant}/years/{$year}/transfer/{@name}?display=html')">X</button> -->
						<!-- jquery rails -->
						<!-- <a data-confirm="Are you sure?" data-method="delete" href="{$home-web}/{$tenant}/{@name}" rel="nofollow">Löschen</a> -->
						<a href="{$home-web-gui}/{$tenant}/{$year}/transfer/{@name}/delete.html">löschen…</a>
					</li>

				</ul>
			</td>
			<td style="text-align:right">
				<xsl:value-of select="format-number(@size,'###.##0', 'european')"/>
			</td>
			<td style="text-align:center"> 
				<xsl:value-of select="format-dateTime(@created,'[D01].[M01].[Y0001]')"/> 
			</td>
		</tr>
	</xsl:template>
</xsl:stylesheet>