<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ivdnt="http://www.ivdnt.org/xslt/namespaces"
    exclude-result-prefixes="#all"
    expand-text="yes"
    version="3.0">
    
    <xsl:output method="html" version="5.0" encoding="UTF-8"/>
    
    <xsl:param name="VERSIONINFO" as="xs:string" select="''"/>
    <xsl:param name="BASEARTICLEURL" as="xs:string" required="yes"/> <!-- for development use: "http://gtb.inl.nl/iWDB/search?actie=article", for test use: "http://gtb.ato.inl.nl/iWDB/search?actie=article" -->
    <xsl:param name="BASEARTICLECONTENTURL" as="xs:string" required="yes"/> <!-- for development use: "http://gtb.inl.nl/iWDB/search?actie=article_content", for test use: "http://gtb.ato.inl.nl/iWDB/search?actie=article_content" -->
    <xsl:param name="BASESEARCHURL" as="xs:string" required="yes"/> <!-- for development use: "../redirect.php?actie=results", for test use: "http://gtb.ato.inl.nl/iWDB/search?actie=results" -->
    <xsl:param name="BASELISTURL" as="xs:string" required="yes"/> <!-- for development use: "redirect.php?actie=list", for test use: "http://gtb.ato.inl.nl/iWDB/search?actie=list" -->
    
    <xsl:include href="include.xslt"/>
    <xsl:include href="tabs.xslt"/>
    <xsl:include href="modal.xslt"/>
    
    <xsl:variable name="zoekformulier-label-column-class" as="xs:string" select="'col-md-4'"/>
    <xsl:variable name="zoekformulier-input-column-class" as="xs:string" select="'col-md-8'"/>
    <xsl:variable name="zoekformulier-vantot-label-class" as="xs:string" select="'col-md-4'"/>
    <xsl:variable name="bronselector-column-class" as="xs:string" select="'col-md-2'"/>
    
    <xsl:variable name="aantal-speciaal-teken-kolommen" as="xs:integer" select="13"/>
        
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
    
    <xsl:template match="/">
        <!-- Stap 1: los alle includes op, dat maakt het navigeren makkelijker, bijvoorbeeld om na te gaan of een formulier modals heeft. -->
        <xsl:variable name="includes-resolved" as="element()">
            <xsl:apply-templates select="/" mode="ivdnt:include-mode"/>
        </xsl:variable>
        
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
                Interactieve uitbreidingen met behulp van Saxon-JS (XSLT in de browser), Bootstrap (http://getbootstrap.com/) en Datatables (https://datatables.net/).
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
            
            <link rel="stylesheet" media="screen" href="css/bootstrap.min.css" type="text/css"/>
            <link rel="stylesheet" media="screen" href="css/datatables.min.css" type="text/css" />
            <link rel="stylesheet" media="screen" href="css/gtb.css" type="text/css"/>
            <link rel="stylesheet" media="screen" href="css/gtb-artikel.css" type="text/css"/>
            
            <script src="js/jquery-3.2.0.min.js" type="text/javascript"></script>
            <script src="js/bootstrap.min.js" type="text/javascript"></script>
            <script src="js/bootstrap3-typeahead.min.js" type="text/javascript"></script>
            <script src="js/datatables.min.js" type="text/javascript"></script>
            <script src="js/download.js" type="text/javascript"></script>
            <!-- baseListURL contains the baseurl for the typeahead functionality. This is a sample URL:
                 .../iWDB/search?wdb=onw%2Cvmnw%2Cmnw%2Cwnt%2Cwft%2C&actie=list&index=lemmodern&prefix=koe&sensitive=false&xmlerror=true
            -->
            <script type="text/javascript">const BASE_LIST_URL = "<xsl:value-of select="$BASELISTURL"/>";</script>
            <script src="js/gtb.js" type="text/javascript"></script>
                        
            <link rel="stylesheet" media="screen" href="css/gtb.css" type="text/css"/>
            <script type="text/javascript" src="saxonjs/SaxonJS.min.js"></script>
            <script xsl:expand-text="no">
                window.onload = function() {
                    SaxonJS.transform({
                        stylesheetLocation: "xslt/gtb.sef",
                        initialTemplate: "initialize",
                        stylesheetParams: {
                             baseArticleURL: "<xsl:value-of select="$BASEARTICLEURL"/>",
                             baseArticleContentURL: "<xsl:value-of select="$BASEARTICLECONTENTURL"/>",
                             baseSearchURL: "<xsl:value-of select="$BASESEARCHURL"/>"
                        }
                    });
                }
            </script>
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
        <div class="{normalize-space('row formulierregel ' || @class)}">
            <xsl:apply-templates mode="#current"/>
        </div>
    </xsl:template>
    
    <xsl:template match="ivdnt:formulierlabel" mode="ivdnt:html-mode">
        <div class="{$zoekformulier-label-column-class}"><span class="{normalize-space(local-name() || ' ' || @class)}"><xsl:apply-templates mode="#current"/></span></div>
    </xsl:template>
    
    <xsl:template match="ivdnt:formulierinput" mode="ivdnt:html-mode">
        <div class="{$zoekformulier-input-column-class}"><div class="{local-name()}"><xsl:apply-templates mode="#current"/></div></div>
    </xsl:template>

    <xsl:template match="ivdnt:formulierinput/input | ivdnt:formulierinput/select" mode="ivdnt:html-mode">
        <xsl:copy>
            <xsl:attribute name="id" select="ivdnt:generate-input-id(.)"/>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:attribute name="data-label" select="ancestor::ivdnt:formulierregel[1]/ivdnt:formulierlabel"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="ivdnt:van-tot-velden" mode="ivdnt:html-mode">        
        <p class="form-control-static">
            <span class="col-md-2">Vanaf </span>
            <!-- input style=... dient om de 100% van .form-control in bootstrap.css te overschrijven.
                 Het percentage is proefondervindelijk vastgesteld en klopt niet eens helemaal. 
                 TODO moet netter kunnen. -->
            <input id="{ivdnt:generate-input-id(.)}.van" type="text" name="{@van}" data-humanname="{@data-humanname-van}" class="col-md-2 form-control" style="width: 21%"/>
            <span class="col-md-2">tot / met </span>
            <input id="{ivdnt:generate-input-id(.)}.tot" type="text" name="{@tot}" data-humanname="{@data-humanname-tot}" class="col-md-2 form-control" style="width: 21%"/>
        </p>
    </xsl:template>
    
    <xsl:template match="ivdnt:bronselectors" mode="ivdnt:html-mode">
        <!-- use suffix attribute to add a suffix to the dictionary names, e.g. suffix="bronnen" yields name="onwbronnen" -->
        <div class="{$zoekformulier-label-column-class}">
            <span class="formulierlabel formuliertitel"><xsl:value-of select="ancestor::ivdnt:formulier[1]/@label"/></span>
        </div>
        <div class="{$zoekformulier-input-column-class}">
            <div class="formulierinput">
                <div class="row">
                    <div class="{$bronselector-column-class} gtbcheckbox"><label title="Oudnederlands Woordenboek">ONW <input id="{ivdnt:generate-input-id(.)}.onw" checked="checked" data-inputname="wdb" data-humanname="zoek in ONW" type="checkbox" name="onw{@suffix}" class="checkbox-inline"/></label></div>
                    <div class="{$bronselector-column-class} gtbcheckbox"><label title="Vroegmiddelnederlands Woordenboek">VMNW <input id="{ivdnt:generate-input-id(.)}.vmnw" checked="checked" data-inputname="wdb" data-humanname="zoek in VMNW" type="checkbox" name="vmnw{@suffix}" class="checkbox-inline"/></label></div>
                    <div class="{$bronselector-column-class} gtbcheckbox"><label title="Middelnederlandsch Woordenboek">MNW <input id="{ivdnt:generate-input-id(.)}.mnw" checked="checked" data-inputname="wdb" data-humanname="zoek in MNW" type="checkbox" name="mnw{@suffix}" class="checkbox-inline"/></label></div>
                    <div class="{$bronselector-column-class} gtbcheckbox"><label title="Woordenboek der Nederlandsche Taal">WNT <input id="{ivdnt:generate-input-id(.)}.wnt" checked="checked" data-inputname="wdb" data-humanname="zoek in WNT"  type="checkbox" name="wnt{@suffix}" class="checkbox-inline"/></label></div>
                    <div class="{$bronselector-column-class} gtbcheckbox"><label title="Woordenboek der Friese taal">WFT <input id="{ivdnt:generate-input-id(.)}.wft" checked="checked" data-inputname="wdb" data-humanname="zoek in WFT" type="checkbox" name="wft{@suffix}" class="checkbox-inline"/></label></div>
                </div>
            </div>
        </div>
    </xsl:template>
    
    <xsl:template match="ivdnt:resultaatformaatselectors" mode="ivdnt:html-mode">
        <div class="{$zoekformulier-label-column-class}">
            <span class="formulierlabel formuliertitel">Resultaten weergeven als </span>
        </div>
        <div class="{$zoekformulier-input-column-class}">
            <div class="formulierinput">
                <div class="row">
                    <div class="{$bronselector-column-class} gtbradio"><label title="Toon een lijst met artikelen">Artikelen <input id="{ivdnt:generate-input-id(.)}.0" checked="checked" data-inputname="domein" data-humanname="toon artikelen" type="radio" name="domein" value="0" class="radio-inline"/></label></div>
                    <div class="{$bronselector-column-class} gtbradio"><label title="Toon een lijst met betekenisomschrijvingen">Omschr. <input id="{ivdnt:generate-input-id(.)}.1" data-inputname="domein" data-humanname="toon omschrijvingen" type="radio" name="domein" value="1" class="radio-inline"/></label></div>
                    <div class="{$bronselector-column-class} gtbradio"><label title="Toon een lijst met citaten">Citaten <input id="{ivdnt:generate-input-id(.)}.2" data-inputname="domein" data-humanname="toon citaten" type="radio" name="domein" value="2" class="radio-inline"/></label></div>
                    <div class="{$bronselector-column-class} gtbradio"><label title="Toon een lijst met kopsecties">Kopsecties <input id="{ivdnt:generate-input-id(.)}.3" data-inputname="domein" data-humanname="toon kopsecties" type="radio" name="domein" value="3" class="radio-inline"/></label></div>
                    <div class="{$bronselector-column-class} gtbradio"><label title="Toon een lijst met verbindingen">Verbind. <input id="{ivdnt:generate-input-id(.)}.4" data-inputname="domein" data-humanname="toon verbindingen" type="radio" name="domein" value="4" class="radio-inline"/></label></div>
                </div>
            </div>
        </div>
    </xsl:template>
    
    <xsl:template match="ivdnt:woordsoorten" mode="ivdnt:html-mode">
        <div class="woordsoorten" id="{ivdnt:get-showhide-id(.)}">
            <xsl:apply-templates mode="ivdnt:ivdnt-woordsoort"></xsl:apply-templates>
        </div>
    </xsl:template>
    
    <xsl:function name="ivdnt:get-showhide-id" as="xs:string">
        <xsl:param name="element" as="element()"/>
        <xsl:value-of select="generate-id($element/ancestor-or-self::ivdnt:woordsoorten)"/>
    </xsl:function>
    
    <xsl:template match="ivdnt:woordsoort" mode="ivdnt:ivdnt-woordsoort">
        <div data-hoofdwoordsoort="{@toon}">
            <p class="woordsoort" data-zoek="{@zoek}">
                <xsl:choose>
                    <xsl:when test="ivdnt:woordsoortitemgroep">
                        <a href="#" data-showhidegroup="{ivdnt:get-showhide-id(.)}" class="gtb-collapsed">&#160;{@toon}</a>
                    </xsl:when>
                    <xsl:otherwise>
                        <label>
                            <!-- N.B.: value is expres leeg, dit maakt het onderscheid met subwaardes makkelijker. -->
                            <input id="{ivdnt:generate-input-id(.)}" type="checkbox" value="" name="woordsoort.{generate-id()}"/><span>&#160;{@toon}</span>
                        </label>
                    </xsl:otherwise>
                </xsl:choose>
            </p> 
            <xsl:if test="ivdnt:woordsoortitemgroep">
                <!-- We gebruiken een eigen class in plaats van die van Bootstrap om te zorgen dat we beide namen kunnen gebruiken zonder eventuele gekoppelde GTB-logica in XSLT of Javascript te verstoren.  -->
                <div class="gtb-hidden" data-showhidegroup="{ivdnt:get-showhide-id(.)}">
                    <table class="woordsoorttable">
                        <xsl:if test="ivdnt:woordsoortitemgroep/@label">
                            <thead>
                                <tr>
                                    <xsl:for-each select="ivdnt:woordsoortitemgroep">
                                        <th>{@label}</th>
                                    </xsl:for-each>
                                </tr>
                            </thead>
                        </xsl:if>
                        <tbody>
                            <xsl:variable name="context" as="element(ivdnt:woordsoort)" select="."/>
                            <xsl:variable name="numcols" as="xs:integer" select="count(ivdnt:woordsoortitemgroep)"/>
                            <xsl:variable name="numrows" as="xs:integer" select="max(for $w in ivdnt:woordsoortitemgroep return count($w/ivdnt:woordsoortitem))"/>
                            <xsl:for-each select="1 to $numrows">
                                <xsl:variable name="row" as="xs:integer" select="."/>
                                <tr>
                                    <xsl:for-each select="1 to $numcols">
                                        <xsl:variable name="col" as="xs:integer" select="."/>
                                        <td><xsl:apply-templates select="$context/ivdnt:woordsoortitemgroep[$col]/ivdnt:woordsoortitem[$row]" mode="ivdnt:ivdnt-woordsoort"/></td>
                                    </xsl:for-each>
                                </tr>
                            </xsl:for-each>
                        </tbody>
                    </table>
                </div>
            </xsl:if>
        </div>
    </xsl:template>
    
    <xsl:template match="ivdnt:woordsoortitem" mode="ivdnt:ivdnt-woordsoort">
        <label>
            <input id="{ivdnt:generate-input-id(.)}" type="checkbox" value="{@zoek}" name="woordsoortitem.{generate-id()}"/> <span>{@toon}</span>
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
    
    <xsl:template match="ivdnt:sorteeropties" mode="ivdnt:html-mode">
        <!-- TODO Wanneer zijn welke opties enabled/disabled?
             TODO De opties zijn afhandelijk van de aard van het resultaat, dus waarschijnlijk dynamisch bepalen.
             
             De technische sleutelnamen, zoals "hits","wdb","mdl","lemma","woordsoort", zijn afkomstig uit Sorteren.lzx
        -->
        <select id="{ivdnt:generate-input-id(.)}" name="{@name}" class="form-control">
            <option value=""></option>
            <option value="wdb">Woordenboek</option>
            <option value="hits">Aantal concordanties</option>
            <option value="mdl">Mod. Ned. trefwoord</option>
            <option value="lemma">Origineel trefwoord</option>
            <option value="woordsoort">Woordsoort</option>
        </select>
    </xsl:template>
</xsl:stylesheet>
