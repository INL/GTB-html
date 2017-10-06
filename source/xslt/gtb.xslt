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
    <xsl:param name="baseArticleContentURL" as="xs:string" required="yes"/>
    <!-- Pass the start of the URL to which the query parameters (excluding the first part, ?actie=article_content - this is part of the parameter value) for retrieving the bron (source) will be appended: -->
    <xsl:param name="baseArticleURL" as="xs:string" required="yes"/>
    <!-- Pass (json) true or set here to true() if you want to see the full search URL (for development purposes): -->
    <xsl:param name="showLinkToSearchResultXml" as="xs:boolean" select="false()"/>
    <!-- Pass (json) true or set here to true() if you want to see the XML list containing all inputs and selects (for development purposes): -->
    <xsl:param name="showInputsAndSelectsXML" as="xs:boolean" select="false()"/>
    <!-- Number of lines in each result page. -->
    <xsl:param name="maxLinesInResultPage" as="xs:integer" select="250"/>
    <!-- The order in which the results of dictionaries get listed in the results. Used to calculate line offsets when jumping to a dictionary. Space-separated value. -->
    <xsl:param name="dictionaryOutputOrder" select="'ONW VMNW MNW WNT WFT'"/>
    
    <xsl:key name="showhidegroup-divs" match="div[@data-showhidegroup]" use="@data-showhidegroup"/>
    <xsl:key name="ids" match="*[@id]" use="@id"/>
    
    <!-- TODO Bijhouden van bezochte uri's is niet nodig. -->
    <!--<xsl:variable name="VISITED_URIS_PROPERTY" as="xs:string" select="'visited-uris'"/>-->
    <xsl:variable name="URL_FOR_CONTENT_PROPERTY" as="xs:string" select="'url-for-content'"/>
    <xsl:variable name="TEXT_INPUT_URI_PARAMS_PROPERTY" as="xs:string" select="'text-input-uri-params'"/>
    <xsl:variable name="CURRENT_QUESTION_DESCRIPTION_PROPERTY" as="xs:string" select="'current-question-description'"/>
    <xsl:variable name="FORMDIV_INPUTS_AND_SELECTS_PROPERTY" as="xs:string" select="'formdiv-inputs-and-selects'"/>
    <xsl:variable name="RESULT_TABDIV_ID_PROPERTY" as="xs:string" select="'result-tabdiv-id'"/>
    <xsl:variable name="RESULT_SORTKEYS_PROPERTY" as="xs:string" select="'result-sortkeys'"/>
    <xsl:variable name="RESULT_SORTREVERSE_PROPERTY" as="xs:string" select="'result-sortreverse'"/>
    <xsl:variable name="FOCUSSED_TEXTBOX_PROPERTY" as="xs:string" select="'focussed_textbox-id'"/>
    <xsl:variable name="ZOEK_FORMULIER_CLASS" as="xs:string" select="'zoek-formulier'"/>    

    <xsl:include href="render-results.xslt"/>
    <xsl:include href="history.xslt"/>
    <xsl:include href="events.xslt"/>
    
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
    
    <xsl:template name="ivdnt:check">
        <xsl:param name="checkbox" as="element(input)" required="yes"/>
        <ixsl:set-property name="checked" object="$checkbox" select="true()"/>
    </xsl:template>
    
    <xsl:template name="ivdnt:uncheck">
        <xsl:param name="checkbox" as="element(input)" required="yes"/>
        <ixsl:set-property name="checked" object="$checkbox" select="false()"/>
        <!-- note that <ixsl:remove-attribute name="checked"> does not work (the current context is the input, equal to parameter $checkbox, so it could have worked). -->
    </xsl:template>
    
    <!--<!-\- Return a space separated string consisting of all visited uris. Note that we attempted to use maps and arrays, but we got too many runtimes errors, so we gave up. -\->
    <xsl:function name="ivdnt:get-visited-uris" as="xs:string">
        <xsl:sequence select="ixsl:get(ixsl:page(), 'visited-uris')"/>
    </xsl:function>-->
    
    <!--<xsl:template name="ivdnt:add-visited-uri">
        <xsl:param name="uri" as="xs:string" required="yes"/>
        <xsl:variable name="oldvalue" as="xs:string" select="ivdnt:get-visited-uris()"/>
        <xsl:variable name="newvalue" as="xs:string" select="string-join(distinct-values(($oldvalue, $uri)), ' ')"/>
        <ixsl:set-property name="{$VISITED_URIS_PROPERTY}" select="$newvalue" object="ixsl:page()"/>
    </xsl:template>-->
    
    <!--<xsl:function name="ivdnt:is-visited-uri" as="xs:boolean">
        <xsl:param name="uri" as="xs:string"/>
        <xsl:variable name="visited-uris" as="xs:string" select="ivdnt:get-visited-uris()"/>
        <!-\- Test if the sequence visited-uris contains the uri: -\->
        <!-\-<xsl:message select="'ivdnt:is-visited-uri geeft: ' || ($uri = tokenize($visited-uris, ' '))"/>-\->
        <xsl:sequence select="($uri = tokenize($visited-uris, ' '))"/>
    </xsl:function>-->
    
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
        <!--<xsl:variable name="visited-uris" as="xs:string" select="''"/>
        <ixsl:set-property name="{$VISITED_URIS_PROPERTY}" select="$visited-uris" object="ixsl:page()"/>-->
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
        <xsl:param name="formdiv-inputs-and-selects" as="element(inputs-and-selects)" required="yes"/>
        
        <xsl:variable name="text-input-uri-params" as="xs:string" select="ivdnt:get-value-inputs-for-url($formdiv-inputs-and-selects)"/>
        <xsl:variable name="url-for-content" select="ivdnt:get-zoeken-url($text-input-uri-params, $formdiv-inputs-and-selects)"/>
                
        <!-- Activate the tabtitle whose id is $tabid: -->
        <xsl:variable name="result-tab-title" as="element()" select="key('ids', $tabid)"/>
        <xsl:for-each select="$result-tab-title/parent::*/*">
            <xsl:variable name="class-without-active" select="ivdnt:remove-class-value(@class, 'active')" as="attribute(class)"/>
            <ixsl:set-attribute name="class" select="ivdnt:add-class-values($class-without-active, if (@id eq $tabid) then ('active') else ())"/>
        </xsl:for-each>
        
        <!-- Activate the div whose id is equal to the href of the "resultaat" tabtitle: -->
        <xsl:variable name="tabdiv-id" as="xs:string" select="ivdnt:strip-hash-from-id($result-tab-title/a/@href)"/>
        <xsl:variable name="current-tab" as="element(div)" select="ivdnt:get-active-tabdiv(.)"/>
        
        <xsl:variable name="question-description" as="element(span)">
            <span><xsl:copy-of select="ivdnt:get-question-description($formdiv-inputs-and-selects)"/></span>
        </xsl:variable>
        <!-- Save some info for later use: -->
        <ixsl:set-property name="{$URL_FOR_CONTENT_PROPERTY}" select="$url-for-content" object="ixsl:page()"/>
        <ixsl:set-property name="{$TEXT_INPUT_URI_PARAMS_PROPERTY}" select="$text-input-uri-params" object="ixsl:page()"/>
        <ixsl:set-property name="{$CURRENT_QUESTION_DESCRIPTION_PROPERTY}" select="$question-description" object="ixsl:page()"/>
        <ixsl:set-property name="{$RESULT_TABDIV_ID_PROPERTY}" select="$tabdiv-id" object="ixsl:page()"/>
        <ixsl:set-property name="{$RESULT_SORTKEYS_PROPERTY}" select="''" object="ixsl:page()"/>
        <ixsl:set-property name="{$RESULT_SORTREVERSE_PROPERTY}" select="'false'" object="ixsl:page()"/>
        
        <!-- Store the XML representation of the inputs and selects at the originating tab div: -->
        <ixsl:set-property name="{$FORMDIV_INPUTS_AND_SELECTS_PROPERTY}" select="ivdnt:add-formdiv-inputs-and-selects($current-tab, $formdiv-inputs-and-selects)" object="$current-tab"/>
        
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
        
        <ixsl:schedule-action document="{$url-for-content}">
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
            <xsl:if test="$showInputsAndSelectsXML">
                <xsl:variable name="originating-formdiv" select="$originating-tabdiv//div[ivdnt:class-contains(@class, $ZOEK_FORMULIER_CLASS)][1]" as="element(div)"/>
                <xsl:variable name="originating-formdiv-id" select="$originating-formdiv/@id" as="xs:string"/>
                <div>
                    <p>De XML-lijst met alle inputs en selects</p>
                    <pre><xsl:copy-of select="ivdnt:get-formdiv-inputs-and-selects(/html/body, $originating-formdiv-id)"/></pre> 
                </div>
            </xsl:if>
            <xsl:if test="$showLinkToSearchResultXml">
                <div>
                    <p>Dit is de uitgerekende URL:</p>
                    <pre style="font-weight: bold"><a target="_blank" href="{$url-for-content}">{$url-for-content}</a></pre>
                </div> 
                <!--<pre>
                    <!-\- Hier het rauwe XML: -\->
                    <xsl:copy-of select="doc($url-for-content)"/>
                </pre>-->
            </xsl:if>
            
            <h4 class="gtb-zoekvraag-description">Zoekvraag: <xsl:copy-of select="ixsl:get(ixsl:page(), $CURRENT_QUESTION_DESCRIPTION_PROPERTY)"/></h4>
            
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
        
        <!--<xsl:call-template name="ivdnt:add-visited-uri">
            <xsl:with-param name="uri" select="$url-for-content"/>
        </xsl:call-template>-->
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
    
    <!-- Return the names and (url-encoded) values of all text inputs of the current form. Each name is linked to a value with an = sign. All name-value-pairs are separated by an ampersand. -->
    <xsl:function name="ivdnt:get-value-inputs-for-url" as="xs:string">
        <xsl:param name="formdiv-inputs-and-selects" as="element(inputs-and-selects)"/>
        <xsl:variable name="values" as="xs:string*">
            <xsl:for-each select="$formdiv-inputs-and-selects/input-or-select[@element eq 'select' or @type eq 'text']">
                <xsl:variable name="name" as="xs:string" select="@name"/>
                <xsl:variable name="value" as="xs:string" select="@value"/>
                <xsl:sequence select="if ($value eq '') then () else $name || '=' || encode-for-uri($value)"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="domeininput" as="element()?" select="$formdiv-inputs-and-selects/input-or-select[@type eq 'radio' and @name eq 'domein' and @checked eq 'checked']"/>
        <xsl:variable name="domein" as="xs:integer" select="if ($domeininput) then xs:integer($domeininput/@value) else 0"/>
        <xsl:value-of select="string-join($values, '&amp;') || '&amp;domein=' || $domein"/>
    </xsl:function>
    
    <!-- Return the (url-encoded) names of all checkboxes of the current form that have @data-inputname="wdb" and that are checked. The names are separated by comma's. -->
    <xsl:function name="ivdnt:get-wdb-inputs-for-url" as="xs:string">
        <xsl:param name="formdiv-inputs-and-selects" as="element(inputs-and-selects)"/>
        
        <xsl:variable name="names" as="xs:string*">
            <xsl:for-each select="$formdiv-inputs-and-selects/input-or-select[@type eq 'checkbox' and @data-inputname eq 'wdb' and @checked eq 'checked']">
                <xsl:value-of select="@name"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:if test="count($names) eq 0">
            <xsl:message>Geen woordenboeken geselecteerd</xsl:message>
        </xsl:if>
        <xsl:value-of select="encode-for-uri(string-join($names, ','))"/>
    </xsl:function>
    
    <!-- Return sensitive=true or sensitive=false depending on the checkedness of the corresponding checkbox. -->
    <xsl:function name="ivdnt:get-sensitivity-for-url" as="xs:string">
        <xsl:param name="formdiv-inputs-and-selects" as="element(inputs-and-selects)"/>
        
        <xsl:variable name="sensitive" as="element(input-or-select)?" select="$formdiv-inputs-and-selects/input-or-select[@data-inputname eq 'sensitive' and @type eq 'checkbox' and @checked eq 'checked']"/>
        <xsl:value-of select="'sensitive=' || exists($sensitive)"/>
    </xsl:function>
    
    <xsl:function name="ivdnt:get-zoeken-url" as="xs:string">
        <xsl:param name="text-input-uri-params" as="xs:string"/>
        <xsl:param name="formdiv-inputs-and-selects" as="element(inputs-and-selects)"/>
        <xsl:variable name="wdb-inputs" as="xs:string" select="ivdnt:get-wdb-inputs-for-url($formdiv-inputs-and-selects)"/>
        <xsl:variable name="sensitivity" as="xs:string" select="ivdnt:get-sensitivity-for-url($formdiv-inputs-and-selects)"/>
        <!-- TODO dynamically determine other-params. -->
        <xsl:variable name="other-params" as="xs:string" select="'&amp;conc=true&amp;xmlerror=true'"/>
        <xsl:value-of select="$baseSearchURL || $other-params || '&amp;' || $text-input-uri-params || '&amp;wdb=' || $wdb-inputs || '&amp;' || $sensitivity"/>
    </xsl:function>
    
    <xsl:function name="ivdnt:get-target-input" as="element(input)">
        <xsl:param name="data-target-id" as="xs:string"/>
        <xsl:sequence select="ixsl:page()//input[@data-modal-target-id eq $data-target-id][1]"/>
    </xsl:function>
    
    <xsl:template name="ivdnt:doe-zoeken">
        <xsl:param name="formdiv" as="element(div)" required="yes"/>
        
        <xsl:variable name="formdiv-id" as="xs:string" select="$formdiv/@id"/>
        <xsl:variable name="formdiv-inputs-and-selects" as="element(inputs-and-selects)" select="ivdnt:get-formdiv-inputs-and-selects(/html/body, $formdiv-id)"/>
        <xsl:variable name="text-input-uri-params" as="xs:string" select="ivdnt:get-value-inputs-for-url($formdiv-inputs-and-selects)"/>
        
        <xsl:call-template name="ivdnt:select-tab">
            <xsl:with-param name="tabid" select="'resultaat'"/>
            <xsl:with-param name="formdiv-inputs-and-selects" select="$formdiv-inputs-and-selects"/>
        </xsl:call-template>
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
    
</xsl:stylesheet>