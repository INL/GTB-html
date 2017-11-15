<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:ivdnt="http://www.ivdnt.org/xslt/namespaces"
    exclude-result-prefixes="xs math"
    expand-text="yes"
    version="3.0">
    
    <xsl:import href="typeahead.xslt"/>
    
    <xsl:template name="ivdnt:typeahead-insert-listitems">
        <xsl:param name="text-field" as="element(input)" required="yes"/>
        
        <xsl:variable name="textfield-name" as="xs:string" select="$text-field/@name"/>
        <xsl:variable name="textfield-value" as="xs:string" select="ivdnt:get-input-value($text-field)"/>
        
        <xsl:variable name="tabdiv" select="ivdnt:get-active-tabdiv(.)"/>
        <xsl:variable name="tabdiv-id" as="xs:string" select="$tabdiv/@id"/>
        
        <xsl:variable name="wdbs" as="xs:string*">
            <xsl:for-each select="$tabdiv//input[@type eq 'checkbox' and @data-inputname eq 'wdb' and ivdnt:is-checked(.)]">
                <xsl:value-of select="@name"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="sensitivity-input" as="element(input)" select="$tabdiv//input[@data-inputname eq 'sensitive']"/>
        <xsl:variable name="wdb-inputs" as="xs:string" select="string-join($wdbs, ',')"/>
        <xsl:variable name="sensitivity" as="xs:string" select="xs:string(ivdnt:is-checked($sensitivity-input))"/>
        
        <xsl:variable name="url" as="xs:string" select="$baseListURL || '&amp;index=' || $textfield-name || '&amp;prefix=' || encode-for-uri($textfield-value) || '&amp;wdb=' || $wdb-inputs || '&amp;sensitive=' || $sensitivity"/>
        
        <ixsl:schedule-action document="{$url}">
            <xsl:call-template name="ivdnt:retrieve-typeahead-listitems">
                <xsl:with-param name="url" select="$url"/>
            </xsl:call-template>
        </ixsl:schedule-action>
    </xsl:template>
    
    <xsl:function name="ivdnt:get-typeahead-value-from-listitem"  as="xs:string">
        <xsl:param name="listitem" as="element(li)"/>
        <xsl:value-of select="string($listitem/a/span[@class eq 'gtb-typeahead-word'])"/>
    </xsl:function>
    
    <xsl:template name="ivdnt:retrieve-typeahead-listitems">
        <xsl:param name="url" as="xs:string"/>

        <xsl:result-document href="?." method="ixsl:replace-content">
            <xsl:apply-templates select="doc($url)" mode="render-typeahead-results"/>
        </xsl:result-document>
    </xsl:template>
    
    <xsl:template match="node()" mode="render-typeahead-results">
        <xsl:apply-templates select="node()"/>
    </xsl:template>
    
    <xsl:template match="result">
        <li>
            <xsl:if test="not(preceding-sibling::result)">
                <xsl:attribute name="class" select="'active'"/>
            </xsl:if>
            <a class="dropdown-item" href="#" role="option"><span class="gtb-typeahead-word">{@Lemma}</span><span class="gtb-typeahead-wdb">{@Wdb}</span></a>
        </li>
    </xsl:template>
    
</xsl:stylesheet>