<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ivdnt="http://www.ivdnt.org/xslt/namespaces"
    exclude-result-prefixes="#all"
    expand-text="yes"
    version="3.0">
    
    <xsl:template match="ivdnt:hulpgroup" mode="ivdnt:html-mode ivdnt:help-mode">
        <xsl:variable name="level" as="xs:integer" select="count(ancestor-or-self::ivdnt:hulpgroup)"/>
        <ul class="list-group gtb-list-subject-level{$level}"><xsl:apply-templates mode="ivdnt:help-mode"/></ul>
    </xsl:template>
    
    <xsl:template match="ivdnt:hulp[@href]" mode="ivdnt:html-mode ivdnt:help-mode">
        <a class="gtb-helplink" href="#" data-help="{@href}"><xsl:apply-templates mode="ivdnt:help-mode"/></a>
    </xsl:template>

    <xsl:template match="ivdnt:hulp[not(@href)]" mode="ivdnt:help-mode">
        <li class="list-group-item"><xsl:apply-templates mode="ivdnt:help-mode"/></li>
    </xsl:template>
</xsl:stylesheet>
