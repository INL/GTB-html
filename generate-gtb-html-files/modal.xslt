<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ivdnt="http://www.ivdnt.org/xslt/namespaces"
    exclude-result-prefixes="#all"
    expand-text="yes"
    version="3.0">
    
    <xsl:function name="ivdnt:gen-data-modal-target-id" as="xs:string">
        <xsl:param name="modal-textfield" as="element(input)"/>
        <xsl:value-of select="'modaltarget.' || generate-id($modal-textfield)"/>
    </xsl:function>
    
    <xsl:template match="@data-modal-target-id" mode="ivdnt:html-mode">
        <xsl:attribute name="{name()}" select="ivdnt:gen-data-modal-target-id(..)"></xsl:attribute>
    </xsl:template>
    
    <xsl:template match="ivdnt:modal" mode="ivdnt:html-mode">
        <xsl:apply-templates select="ivdnt:modaltrigger/node()" mode="ivdnt:modal-mode"/>
    </xsl:template>
    
    <xsl:template match="ivdnt:modal" mode="ivdnt:modal-mode">
        <div id="{generate-id()}">
            <xsl:if test="@type"><xsl:attribute name="data-modaltype" select="@type"/></xsl:if>
            <xsl:if test="@target-input"><xsl:attribute name="data-target-input" select="ivdnt:gen-data-modal-target-id(preceding::input[@data-modal-target-id][1])"/></xsl:if>
            <xsl:copy-of select="ivdnt:add-class-values(@class, 'modal')"/>
            <div class="modal-dialog">
                <xsl:copy-of select="@style"/>
                <div class="modal-content">
                    <xsl:apply-templates select="node() except ivdnt:modaltrigger" mode="ivdnt:modal-mode"/>
                </div>
            </div>
        </div>
    </xsl:template>
    
    <xsl:template match="ivdnt:modaltrigger/*" mode="ivdnt:modal-mode">
        <xsl:copy>
            <xsl:attribute name="class" select="ivdnt:add-class-values(@class, 'modaltrigger')"/>
            <xsl:attribute name="data-toggle" select="'modal'"/>
            <xsl:attribute name="data-target" select="'#' || generate-id(ancestor::ivdnt:modal[1])"/>
            <xsl:apply-templates select="@* except (@class, @data-toggle, @data-target)" mode="ivdnt:html-mode"/>
            <xsl:apply-templates select="node()" mode="ivdnt:html-mode"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ivdnt:modalcontent" mode="ivdnt:modal-mode">
        <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal">&#x00d7;</button> <!-- &#x00d7; is &times;, multiplication character -->
            <xsl:apply-templates select="ivdnt:modaltitle" mode="ivdnt:modal-mode"/>
        </div>
        <div class="modal-body">
            <xsl:apply-templates select="node() except ivdnt:modaltitle" mode="ivdnt:html-mode"/>
        </div>
        <xsl:if test="not(ancestor::ivdnt:modal/@suppress-ok-button eq 'true')">
            <div class="modal-footer">
                <button type="button" class="btn btn-default" data-dismiss="modal" data-modaltype="{ancestor::ivdnt:modal/@type}">Ok</button>
            </div>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="ivdnt:modaltitle" mode="ivdnt:modal-mode">
        <xsl:apply-templates select="node()" mode="ivdnt:html-mode"/>
    </xsl:template>
    
    <xsl:template match="ivdnt:modal[@suppress-ok-button eq 'true']/ivdnt:modalfooter" mode="ivdnt:modal-mode">
        <div class="modal-footer">
            <xsl:apply-templates select="node()" mode="ivdnt:html-mode"/>
        </div>
    </xsl:template>
</xsl:stylesheet>
