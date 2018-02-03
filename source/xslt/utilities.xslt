<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:ivdnt="http://www.ivdnt.org/xslt/namespaces"
    exclude-result-prefixes="xs math"
    expand-text="yes"
    version="3.0">
    
    <!-- This function is used in order to void the output of the result of a called Javascript function. We are working around possible optimizations.-->
    <xsl:function name="ivdnt:always-false" as="xs:boolean">
        <xsl:sequence select="current-date() lt xs:date('1957-11-05')"/>
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
    
    <xsl:template name="ivdnt:set-checked">
        <xsl:param name="checkbox" as="element(input)" required="yes"/>
        <xsl:param name="checked" as="xs:boolean" required="yes"/>
        <ixsl:set-property name="checked" object="$checkbox" select="$checked"/>
    </xsl:template>
    
    <xsl:template name="ivdnt:check">
        <xsl:param name="checkbox" as="element(input)" required="yes"/>
        <xsl:call-template name="ivdnt:set-checked">
            <xsl:with-param name="checkbox" select="$checkbox"/>
            <xsl:with-param name="checked" select="true()"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template name="ivdnt:uncheck">
        <xsl:param name="checkbox" as="element(input)" required="yes"/>
        <xsl:call-template name="ivdnt:set-checked">
            <xsl:with-param name="checkbox" select="$checkbox"/>
            <xsl:with-param name="checked" select="false()"/>
        </xsl:call-template>
        <!-- note that <ixsl:remove-attribute name="checked"> does not work (the current context is the input, equal to parameter $checkbox, so it could have worked). -->
    </xsl:template>
</xsl:stylesheet>