<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:ivdnt="http://www.ivdnt.org/xslt/namespaces"
  exclude-result-prefixes="#all"
  expand-text="yes"
  version="3.0">
  
  <xsl:template match="ivdnt:tabs" mode="ivdnt:html-mode">
    <div>
      <xsl:copy-of select="ivdnt:add-class-values(@class, 'tabs')"/>
      <xsl:apply-templates select="@* except (@class, @for-id, @title-container-class, @content-container-class)" mode="ivdnt:tabs-mode"/>
      
      <ul>
        <xsl:copy-of select="ivdnt:add-class-values(@title-container-class, ('nav', 'nav-tabs'))"/>
        <xsl:apply-templates select="ivdnt:tab/ivdnt:tabtitle" mode="ivdnt:tab-titles"/>
      </ul>
      
      <div>          
        <xsl:copy-of select="ivdnt:add-class-values(@content-container-class, 'tab-content')"/>
        <xsl:apply-templates select="ivdnt:tab" mode="ivdnt:tabs-mode"/>        
      </div>
    </div>
  </xsl:template>
  
  <xsl:template match="ivdnt:tabtitle" mode="ivdnt:tab-titles">
    <li>
      <xsl:copy-of select="parent::ivdnt:tab/@id"/>
      <xsl:copy-of select="ivdnt:add-class-values(@class, (if (not(parent::ivdnt:tab/preceding-sibling::ivdnt:tab)) then ('active') else (), 'tabtitle'))"/>
      <a data-toggle="tab" href="{'#' || generate-id(parent::ivdnt:tab)}">
        <xsl:attribute name="title" select="text()"/>
        <xsl:apply-templates select="node() | @* except @class" mode="ivdnt:html-mode"/>
      </a>
    </li>
  </xsl:template>
  
  <xsl:template match="ivdnt:tab" mode="ivdnt:tabs-mode">
    <!--<xsl:variable name="fade" select="'fade'"/>--><xsl:variable name="fade" select="''"/>
    <div id="{generate-id()}">
      <xsl:copy-of select="ivdnt:add-class-values(@class, ('tab-pane', $fade, if (not(preceding-sibling::ivdnt:tab)) then ('in', 'active') else ()))"/>
      <xsl:apply-templates select="node() | @* except (@class, @id)" mode="ivdnt:html-mode"/>
    </div>
  </xsl:template>
  
  <!-- Pulled, not pushed -->
  <xsl:template match="ivdnt:tabtitle" mode="ivdnt:html-mode"/>
  
  <xsl:template match="node() | @*" mode="ivdnt:tabs-mode" priority="-1">
    <xsl:copy>
      <xsl:apply-templates select="node() | @*" mode="#current"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>