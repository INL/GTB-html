<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:ivdnt="http://www.ivdnt.org/xslt/namespaces"
    exclude-result-prefixes="xs math"
    expand-text="yes"
    version="3.0">
    
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
        <xsl:variable name="topdiv" as="element(div)" select="key('ids', ivdnt:strip-hash-from-id(@data-target))"/>
        <xsl:for-each select="$topdiv//input[@type eq 'checkbox' and ivdnt:is-checked(.)]">
            <xsl:call-template name="ivdnt:uncheck"><xsl:with-param name="checkbox" select="."/></xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="div[ivdnt:class-contains(@class, $ZOEK_FORMULIER_CLASS)]" mode="ixsl:onkeypress">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:if test="xs:integer(ixsl:get($event, 'which')) eq 13">
            <!-- User pressed enter -->
            <xsl:call-template name="ivdnt:doe-zoeken">
                <xsl:with-param name="formdiv" select="."/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
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
        <xsl:variable name="formdiv" as="element(div)" select="ancestor::div[ivdnt:class-contains(@class, $ZOEK_FORMULIER_CLASS)][1]"/>
        <xsl:call-template name="ivdnt:doe-zoeken">
            <xsl:with-param name="formdiv" select="$formdiv"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="button[@name eq 'wis-zoeken']" mode="ixsl:onclick">
        <xsl:variable name="formdiv" as="element(div)" select="ancestor::div[ivdnt:class-contains(@class, $ZOEK_FORMULIER_CLASS)][1]"/>
        <xsl:for-each select="$formdiv//input[@type eq 'text']">
            <ixsl:set-property name="value" select="''" object="."/>
        </xsl:for-each>
        <xsl:for-each select="$formdiv//select">
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
    
    <xsl:template match="button[@name eq 'geschiedenis']" mode="ixsl:onclick">
        <xsl:variable name="current-tab" as="element(div)" select="ivdnt:get-active-tabdiv(.)"/>
        <xsl:variable name="popupdiv" as="element(div)" select="id(ivdnt:strip-hash-from-id(@data-target))"/>
        <xsl:variable name="list-div" as="element(div)" select="$popupdiv//div[ivdnt:class-contains(@class, 'gtb-zoekvragen-geschiedenis')]"/>
        
        <xsl:for-each select="$list-div">
            <!-- for-each merely sets the context -->
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:apply-templates select="ixsl:get($current-tab, $FORMDIV_INPUTS_AND_SELECTS_PROPERTY)" mode="geschiedenis-lijst"/>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="a[ivdnt:class-contains(@class, 'list-group-item')]" mode="ixsl:onclick">
        <xsl:variable name="me" as="element(a)" select="."/>
        <xsl:for-each select="parent::*/a">
            <ixsl:set-attribute name="class" select="if (. is $me) then ivdnt:add-class-values(@class, 'active') else ivdnt:remove-class-value(@class, 'active')"/>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="button[@name eq 'doe-selecteervraag']" mode="ixsl:onclick">
        <!-- Bepaal het nummer van het geselecteerde item.
             Selecteer het overeenkomstige XML-element in de lijst van $FORMDIV_INPUTS_AND_SELECTS_PROPERTY (gegeven het tabblad)
             Stel alle inputs in op basis van het XML-element.
        -->
        <xsl:variable name="current-tab" as="element(div)" select="ivdnt:get-active-tabdiv(.)"/>
        <xsl:variable name="active-a" as="element(a)" select="ancestor::div[ivdnt:class-contains(@class, 'modal-body')]//div[@data-type eq 'inputs-and-selects-list']/a[ivdnt:class-contains(@class, 'active')][1]"/>
        <xsl:if test="exists($active-a)">
            <xsl:variable name="num" as="xs:integer" select="count($active-a/preceding-sibling::a) + 1"/>
            <xsl:variable name="inputs-and-selects-list" as="element(inputs-and-selects-list)?" select="ixsl:get($current-tab, $FORMDIV_INPUTS_AND_SELECTS_PROPERTY)"/>
            <xsl:for-each select="$inputs-and-selects-list/inputs-and-selects[$num]//input-or-select">
                <xsl:variable name="id" as="xs:string" select="@ref"/>
                <xsl:variable name="input-or-select-element" as="element()?" select="ixsl:page()/key('ids', $id)"/>
                <xsl:choose>
                    <xsl:when test="@type = ('radio', 'checkbox')">
                        <xsl:variable name="is-checked" as="xs:boolean" select="exists(.[@checked eq 'checked'])"/>
                        <xsl:choose>
                            <xsl:when test="$is-checked"><xsl:call-template name="ivdnt:check"><xsl:with-param name="checkbox" select="$input-or-select-element"/></xsl:call-template></xsl:when>
                            <xsl:otherwise><xsl:call-template name="ivdnt:uncheck"><xsl:with-param name="checkbox" select="$input-or-select-element"/></xsl:call-template></xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="val" as="xs:string" select="@value"/>
                        <ixsl:set-property name="value" select="$val" object="$input-or-select-element"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:if>
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