<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ivdnt="http://www.ivdnt.org/xslt/namespaces"
    exclude-result-prefixes="#all"
    expand-text="yes"
    version="3.0">
    
    <xsl:template match="ivdnt:include" mode="ivdnt:html-mode">
        <xsl:variable name="resolved-uri" as="xs:anyURI" select="resolve-uri(@href, base-uri(.))"/>
        <xsl:choose>
            <xsl:when test="doc-available($resolved-uri)"><xsl:apply-templates select="doc($resolved-uri)" mode="ivdnt:html-mode"/></xsl:when>
            <xsl:otherwise><xsl:message terminate="yes">Failed to access uri {$resolved-uri}</xsl:message></xsl:otherwise>
        </xsl:choose>        
    </xsl:template>    
</xsl:stylesheet>