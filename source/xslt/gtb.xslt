<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
    xmlns:js="http://saxonica.com/ns/globalJS"
    xmlns:array="http://www.w3.org/2005/xpath-functions/array"
    xmlns:ivdnt="http://www.ivdnt.org/xslt/namespaces"
    expand-text="yes"
    version="3.0">
    
    <!-- Using camel case instead of hyphens for parameters reduces the need for JSON escaping when
         passing parameters to this stylesheet.
    -->
    
    <!-- Pass the start of the URL to which the query parameters (excluding the first part, ?actie=results - this is part of the parameter value) for searching will be appended: -->
    <xsl:param name="baseSearchURL" as="xs:string" required="yes"/>
    <!-- Pass the start of the URL to which the query parameters (excluding the first part, ?actie=article - this is part of the parameter value) for retrieving the article will be appended: -->
    <xsl:param name="baseArticleURL" as="xs:string" required="yes"/>
    <!-- Pass the start of the URL to which the query parameters (excluding the first part, ?actie=list - this is part of the parameter value) for retrieving the article will be appended: -->
    <xsl:param name="baseListURL" as="xs:string" required="yes"/>
    <!-- Pass (json) true or set here to true() if you want to see the full search URL (for development purposes): -->
    <xsl:param name="showLinkToSearchResultXml" as="xs:boolean" select="false()"/>
    <!-- Number of lines in each result page. -->
    <xsl:param name="maxLinesInResultPage" as="xs:integer" select="250"/>
    <!-- The order in which the results of dictionaries get listed in the results. Used to calculate line offsets when jumping to a dictionary. Space-separated value. -->
    <xsl:param name="dictionaryOutputOrder" select="'ONW VMNW MNW WNT WFT'"/>
    
    <xsl:key name="showhidegroup-divs" match="div[@data-showhidegroup]" use="@data-showhidegroup"/>
    <xsl:key name="ids" match="*[@id]" use="@id"/>
    
    <xsl:variable name="VISITED_URIS_PROPERTY" as="xs:string" select="'visited-uris'"/>
    <xsl:variable name="URL_FOR_CONTENT_PROPERTY" as="xs:string" select="'url-for-content'"/>
    <xsl:variable name="TEXT_INPUT_URI_PARAMS_PROPERTY" as="xs:string" select="'text-input-uri-params'"/>
    <xsl:variable name="RESULT_TABDIV_ID_PROPERTY" as="xs:string" select="'result-tabdiv-id'"/>
    <xsl:variable name="RESULT_SORTKEYS_PROPERTY" as="xs:string" select="'result-sortkeys'"/>
    <xsl:variable name="RESULT_SORTREVERSE_PROPERTY" as="xs:string" select="'result-sortreverse'"/>
    <xsl:variable name="FOCUSSED_TEXTBOX_PROPERTY" as="xs:string" select="'focussed_textbox-id'"/>
    <xsl:variable name="ZOEK_FORMULIER_CLASS" as="xs:string" select="'zoek-formulier'"/>    

    <xsl:include href="render-results.xslt"/>
    
    <!-- This function is used in order to void the output of the result of a called Javascript function. We are working around possible optimizations.-->
    <xsl:function name="ivdnt:always-false" as="xs:boolean">
        <xsl:sequence select="current-date() lt xs:date('2000-01-01')"/>
    </xsl:function>
    
    <xsl:function name="ivdnt:class-contains" as="xs:boolean">
        <xsl:param name="class" as="attribute(class)?"/>
        <xsl:param name="required-value" as="xs:string"/>
        <xsl:sequence select="exists(index-of(tokenize(string($class), '\s+'), $required-value))"/>
    </xsl:function>
    
    <xsl:function name="ivdnt:add-class-values" as="attribute(class)">
        <xsl:param name="classlike-attr" as="attribute()?"/>
        <xsl:param name="values-to-be-added" as="xs:string*"/>
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
    
    <xsl:function name="ivdnt:replace-class-value" as="attribute(class)">
        <xsl:param name="classlike-attr" as="attribute()?"/>
        <xsl:param name="old-value" as="xs:string"/>
        <xsl:param name="new-value" as="xs:string"/>
        
        <xsl:attribute name="class" select="ivdnt:add-class-values(ivdnt:remove-class-value($classlike-attr, $old-value), $new-value)"/>
    </xsl:function>
    
    <xsl:function name="ivdnt:is-checked" as="xs:boolean">
        <xsl:param name="input" as="element(input)"/>
        <xsl:sequence select="ixsl:get($input, 'checked')"/>
    </xsl:function>
    
    <xsl:function name="ivdnt:get-input-value" as="xs:string">
        <xsl:param name="input" as="element()"/> <!-- either element(select) or element(input) -->
        <xsl:sequence select="ixsl:get($input, 'value')"/>
    </xsl:function>
    
    <xsl:function name="ivdnt:strip-hash-from-id"  as="xs:string">
        <xsl:param name="id-with-hash" as="xs:string"/>
        <xsl:value-of select="substring-after($id-with-hash, '#')"/>        
    </xsl:function>
    
    <xsl:template name="ivdnt:uncheck">
        <xsl:param name="checkbox" as="element(input)" required="yes"/>
        <ixsl:set-property name="checked" object="$checkbox" select="false()"/>
        <!-- note that <ixsl:remove-attribute name="checked"> does not work (the current context is the input, equal to parameter $checkbox, so it could have worked). -->
    </xsl:template>
    
    <!-- Return a space separated string consisting of all visited uris. Note that we attempted to use maps and arrays, but we got too many runtimes errors, so we gave up. -->
    <xsl:function name="ivdnt:get-visited-uris" as="xs:string">
        <xsl:sequence select="ixsl:get(ixsl:page(), 'visited-uris')"/>
    </xsl:function>
    
    <xsl:template name="ivdnt:add-visited-uri">
        <xsl:param name="uri" as="xs:string" required="yes"/>
        <xsl:variable name="oldvalue" as="xs:string" select="ivdnt:get-visited-uris()"/>
        <xsl:variable name="newvalue" as="xs:string" select="string-join(distinct-values(($oldvalue, $uri)), ' ')"/>
        <ixsl:set-property name="{$VISITED_URIS_PROPERTY}" select="$newvalue" object="ixsl:page()"/>
    </xsl:template>
    
    <xsl:function name="ivdnt:is-visited-uri" as="xs:boolean">
        <xsl:param name="uri" as="xs:string"/>
        <xsl:variable name="visited-uris" as="xs:string" select="ivdnt:get-visited-uris()"/>
        <!-- Test if the sequence visited-uris contains the uri: -->
        <!--<xsl:message select="'ivdnt:is-visited-uri geeft: ' || ($uri = tokenize($visited-uris, ' '))"/>-->
        <xsl:sequence select="($uri = tokenize($visited-uris, ' '))"/>
    </xsl:function>
    
    <xsl:function name="ivdnt:get-showhide-div" as="element(div)">
        <xsl:param as="element()" name="predecessor"/>
        <xsl:sequence select="$predecessor/following::div[@data-showhidegroup eq $predecessor/@data-showhidegroup][1]"/>
    </xsl:function>
    
    <xsl:function name="ivdnt:get-showhide-a" as="element(a)">
        <xsl:param as="element()" name="successor"/>
        <xsl:sequence select="$successor/preceding::a[@data-showhidegroup eq $successor/@data-showhidegroup][1]"/>
    </xsl:function>
    
    <xsl:function name="ivdnt:get-active-tabdiv" as="element(div)">
        <xsl:param name="node-inside-tab" as="node()"/>
        <xsl:variable name="tab-content" as="element(div)" select="$node-inside-tab/ancestor-or-self::div[ivdnt:class-contains(@class, 'tab-content')]"/>
        <xsl:sequence select="$tab-content/div[ivdnt:class-contains(@class, 'active')]"/>
    </xsl:function>
    
    <xsl:template name="initialize">
        <xsl:variable name="visited-uris" as="xs:string" select="''"/>
        <ixsl:set-property name="{$VISITED_URIS_PROPERTY}" select="$visited-uris" object="ixsl:page()"/>
    </xsl:template>
    
    <xsl:template name="ivdnt:gtb-collapse">
        <xsl:for-each select="ivdnt:get-showhide-a(.)">
            <!-- This iterates only once. -->
            <ixsl:set-attribute name="class" select="ivdnt:replace-class-value(@class, 'gtb-expanded', 'gtb-collapsed')"/>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="ivdnt:gtb-expand">
        <xsl:for-each select="ivdnt:get-showhide-a(.)">
            <!-- Dit itereert slecht 1 keer -->
            <ixsl:set-attribute name="class" select="ivdnt:replace-class-value(@class, 'gtb-collapsed', 'gtb-expanded')"/>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="ivdnt:gtb-hide">
        <!-- Huidige context is een div-element dat wordt ingeklapt.
             We gebruiken een eigen class in plaats van die van Bootstrap om te zorgen dat we beide namen kunnen
             gebruiken zonder eventuele gekoppelde GTB-logica in XSLT of Javascript te verstoren.
        -->
        <ixsl:set-attribute name="class" select="ivdnt:add-class-values(@class, 'gtb-hidden')"/>
        <!-- Pas ook de de weergave aan van link die voor het inklappen zorgt: -->
        <xsl:call-template name="ivdnt:gtb-collapse"/>
    </xsl:template>
    
    <xsl:template name="ivdnt:gtb-show">
        <!-- Huidige context is een div-element dat wordt uitgeklapt. -->
        <ixsl:set-attribute name="class" select="ivdnt:remove-class-value(@class, 'gtb-hidden')"/>
        <!-- Pas ook de de weergave aan van link die voor het uitklappen zorgt: -->
        <xsl:call-template name="ivdnt:gtb-expand"/>
    </xsl:template>
    
    <xsl:function name="ivdnt:gtb-is-hidden" as="xs:boolean">
        <xsl:param as="element()" name="element"/>
        <xsl:sequence select="ivdnt:class-contains($element/@class, 'gtb-hidden')"/>
    </xsl:function>
    
    <xsl:template name="ivdnt:deactivate-tab">
        <xsl:param name="tabdiv" as="element(div)" required="yes"/>
        <xsl:for-each select="$tabdiv">
            <!-- Only one iteration -->
            <!--<xsl:message>deactivate id={@id}</xsl:message>-->
            <ixsl:set-attribute name="class" select="ivdnt:add-class-values(@class, 'gtb-disabled')"/>
            
            <!-- Genereer een div met de wait-button of maak hem zichtbaar. In eerste instantie genereerden we dit divje bij het maken van de HTML-file,
                 maar aangezien de inhoud van de result-tabbladen weer opnieuw wordt gegenereerd, heeft dit daar geen zin:
            -->
            <xsl:variable name="waitdiv" as="element(div)?" select="div[ivdnt:class-contains(@class, 'gtb-wait')]"/>
            <xsl:choose>
                <xsl:when test="$waitdiv">
                    <!-- Show it: -->
                    <!--<xsl:message>deactivate (exists), class={@class}</xsl:message>-->
                    <xsl:for-each select="$waitdiv"><ixsl:set-attribute name="class" select="ivdnt:remove-class-value(@class, 'gtb-hidden')"/></xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <!-- Create it: -->
                    <xsl:result-document href="?." method="ixsl:append-content">
                        <!--<xsl:message>deactivate (does not exist)</xsl:message>-->
                        <div class="gtb-wait">
                            <!-- TODO waarom draait het icoontje niet? Cf. https://www.bootply.com/128062 -->
                            <button class="btn btn-lg btn-info"><span class="gtb-waiticon"/>&#160;Even geduld a.u.b. ...</button>
                        </div>
                    </xsl:result-document>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="ivdnt:reactivate-tab">
        <xsl:param name="tabdiv" as="element(div)" required="yes"/>
        <xsl:for-each select="$tabdiv">
            <!-- Only one iteration -->
            <!--<xsl:message>reactivate id={@id}</xsl:message>-->
            <ixsl:set-attribute name="class" select="ivdnt:remove-class-value(@class, 'gtb-disabled')"/>
            
            <!-- Maak de div met de wait-button onzichtbaar (vergelijk template deactivate-tab);
                 als de content van de tab opnieuw gegenereerd is, doet dit niets (er is dan
                 namelijk geen match meer). Onzichtbaar maken is makkelijker dan geheel weghalen,
                 vandaar deze keuze.
            -->
            <xsl:for-each select="div[ivdnt:class-contains(@class, 'gtb-wait')]">
                <!-- Also, one iteration. -->
                <!--<xsl:message>reactivate eerst class={@class}</xsl:message>-->
                <ixsl:set-attribute name="class" select="ivdnt:add-class-values(@class, 'gtb-hidden')"/>
                <!--<xsl:message>reactivate dan class={@class}</xsl:message>-->
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="ivdnt:select-tab">
        <xsl:param name="tabid" as="xs:string" required="yes"/>
        <xsl:param name="url-for-content" as="xs:string" required="yes"/>
        <xsl:param name="text-input-uri-params" as="xs:string" required="yes" tunnel="yes"/>
                
        <!-- Activate the tabtitle whose id is $tabid: -->
        <xsl:variable name="result-tab-title" as="element()" select="key('ids', $tabid)"/>
        <xsl:for-each select="$result-tab-title/parent::*/*">
            <xsl:variable name="class-without-active" select="ivdnt:remove-class-value(@class, 'active')" as="attribute(class)"/>
            <ixsl:set-attribute name="class" select="ivdnt:add-class-values($class-without-active, if (@id eq $tabid) then ('active') else ())"/>
        </xsl:for-each>
        
        <!-- Activate the div whose id is equal to the href of the "resultaat" tabtitle: -->
        <xsl:variable name="tabdiv-id" as="xs:string" select="ivdnt:strip-hash-from-id($result-tab-title/a/@href)"/>
        
        <!-- Save some info for use by pagination: -->
        <ixsl:set-property name="{$URL_FOR_CONTENT_PROPERTY}" select="$url-for-content" object="ixsl:page()"/>
        <ixsl:set-property name="{$TEXT_INPUT_URI_PARAMS_PROPERTY}" select="$text-input-uri-params" object="ixsl:page()"/>
        <ixsl:set-property name="{$RESULT_TABDIV_ID_PROPERTY}" select="$tabdiv-id" object="ixsl:page()"/>
        <ixsl:set-property name="{$RESULT_SORTKEYS_PROPERTY}" select="''" object="ixsl:page()"/>
        <ixsl:set-property name="{$RESULT_SORTREVERSE_PROPERTY}" select="'false'" object="ixsl:page()"/>
        
        <xsl:variable name="current-tab" as="element(div)" select="ivdnt:get-active-tabdiv(.)"/>
        
        <xsl:call-template name="ivdnt:show-results">
            <xsl:with-param name="url-for-content" select="$url-for-content"/>
            <xsl:with-param name="tabdiv-id" select="$tabdiv-id"/>
            <xsl:with-param name="startline" select="1" as="xs:integer"/>
            <xsl:with-param name="originating-tabdiv" select="$current-tab"/>
            <xsl:with-param name="text-input-uri-params" select="$text-input-uri-params" tunnel="yes"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template name="ivdnt:show-results">
        <xsl:param name="url-for-content" as="xs:string" required="yes"/>
        <xsl:param name="tabdiv-id" as="xs:string" required="yes"/>
        <xsl:param name="startline" as="xs:integer" required="yes"/>
        <xsl:param name="originating-tabdiv" as="element(div)" required="yes"/>
        <xsl:param name="text-input-uri-params" as="xs:string" required="no" tunnel="yes"/>
        
        <!--<xsl:if test="not(ivdnt:is-visited-uri($url-for-content))"><xsl:call-template name="ivdnt:deactivate-tab"><xsl:with-param name="tabdiv" select="$originating-tabdiv"/></xsl:call-template></xsl:if>-->
        <xsl:call-template name="ivdnt:deactivate-tab"><xsl:with-param name="tabdiv" select="$originating-tabdiv"/></xsl:call-template>
        
        <ixsl:schedule-action document="{$url-for-content}" wait="0">
            <xsl:call-template name="ivdnt:render-results">
                <xsl:with-param name="url-for-content" select="$url-for-content"/>
                <xsl:with-param name="tabdiv-id" select="$tabdiv-id"/>
                <xsl:with-param name="startline" select="$startline" as="xs:integer"/>
                <xsl:with-param name="originating-tabdiv" select="$originating-tabdiv"/>
                <xsl:with-param name="text-input-uri-params" select="$text-input-uri-params" tunnel="yes"/>
            </xsl:call-template>
        </ixsl:schedule-action>
    </xsl:template>
    
    <xsl:template name="ivdnt:export-result">
        <xsl:param name="url-for-content" as="xs:string" required="yes"/>
        <xsl:param name="client-filename" as="xs:string" required="yes"/>
        <xsl:param name="mimetype" as="xs:string" required="yes"/>
        
        <xsl:sequence select="js:exportResult($url-for-content, $client-filename, $mimetype)[ivdnt:always-false()]" />
    </xsl:template>
    
    <xsl:template name="ivdnt:print-result">
        <xsl:param name="url-for-content" as="xs:string" required="yes"/>
        
        <xsl:sequence select="js:openNewWindow($url-for-content)[ivdnt:always-false()]" />
    </xsl:template>
    
    <xsl:template name="ivdnt:render-results">
        <xsl:param name="url-for-content" as="xs:string" required="yes"/>
        <xsl:param name="tabdiv-id" as="xs:string" required="yes"/>
        <xsl:param name="startline" as="xs:integer" required="yes"/>
        <xsl:param name="originating-tabdiv" as="element(div)" required="yes"/>
        <xsl:param name="text-input-uri-params" as="xs:string" required="yes" tunnel="yes"/>
        
        <xsl:variable name="tabdiv" as="element()" select="key('ids', $tabdiv-id)"/>
        <xsl:result-document href="#resultaathouder" method="ixsl:replace-content">
            <xsl:if test="$showLinkToSearchResultXml">
                <div>
                    <p>Dit is de uitgerekende URL:</p>
                    <pre style="font-weight: bold"><a target="_blank" href="{$url-for-content}">{$url-for-content}</a></pre>
                </div>    
            </xsl:if>
            
            <xsl:apply-templates select="doc($url-for-content)" mode="render-results">
                <xsl:with-param name="html" select="/html"/>
                <xsl:with-param name="startline" select="$startline" as="xs:integer"/>
            </xsl:apply-templates>
            
            <xsl:for-each select="$tabdiv/parent::*/*">
                <xsl:variable name="class-without-active" select="ivdnt:remove-class-value(@class, 'active')" as="attribute(class)"/>
                <xsl:variable name="class-without-active-and-in" select="ivdnt:remove-class-value($class-without-active, 'in')" as="attribute(class)"/>
                <xsl:variable name="new-class" as="attribute(class)" select="ivdnt:add-class-values($class-without-active-and-in, if (@id eq $tabdiv-id) then ('in', 'active') else ())"/>
                <ixsl:set-attribute name="class" select="$new-class"/>
            </xsl:for-each>
        </xsl:result-document>
        
        <!--<xsl:if test="not(ivdnt:is-visited-uri($url-for-content))"><xsl:call-template name="ivdnt:reactivate-tab"><xsl:with-param name="tabdiv" select="$originating-tabdiv"/></xsl:call-template></xsl:if>-->
        <ixsl:schedule-action wait="100"><xsl:call-template name="ivdnt:reactivate-tab"><xsl:with-param name="tabdiv" select="$originating-tabdiv"/></xsl:call-template></ixsl:schedule-action>
        
        <xsl:call-template name="ivdnt:add-visited-uri">
            <xsl:with-param name="uri" select="$url-for-content"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="a[@data-showhidegroup]" mode="ixsl:onclick">
        <!-- Toon/verberg het eerstvolgende div met overeenkomstige @data-showhidegroup; bij het tonen van een div wordt een reeds zichtbare van dezelfde
             groep weer verborgen.
        -->
        <xsl:variable name="next-div" as="element(div)" select="ivdnt:get-showhide-div(.)"/>
        <xsl:for-each select="key('showhidegroup-divs', @data-showhidegroup)">
            <xsl:choose>
                <xsl:when test=". is $next-div">
                    <xsl:choose>
                        <xsl:when test="ivdnt:gtb-is-hidden(.)">
                            <xsl:call-template name="ivdnt:gtb-show"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="ivdnt:gtb-hide"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="ivdnt:gtb-hide"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:function name="ivdnt:woordsoortvalue" as="xs:string">
        <xsl:param name="context" as="node()"/>
        <xsl:variable name="topdiv" select="$context/ancestor::div[@data-modaltype eq 'woordsoortzoeken'][1]"/>
        <xsl:variable name="values" as="xs:string*">
            <xsl:for-each select="$topdiv//div[@data-hoofdwoordsoort][.//input[ivdnt:is-checked(.)]]">
                <xsl:variable name="input-values" as="xs:string+" select="for $i in .//input[ivdnt:is-checked(.)] return ivdnt:get-input-value($i)"/>
                <xsl:variable name="input-values-joined" as="xs:string" select="string-join($input-values, '|')"/>
                <xsl:variable name="input-values-searchstring" as="xs:string" select="if ($input-values-joined eq '') then '' else '&lt;' || $input-values-joined || '&gt;'"/>

                <xsl:value-of select="@data-hoofdwoordsoort || $input-values-searchstring || '.'"/>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:value-of select="string-join($values, ' ')"/>
    </xsl:function>
    
    
    <!-- Return the names and (url-encoded) values of all text inputs below $topdiv. Each name is linked to a value with an = sign. All name-value-pairs are separated by an ampersand. -->
    <xsl:function name="ivdnt:get-value-inputs-for-url" as="xs:string">
        <xsl:param name="topdiv" as="element(div)"/>
        <xsl:variable name="values" as="xs:string*">
            <xsl:for-each select="$topdiv//*[self::select | self::input[@type eq 'text']]">
                <xsl:variable name="name" as="xs:string" select="@name"/>
                <xsl:variable name="value" as="xs:string" select="normalize-space(ivdnt:get-input-value(.))"/>
                <xsl:sequence select="if ($value eq '') then () else $name || '=' || encode-for-uri($value)"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="domeininput" as="element()?" select="$topdiv//input[@type eq 'radio' and @name eq 'domein' and ivdnt:is-checked(.)]"/>
        <xsl:variable name="domein" as="xs:integer" select="if ($domeininput) then xs:integer(ivdnt:get-input-value($domeininput)) else 0"/>
        <xsl:value-of select="string-join($values, '&amp;') || '&amp;domein=' || $domein"/>
    </xsl:function>
    
    <!-- Return the (url-encoded) names of all checkboxes below $topdiv that have @data-inputname="wdb" and that are checked. The names are separated by comma's. -->
    <xsl:function name="ivdnt:get-wdb-inputs-for-url" as="xs:string">
        <xsl:param name="topdiv" as="element(div)"/>
        <xsl:variable name="names" as="xs:string+">
            <xsl:for-each select="$topdiv//input[@type eq 'checkbox' and @data-inputname eq 'wdb' and ivdnt:is-checked(.)]">
                <xsl:value-of select="@name"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="encode-for-uri(string-join($names, ','))"/>
    </xsl:function>
    
    <!-- Return sensitive=true or sensitive=false depending on the checkedness of the corresponding checkbox. -->
    <xsl:function name="ivdnt:get-sensitivity-for-url" as="xs:string">
        <xsl:param name="topdiv" as="element(div)"/>
        <xsl:variable name="sensitive" as="element(input)?" select="$topdiv//input[@type eq 'checkbox' and @data-inputname eq 'sensitive' and ivdnt:is-checked(.)]"/>
        <xsl:value-of select="'sensitive=' || exists($sensitive)"/>
    </xsl:function>
    
    <xsl:function name="ivdnt:get-zoeken-url" as="xs:string">
        <xsl:param name="topdiv" as="element(div)"/>
        <xsl:variable name="text-inputs" as="xs:string" select="ivdnt:get-value-inputs-for-url($topdiv)"/>
        <xsl:variable name="wdb-inputs" as="xs:string" select="ivdnt:get-wdb-inputs-for-url($topdiv)"/>
        <xsl:variable name="sensitivity" as="xs:string" select="ivdnt:get-sensitivity-for-url($topdiv)"/>
        <!-- TODO dynamically determine other-params. -->
        <xsl:variable name="other-params" as="xs:string" select="'&amp;conc=true&amp;xmlerror=true'"/>
        <xsl:value-of select="$baseSearchURL || $other-params || '&amp;' || $text-inputs || '&amp;wdb=' || $wdb-inputs || '&amp;' || $sensitivity"/>
    </xsl:function>
    
    <!--<xsl:function name="ivdnt:get-typeahead-url" as="xs:string">
        <xsl:param name="topdiv" as="element(div)"/>
        <xsl:param name="current-textfield" as="element(input)"/>
        <xsl:variable name="wdb-inputs" as="xs:string" select="ivdnt:get-wdb-inputs-for-url($topdiv)"/>
        <xsl:variable name="sensitivity" as="xs:string" select="ivdnt:get-sensitivity-for-url($topdiv)"/>
        <xsl:variable name="prefix" as="xs:string" select="encode-for-uri(ivdnt:get-input-value($current-textfield))"/>
        <!-\- TODO dynamically determine other-params. -\->
        <xsl:variable name="other-params" as="xs:string" select="'&amp;xmlerror=true'"/>
        <xsl:value-of select="$baseListURL || $other-params || '&amp;prefix=' || $prefix || '&amp;index=' || $current-textfield/@name || '&amp;wdb=' || $wdb-inputs || '&amp;' || $sensitivity"/>
    </xsl:function>-->
    
    <xsl:function name="ivdnt:get-target-input" as="element(input)">
        <xsl:param name="data-target-id" as="xs:string"/>
        <xsl:sequence select="ixsl:page()//input[@data-modal-target-id eq $data-target-id][1]"/>
    </xsl:function>
    
    <xsl:template match="button[@data-dismiss eq 'modal' and not(ivdnt:class-contains(@class, 'close'))]" mode="ixsl:onclick">
        <xsl:variable name="target-input-name" as="xs:string?" select="ancestor::div[@data-target-input][1]/@data-target-input"/>
        
        <xsl:if test="$target-input-name">
            <xsl:variable name="target-input" as="element(input)" select="ivdnt:get-target-input($target-input-name)"/>
            <xsl:variable name="target-input-value" as="xs:string" select="ivdnt:get-input-value($target-input)"/>
            <xsl:variable name="target-input-value" as="xs:string" select="if ($target-input-value eq '') then '' else $target-input-value || ' '"/>
            
            <ixsl:set-property name="value" select="$target-input-value || ivdnt:woordsoortvalue(.)" object="$target-input"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="button[ivdnt:class-contains(@class, 'woordsoortassistentieknop')]" mode="ixsl:onclick">
        <xsl:variable name="topdiv" as="element(div)" select="id(ivdnt:strip-hash-from-id(@data-target))"/>
        <xsl:for-each select="$topdiv//input[@type eq 'checkbox' and ivdnt:is-checked(.)]">
            <xsl:call-template name="ivdnt:uncheck"><xsl:with-param name="checkbox" select="."/></xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="ivdnt:doe-zoeken">
        <xsl:param name="topdiv" as="element(div)" required="yes"/>
        <xsl:call-template name="ivdnt:select-tab">
            <xsl:with-param name="tabid" select="'resultaat'"/>
            <xsl:with-param name="url-for-content" select="ivdnt:get-zoeken-url($topdiv)"/>
            <xsl:with-param name="text-input-uri-params" as="xs:string" select="ivdnt:get-value-inputs-for-url($topdiv)" tunnel="yes"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="div[ivdnt:class-contains(@class, $ZOEK_FORMULIER_CLASS)]" mode="ixsl:onkeypress">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:if test="xs:integer(ixsl:get($event, 'which')) eq 13">
            <!-- User pressed enter -->
            <xsl:call-template name="ivdnt:doe-zoeken">
                <xsl:with-param name="topdiv" select="."/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <xsl:function name="ivdnt:get-url-for-content" as="xs:string">
        <xsl:variable name="url-for-content" as="xs:string" select="ixsl:get(ixsl:page(), $URL_FOR_CONTENT_PROPERTY)"/>
        <xsl:variable name="sortkeys" as="xs:string" select="ixsl:get(ixsl:page(), $RESULT_SORTKEYS_PROPERTY)"/>
        <xsl:choose>
            <xsl:when test="$sortkeys ne ''">
                <xsl:value-of select="$url-for-content || '&amp;sort=' || encode-for-uri($sortkeys) || '&amp;reverse=' || ixsl:get(ixsl:page(), $RESULT_SORTREVERSE_PROPERTY)"/>
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="$url-for-content"/></xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:template match="a[@data-startline]" mode="ixsl:onclick">
        <xsl:variable name="url-for-content" as="xs:string" select="ivdnt:get-url-for-content()"/>
        <xsl:variable name="text-input-uri-params" as="xs:string" select="ixsl:get(ixsl:page(), $TEXT_INPUT_URI_PARAMS_PROPERTY)"/>
        <xsl:variable name="tabdiv-id" as="xs:string" select="ixsl:get(ixsl:page(), $RESULT_TABDIV_ID_PROPERTY)"/>
        
        <xsl:variable name="url" as="xs:string" select="$url-for-content || '&amp;start=' || @data-startline"/>
        
        <xsl:variable name="current-tab" as="element(div)" select="ivdnt:get-active-tabdiv(.)"/>
        
        <xsl:call-template name="ivdnt:show-results">
            <xsl:with-param name="url-for-content" select="$url"/>
            <xsl:with-param name="tabdiv-id" select="$tabdiv-id"/>
            <xsl:with-param name="startline" select="@data-startline" as="xs:integer"/>
            <xsl:with-param name="originating-tabdiv" select="$current-tab"/>
            <xsl:with-param name="text-input-uri-params" select="$text-input-uri-params" tunnel="yes"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="button[@name eq 'start-zoeken']" mode="ixsl:onclick">
        <xsl:variable name="topdiv" as="element(div)" select="ancestor::div[ivdnt:class-contains(@class, $ZOEK_FORMULIER_CLASS)][1]"/>
        <xsl:call-template name="ivdnt:doe-zoeken">
            <xsl:with-param name="topdiv" select="$topdiv"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="button[@name eq 'wis-zoeken']" mode="ixsl:onclick">
        <xsl:variable name="topdiv" as="element(div)" select="ancestor::div[ivdnt:class-contains(@class, $ZOEK_FORMULIER_CLASS)][1]"/>
        <xsl:for-each select="$topdiv//input[@type eq 'text']">
            <ixsl:set-property name="value" select="''" object="."/>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="button[@name eq 'wis-sorteren']" mode="ixsl:onclick">
        <xsl:variable name="topdiv" as="element(div)" select="ancestor::div[@data-modaltype eq 'sorteren'][1]"/>
        <xsl:for-each select="$topdiv//select">
            <ixsl:set-property name="value" select="option[1]/@value" object="."/>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="button[@name eq 'doe-sorteren']" mode="ixsl:onclick">
        <xsl:variable name="topdiv" as="element(div)" select="ancestor::div[@data-modaltype eq 'sorteren'][1]"/>
        <xsl:variable name="keys" as="xs:string*" select="for $select in $topdiv//select return ivdnt:get-input-value($select)[. ne '']"/>
        <xsl:variable name="value-of-reversed-input" as="xs:string" select="ivdnt:get-input-value($topdiv//input[@name eq 'sorteervolgorde' and ivdnt:is-checked(.)])"/>
        <xsl:variable name="reversed" as="xs:string" select="if ($value-of-reversed-input eq 'aflopend') then 'true' else 'false'"/>
        
        <xsl:choose>
            <xsl:when test="count($keys) gt 0">
                <ixsl:set-property name="{$RESULT_SORTKEYS_PROPERTY}" select="string-join($keys, ',')" object="ixsl:page()"/>
                <ixsl:set-property name="{$RESULT_SORTREVERSE_PROPERTY}" select="$reversed"  object="ixsl:page()"/>
            </xsl:when>
        </xsl:choose>
        
        <xsl:variable name="url-for-content" as="xs:string" select="ivdnt:get-url-for-content()"/>
        <xsl:variable name="text-input-uri-params" as="xs:string" select="ixsl:get(ixsl:page(), $TEXT_INPUT_URI_PARAMS_PROPERTY)"/>

        <!-- We kunnen current-tab niet berekenen met ivdnt:get-active-tabdiv() omdat we in de auxiliaries-div zitten en niet binnen
             een echte tab.
        -->
        <xsl:variable name="current-tab" as="element(div)" select="key('ids', 'resultaathouder')/parent::div"/>
        <xsl:variable name="tabdiv-id" as="xs:string" select="$current-tab/@id"/>
        
        <xsl:call-template name="ivdnt:show-results">
            <xsl:with-param name="url-for-content" select="$url-for-content"/>
            <xsl:with-param name="tabdiv-id" select="$tabdiv-id"/>
            <xsl:with-param name="startline" select="1" as="xs:integer"/>
            <xsl:with-param name="originating-tabdiv" select="$current-tab"/>
            <xsl:with-param name="text-input-uri-params" select="$text-input-uri-params" tunnel="yes"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="select[matches(@name, '^sleutel[1-4]$')]" mode="ixsl:onchange">
        <xsl:variable name="thisSelect" as="element(select)" select="."/>
        <xsl:variable name="topdiv" as="element(div)" select="ancestor::div[@id eq 'sleutels'][1]"/>
        <xsl:variable name="thisSelectValue" select="ivdnt:get-input-value($thisSelect)"/>
        <xsl:variable name="allSelectedValues" as="xs:string*" select="for $s in $topdiv//select return ivdnt:get-input-value($s)"/>
        <xsl:for-each select="$topdiv//select/option[@value ne '']">
            <xsl:choose>
                <xsl:when test="@value = $allSelectedValues">
                    <xsl:choose>
                        <xsl:when test="parent::select is $thisSelect and @value eq $thisSelectValue">
                            <ixsl:remove-attribute name="disabled"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <ixsl:set-attribute name="disabled" select="'disabled'"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <ixsl:remove-attribute name="disabled"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="button[@name eq 'doe-exporteren']" mode="ixsl:onclick">
        <xsl:variable name="topdiv" as="element(div)" select="ancestor::div[@data-modaltype eq 'exporteren'][1]"/>
        <xsl:variable name="value-of-format-input" as="xs:string" select="ivdnt:get-input-value($topdiv//input[@name eq 'uitvoer' and ivdnt:is-checked(.)])"/>
        
        <xsl:variable name="url-for-content" as="xs:string" select="ivdnt:get-url-for-content() || '&amp;uitvoer=' || $value-of-format-input"/>
        
        <xsl:call-template name="ivdnt:export-result">
            <xsl:with-param name="url-for-content" select="$url-for-content"/>
            <xsl:with-param name="client-filename" select="'gtb-export.' || $value-of-format-input"/>
            <xsl:with-param name="mimetype" select="'text/' || $value-of-format-input"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="button[@name eq 'doe-afdrukken']" mode="ixsl:onclick">
        <xsl:variable name="url-for-content" as="xs:string" select="ivdnt:get-url-for-content() || '&amp;uitvoer=printhtml'"/>
        
        <xsl:call-template name="ivdnt:print-result">
            <xsl:with-param name="url-for-content" select="$url-for-content"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="input[@name eq 'toon-tekens']" mode="ixsl:onclick">
        <xsl:variable name="parentdiv" select="following::div[ivdnt:class-contains(@class, 'speciaalteken')][1]" as="element(div)"/>
        <xsl:variable name="is-checked" as="xs:boolean" select="ivdnt:is-checked(.)"/>
        <xsl:for-each select="$parentdiv//tr[ivdnt:class-contains(@class, 'collapse')]">
            <xsl:choose>
                <xsl:when test="$is-checked">
                    <ixsl:set-attribute name="class" select="ivdnt:replace-class-value(@class, 'out', 'in')"/>
                </xsl:when>
                <xsl:otherwise>
                    <ixsl:set-attribute name="class" select="ivdnt:replace-class-value(@class, 'in', 'out')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="td[ivdnt:class-contains(@class, 'speciaalteken')]" mode="ixsl:onclick">
        <xsl:variable name="char" as="xs:string" select="text()"/>
        
        <xsl:variable name="focussed-textbox" as="element(input)?" select="ixsl:get(ixsl:page(), $FOCUSSED_TEXTBOX_PROPERTY)"/>
        <xsl:variable name="textbox" as="element(input)" select="if ($focussed-textbox) then $focussed-textbox else following::input[@type eq 'text'][1]"/>
        <xsl:if test="$textbox">
            <!-- We laten het type achterwege bij selStart en selEnd. In Chrome is het double, is dat overal zo? Je zou integer verwachten. -->
            <xsl:variable name="selStart" select="ixsl:get($textbox, 'selectionStart')"/>
            <xsl:variable name="selEnd" select="ixsl:get($textbox, 'selectionEnd')"/>
            <xsl:variable name="text" as="xs:string" select="ixsl:get($textbox, 'value')"/>
            <xsl:variable name="newtext" as="xs:string" select="substring($text, 1, $selStart) || $char || substring($text, $selEnd+1)"/>
            <ixsl:set-property name="value" select="$newtext" object="$textbox"/>
            <xsl:variable name="newSelStart" select="$selStart + string-length($char)"/>
            <ixsl:set-property name="selectionEnd" select="$newSelStart" object="$textbox"/>
            <!-- Set focus and show the caret. The predicate below with current-date() always returns false, thus making sure that the result of ixsl:call() is not put into the result. -->
            <xsl:sequence select="ixsl:call($textbox, 'focus', [])[string(current-date()) eq 'nimmer']"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="input[@type eq 'text']" mode="ixsl:onfocusin">
        <!--<xsl:message select="'Text box with name ' || @name || ' just received focus'"/>-->
        <ixsl:set-property name="{$FOCUSSED_TEXTBOX_PROPERTY}" select="." object="ixsl:page()"/>
    </xsl:template>
    
</xsl:stylesheet>