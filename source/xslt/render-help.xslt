<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT" xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:ivdnt="http://www.ivdnt.org/xslt/namespaces"
    exclude-result-prefixes="xs math" expand-text="yes" version="3.0">

    <xsl:template match="node() | @*" mode="render-help" priority="-1">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="render-help"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="text()" mode="render-help">
        <xsl:value-of select="translate(., 'e', '&#x259;')"/>
    </xsl:template>
    
</xsl:stylesheet>
