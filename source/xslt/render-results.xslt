<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:ivdnt="http://www.ivdnt.org/xslt/namespaces"
    exclude-result-prefixes="xs math"
    expand-text="yes"
    version="3.0">
    
    <xsl:function name="ivdnt:quote" as="xs:string">
        <xsl:param name="string" as="xs:string"/>
        <xsl:value-of select="'&quot;' || replace($string, '&quot;', '\\&quot;') || '&quot;'"/>
    </xsl:function>
    
    <xsl:function name="ivdnt:attributes2string" as="xs:string">
        <xsl:param name="attrs" as="attribute()*"/>
        <xsl:variable name="result" as="xs:string*"><xsl:for-each select="$attrs">{name(.) || '=' || ivdnt:quote(.)}</xsl:for-each></xsl:variable>
        <xsl:value-of select="if (count($result) gt 0) then ' ' || string-join($result, ' ') else ''"/>
    </xsl:function>
    
    <xsl:template match="results" mode="render-results">
        <xsl:param name="html" as="element(html)" required="yes"/>
        <xsl:param name="startline" as="xs:integer" required="yes"/>
        <div class="gtb-results">
            <xsl:apply-templates select="statistics" mode="render-results"/>
            <!-- Note: the id 'gtb-result-table' is used on several places in this file and in js/gtb.js -->
            <table id="gtb-result-table">
                <colgroup>
                    <col class="gtb-wdbcol-line"/>
                    <col class="gtb-wdbcol-wdb"/>
                    <col class="gtb-wdbcol-modern_lemma"/>
                    <col class="gtb-wdbcol-lemma"/>
                    <col class="gtb-wdbcol-woordsoort"/>
                    <col class="gtb-wdbcol-betekenis"/>
                </colgroup>
                <thead>
                    <tr>
                        <td>Nr.</td>
                        <td>Wdb</td>
                        <td>Mod. Ned. trefwoord</td>
                        <td>Origineel trefwoord</td>
                        <td>Woordsoort</td>
                        <td>Betekenis</td>
                    </tr>
                </thead>
                <tbody>
                    <xsl:apply-templates select="result" mode="render-results"/>
                </tbody>
            </table>
            <xsl:copy-of select="$html/key('ids', 'resultaatknoppen')"/>
        </div>
        <div class="dataTables_paginate paging_simple_numbers gtb-pagineringsknoppen" id="gtb-result-table_paginate">
            <ul class="pagination">
                <xsl:call-template name="ivdnt:gen-pagination">
                    <xsl:with-param name="statistics" select="statistics"/>
                    <xsl:with-param name="startline" select="$startline"/>
                </xsl:call-template>
            </ul>
        </div>
        <script xsl:expand-text="no">
            var table = $('#gtb-result-table') ;
            $(document).ready( function () {
                 table.DataTable();
            } );
            
            table.DataTable( {
                "paging": false,
                "bFilter": false,
                "bSort" : false,
                language: {
                       url: 'js/nl.json',
                }
            } );
        </script>
        
    </xsl:template>
    
    <xsl:template name="ivdnt:gen-pagination">
        <xsl:param name="statistics" as="element(statistics)" required="yes"/>
        <xsl:param name="startline" as="xs:integer" required="yes"/>
        
        <xsl:variable name="last-startline" select="max(((xs:integer($statistics/stat[1]/@count) + 1) - $maxLinesInResultPage, 1))" as="xs:integer"/>
        <xsl:variable name="preceding-startline" select="if (($startline - $maxLinesInResultPage) ge 1) then $startline - $maxLinesInResultPage else ()" as="xs:integer?"/>
        <xsl:variable name="following-startline" select="if (($startline + $maxLinesInResultPage) gt $last-startline) then () else $startline + $maxLinesInResultPage " as="xs:integer?"/>
        <xsl:variable name="beyond-following-startline" select="if (not(exists($preceding-startline)) and exists($following-startline))
            then if (($following-startline + $maxLinesInResultPage) gt $last-startline)
                 then ()
                 else $following-startline + $maxLinesInResultPage
            else ()" as="xs:integer?"/>
        <xsl:variable name="surrounding-startlines" select="($preceding-startline, $startline, $following-startline, $beyond-following-startline)" as="xs:integer+"/>
        
        <li class="gtb-paginate_button "><a href="#" data-startline="1" title="Ga naar regel 1">Eerste</a></li>
        <li class="gtb-paginate_button previous {if (empty($preceding-startline)) then 'disabled' else ''}" id="gtb-result-table_previous">
            <xsl:variable name="line" as="xs:integer" select="max(($startline - $maxLinesInResultPage, 1))"/>
            <a href="#" data-startline="{$line}" title="Ga naar regel {$line}">Vorige</a>
        </li>
        <xsl:if test="$surrounding-startlines[1] ne 1">
            <li class="gbt-paginate_button disabled"><a href="#">…</a></li>
        </xsl:if>
        <xsl:for-each select="$surrounding-startlines">
            <li class="gtb-paginate_button {if (. eq $startline) then 'active' else ''}"><a title="Ga naar regel {.}" href="#" data-startline="{.}">{ivdnt:linenumber2pagenumber(.)}</a></li>
        </xsl:for-each>
        <xsl:if test="$surrounding-startlines[3] ne $last-startline">
            <li class="gbt-paginate_button disabled"><a href="#">…</a></li>
        </xsl:if>
        <li class="gtb-paginate_button next {if (empty($following-startline)) then 'disabled' else ''}" id="gtb-result-table_next">
            <a href="#" data-startline="{$following-startline}" title="Ga naar regel {$following-startline}">Volgende</a>
        </li>
        <li class="gtb-paginate_button "><a href="#" data-startline="{$last-startline}" title="Ga naar regel {$last-startline}">Laatste</a></li>
    </xsl:template>
    
    <xsl:function name="ivdnt:linenumber2pagenumber" as="xs:integer">
        <xsl:param name="linenumber" as="xs:integer"/>
        <xsl:sequence select="xs:integer((($linenumber + $maxLinesInResultPage) - 1) div $maxLinesInResultPage)"/>
    </xsl:function>
    
    <xsl:function name="ivdnt:get-preceding-dict-linecount" as="xs:integer">
        <xsl:param name="statistics" as="element(statistics)"/>
        <xsl:param name="dictnames" as="xs:string*"/>
        <xsl:param name="dictname" as="xs:string"/>
        
        <xsl:choose>
            <xsl:when test="empty($dictnames) or ($dictnames[1] eq $dictname)">
                <xsl:sequence select="0"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="stat" as="element(stat)?" select="$statistics/stat[@item eq $dictnames[1]]"/>
                <xsl:variable name="statcount" as="xs:integer" select="if ($stat) then xs:integer($stat/@count) else 0"/>
                <xsl:sequence select="$statcount + ivdnt:get-preceding-dict-linecount($statistics, subsequence($dictnames, 2), $dictname)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="ivdnt:calculate-dictionary-startline" as="xs:integer">
        <xsl:param name="statistics" as="element(statistics)"/>
        <xsl:param name="dictname" as="xs:string"/>
        
        <xsl:sequence select="ivdnt:get-preceding-dict-linecount($statistics, tokenize($dictionaryOutputOrder, '\s+'), $dictname) + 1"/>
    </xsl:function>
    
    <xsl:template match="statistics" mode="render-results">
        <p class="gtb-statistics">
            <xsl:apply-templates mode="render-results"/>
        </p>
    </xsl:template>
    
    <xsl:template match="stat" mode="render-results">
        <xsl:variable name="documenten" as="xs:string" select="if (xs:integer(@count) eq 1) then 'document' else 'documenten'"/>
        <xsl:variable name="searchstring" as="xs:string" select="if (preceding-sibling::stat) then @item else ''"/>
        <span class="gtbstatitem"><a href="#" data-startline="{if (not(preceding-sibling::stat)) then 1 else ivdnt:calculate-dictionary-startline(parent::statistics, @item)}">{@item}</a>:&#160;</span>
        <span class="gtb-statcount" title="aantal hits: {@hits} in {@count} {$documenten}">{@count}</span>
        <xsl:if test="following-sibling::stat">
            <span class="gtb-statseparator"><xsl:text>&#32;-&#32;</xsl:text></span>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="result" mode="render-results">
        <!-- TODO Ignore attributes Homoniemnr and hits? -->
        <tr class="gtb-result-row">
            <xsl:apply-templates select="@line" mode="render-results"/>
            <xsl:apply-templates select="@Wdb" mode="render-results"/>
            <xsl:apply-templates select="@Modern_lemma" mode="render-results"/>
            <xsl:apply-templates select="@Lemma" mode="render-results"/>
            <xsl:apply-templates select="@Woordsoort" mode="render-results"/>
            <xsl:apply-templates select="@Betekenis" mode="render-results"/>
        </tr>
    </xsl:template>
    
    <xsl:template match="result/@*" mode="render-results">
        <xsl:variable name="wdbclass" select="if (local-name(.) eq 'Wdb') then ' gtb-wdb-' || translate(lower-case(.), ' ', '_') else ''"/>
        <td class="{'gtb-' || lower-case(local-name(.)) || $wdbclass}">
            <xsl:apply-templates select="." mode="render-result-attributes"/>
        </td>
    </xsl:template>
    
    <xsl:template match="@Line | @Wdb | @Woordsoort" mode="render-result-attributes">
        <!-- No parsing or special rules needed for these attributes. -->
        <xsl:value-of select="."/>
    </xsl:template>
    
    <xsl:template match="@Modern_lemma | @Betekenis" mode="render-result-attributes">
        <xsl:call-template name="parse-result-attributes"/>
        
        <xsl:if test="(local-name() eq 'Lemma') and (parent::*/@Homoniemnr ne '')">
            <span class="gtb-homoniemnr">{parent::*/@Homoniemnr}</span>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="@Lemma" mode="render-result-attributes">
        <xsl:param name="text-input-uri-params" as="xs:string" tunnel="yes"/>
        
        <!-- Assume url encoding is not needed for dictionary name or id. -->
        <xsl:variable name="form-pane" select="ancestor::div[ivdnt:class-contains(@class, 'tab-content')][1]//div[ivdnt:class-contains(@class, $BASISZOEKEN_FORMULIER_CLASS)]"/>
        <xsl:variable name="href" as="xs:string" select="$baseArticleURL || '&amp;wdb=' || parent::*/@Wdb || '&amp;id=' || parent::*/@id || '&amp;' || $text-input-uri-params"/>
        <!--<xsl:message select="'href=' || $href"/>-->
        <a href="{$href}" target="_blank">
            <xsl:call-template name="parse-result-attributes"/>
            <span class="gtb-homoniemnr">{parent::*/@Homoniemnr}</span>
        </a>
    </xsl:template>
    
    <xsl:template name="parse-result-attributes">
        <!-- The attribute values may contain a kind of markup, e.g. Betekenis="some text <i>italic text</i> more text".
             We parse it and then process it further.
        -->
        <xsl:try>
            <xsl:apply-templates select="parse-xml-fragment(.)" mode="parse-result-attribute"/>
            <xsl:catch>
                <span class="gtb-xml-error"><xsl:value-of select="."/></span>
            </xsl:catch>
        </xsl:try>
    </xsl:template>
    
    <xsl:template match="*" mode="parse-result-attribute">
        <span class="gtb-xml-error">&lt;{name(.) || ivdnt:attributes2string(@*)}&gt;</span>
        <xsl:apply-templates mode="parse-result-attribute"/>
        <span class="gtb-xml-error">&lt;/{name(.)}&gt;</span>
    </xsl:template>
    
    <!-- TODO find out about markup used inside attributes --> 
    <xsl:template match="I|i|EM|em|B|b" mode="parse-result-attribute">
        <xsl:element name="{lower-case(local-name(.))}">
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="parse-result-attribute"/>
        </xsl:element>
    </xsl:template>
    
</xsl:stylesheet>