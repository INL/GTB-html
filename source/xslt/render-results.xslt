<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:ivdnt="http://www.ivdnt.org/xslt/namespaces"
    exclude-result-prefixes="xs math"
    expand-text="yes"
    version="3.0">
    
    <xsl:variable name="max-hoogte-title" as="xs:string" select="'Klik voor maximale hoogte'"/>
    <xsl:variable name="min-hoogte-title" as="xs:string" select="'Klik voor de normale hoogte'"/>
    
    <xsl:function name="ivdnt:quote" as="xs:string">
        <xsl:param name="string" as="xs:string"/>
        <xsl:value-of select="'&quot;' || replace($string, '&quot;', '\\&quot;') || '&quot;'"/>
    </xsl:function>
    
    <xsl:function name="ivdnt:is-bronnenlijst-result"  as="xs:boolean">
        <xsl:param name="results-element" as="element(results)"/>
        <xsl:sequence select="exists($results-element/result[@titel])"></xsl:sequence>
    </xsl:function>
    
    <xsl:template match="results" mode="render-results">
        <xsl:param name="html" as="element(html)" required="yes"/>
        <xsl:param name="startline" as="xs:integer" required="yes"/>
        
        <xsl:variable name="first-result" as="element(result)?" select="result[1]"/>
        <xsl:apply-templates select="statistics" mode="render-results"/>
        
        <xsl:variable name="selected-domein" as="xs:string" select="$html/key('ids', 'resultaatformaatselectors')//input[@type eq 'radio' and @name eq 'domein' and ivdnt:is-checked(.)]/@value"/>
        
        <div class="gtb-results">
            <div class="gtb-results-head">
                <div class="gtb-wdbcol-line">Nr.</div>
                <div class="gtb-wdbcol-wdb">Wdb</div>
                <xsl:choose>
                    <xsl:when test="ivdnt:is-bronnenlijst-result(.)">
                        <div class="gtb-wdbcol-auteur">Auteur</div>
                        <div class="gtb-wdbcol-titel">Titel</div>
                        <div class="gtb-wdbcol-van">Datering</div>
                        <div class="gtb-wdbcol-locatie">Lokalisering</div>
                    </xsl:when>
                    <xsl:otherwise>
                        <div class="gtb-wdbcol-modern_lemma">Mod. Ned. trefwoord</div>
                        <div class="gtb-wdbcol-lemma">Origineel trefwoord</div>
                        <div class="gtb-wdbcol-woordsoort">Woordsoort</div>
                        <xsl:if test="$first-result/@Verbinding"><div class="gtb-wdbcol-verbinding">Verbinding</div></xsl:if>
                        <xsl:if test="$first-result/@hits and $first-result/conc"><div class="gtb-wdbcol-hits">Freq. </div></xsl:if>
                        <xsl:choose>
                            <xsl:when test="$first-result/conc"><div class="gtb-wdbcol-conc">Concordantie</div></xsl:when>
                            <xsl:when test="$first-result/@Betekenis"><div class="gtb-wdbcol-betekenis">Betekenis</div></xsl:when>
                        </xsl:choose>
                        <xsl:if test="$first-result/@Kopsectie"><div class="gtb-wdbcol-kopsectie">Kopsectie</div></xsl:if>
                        <xsl:if test="$first-result/@Citaat"><div class="gtb-wdbcol-citaat">Citaat</div></xsl:if>
                    </xsl:otherwise>
                </xsl:choose>                        
            </div>

            <div class="gtb-results-body">
                <xsl:apply-templates select="result" mode="render-results">
                    <xsl:with-param name="selected-domein" select="$selected-domein" tunnel="yes"/>
                </xsl:apply-templates>
            </div>
        </div>
        
        <div class="gtb-pagineringsknoppen" id="gtb-result-table_paginate">
            <ul class="pagination">
                <xsl:call-template name="ivdnt:gen-pagination">
                    <xsl:with-param name="statistics" select="statistics"/>
                    <xsl:with-param name="currentStartLine" select="$startline"/>
                </xsl:call-template>
            </ul>
        </div>

        <!-- /node() ipv /* om whitespace te behouden, belangrijk voor spacing tussen inline-block elementen zoals buttons -->
        <xsl:apply-templates select="$html/key('ids', 'resultaatknoppen')/node()" mode="render-resultaatknoppen">
            <!-- TODO als de namen van de sorteersleutels te koppelen zijn aan de attributen van de <result> items, zouden we de select/option-items kunnen genereren op basis van
                 het zoekresultaat (<results>-XML). Dan is de omslachtige constructie met meerdere sorteer-modaldefinities niet meer nodig.
                 Het zou mooi zijn als de attribuutnamen gelijk waren geweest aan de sorteersleutels, bijv. sleutel=mdl maar attribuut=Modern_lemma (Mod. Ned. trefwoord).
            -->
            <xsl:with-param name="vereist-sorteertype" as="xs:string" select="if (ivdnt:is-bronnenlijst-result(.)) then 'sorteren-bronnen' else 'sorteren-normaal'" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="node() | @*" mode="render-resultaatknoppen">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="render-resultaatknoppen"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="button[@data-sorteertype]" mode="render-resultaatknoppen">
        <xsl:param name="vereist-sorteertype" as="xs:string" required="yes" tunnel="yes"/>
        <xsl:choose>
            <xsl:when test="@data-sorteertype eq $vereist-sorteertype">
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*" mode="render-resultaatknoppen"/>
                </xsl:copy>
            </xsl:when>
            <!-- Anders: toon de knop niet -->
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>
    
    <xsl:function name="ivdnt:range-title"  as="xs:string">
        <xsl:param name="firstOfRange" as="xs:integer"/>
        <xsl:param name="maxLineNumber" as="xs:integer"/>
        
        <xsl:variable name="lastOfRange" as="xs:integer" select="min(($firstOfRange + $maxLinesInResultPage - 1, $maxLineNumber))"/>
        <xsl:value-of select="'Toon regel ' || $firstOfRange || ' - ' || $lastOfRange"/>
    </xsl:function>
    
    <xsl:template name="ivdnt:gen-pagination">
        <xsl:param name="statistics" as="element(statistics)" required="yes"/>
        <xsl:param name="currentStartLine" as="xs:integer" required="yes"/>
        
        <!-- Note: a result with value 0 means: invalid line number. -->
        <xsl:variable name="highestLineNumber" as="xs:integer" select="xs:integer($statistics/stat[1]/@count)"/>
        <xsl:variable name="lastPageNumber" as="xs:integer" select="xs:integer(($highestLineNumber + $maxLinesInResultPage - 1) div $maxLinesInResultPage)"/>
        <xsl:variable name="lastStartLine" as="xs:integer" select="(($lastPageNumber - 1) * $maxLinesInResultPage) + 1"/>
        <xsl:variable name="nextStartLine" as="xs:integer" select="if (($currentStartLine + $maxLinesInResultPage) gt $highestLineNumber) then 0 else $currentStartLine + $maxLinesInResultPage"/>
        <xsl:variable name="beyondNextStartLine" as="xs:integer" select="if ($nextStartLine eq 0) then 0 else if (($nextStartLine + $maxLinesInResultPage) gt $highestLineNumber) then 0 else $nextStartLine + $maxLinesInResultPage"/>
        <xsl:variable name="prevStartLine" as="xs:integer" select="if ($currentStartLine lt $maxLinesInResultPage) then 0 else $currentStartLine - $maxLinesInResultPage"/>
        
        <xsl:variable name="surroundingStartlines" select="($prevStartLine, $currentStartLine, $nextStartLine, $beyondNextStartLine)" as="xs:integer+"/>
        
        <ixsl:set-property name="{$CURRENT_STARTLINE_PROPERTY}" select="$currentStartLine" object="ixsl:page()"/>
        
        <li class="gtb-paginate_button "><a href="#" data-startline="1" title="{ivdnt:range-title(1, $highestLineNumber)}">Eerste</a></li>
        <li class="gtb-paginate_button previous {if ($prevStartLine eq 0) then 'disabled' else ''}" id="gtb-result-table_previous">
            <xsl:variable name="line" as="xs:integer" select="max(($prevStartLine, 1))"/>
            <a href="#" data-startline="{$line}" title="{ivdnt:range-title($line, $highestLineNumber)}">Vorige</a>
        </li>
        <xsl:if test="$surroundingStartlines[1] ne 1">
            <li class="gbt-paginate_button disabled"><a href="#">…</a></li>
        </xsl:if>
        <xsl:for-each select="$surroundingStartlines[. ne 0]">
            <li class="gtb-paginate_button {if (. eq $currentStartLine) then 'active' else ''}"><a title="{ivdnt:range-title(., $highestLineNumber)}" href="#" data-startline="{.}">{ivdnt:linenumber2pagenumber(.)}</a></li>
        </xsl:for-each>
        <xsl:if test="$surroundingStartlines[3] ne $lastStartLine">
            <li class="gbt-paginate_button disabled"><a href="#">…</a></li>
        </xsl:if>
        <li class="gtb-paginate_button next {if ($nextStartLine eq 0) then 'disabled' else ''}" id="gtb-result-table_next">
            <a href="#" data-startline="{$nextStartLine}" title="{ivdnt:range-title($nextStartLine, $highestLineNumber)}">Volgende</a>
        </li>
        <li class="gtb-paginate_button "><a href="#" data-startline="{$lastStartLine}" title="{ivdnt:range-title($lastStartLine, $highestLineNumber)}">Laatste</a></li>
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
        <xsl:variable name="this" as="element(statistics)" select="."/>
        <xsl:variable name="dictionaries" as="xs:string+" select="tokenize($dictionaryOutputOrder, '\s+')"/>
        <p class="gtb-statistics">
            <!-- This should generate only output for the "total count" line: -->
            <xsl:apply-templates mode="render-results" select="$this/stat[not(@item = $dictionaries)]"/>
            
            <!-- Output the results in chronological dictionary order: -->
            <xsl:for-each select="$dictionaries">
                <xsl:variable name="dict" as="xs:string" select="."/>
                <xsl:apply-templates select="$this/stat[@item eq $dict]" mode="render-results"/>
            </xsl:for-each>
        </p>
    </xsl:template>
    
    <xsl:template match="stat" mode="render-results">
        <xsl:variable name="documenten" as="xs:string" select="if (xs:integer(@count) eq 1) then 'document' else 'documenten'"/>
        <xsl:variable name="searchstring" as="xs:string" select="if (preceding-sibling::stat) then @item else ''"/>
        <xsl:variable name="flyby" as="xs:string" select="if (preceding-sibling::stat) then 'Ga naar de eerste regel van ' || @item else ''"/>
        <span class="gtbstatitem">
            <a href="#" data-startline="{if (not(preceding-sibling::stat)) then 1 else ivdnt:calculate-dictionary-startline(parent::statistics, @item)}">
                <xsl:if test="$flyby ne ''"><xsl:attribute name="title" select="$flyby"/></xsl:if>
                <xsl:value-of select="@item"/>
            </a>:&#160;
        </span>
        <span class="gtb-statcount" title="aantal hits: {@hits} in {@count} {$documenten}">{@count}</span>
        <xsl:if test="@item ne tokenize($dictionaryOutputOrder)[last()]">
            <span class="gtb-statseparator"><xsl:text>&#32;-&#32;</xsl:text></span>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="result" mode="render-results">
        <!-- TODO Ignore attributes Homoniemnr and hits? -->
        <div class="gtb-result-row">
            <xsl:apply-templates select="@line" mode="render-results"/>
            <xsl:apply-templates select="@Wdb" mode="render-results"/>
            <xsl:apply-templates select="@Modern_lemma" mode="render-results"/>
            <xsl:apply-templates select="@Lemma" mode="render-results"/>
            <xsl:apply-templates select="@Woordsoort" mode="render-results"/>
            <xsl:apply-templates select="@Verbinding" mode="render-results"/>
            <xsl:choose>
                <xsl:when test="conc">
                    <xsl:apply-templates select="@hits" mode="render-results"/>
                    <div class="gtb-wdbcol-conc gtb-cell-reduced" title="{$max-hoogte-title}"><xsl:apply-templates select="conc" mode="render-results"/></div>
                </xsl:when>
                <xsl:when test="@Betekenis"><xsl:apply-templates select="@Betekenis" mode="render-results"/></xsl:when>
            </xsl:choose>
            <xsl:apply-templates select="@Kopsectie" mode="render-results"/>
            <xsl:apply-templates select="@Citaat" mode="render-results"/>
            
            <!-- Attributen van het bronnenlijst-resultaat (behalve @Wdb en @line is er geen overlap): -->
            <xsl:apply-templates select="@auteur" mode="render-results"/>
            <xsl:apply-templates select="@titel" mode="render-results"/>
            <xsl:apply-templates select="@van" mode="render-results"/>
            <xsl:apply-templates select="@locatie" mode="render-results"/>
        </div>
    </xsl:template>
    
    <xsl:template match="conc" mode="render-results">
        <span class="gtb-conc-line">
            <span class="gtb-conc-voor clearfix"><span><xsl:apply-templates select="ivdnt:remove-escaped-tags(@voor)" mode="render-conc-attributes"/></span></span>
            <span class="gtb-conc-zoekwoord"><xsl:apply-templates select="ivdnt:remove-escaped-tags(@zoekwoord)" mode="render-conc-attributes"/></span>
            <span class="gtb-conc-na"><xsl:apply-templates select="ivdnt:remove-escaped-tags(@na)" mode="render-conc-attributes"/></span>
            <br/>
        </span>
    </xsl:template>
    
    <xsl:template match="@voor | @zoekwoord | @na" mode="render-conc-attributes">
        <xsl:call-template name="parse-result-attributes"/>
    </xsl:template>
    
    <xsl:template match="result/@*" mode="render-results">
        <xsl:variable name="wdbclass" select="if (local-name(.) eq 'Wdb') then ' gtb-wdb-' || translate(lower-case(.), ' ', '_') else ''"/>
        <xsl:variable name="class" as="xs:string" select="'gtb-' || lower-case(local-name(.)) || $wdbclass"/>
        <xsl:variable name="colclass" as="xs:string" select="'gtb-wdbcol-' || lower-case(local-name(.))"/>
        <xsl:choose>
            <xsl:when test="lower-case(local-name()) eq 'betekenis'">
                <div class="{$class} {$colclass} gtb-cell-reduced" title="{$max-hoogte-title}"><xsl:apply-templates select="." mode="render-result-attributes"/></div>
            </xsl:when>
            <xsl:otherwise>
                <div class="{$class} {$colclass}"><xsl:apply-templates select="." mode="render-result-attributes"/></div>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    <xsl:template match="@van" mode="render-result-attributes">
        <xsl:variable name="datering" as="xs:string" select="if (. eq ../@tot) then . else . || ' - ' || ../@tot"/>
        {$datering}
    </xsl:template>
    
    <xsl:template match="@Line | @Wdb | @Woordsoort | @locatie | @hits" mode="render-result-attributes">
        <!-- No parsing or special rules needed for these attributes. -->
        <xsl:value-of select="."/>
    </xsl:template>
    
    <xsl:template match="@Modern_lemma | @Betekenis | @Citaat | @Verbinding | @Kopsectie | @auteur" mode="render-result-attributes">
        <xsl:call-template name="parse-result-attributes"/>
        
        <xsl:if test="(local-name() eq 'Lemma') and (parent::*/@Homoniemnr ne '')">
            <sup class="gtb-homoniemnr">{parent::*/@Homoniemnr}</sup>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="@Lemma" mode="render-result-attributes">
        <xsl:param name="text-input-uri-params" as="xs:string" tunnel="yes"/>
        <xsl:param name="selected-domein" as="xs:string" tunnel="yes"/>
        
        <xsl:variable name="amp-plus-domeinqueryparam" as="xs:string">
            <xsl:choose>
                <xsl:when test="$selected-domein = ('1', '4')">
                    <!-- 1 (definities), 4 (verbindingen) -->
                    <xsl:value-of select="'&amp;Betekenis_id=' || ../@Betekenis_id"/>
                </xsl:when>
                <xsl:when test="$selected-domein eq '2'">
                    <!-- 2 (citaten) -->
                    <xsl:value-of select="'&amp;Citaat_id=' || ../@Citaat_id"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- 0 (artikelen), 3 (kopsecties) of iets geks: lege string -->
                    <xsl:value-of select="''"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- Assume url encoding is not needed for dictionary name or id. -->
        <xsl:variable name="href" as="xs:string" select="$baseArticleURL-expanded || '&amp;wdb=' || parent::*/@Wdb || '&amp;id=' || parent::*/@id || $amp-plus-domeinqueryparam || '&amp;' || $text-input-uri-params"/>
        <a href="{$href}" target="_blank">
            <xsl:call-template name="parse-result-attributes"/>
            <sup class="gtb-homoniemnr">{parent::*/@Homoniemnr}</sup>
        </a>
    </xsl:template>
    
    <xsl:template match="@titel" mode="render-result-attributes">
        <xsl:param name="text-input-uri-params" as="xs:string" tunnel="yes"/>
        
        <xsl:variable name="auteur-as-xml" as="node()*">
            <xsl:try>
                <xsl:sequence select="parse-xml-fragment(../@auteur)"/>
                <xsl:catch>
                    <xsl:message>Fout bij parseren van auteur, input={../@auteur}</xsl:message>
                    <xsl:sequence select="()"/>
                </xsl:catch>
            </xsl:try>
        </xsl:variable>
        
        <!-- Assume url encoding is not needed for dictionary name or id; the name of the author is wrapped in a b element. -->
        <!-- TODO auteur komt niet uit b element, maar uit query string van vraag. Is de auteur wel nodig in de href? -->
        <xsl:variable name="href" as="xs:string" select="$baseArticleContentURL-expanded || '&amp;wdb=' || parent::*/@Wdb || 'BRONNEN&amp;id=' || parent::*/@id || '&amp;' || $text-input-uri-params"/>
        <a href="{$href}" target="_blank">
            <xsl:call-template name="parse-result-attributes"/>
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
        <span class="gtb-art-{lower-case(name(.))}">
            <xsl:apply-templates select="@*" mode="parse-result-attribute"/>
            <xsl:apply-templates mode="parse-result-attribute"/>
        </span>
    </xsl:template>
    
    <xsl:template match="@*" mode="parse-result-attribute">
        <xsl:attribute name="data-{lower-case(name(.))}" select="."/>
    </xsl:template>
    
    <xsl:template match="font[@color]|FONT[@color]" mode="parse-result-attribute">
        <span style="color: {@color}">
            <xsl:apply-templates select="@* except @color" mode="parse-result-attribute"/>
            <xsl:apply-templates mode="parse-result-attribute"/>
        </span>
    </xsl:template>
    
    <xsl:template match="br|BR" mode="parse-result-attribute">
        <xsl:element name="{lower-case(local-name(.))}">
            <xsl:apply-templates select="@*" mode="parse-result-attribute"/>
            <xsl:apply-templates mode="parse-result-attribute"/>
        </xsl:element>
    </xsl:template>
    
</xsl:stylesheet>