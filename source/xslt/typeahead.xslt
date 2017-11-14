<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:ivdnt="http://www.ivdnt.org/xslt/namespaces"
    exclude-result-prefixes="xs math"
    expand-text="yes"
    version="3.0">
    
    <!-- General usage of this XSLT module:
         - You need to include the bootstrap CSS and JS files.
         - Add a class value "typeahead" to a textfield (<input type="text">)
         - Put an empty <ul> right of the textfield and give it also a class with values "typeahead and dropdown-menu", eg. <ul class="typeahead dropdown-menu"/>
         - Define ul.typeahead in CSS to have display:none. You may also want to specify top and left, eg.: ul.typeahead { top: 34px; left: 15px; display: none; }
         - Redefine the functions and templatess below as you see fit.
    -->
    
    <!-- ==========================================================================-->
    <!-- The following functions and templates will probably need to be redefined: -->
    <!-- ==========================================================================-->
    
    <!-- Obtain the string from the list item, sothat it can be stored in the corresponding text box.
         Uou may want to redefine this function if the content of the a element is somewhat more complex
         than just text.
    -->
    <xsl:function name="ivdnt:get-typeahead-value-from-listitem"  as="xs:string">
        <xsl:param name="listitem" as="element(li)"/>
        <xsl:value-of select="string($listitem/a)"/>
    </xsl:function>
    
    <!-- Generate a sequence of <li> elements, with <a class="dropdown-item" href="#" role="option"> children.
         These elements will be shown in a typehead list popping up.
         In order to highlight the currently selected list item, dynamically add a class value "active" (this is bootstrap behavious).
         
         Implementations will probably use a combination of ixsl:schedule-action, the doc-function with a certain URL and xsl:apply-templates.
         
         The text-field parameter can be used to obtain the text that the user has entered upto now, and also other attributes that may
         be relevant, such as perhaps the textifle
    -->
    <xsl:template name="ivdnt:typeahead-insert-listitems">
        <xsl:param name="text-field" as="element(input)" required="yes"/>

        <xsl:result-document href="?." method="ixsl:replace-content">
            <li><a class="dropdown-item" href="#" rel="option">Please implement</a></li>
            <li><a class="dropdown-item" href="#" rel="option">this method</a></li>
            <li class="active"><a class="dropdown-item" href="#" rel="option">yourself</a></li>
            <li><a class="dropdown-item" href="#" rel="option">by generating a sequene</a></li>
            <li><a class="dropdown-item" href="#" rel="option">of li elements</a></li>
        </xsl:result-document>
    </xsl:template>
    
    <!-- =============================================================================================================== -->
    <!-- The following functions and templates may be redefined, but are expected to be goog enough for the general case: -->
    <!-- =============================================================================================================== -->
    
    <!-- Obtains the typeahead ul element that follows the current textfield (input element). --> 
    <xsl:function name="ivdnt:get-my-typeahead-ul"  as="element(ul)">
        <xsl:param name="input" as="element(input)"/>
        <xsl:sequence select="$input/following-sibling::ul[ivdnt:class-contains(@class, 'typeahead')][1]"/>
    </xsl:function>
    
    <!-- Obtains the typeahead textfield (input element) that precedes the given typeahead ul element. -->
    <xsl:function name="ivdnt:get-my-typeahead-textfield"  as="element(input)">
        <xsl:param name="ul" as="element(ul)"/>
        <xsl:sequence select="$ul/preceding-sibling::input[ivdnt:class-contains(@class, 'typeahead')][1]"/>
    </xsl:function>
    
    <!-- Stores the value of the selected item in the typeahead list into the corresponding typeahead textfield. -->
    <xsl:template name="ivdnt:typeahead-select">
        <xsl:param name="selected-listitem" as="element(li)" required="yes"/>
        <xsl:variable name="value" select="ivdnt:get-typeahead-value-from-listitem($selected-listitem)"/>
        <xsl:call-template name="ivdnt:typeahead-update-textbox">
            <xsl:with-param name="textbox" as="element(input)" select="ivdnt:get-my-typeahead-textfield($selected-listitem/parent::ul)"/>
            <xsl:with-param name="value" as="xs:string" select="$value"/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- Deal with a keyup event by calling idvnt:typeahead-key -->
    <xsl:template match="input[ivdnt:class-contains(@class, 'typeahead')]" mode="ixsl:onkeyup">
        <!-- In mode onkeyup, the key has been processed, so the value of the text box has been updated. -->
        <xsl:call-template name="ivdnt:typeahead-key">
            <xsl:with-param name="textfield" select="."/>
            <!--<xsl:with-param name="mode" select="'onkeyup'"/>-->
        </xsl:call-template>
    </xsl:template>
    
    <!-- Hide the typeahead list when the corresponding textfield looses focus. -->
    <!--<xsl:template match="input[ivdnt:class-contains(@class, 'typeahead')]" mode="ixsl:onblur ixsl:onfocusout">
        <!-\- TODO a click that causes an onblur, hides the onclick on the li. -\->
        <!-\- TODO Find out whether onblur (W3C preferred) or onfocusout (IE) is the way to go. -\->
        <xsl:call-template name="ivdnt:typeahead-hide">
            <xsl:with-param name="ul" select="following-sibling::ul[ivdnt:class-contains(@class, 'typeahead')][1]"/>
        </xsl:call-template>
    </xsl:template>-->
    
    <!-- Deal with a click in the typeahead list by storing the selected value in the textfield and then hiding the list. -->
    <xsl:template match="ul[ivdnt:class-contains(@class, 'typeahead')]/li" mode="ixsl:onclick">
        <!-- TODO a click that causes an onblur, hides the onclick on the li. -->
        <xsl:variable name="current-li" as="element(li)" select="."/>
        
        <xsl:for-each select="parent::ul/li">
            <ixsl:set-attribute name="class" select="if (. is $current-li) then 'active' else ''"/>
        </xsl:for-each>
        <xsl:call-template name="ivdnt:typeahead-select">
            <xsl:with-param name="selected-listitem" select="."/>
        </xsl:call-template>
        <xsl:call-template name="ivdnt:typeahead-hide">
            <xsl:with-param name="ul" select="$current-li/parent::ul"/>
        </xsl:call-template>
    </xsl:template>
    
    <!--<!-\- TODO arrows, enter, escape, etc. is not reported.
    <xsl:template match="input[ivdnt:class-contains(@class, 'typeahead')]" mode="ixsl:keypress">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:variable name="whichKey" select="xs:integer(ixsl:get($event, 'which'))" as="xs:integer"/>
        <xsl:message>at input, key={$whichKey}</xsl:message>
        <xsl:choose>
            <xsl:when test="$whichKey eq 27">
                <!-\- escape key -\->
                <xsl:call-template name="ivdnt:typeahead-hide"><xsl:with-param name="ul" select="ivdnt:get-my-typeahead-ul(.)"/></xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>todo</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="ul[ivdnt:class-contains(@class, 'typeahead')]/li" mode="ixsl:keypress">
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:variable name="whichKey" select="xs:integer(ixsl:get($event, 'which'))" as="xs:integer"/>
        <xsl:message>at li, key={$whichKey}</xsl:message>
        <xsl:choose>
            <xsl:when test="$whichKey eq 27">
                <!-\- escape key -\->
                <xsl:call-template name="ivdnt:typeahead-hide"><xsl:with-param name="ul" select="parent::ul"/></xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>todo</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>-->
    
    <!-- Hides the typeahead list. -->
    <xsl:template name="ivdnt:typeahead-hide">
        <xsl:param name="ul" as="element(ul)" required="yes"/>
        <ixsl:set-style name="display" select="'none'" object="$ul"/>
    </xsl:template>
    
    <!-- Deals with a keyup event in the typeahead textfield, by calling ivdnt:typeahead-insert-listitems. That
         template will store a sequence of, as described at ivdng:typeahead-insert-listitems.
         If the textfield become empty, the typehead list is hidden.
    -->
    <xsl:template name="ivdnt:typeahead-key">
        <xsl:param name="textfield" as="element(input)" required="yes"/>
        <xsl:for-each select="ivdnt:get-my-typeahead-ul($textfield)">
            <!-- One iteration only -->
            <xsl:call-template name="ivdnt:typeahead-insert-listitems">
                <xsl:with-param name="text-field" select="$textfield"/>
            </xsl:call-template>
            <xsl:variable name="text" as="xs:string" select="ivdnt:get-input-value($textfield)"/>
            <ixsl:set-style name="display" select="if ($text ne '') then 'block' else 'none'"/>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="ivdnt:typeahead-update-textbox">
        <xsl:param name="textbox" as="element(input)" required="yes"/>
        <xsl:param name="value" as="xs:string" required="yes"/>
        
        <ixsl:set-property name="value" select="$value" object="$textbox"/>
    </xsl:template>
    
</xsl:stylesheet>