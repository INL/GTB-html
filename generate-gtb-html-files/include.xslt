<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ivdnt="http://www.ivdnt.org/xslt/namespaces"
    exclude-result-prefixes="#all"
    expand-text="yes"
    version="3.0">
    
    <xsl:template match="ivdnt:include" mode="ivdnt:html-mode">
        <xsl:apply-templates select="doc(resolve-uri(@href, base-uri(.)))/*" mode="ivdnt:html-mode"/>
    </xsl:template>    
</xsl:stylesheet>