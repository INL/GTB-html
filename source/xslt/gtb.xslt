<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:ivdnt="http://www.ivdnt.org/xslt/namespaces"
    exclude-result-prefixes="xs math"
    expand-text="yes"
    version="3.0">
    
    <!-- Using camel case instead of hyphens for parameters reduces the need for JSON escaping when
         passing parameters to this stylesheet.
    -->
    
    <!-- Pass the start of the URL to which the query parameters (excluding the first part, ?actie=results - this is part of the parameter value) for searching will be appended: -->
    <xsl:param name="baseSearchURL" as="xs:string" required="yes"/>
    <!-- Pass the start of the URL to which the query parameters (excluding the first part, ?actie=article - this is part of the parameter value) for retrieving the article will be appended: -->
    <xsl:param name="baseArticleURL" as="xs:string" required="yes"/>
    <!-- Pass (json) true or set here to true() if you want to see the full search URL (for development purposes): -->
    <xsl:param name="showLinkToSearchResultXml" as="xs:boolean" select="false()"/>
    <!-- Number of lines in each result page. -->
    <xsl:param name="maxLinesInResultPage" as="xs:integer" select="250"/>
    <!-- The order in which the results of dictionaries get listed in the results. Used to calculate line offsets when jumping to a dictionary. Space-separated value. -->
    <xsl:param name="dictionaryOutputOrder" select="'ONW VMNW MNW WNT WFT'"/>
    
    <xsl:key name="showhidegroup-divs" match="div[@data-showhidegroup]" use="@data-showhidegroup"/>
    <xsl:key name="ids" match="*[@id]" use="@id"/>
    
    <xsl:include href="render-results.xslt"/>
    
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
    
    <xsl:function name="ivdnt:input-value" as="xs:string">
        <xsl:param name="input" as="element(input)"/>
        <xsl:sequence select="ixsl:get($input, 'value')"/>
    </xsl:function>
    
    <xsl:template name="ivdnt:uncheck">
        <xsl:param name="checkbox" as="element(input)" required="yes"/>
        <ixsl:set-property name="checked" object="$checkbox" select="false()"/>
        <!-- note that <ixsl:remove-attribute name="checked"> does not work (the current context is the input, equal to parameter $checkbox, so it could have worked). -->
    </xsl:template>
    
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
    
    <xsl:function name="ivdnt:add-random-to-url" as="xs:string">
        <xsl:param name="url" as="xs:string"/>
        <!-- Uitgeschakeld, sinds deze toevoeging zien we in het console van Chrome steeds het volgende:
            
             Deprecation] Synchronous XMLHttpRequest on the main thread is deprecated because of its detrimental effects to the end user's experience. For more help, check https://xhr.spec.whatwg.org/.
             
             Tevens lijkt de applicatie bij het opvragen van een URL regelmatig te hangen.
        -->
        <!--<xsl:variable name="random" select="js:gtbRandom()" xmlns:js="http://saxonica.com/ns/globalJS"/>
        <!-\- De %5F%5Flzbc%5F%5F (__lzbc__) is een erfenis van OpenLaszlo -\->
        <xsl:variable name="param" select="'%5F%5Flzbc%5F%5F=' || encode-for-uri(string($random))"/>
        <xsl:value-of select="if (contains($url, '?')) then substring-before($url, '?') || '?' || $param || '&amp;' || substring-after($url, '?') else $url || '?' || $param"/>-->
        <xsl:value-of select="$url"/>
    </xsl:function>
    
    <xsl:template name="initialize">
        <!-- Nothing (yet) -->
    </xsl:template>
    
    <xsl:template name="ivdnt:gtb-collapse">
        <xsl:for-each select="ivdnt:get-showhide-a(.)">
            <!-- This iterates only once. -->
            <ixsl:set-attribute name="class" select="ivdnt:replace-class-value(@class, 'gtbexpanded', 'gtbcollapsed')"/>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="ivdnt:gtb-expand">
        <xsl:for-each select="ivdnt:get-showhide-a(.)">
            <!-- Dit itereert slecht 1 keer -->
            <ixsl:set-attribute name="class" select="ivdnt:replace-class-value(@class, 'gtbcollapsed', 'gtbexpanded')"/>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="ivdnt:gtb-hide">
        <!-- Huidige context is een div-element dat wordt ingeklapt.
             We gebruiken een eigen class in plaats van die van Bootstrap om te zorgen dat we beide namen kunnen
             gebruiken zonder eventuele gekoppelde GTB-logica in XSLT of Javascript te verstoren.
        -->
        <ixsl:set-attribute name="class" select="ivdnt:add-class-values(@class, 'gtbhidden')"/>
        <!-- Pas ook de de weergave aan van link die voor het inklappen zorgt: -->
        <xsl:call-template name="ivdnt:gtb-collapse"/>
    </xsl:template>
    
    <xsl:template name="ivdnt:gtb-show">
        <!-- Huidige context is een div-element dat wordt uitgeklapt. -->
        <ixsl:set-attribute name="class" select="ivdnt:remove-class-value(@class, 'gtbhidden')"/>
        <!-- Pas ook de de weergave aan van link die voor het uitklappen zorgt: -->
        <xsl:call-template name="ivdnt:gtb-expand"/>
    </xsl:template>
    
    <xsl:function name="ivdnt:gtb-is-hidden" as="xs:boolean">
        <xsl:param as="element()" name="element"/>
        <xsl:sequence select="ivdnt:class-contains($element/@class, 'gtbhidden')"/>
    </xsl:function>
    
    <xsl:template name="ivdnt:deactivate-tab">
        <xsl:param name="tabdiv" as="element(div)" required="yes"/>
        <xsl:for-each select="$tabdiv">
            <!-- Only one iteration -->
            <!--<xsl:message>deactivate id={@id}</xsl:message>-->
            <ixsl:set-attribute name="class" select="ivdnt:add-class-values(@class, 'gtbdisabled')"/>
            
            <!-- Genereer een div met de wait-button of maak hem zichtbaar. In eerste instantie genereerden we dit divje bij het maken van de HTML-file,
                 maar aangezien de inhoud van de result-tabbladen weer opnieuw wordt gegenereerd, heeft dit daar geen zin:
            -->
            <xsl:variable name="waitdiv" as="element(div)?" select="div[ivdnt:class-contains(@class, 'gtbwait')]"/>
            <xsl:choose>
                <xsl:when test="$waitdiv">
                    <!-- Show it: -->
                    <!--<xsl:message>deactivate (exists), class={@class}</xsl:message>-->
                    <xsl:for-each select="$waitdiv"><ixsl:set-attribute name="class" select="ivdnt:remove-class-value(@class, 'gtbhidden')"/></xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <!-- Create it: -->
                    <xsl:result-document href="?." method="ixsl:append-content">
                        <!--<xsl:message>deactivate (does not exist)</xsl:message>-->
                        <div class="gtbwait">
                            <!-- TODO waarom draait het icoontje niet? Cf. https://www.bootply.com/128062 -->
                            <button class="btn btn-lg btn-info"><span class="glyphicon glyphicon-refresh glyphicon-refresh-animate"></span>&#160;Even geduld a.u.b. ...</button>
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
            <ixsl:set-attribute name="class" select="ivdnt:remove-class-value(@class, 'gtbdisabled')"/>
            
            <!-- Maak de div met de wait-button onzichtbaar (vergelijk template deactivate-tab);
                 als de content van de tab opnieuw gegenereerd is, doet dit niets (er is dan
                 namelijk geen match meer). Onzichtbaar maken is makkelijker dan geheel weghalen,
                 vandaar deze keuze.
            -->
            <xsl:for-each select="div[ivdnt:class-contains(@class, 'gtbwait')]">
                <!-- Also, one iteration. -->
                <!--<xsl:message>reactivate eerst class={@class}</xsl:message>-->
                <ixsl:set-attribute name="class" select="ivdnt:add-class-values(@class, 'gtbhidden')"/>
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
        <xsl:variable name="tabdiv-id" as="xs:string" select="substring-after($result-tab-title/a/@href, '#')"/>
        
        <!-- Save some info for use by pagination: -->
        <ixsl:set-property name="url-for-content" select="$url-for-content" object="ixsl:page()"/>
        <ixsl:set-property name="text-input-uri-params" select="$text-input-uri-params" object="ixsl:page()"/>
        <ixsl:set-property name="result-tabdiv-id" select="$tabdiv-id" object="ixsl:page()"/>
        
        <xsl:variable name="current-tab" as="element(div)" select="ivdnt:get-active-tabdiv(.)"/>
        <xsl:call-template name="ivdnt:deactivate-tab"><xsl:with-param name="tabdiv" select="$current-tab"/></xsl:call-template>

        <ixsl:schedule-action document="{$url-for-content}" wait="0">
            <xsl:call-template name="ivdnt:render-results">
                <xsl:with-param name="url-for-content" select="$url-for-content"/>
                <xsl:with-param name="tabdiv-id" select="$tabdiv-id"/>
                <xsl:with-param name="startline" select="1" as="xs:integer"/>
                <xsl:with-param name="originating-tabdiv" select="$current-tab"/>
            </xsl:call-template>
        </ixsl:schedule-action>
    </xsl:template>
    
    <xsl:template name="ivdnt:render-results">
        <xsl:param name="url-for-content" as="xs:string" required="yes"/>
        <xsl:param name="tabdiv-id" as="xs:string" required="yes"/>
        <xsl:param name="startline" as="xs:integer" required="yes"/>
        <xsl:param name="originating-tabdiv" as="element(div)" required="yes"/>
        
        <xsl:variable name="randomized-url" select="ivdnt:add-random-to-url($url-for-content)" as="xs:string"/>
        <!--<xsl:message select="'randomized-url' || $randomized-url"/>-->
        
        <xsl:variable name="tabdiv" as="element()" select="key('ids', $tabdiv-id)"/>
        <xsl:result-document href="{'#' || $tabdiv-id}" method="ixsl:replace-content">
            <xsl:if test="$showLinkToSearchResultXml">
                <div>
                    <p>Dit is de uitgerekende URL:</p>
                    <pre style="font-weight: bold"><a target="_blank" href="{$randomized-url}">{$randomized-url}</a></pre>
                </div>    
            </xsl:if>
            
            <xsl:apply-templates select="doc($randomized-url)" mode="render-results">
                <xsl:with-param name="startline" select="$startline" as="xs:integer"/>
            </xsl:apply-templates>
            
            <xsl:for-each select="$tabdiv/parent::*/*">
                <xsl:variable name="class-without-active" select="ivdnt:remove-class-value(@class, 'active')" as="attribute(class)"/>
                <xsl:variable name="class-without-active-and-in" select="ivdnt:remove-class-value($class-without-active, 'in')" as="attribute(class)"/>
                <xsl:variable name="new-class" as="attribute(class)" select="ivdnt:add-class-values($class-without-active-and-in, if (@id eq $tabdiv-id) then ('in', 'active') else ())"/>
                <ixsl:set-attribute name="class" select="$new-class"/>
            </xsl:for-each>
        </xsl:result-document>
        
        <xsl:call-template name="ivdnt:reactivate-tab"><xsl:with-param name="tabdiv" select="$originating-tabdiv"/></xsl:call-template>
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
        <xsl:variable name="topdiv" select="$context/ancestor::div[@data-modaltype eq 'basiszoeken-woordsoort'][1]"/>
        <xsl:variable name="values" as="xs:string*">
            <xsl:for-each select="$topdiv//div[@data-hoofdwoordsoort][.//input[ivdnt:is-checked(.)]]">
                <xsl:variable name="input-values" as="xs:string+" select="for $i in .//input[ivdnt:is-checked(.)] return ivdnt:input-value($i)"/>
                <xsl:variable name="input-values-joined" as="xs:string" select="string-join($input-values, '|')"/>
                <xsl:variable name="input-values-searchstring" as="xs:string" select="if ($input-values-joined eq '') then '' else '&lt;' || $input-values-joined || '&gt;'"/>

                <xsl:value-of select="@data-hoofdwoordsoort || $input-values-searchstring || '.'"/>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:value-of select="string-join($values, ' ')"/>
    </xsl:function>
    
    
    <!-- Return the names and (url-encoded) values of all text inputs below $topdiv. Each name is linked to a value with an = sign. All name-value-pairs are separated by an ampersand. -->
    <xsl:function name="ivdnt:get-text-inputs-for-url" as="xs:string">
        <xsl:param name="topdiv" as="element(div)"/>
        <xsl:variable name="values" as="xs:string*">
            <xsl:for-each select="$topdiv//input[@type eq 'text']">
                <xsl:variable name="name" as="xs:string" select="@name"/>
                <xsl:variable name="value" as="xs:string" select="normalize-space(ivdnt:input-value(.))"/>
                <xsl:sequence select="if ($value eq '') then () else $name || '=' || encode-for-uri($value)"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="string-join($values, '&amp;')"/>
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
    
    <xsl:function name="ivdnt:get-basiszoeken-url" as="xs:string">
        <xsl:param name="topdiv" as="element(div)"/>
        <xsl:variable name="text-inputs" as="xs:string" select="ivdnt:get-text-inputs-for-url($topdiv)"/>
        <xsl:variable name="wdb-inputs" as="xs:string" select="ivdnt:get-wdb-inputs-for-url($topdiv)"/>
        <xsl:variable name="sensitivity" as="xs:string" select="ivdnt:get-sensitivity-for-url($topdiv)"/>
        <!-- TODO dynamically determine other-params. -->
        <xsl:variable name="other-params" as="xs:string" select="'&amp;domein=0&amp;conc=true&amp;xmlerror=true'"/>
        <xsl:value-of select="$baseSearchURL || $other-params || '&amp;' || $text-inputs || '&amp;wdb=' || $wdb-inputs || '&amp;' || $sensitivity"/>
    </xsl:function>
    
    <xsl:function name="ivdnt:get-target-input" as="element(input)">
        <xsl:param name="inputname" as="xs:string"/>
        <xsl:sequence select="ixsl:page()//input[@name eq $inputname][1]"/>
    </xsl:function>
    
    <xsl:template match="button[@data-dismiss eq 'modal' and not(ivdnt:class-contains(@class, 'close'))]" mode="ixsl:onclick">
        <xsl:variable name="target-input-name" as="xs:string" select="ancestor::div[@data-target-input][1]/@data-target-input"/>
        <xsl:variable name="target-input" as="element(input)" select="ivdnt:get-target-input($target-input-name)"/>
        <xsl:variable name="target-input-value" as="xs:string" select="ivdnt:input-value($target-input)"/>
        <xsl:variable name="target-input-value" as="xs:string" select="if ($target-input-value eq '') then '' else $target-input-value || ' '"/>

        <ixsl:set-property name="value" select="$target-input-value || ivdnt:woordsoortvalue(.)" object="$target-input"/>
    </xsl:template>
    
    <xsl:template match="button[ivdnt:class-contains(@class, 'woordsoortassistentieknop')]" mode="ixsl:onclick">
        <xsl:variable name="topdiv" as="element(div)" select="following::div[@data-modaltype eq 'basiszoeken-woordsoort'][1]"/>
        <xsl:for-each select="$topdiv//input[@type eq 'checkbox' and ivdnt:is-checked(.)]">
            <xsl:call-template name="ivdnt:uncheck"><xsl:with-param name="checkbox" select="."/></xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="ivdnt:doe-basiszoeken">
        <xsl:param name="topdiv" as="element(div)" required="yes"/>
        <xsl:call-template name="ivdnt:select-tab">
            <xsl:with-param name="tabid" select="'resultaat'"/>
            <xsl:with-param name="url-for-content" select="ivdnt:get-basiszoeken-url($topdiv)"/>
            <xsl:with-param name="text-input-uri-params" as="xs:string" select="ivdnt:get-text-inputs-for-url($topdiv)" tunnel="yes"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="div[ivdnt:class-contains(@class, 'basiszoeken-formulier')]" mode="ixsl:onkeypress">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:if test="xs:integer(ixsl:get($event, 'which')) eq 13">
            <!-- User pressed enter -->
            <xsl:call-template name="ivdnt:doe-basiszoeken">
                <xsl:with-param name="topdiv" select="."/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="a[@data-startline]" mode="ixsl:onclick">
        <xsl:variable name="url-for-content" as="xs:string" select="ixsl:get(ixsl:page(), 'url-for-content')"/>
        <xsl:variable name="text-input-uri-params" as="xs:string" select="ixsl:get(ixsl:page(), 'text-input-uri-params')"/>
        <xsl:variable name="tabdiv-id" as="xs:string" select="ixsl:get(ixsl:page(), 'result-tabdiv-id')"/>
        
        <xsl:variable name="url" as="xs:string" select="$url-for-content || '&amp;start=' || @data-startline"/>
        
        <xsl:variable name="current-tab" as="element(div)" select="ivdnt:get-active-tabdiv(.)"/>
        <xsl:call-template name="ivdnt:deactivate-tab"><xsl:with-param name="tabdiv" select="$current-tab"/></xsl:call-template>
        
        <!--<xsl:message select="'url=' || $url || ', startline=' || @data-startline"/>-->
        <ixsl:schedule-action document="{$url}" wait="0">
            <xsl:call-template name="ivdnt:render-results">
                <xsl:with-param name="url-for-content" select="$url"/>
                <xsl:with-param name="tabdiv-id" select="$tabdiv-id"/>
                <xsl:with-param name="startline" select="@data-startline" as="xs:integer"/>
                <xsl:with-param name="originating-tabdiv" select="$current-tab"/>
                <xsl:with-param name="text-input-uri-params" select="$text-input-uri-params" tunnel="yes"/>
            </xsl:call-template>
        </ixsl:schedule-action>
    </xsl:template>
    
    <xsl:template match="button[@name eq 'start-zoeken']" mode="ixsl:onclick">
        <xsl:variable name="topdiv" as="element(div)" select="ancestor::div[ivdnt:class-contains(@class, 'basiszoeken-formulier')][1]"/>
        <xsl:call-template name="ivdnt:doe-basiszoeken">
            <xsl:with-param name="topdiv" select="$topdiv"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="button[@name eq 'wis-zoeken']" mode="ixsl:onclick">
        <xsl:variable name="topdiv" as="element(div)" select="ancestor::div[ivdnt:class-contains(@class, 'basiszoeken-formulier')][1]"/>
        <xsl:for-each select="$topdiv//input[@type eq 'text']">
            <ixsl:set-property name="value" select="''" object="."/>
        </xsl:for-each>
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
       <!-- <xsl:variable name="target-input-name" as="xs:string" select="ancestor::div[@data-target-input][1]/@data-target-input"/>
        <xsl:variable name="target-input" as="element(input)" select="ivdnt:get-target-input($target-input-name)"/>
        <xsl:variable name="target-input-value" as="xs:string" select="ivdnt:input-value($target-input)"/>
        
        <ixsl:set-property name="value" select="$target-input-value || text()" object="$target-input"/>-->
        
        <xsl:variable name="char" as="xs:string" select="text()"/>
        
        <xsl:variable name="focussed-textbox" as="element(input)?" select="ixsl:get(ixsl:page(), '_focussed_textbox')"/>
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
        <ixsl:set-property name="_focussed_textbox" select="." object="ixsl:page()"/>
    </xsl:template>
</xsl:stylesheet>