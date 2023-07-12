<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ivdnt="http://www.ivdnt.org/xslt/namespaces"
    exclude-result-prefixes="#all"
    expand-text="yes"
    version="3.0">
    
    <xsl:output method="html" version="5.0" encoding="UTF-8"/>
    
    <xsl:param name="UUID" as="xs:string" required="yes"/>
    
    <xsl:param name="VERSIONINFO" as="xs:string" select="''"/>
    <xsl:param name="BASEARTICLEURL" as="xs:string" required="yes"/> <!-- for development use: "http://gtb.inl.nl/iWDB/search?actie=article", for test use: "http://gtb.ato.inl.nl/iWDB/search?actie=article" -->
    <xsl:param name="BASEARTICLECONTENTURL" as="xs:string" required="yes"/> <!-- for development use: "http://gtb.inl.nl/iWDB/search?actie=article_content", for test use: "http://gtb.ato.inl.nl/iWDB/search?actie=article_content" -->
    <xsl:param name="BASESEARCHURL" as="xs:string" required="yes"/> <!-- for development use: "../redirect.php?actie=results", for test use: "http://gtb.ato.inl.nl/iWDB/search?actie=results" -->
    <xsl:param name="BASELISTURL" as="xs:string" required="yes"/> <!-- for development use: "redirect.php?actie=list", for test use: "http://gtb.ato.inl.nl/iWDB/search?actie=list" -->
    <xsl:param name="PLAUSIBLE_TRACKING_DOMAIN" as="xs:string" select="''"/> <!-- Plausible tracking domain; if not supplied, no tracking code will be generated (useful during debugging/testing). -->

    <!-- Space-separated dictionary abbreviations. Default is all dictionaries. -->
    <xsl:param name="SELECTED_SOURCES" select="'onw vmnw mnw wnt wft'"/>
    
    <xsl:include href="include.xslt"/>
    <xsl:include href="tabs.xslt"/>
    <xsl:include href="modal.xslt"/>
    <xsl:include href="help.xslt"/>
    
    <xsl:variable name="ROOT" as="document-node()" select="/"/>
    <xsl:variable name="BASE-URI" as="xs:string" select="base-uri(/)"/>
    
    <xsl:variable name="zoekformulier-label-column-class" as="xs:string" select="'col-sm-4'"/>
    <xsl:variable name="zoekformulier-input-column-class" as="xs:string" select="'col-sm-8'"/>
    <xsl:variable name="zoekformulier-vantot-label-class" as="xs:string" select="'col-sm-4'"/>
    <xsl:variable name="bronselector-column-class" as="xs:string" select="'col-xs-2'"/>
    
    <xsl:variable name="aantal-speciaal-teken-kolommen" as="xs:integer" select="13"/>
    
    <xsl:variable name="selected_sources_sequence" as="xs:string*" select="tokenize($SELECTED_SOURCES, '\s+')"/>
        
    <xsl:function name="ivdnt:class-contains" as="xs:boolean">
        <xsl:param name="class" as="attribute(class)?"/>
        <xsl:param name="required-value" as="xs:string"/>
        <xsl:sequence select="exists(index-of(tokenize(string($class), '\s+'), $required-value))"/>
    </xsl:function>
    
    <xsl:function name="ivdnt:add-class-values" as="attribute(class)">
        <xsl:param name="classlike-attr" as="attribute()?"/>
        <xsl:param name="values-to-be-added" as="xs:string+"/>
        <xsl:variable name="newvalue" as="xs:string+" select="(tokenize(string($classlike-attr), '\s+'), $values-to-be-added)"/>
        
        <xsl:attribute name="class" select="string-join(distinct-values($newvalue), ' ')"/>
    </xsl:function>
    
    <xsl:function name="ivdnt:remove-class-value" as="attribute(class)">
        <xsl:param name="classlike-attr" as="attribute()?"/>
        <xsl:param name="value-to-be-removed" as="xs:string"/>
        <xsl:variable name="class-as-seq" as="xs:string*" select="distinct-values(tokenize(string($classlike-attr), '\s+'))"/>
        <xsl:variable name="index" as="xs:integer?" select="index-of($class-as-seq, $value-to-be-removed)"/>
        
        <xsl:attribute name="class" select="if (empty($index)) then $classlike-attr else string-join(remove($class-as-seq, $index), ' ')"/>
    </xsl:function>
    
    <xsl:function name="ivdnt:generate-input-id"  as="xs:string">
        <xsl:param name="input-or-select-element" as="element()"/>
        <xsl:variable name="prefix" as="xs:string" select="if ($input-or-select-element/@name) then $input-or-select-element/@name else local-name($input-or-select-element)"/>
        <xsl:value-of select="$prefix || '.' || generate-id($input-or-select-element)"/>
    </xsl:function>
    
    <xsl:function name="ivdnt:gen-unique-filename"  as="xs:string">
       <xsl:param name="path" as="xs:string"/>
       <xsl:value-of select="$path || '?uuid=' || $UUID"/>        
    </xsl:function>
    
    <xsl:template match="/">
        <!-- Stap 1: los alle includes op, dat maakt het navigeren makkelijker, bijvoorbeeld om na te gaan of een formulier modals heeft. -->
        <xsl:variable name="includes-resolved" as="element()">
            <xsl:apply-templates select="/" mode="ivdnt:include-mode"/>
        </xsl:variable>
        
        <!--<xsl:result-document href="/tmp/debug.xml"><xsl:copy-of select="$includes-resolved"/></xsl:result-document>-->
        
        <!-- Stap 2: doe de normale conversie -->
        <xsl:copy>
            <xsl:apply-templates select="$includes-resolved" mode="ivdnt:html-mode"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="html" mode="ivdnt:html-mode">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:comment>
                HTML-bestand gegenereerd op basis van index.xml op {current-dateTime()} met behulp van XSLT 3.0, verwerkt door de Saxon XSLT-processor (http://www.saxonica.com).
                Interactieve uitbreidingen met behulp van Saxon-JS (XSLT in de browser), Bootstrap (http://getbootstrap.com/).
                Deze software werd ontwikkeld in opdracht van het instituut voor de Nederlandse taal (http://www.ivdnt.org) door Pieter Masereeuw (http://www.masereeuw.nl).
            </xsl:comment>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="head" mode="ivdnt:html-mode">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            
            <meta charset="UTF-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1" />
            
            <!-- favicons for a billion different devices -->
            <link rel="apple-touch-icon" sizes="180x180" href="img/apple-touch-icon.png" />
            <link rel="icon" type="image/png" sizes="32x32" href="img/favicon-32x32.png" />
            <link rel="icon" type="image/png" sizes="16x16" href="img/favicon-16x16.png" />
            <link rel="manifest" href="img/site.webmanifest" />
            <link rel="mask-icon" href="img/safari-pinned-tab.svg" color="#5bbad5" />
            <link rel="shortcut icon" href="img/favicon.ico" />
            <meta name="msapplication-TileColor" content="#2b5797" />
            <meta name="msapplication-config" content="img/browserconfig.xml" />
            <meta name="theme-color" content="#001475" />

            <link rel="stylesheet" media="screen" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css" type="text/css"/>
            <link rel="stylesheet" media="screen" href="{ivdnt:gen-unique-filename('css/bootstrap.min.css')}" type="text/css"/>
            <link rel="stylesheet" media="screen" href="{ivdnt:gen-unique-filename('css/gtb.css')}" type="text/css"/>
            <link rel="stylesheet" media="screen" href="{ivdnt:gen-unique-filename('css/gtb-artikel.css')}" type="text/css"/>
            <link rel="stylesheet" media="screen" href="{ivdnt:gen-unique-filename('css/gtb-helpteksten.css')}" type="text/css"/>
            <link rel="stylesheet" media="screen" href="{ivdnt:gen-unique-filename('css/gtb-typeahead.css')}" type="text/css"/>
            
            <script src="{ivdnt:gen-unique-filename('js/jquery-3.2.0.min.js')}" type="text/javascript"></script>
            <script src="{ivdnt:gen-unique-filename('js/bootstrap.min.js')}" type="text/javascript"></script>
            <script src="{ivdnt:gen-unique-filename('js/download.js')}" type="text/javascript"></script>
            <!-- baseListURL contains the baseurl for the typeahead functionality. This is a sample URL:
                 .../iWDB/search?wdb=onw%2Cvmnw%2Cmnw%2Cwnt%2Cwft%2C&actie=list&index=lemmodern&prefix=koe&sensitive=false&xmlerror=true
            -->
            <script src="{ivdnt:gen-unique-filename('js/gtb.js')}" type="text/javascript"></script>
                        
            <script type="text/javascript" src="{ivdnt:gen-unique-filename('saxonjs/SaxonJS.min.js')}"></script>
            <script type="text/javascript" xsl:expand-text="no">
                window.onload = function() {
                    SaxonJS.transform({
                    stylesheetLocation: "<xsl:value-of select="ivdnt:gen-unique-filename('xslt/gtb.sef')"/>",
                        initialTemplate: "initialize",
                        stylesheetParams: {
                             baseArticleURL: "<xsl:value-of select="$BASEARTICLEURL"/>",
                             baseArticleContentURL: "<xsl:value-of select="$BASEARTICLECONTENTURL"/>",
                             baseSearchURL: "<xsl:value-of select="$BASESEARCHURL"/>",
                             baseListURL: "<xsl:value-of select="$BASELISTURL"/>",
                             gtbFrontEndVersion: "<xsl:value-of select="$VERSIONINFO"/>"
                        }
                    });
                };

		/*
                // Try to warn that the Back button won't nagivate within the site.
                window.addEventListener("beforeunload", function (e) {
                    // NOTE: most modern browsers don't display custom messages anymore, but will display their own message
                    // (or the event may even be ignored if the user hasn't interacted with the page yet)
                    var confirmationMessage = "Let op, u verlaat hiermee de applicatie. Wilt u de applicatie verlaten?\n\n(navigeren binnen de applicatie kan met behulp van de tabbladen)";

                    (e || window.event).returnValue = confirmationMessage; //Gecko + IE
                    return confirmationMessage; //Gecko + Webkit, Safari, Chrome etc.
                });
		*/

            </script>
            
            <xsl:if test="$PLAUSIBLE_TRACKING_DOMAIN ne ''">
                <script defer="" data-domain="{@PLAUSIBLE_TRACKING_DOMAIN}" src="https://statistiek.ivdnt.org/js/plausible.js"></script>
            </xsl:if>

            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="@ivdnt:versioninfo" mode="#all">
        <xsl:if test="$VERSIONINFO ne ''">
            <xsl:attribute name="title" select="'build info: ' || $VERSIONINFO"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="body" mode="ivdnt:html-mode">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- De gebruiker hoeft mijn geneuzel niet te zien... -->
    <xsl:template match="comment()" mode="#all"/>
    
    <xsl:template match="node() | @*" mode="ivdnt:html-mode" priority="-1">
        <xsl:copy><xsl:apply-templates select="node() | @*" mode="#current"/></xsl:copy>
    </xsl:template>
    
    <xsl:template match="input | select" mode="ivdnt:html-mode">
        <xsl:copy>
            <!-- Als er een attribuut data-onlydicts is bij de bovenliggende formulierregel, kopieer het: -->
            <xsl:copy-of select="ancestor::ivdnt:formulierregel/@data-onlydicts"/>
            <xsl:attribute name="id" select="ivdnt:generate-input-id(.)"/>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="ivdnt:formulier" mode="ivdnt:html-mode">
        <div id="{generate-id()}">
            <xsl:apply-templates select="node() | @*" mode="ivdnt:html-mode"/>
        </div>
        <!--  Als het formulier modals heeft, plaats deze dan erachter. -->
        <xsl:apply-templates select=".//ivdnt:modal" mode="ivdnt:modal-mode"/>
    </xsl:template>
    
    <xsl:template match="ivdnt:formulier/@label" mode="ivdnt:html-mode">
        <xsl:attribute name="data-label" select="."/>
    </xsl:template>
    
    <xsl:template match="ivdnt:formulierregel" mode="ivdnt:html-mode">
        <div class="{normalize-space('form-group formulierregel ' || @class)}">
            <xsl:apply-templates mode="#current"/>
        </div>
    </xsl:template>
    
    <xsl:template match="ivdnt:formulierlabel" mode="ivdnt:html-mode">
        <label class="{normalize-space($zoekformulier-label-column-class || ' formulierlabel ' || @class)}">
            <xsl:apply-templates mode="#current"/>
        </label>
    </xsl:template>
    
    <xsl:template match="ivdnt:formulierinput" mode="ivdnt:html-mode">
        <div class="{normalize-space($zoekformulier-input-column-class || ' formulierinput ' || @class)}">
            <xsl:apply-templates mode="#current"/>
        </div>
    </xsl:template>

    <xsl:template match="ivdnt:formulierinput/input | ivdnt:formulierinput/select" mode="ivdnt:html-mode">
        <xsl:copy>
            <!-- Als er een attribuut data-onlydicts is bij de bovenliggende formulierregel, kopieer het: -->
            <xsl:copy-of select="ancestor::ivdnt:formulierregel/@data-onlydicts"/>
            <xsl:attribute name="id" select="ivdnt:generate-input-id(.)"/>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:attribute name="data-label" select="ancestor::ivdnt:formulierregel[1]/ivdnt:formulierlabel"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
        <xsl:if test="self::input[@type eq 'text' and ivdnt:class-contains(@class, 'typeahead')]">
            <ul class="typeahead dropdown-menu" role="listbox"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="ivdnt:van-tot-velden" mode="ivdnt:html-mode">
        <div class="{normalize-space('input-group ' || @class)}">
            <input id="{ivdnt:generate-input-id(.)}.van" type="text" name="{@van}" data-humanname="{@data-humanname-van}" class="form-control">
                <!-- Als er een attribuut data-onlydicts is bij de bovenliggende formulierregel, kopieer het: -->
                <xsl:copy-of select="ancestor::ivdnt:formulierregel/@data-onlydicts"/>
            </input>
            <span class="input-group-addon">tot / met</span>
            <input id="{ivdnt:generate-input-id(.)}.tot" type="text" name="{@tot}" data-humanname="{@data-humanname-tot}" class="form-control">
                <!-- Als er een attribuut data-onlydicts is bij de bovenliggende formulierregel, kopieer het: -->
                <xsl:copy-of select="ancestor::ivdnt:formulierregel/@data-onlydicts"/>
            </input>
        </div>
    </xsl:template>
    
    <xsl:template match="ivdnt:bronselectors" mode="ivdnt:html-mode">
        <!-- use suffix attribute to add a suffix to the dictionary names, e.g. suffix="bronnen" yields name="onwbronnen" -->
        <xsl:variable name="bronnen-title" as="xs:string" select="if (@suffix eq 'bronnen') then 'Bronnen bij' else 'Woordenboeken'"/>
        <div class="formulierregel form-group">
            <label class="{$zoekformulier-label-column-class} formulierlabel">{$bronnen-title}</label>
    
            <div class="{$zoekformulier-input-column-class}">
                <div class="gtb-bronselectors">
                    <label title="Oudnederlands Woordenboek" class="checkbox-inline gtbcheckbox">
                        <input id="{ivdnt:generate-input-id(.)}.onw" data-inputname="wdb" data-humanname="zoek in ONW" type="checkbox" name="onw{@suffix}">
                            <xsl:if test="'onw' = $selected_sources_sequence">
                                <xsl:attribute name="checked">checked</xsl:attribute>
                            </xsl:if>
                        </input> 
                        ONW
                    </label>
                    <label title="Vroegmiddelnederlands Woordenboek" class="checkbox-inline gtbcheckbox">
                        <input id="{ivdnt:generate-input-id(.)}.vmnw" data-inputname="wdb" data-humanname="zoek in VMNW" type="checkbox" name="vmnw{@suffix}">
                            <xsl:if test="'vmnw' = $selected_sources_sequence">
                                <xsl:attribute name="checked">checked</xsl:attribute>
                            </xsl:if>
                        </input>
                        VMNW
                    </label>
                    <label title="Middelnederlandsch Woordenboek" class="checkbox-inline gtbcheckbox">
                        <input id="{ivdnt:generate-input-id(.)}.mnw" data-inputname="wdb" data-humanname="zoek in MNW" type="checkbox" name="mnw{@suffix}">
                            <xsl:if test="'mnw' = $selected_sources_sequence">
                                <xsl:attribute name="checked">checked</xsl:attribute>
                            </xsl:if>
                        </input>
                        MNW
                    </label>
                    <label title="Woordenboek der Nederlandsche Taal" class="checkbox-inline gtbcheckbox">
                        <input id="{ivdnt:generate-input-id(.)}.wnt" data-inputname="wdb" data-humanname="zoek in WNT" type="checkbox" name="wnt{@suffix}">
                            <xsl:if test="'wnt' = $selected_sources_sequence">
                                <xsl:attribute name="checked">checked</xsl:attribute>
                            </xsl:if>
                        </input>
                        WNT
                    </label>
                    <label title="Woordenboek der Friese taal" class="checkbox-inline gtbcheckbox">
                        <input id="{ivdnt:generate-input-id(.)}.wft" data-inputname="wdb" data-humanname="zoek in WFT" type="checkbox" name="wft{@suffix}">
                            <xsl:if test="'wft' = $selected_sources_sequence">
                                <xsl:attribute name="checked">checked</xsl:attribute>
                            </xsl:if>
                        </input>
                        WFT
                    </label>
                </div>
            </div>
        </div>
    </xsl:template>
    
    <xsl:template match="ivdnt:resultaatformaatselectors" mode="ivdnt:html-mode">
        <div class="formulierregel form-group">
            <label class="{$zoekformulier-label-column-class} formulierlabel">Resultaten weergeven als </label>
            <div class="{$zoekformulier-input-column-class}">
                <div id="resultaatformaatselectors" class="gtb-resultaatformaatselectors">
                    <label class="radio-inline gtbradio" title="Toon een lijst met artikelen"><input id="{ivdnt:generate-input-id(.)}.0" checked="checked" data-inputname="domein" data-humanname="toon artikelen" type="radio" name="domein" value="0"/>Artikelen</label>
                    <label class="radio-inline gtbradio" title="Toon een lijst met betekenisomschrijvingen"><input id="{ivdnt:generate-input-id(.)}.1" data-inputname="domein" data-humanname="toon omschrijvingen" type="radio" name="domein" value="1"/>Definities</label>
                    <label class="radio-inline gtbradio" title="Toon een lijst met citaten"><input id="{ivdnt:generate-input-id(.)}.2" data-inputname="domein" data-humanname="toon citaten" type="radio" name="domein" value="2"/>Citaten</label>
                    <label class="radio-inline gtbradio" title="Toon een lijst met kopsecties"><input id="{ivdnt:generate-input-id(.)}.3" data-inputname="domein" data-humanname="toon kopsecties" type="radio" name="domein" value="3"/>Kopsecties</label>
                    <label class="radio-inline gtbradio" title="Toon een lijst met verbindingen"><input id="{ivdnt:generate-input-id(.)}.4" data-inputname="domein" data-humanname="toon verbindingen" type="radio" name="domein" value="4"/>Verbindingen</label>
                </div>
            </div>
        </div>
    </xsl:template>
    
    <!-- collapse -->
    
    <xsl:template match="ivdnt:collapse[@label]" priority="100" mode="ivdnt:html-mode">
        <p class="gtb-collapse-label">
            <a>
                <xsl:attribute name="data-toggle" select="'collapse'"/>
                <xsl:attribute name="href" select="concat('#', generate-id(.))"/>
                
                <xsl:choose>
                    <xsl:when test="@open='true'">
                        <xsl:attribute name="aria-expanded" select="'true'"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:attribute name="aria-expanded" select="'false'"/>
                        <xsl:attribute name="class" select="'collapsed'"/>
                    </xsl:otherwise>
                </xsl:choose>
                
                <!-- altijd eentje verborgen door css -->
                <span class="fa fa-lg fa-caret-right"></span>
                <span class="fa fa-lg fa-caret-down"></span>
                <xsl:value-of select="@label"/>
            </a>
        </p>
        
        <xsl:next-match/>
    </xsl:template>
    
    <xsl:template match="ivdnt:collapse" priority="80" mode="ivdnt:html-mode">
        <div>
            <!-- 
                Als er een label is, voeg .collapse class toe aan de content zodat we gesloten starten 
                Wanneer er geen label is, zou de gebruiker hem nooit meer kunnen openen, dus doe het dan niet.
            -->
            <xsl:choose>
                <xsl:when test="@label and @open='true'"> <!-- open negeren als er geen label is -->
                    <xsl:copy-of select="ivdnt:add-class-values(@class, 'gtb-collapse collapse in')"/>
                    <xsl:attribute name="aria-expanded" select="'true'"/>
                </xsl:when>
                <xsl:when test="@label">
                    <xsl:copy-of select="ivdnt:add-class-values(@class, 'gtb-collapse collapse')"/>
                    <xsl:attribute name="aria-expanded" select="'false'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="ivdnt:add-class-values(@class, 'gtb-collapse')"/>
                </xsl:otherwise>
            </xsl:choose>
            
            <xsl:attribute name="id" select="generate-id(.)"/>
            
            <xsl:apply-templates select="node()|@*" mode="ivdnt:html-mode"/>
        </div>
    </xsl:template>
    
    <xsl:template match="@woordsoortgroep" mode="ivdnt:html-mode">
        <xsl:attribute name="data-woordsoortgroep" select="."/>
		<a class="gtb-selecteer-woordsoortgroep off btn btn-default btn-sm"></a>
	</xsl:template>
   
    <xsl:template match="ivdnt:woordsoort" mode="ivdnt:html-mode">
       <label class="checkbox-inline gtb-woordsoort">
            <input type="checkbox" value="{@zoek}"/>
            {@toon}
       </label>
    </xsl:template>
    
    <xsl:template match="ivdnt:specialetekens" mode="ivdnt:html-mode">
        <div class="speciaalteken collapse out">
            <table class="speciaalteken">
                <tbody>
                    <xsl:for-each-group select="ivdnt:teken" group-adjacent="xs:integer((position() - 1) div $aantal-speciaal-teken-kolommen)">
                        <tr>
                            <xsl:apply-templates select="current-group()" mode="ivdnt:ivdnt-teken"/>
                            <xsl:if test="count(current-group()) lt $aantal-speciaal-teken-kolommen">
                                <td colspan="{$aantal-speciaal-teken-kolommen - count(current-group())}">&#160;</td>
                            </xsl:if>
                        </tr>
                    </xsl:for-each-group>
                </tbody>
            </table>
        </div>
    </xsl:template>
    
    <xsl:template match="ivdnt:teken" mode="ivdnt:ivdnt-teken">
        <td class="speciaalteken" data-dismiss="modal"><xsl:apply-templates mode="ivdnt:ivdnt-teken"/></td>
    </xsl:template>
    
    <xsl:template match="ivdnt:sorteeropties[ancestor::ivdnt:modal/@type eq 'sorteren-normaal']" mode="ivdnt:html-mode">
        <!-- TODO Wanneer zijn welke opties enabled/disabled?             
             De technische sleutelnamen, zoals "hits","wdb","mdl","lemma","woordsoort", zijn afkomstig uit Sorteren.lzx
        -->
        <select id="{ivdnt:generate-input-id(.)}" name="{@name}" class="form-control">
            <option value=""></option>
            <option value="wdb">Woordenboek</option>
            <option value="hits">Aantal concordanties</option>
            <option value="mdl">Mod. Ned. trefwoord</option>
            <option value="lemma">Origineel trefwoord</option>
            <option value="woordsoort">Woordsoort</option>
            <option value="auteur">Auteur citaat</option>
            <option value="bron">Titel citaat</option>
            <option value="datering">Datering citaat</option>
            <option value="loc">Lokalisering citaat</option>
        </select>
    </xsl:template>

    <xsl:template match="ivdnt:sorteeropties[ancestor::ivdnt:modal/@type eq 'sorteren-bronnen']" mode="ivdnt:html-mode">
        <!-- TODO Wanneer zijn welke opties enabled/disabled?             
             De technische sleutelnamen, zoals "wdb","auteur","bron","datering","loc", zijn afkomstig uit Sorteren.lzx
        -->
        <select id="{ivdnt:generate-input-id(.)}" name="{@name}" class="form-control">
            <option value=""></option>
            <option value="wdb">Woordenboek</option>
            <option value="auteur">Auteur</option>
            <option value="bron">Titel</option>
            <option value="datering">Datering</option>
            <option value="loc">Lokalisering</option>
        </select>
    </xsl:template>
</xsl:stylesheet>
