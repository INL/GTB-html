<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ivdnt="http://www.ivdnt.org/xslt/namespaces"
    exclude-result-prefixes="#all"
    expand-text="yes"
    version="3.0">
    <xsl:template match="ivdnt:hulp[@href]" mode="ivdnt:html-mode ivdnt:help-mode">
        <a class="gtb-helplink" href="#" data-help="{@href}"><xsl:apply-templates mode="ivdnt:help-mode"/></a>
    </xsl:template>
</xsl:stylesheet>
