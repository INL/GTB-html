<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:ivdnt="http://www.ivdnt.org/xslt/namespaces"
    exclude-result-prefixes="xs math"
    expand-text="yes"
    version="3.0">
    
    <!-- Return an XML document containing all inputs and selects below the element passed as the parameter.
         If the input or select element is below a division with a class containing $ZOEK_FORMULIER_CLASS the value of the id of that element
         is placed into the generated element.
    -->
    <xsl:function name="ivdnt:get-formdiv-inputs-and-selects" as="element(inputs-and-selects)">
        <xsl:param name="where-to-start" as="element()"/>
        <xsl:param name="formdiv-id" as="xs:string"/>
        <inputs-and-selects>
            <xsl:for-each select="$where-to-start//div[ivdnt:class-contains(@class, $ZOEK_FORMULIER_CLASS) and @id eq $formdiv-id][1]">
                <!-- This iterates only one time -->
                <xsl:variable name="formdiv" as="element(div)" select="."/>
                <xsl:sequence select="ivdnt:create-input-or-select-elements($formdiv)"/>
            </xsl:for-each>
        </inputs-and-selects>
    </xsl:function>
    
    <xsl:function name="ivdnt:create-input-or-select-elements"  as="element()+">
        <xsl:param name="formdiv" as="element(div)"/>
        
        <xsl:for-each select="$formdiv//*[self::select | self::input[@name]]">
            <xsl:variable name="name" as="xs:string" select="@name"/>
            <xsl:variable name="type" as="xs:string" select="if (self::input) then @type else ''"/>
            <xsl:variable name="value" as="xs:string" select="normalize-space(ivdnt:get-input-value(.))"/>
            <xsl:variable name="checked" as="xs:boolean" select="if ($type = ('radio', 'checkbox')) then ivdnt:is-checked(.) else false()"/>
            <xsl:sequence select="ivdnt:create-input-or-select-element(., $formdiv)"/>
            <xsl:if test="@data-label eq 'Woordsoort'">
                <xsl:variable name="data-target" as="xs:string" select="ivdnt:strip-hash-from-id(following-sibling::input[1]/@data-target)"/>
                <woordsoort-inputs>
                    <xsl:variable name="woordsoort-div" as="element(div)" select="key('ids', $data-target)"/>
                    <xsl:sequence select="ivdnt:create-input-or-select-elements($woordsoort-div)"/>
                </woordsoort-inputs>
            </xsl:if>
        </xsl:for-each>
    </xsl:function>
    
    <xsl:function name="ivdnt:create-input-or-select-element"  as="element(input-or-select)">
        <xsl:param name="input-or-select-element" as="element()"/>
        <xsl:param name="formdiv" as="element(div)"/>
        
        <xsl:variable name="name" as="xs:string" select="$input-or-select-element/@name"/>
        <xsl:variable name="type" as="xs:string" select="if ($input-or-select-element/self::input) then $input-or-select-element/@type else ''"/>
        <xsl:variable name="value" as="xs:string" select="normalize-space(ivdnt:get-input-value($input-or-select-element))"/>
        <xsl:variable name="checked" as="xs:boolean" select="if ($input-or-select-element/$type = ('radio', 'checkbox')) then ivdnt:is-checked($input-or-select-element) else false()"/>
        <input-or-select element="{local-name($input-or-select-element)}" name="{$name}" type="{$type}" value="{$value}" ref="{$input-or-select-element/@id}">
            <xsl:copy-of select="$input-or-select-element/@*[starts-with(name(), 'data-')]"/>
            <xsl:attribute name="form-div-id" select="$formdiv/@id"/>
            <xsl:if test="$checked"><xsl:attribute name="checked" select="'checked'"/></xsl:if>
            <xsl:if test="$type ne ''"><xsl:attribute name="type" select="$type"/></xsl:if>
            <xsl:if test="$formdiv/@data-label ne ''"><xsl:attribute name="form-label" select="$formdiv/@data-label"/></xsl:if>
        </input-or-select>
    </xsl:function>
   
    <xsl:function name="ivdnt:add-formdiv-inputs-and-selects"  as="element(inputs-and-selects-list)">
        <xsl:param name="tabdiv" as="element(div)"/>
        <xsl:param name="formdiv-inputs-and-selects" as="element(inputs-and-selects)"/>
        
        <!-- Note that the first time, ixsl:get issues a console warning when retrieving the value of $FORMDIV_INPUTS_AND_SELECTS_PROPERTY. So be it. -->
        <xsl:variable name="existing-inputs-and-selects-list" as="element(inputs-and-selects-list)?" select="ixsl:get($tabdiv, $FORMDIV_INPUTS_AND_SELECTS_PROPERTY)"/>
        
        <inputs-and-selects-list>
            <xsl:copy-of select="$existing-inputs-and-selects-list/*"/>
            <xsl:copy-of select="$formdiv-inputs-and-selects"/>
        </inputs-and-selects-list>
    </xsl:function>
    
    <xsl:function name="ivdnt:input-or-select-sort-value"  as="xs:integer">
        <xsl:param name="input-or-select" as="element(input-or-select)"/>
        <xsl:variable name="value" as="xs:integer">
            <xsl:choose>
                <xsl:when test="$input-or-select/@type = ('checkbox', 'radio')">10</xsl:when>
                <xsl:when test="$input-or-select/@element eq 'select'">5</xsl:when>
                <!-- otherwise: must be input with type=text -->
                <xsl:otherwise>1</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:sequence select="$value"></xsl:sequence>
    </xsl:function>
    
    <xsl:function name="ivdnt:is-text-or-select-field" as="xs:boolean">
        <xsl:param name="input" as="element(input-or-select)"/>
        <xsl:sequence select="exists($input[@type eq 'text' or @element eq 'select'])"/>
    </xsl:function>
    
    <xsl:function name="ivdnt:is-wdb-field" as="xs:boolean">
        <xsl:param name="input" as="element(input-or-select)"/>
        <xsl:sequence select="exists($input[@type eq 'checkbox' and @data-inputname eq 'wdb'])"/>
    </xsl:function>
    
    <xsl:function name="ivdnt:is-domein-field" as="xs:boolean">
        <xsl:param name="input" as="element(input-or-select)"/>
        <xsl:sequence select="exists($input[@type eq 'radio' and @data-inputname eq 'domein'])"/>
    </xsl:function>
    
    <xsl:function name="ivdnt:get-question-description"  as="node()+">
        <xsl:param name="inputs-and-selects-element" as="element(inputs-and-selects)"/>
        <xsl:variable name="textspans" as="element(span)*">
            <xsl:apply-templates select="$inputs-and-selects-element/input-or-select[@data-humanname ne '' and ivdnt:is-text-or-select-field(.)]" mode="geschiedenis-lijst">
                <xsl:sort data-type="number" select="ivdnt:input-or-select-sort-value(.)"></xsl:sort>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="wdbspans" as="element(span)*">
            <xsl:apply-templates select="$inputs-and-selects-element/input-or-select[@data-humanname ne '' and ivdnt:is-wdb-field(.)]" mode="geschiedenis-lijst">
                <xsl:sort data-type="number" select="ivdnt:input-or-select-sort-value(.)"></xsl:sort>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="domeinspans" as="element(span)*">
            <xsl:apply-templates select="$inputs-and-selects-element/input-or-select[@data-humanname ne '' and ivdnt:is-domein-field(.)]" mode="geschiedenis-lijst">
                <xsl:sort data-type="number" select="ivdnt:input-or-select-sort-value(.)"></xsl:sort>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="otherspans" as="element(span)*">
            <xsl:apply-templates select="$inputs-and-selects-element/input-or-select[@data-humanname ne '' and not(ivdnt:is-text-or-select-field(.) or ivdnt:is-wdb-field(.) or ivdnt:is-domein-field(.))]" mode="geschiedenis-lijst">
                <xsl:sort data-type="number" select="ivdnt:input-or-select-sort-value(.)"></xsl:sort>
            </xsl:apply-templates>
        </xsl:variable>
        
        <xsl:for-each select="$textspans">
            <xsl:copy-of select="."/>
            <xsl:if test="position() ne last()"><xsl:text>,&#32;</xsl:text></xsl:if>
        </xsl:for-each>
        <xsl:text>; zoek in:&#32;</xsl:text>
        <xsl:for-each select="$wdbspans">
            <xsl:copy-of select="."/>
            <xsl:if test="position() ne last()"><xsl:text>&#32;/&#32;</xsl:text></xsl:if>
        </xsl:for-each>
        <xsl:if test="exists($domeinspans)"><xsl:text>;&#32;</xsl:text>
            <xsl:for-each select="$domeinspans">
                <!-- Zolang domeinspans een radio is, itereert dit maar één keer. -->
                <xsl:copy-of select="."/>
                <xsl:if test="position() ne last()"><xsl:text>&#32;</xsl:text></xsl:if>
            </xsl:for-each>
        </xsl:if>
        <xsl:if test="exists($otherspans)">
            <xsl:text>;&#32;</xsl:text>
            <xsl:for-each select="$otherspans">
                <xsl:copy-of select="."/>
                <xsl:if test="position() ne last()"><xsl:text>, &#32;</xsl:text></xsl:if>
            </xsl:for-each>        </xsl:if>
        
    </xsl:function>
    
    <xsl:template match="inputs-and-selects-list" mode="geschiedenis-lijst">
        <div class="list-group" data-type="inputs-and-selects-list"><xsl:apply-templates mode="geschiedenis-lijst"/></div>
    </xsl:template>
    
    <xsl:template match="inputs-and-selects" mode="geschiedenis-lijst">
        <xsl:variable name="description" as="node()+" select="ivdnt:get-question-description(.)"/>
        
        <a href="#" class="list-group-item list-group-item-action">
            <xsl:copy-of select="$description"/>
        </a>
    </xsl:template>
    
    <xsl:template match="input-or-select[@type = ('checkbox', 'radio') and @checked='checked']" mode="geschiedenis-lijst">
        <xsl:choose>
            <xsl:when test="ivdnt:is-wdb-field(.)"><span>{upper-case(@name)}</span></xsl:when>
            <xsl:when test="ivdnt:is-domein-field(.)"><span>{@data-humanname}</span></xsl:when>
            <xsl:otherwise><span>{@data-humanname}: <span class="gtb-input-value">ja t={@type} n={@name}</span></span></xsl:otherwise>
        </xsl:choose>        
    </xsl:template>
    
    <xsl:template match="input-or-select[(@type eq 'text' or @element eq 'select') and @value ne '']" mode="geschiedenis-lijst">
        <span>{@data-humanname} (<span class="gtb-input-value">{@value}</span>)</span>
    </xsl:template>
    
</xsl:stylesheet>