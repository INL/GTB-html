<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ivdnt="http://www.ivdnt.org/xslt/namespaces"
    exclude-result-prefixes="#all"
    expand-text="yes"
    version="3.0">
    
    <xsl:output method="html" version="5.0" encoding="UTF-8"/>
    
    <xsl:include href="include.xslt"/>
    <xsl:include href="tabs.xslt"/>
    <xsl:include href="modal.xslt"/>
    
    <xsl:variable name="basiszoeken-label-column-class" as="xs:string" select="'col-md-4'"/>
    <xsl:variable name="basiszoeken-input-column-class" as="xs:string" select="'col-md-8'"/>
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
    
    <xsl:template match="/">
        <xsl:copy>
            <xsl:apply-templates mode="ivdnt:html-mode"/>
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
            
            <script src="js/jquery-3.2.0.min.js" type="text/javascript"></script>
            <script src="js/bootstrap.min.js" type="text/javascript"></script>
            <script src="js/datatables.min.js" type="text/javascript"></script>
                        
            <link rel="stylesheet" media="screen" href="css/gtb.css" type="text/css"/>
            <script type="text/javascript" src="saxonjs/SaxonJS.min.js"></script>
            <script xsl:expand-text="no">
                window.onload = function() {
                    SaxonJS.transform({
                        stylesheetLocation: "xslt/gtb.sef",
                        initialTemplate: "initialize",
                        stylesheetParams: {
                             baseArticleURL: "http://gtb.inl.nl/iWDB/search?actie=article",
                             baseSearchURL: "../redirect.php?actie=results",
                             XXXXXbaseSearchURL: "http://gtb.inl.nl/iWDB/search?actie=results",
                             baseListURL: "../redirect.php?actie=list",
                             XXXXXbaseListURL: "http://gtb.inl.nl/iWDB/search?actie=list"
                        }
                    });
                }
            </script>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="body" mode="ivdnt:html-mode">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="node() | @*" mode="ivdnt:html-mode">
        <xsl:copy><xsl:apply-templates select="node() | @*" mode="#current"/></xsl:copy>
    </xsl:template>
    
    <xsl:template match="ivdnt:formulierregel" mode="ivdnt:html-mode">
        <div class="row formulierregel">
            <xsl:apply-templates mode="#current"/>
        </div>
    </xsl:template>
    
    <xsl:template match="ivdnt:formulierlabel" mode="ivdnt:html-mode">
        <div class="{$basiszoeken-label-column-class}"><span class="{local-name()}"><xsl:apply-templates mode="#current"/></span></div>
    </xsl:template>
    
    <xsl:template match="ivdnt:formulierinput" mode="ivdnt:html-mode">
        <div class="{$basiszoeken-input-column-class}"><div class="{local-name()}"><xsl:apply-templates mode="#current"/></div></div>
    </xsl:template>
    
    <xsl:template match="ivdnt:formulierinput/input" mode="ivdnt:html-mode">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:attribute name="data-label" select="ancestor::ivdnt:formulierregel[1]/ivdnt:formulierlabel"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="ivdnt:bronselectors" mode="ivdnt:html-mode">
        <div class="{$basiszoeken-label-column-class}">
            <span class="formulierlabel formuliertitel">Basiszoeken</span>
        </div>
        <div class="{$basiszoeken-input-column-class}">
            <div class="formulierinput">
                <div class="row">
                    <div class="{$bronselector-column-class} gtbcheckbox"><label>ONW <input checked="checked" data-inputname="wdb" type="checkbox" name="onw" class="checkbox-inline"/></label></div>
                    <div class="{$bronselector-column-class} gtbcheckbox"><label>VMNW <input checked="checked" data-inputname="wdb" type="checkbox" name="vmnw" class="checkbox-inline"/></label></div>
                    <div class="{$bronselector-column-class} gtbcheckbox"><label>MNW <input checked="checked" data-inputname="wdb" type="checkbox" name="mnw" class="checkbox-inline"/></label></div>
                    <div class="{$bronselector-column-class} gtbcheckbox"><label>WNT <input checked="checked" data-inputname="wdb" type="checkbox" name="wnt" class="checkbox-inline"/></label></div>
                    <div class="{$bronselector-column-class} gtbcheckbox"><label>WFT <input checked="checked" data-inputname="wdb" type="checkbox" name="wft" class="checkbox-inline"/></label></div>
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
                        <a href="#" data-showhidegroup="{ivdnt:get-showhide-id(.)}" class="gtbcollapsed">&#160;{@toon}</a>
                    </xsl:when>
                    <xsl:otherwise>
                        <label>
                            <!-- name="{@id}" niet meer nodig bij <input>.
                                 TODO verwijder id's uit woordsoortassistentie.xml
                                 N.B.: value is expres leeg, dit maakt het onderscheid met subwaardes makkelijker.
                            -->
                            <input type="checkbox" value=""/><span>&#160;{@toon}</span>
                        </label>
                    </xsl:otherwise>
                </xsl:choose>
            </p> 
            <xsl:if test="ivdnt:woordsoortitemgroep">
                <!-- We gebruiken een eigen class in plaats van die van Bootstrap om te zorgen dat we beide namen kunnen gebruiken zonder eventuele gekoppelde GTB-logica in XSLT of Javascript te verstoren.  -->
                <div class="gtbhidden" data-showhidegroup="{ivdnt:get-showhide-id(.)}">
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
        <!--<label class="checkbox-custom checkbox-inline" data-initialize="checkbox" id="{@id}">
            <input class="sr-only" type="checkbox" name="{@id}" value="{@toon}"/> <span class="checkbox-label">{@toon}</span>
        </label>-->
        <label>
            <!-- name="{@id}" niet meer nodig bij <input>.
                 TODO verwijder id's uit woordsoortassistentie.xml
            -->
            <input type="checkbox" value="{@zoek}"/> <span>{@toon}</span>
        </label>
    </xsl:template>
    
    <xsl:template match="ivdnt:specialetekens" mode="ivdnt:html-mode">
        <div class="speciaalteken">
            <table class="speciaalteken">
                <tbody>
                    <xsl:for-each-group select="ivdnt:teken" group-adjacent="xs:integer((position() - 1) div $aantal-speciaal-teken-kolommen)">
                        <tr>
                            <xsl:if test="xs:integer(current-grouping-key()) ge 1">
                                <xsl:attribute name="class" select="'collapse out'"/>
                            </xsl:if>
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
</xsl:stylesheet>
