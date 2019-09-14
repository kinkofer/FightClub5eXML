<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:exsl="http://exslt.org/common">
    <xsl:output method="xml" indent="yes" />
    
    <xsl:template match="collection">
        <compendium version="5" auto_indent="NO">
            <xsl:variable name="compendium" select="document(doc/@href)/compendium" />
            
            <xsl:copy-of select="$compendium/item" />
            <xsl:copy-of select="$compendium/race" />
            
            <xsl:call-template name="classes-with-subclasses" />
            
            <xsl:copy-of select="$compendium/feat" />
            <xsl:copy-of select="$compendium/background" />
            <xsl:copy-of select="$compendium/spell" />
            <xsl:copy-of select="$compendium/monster" />
        </compendium>
    </xsl:template>
    
    
    <!-- Template once a class is selected -->
    <xsl:template name="class">
        <xsl:copy-of select="hd" />
        <xsl:copy-of select="proficiency" />
        <xsl:copy-of select="spellAbility" />
        <xsl:copy-of select="numSkills" />
        <xsl:copy-of select="armor" />
        <xsl:copy-of select="weapons" />
        <xsl:copy-of select="tools" />
        <xsl:copy-of select="wealth" />
        <xsl:copy-of select="autolevel" />
    </xsl:template>
    
    
    <!-- Merges subclasses into classes -->
    <xsl:template name="classes-with-subclasses">
        <xsl:variable name="compendium" select="document(doc/@href)/compendium" />
        
        
        <!-- Define class variables -->
        <xsl:variable name="Barbarian" select="'Barbarian'" />
        <xsl:variable name="Bard" select="'Bard'" />
        <xsl:variable name="Cleric" select="'Cleric'" />
        <xsl:variable name="Druid" select="'Druid'" />
        <xsl:variable name="Fighter" select="'Fighter'" />
        <xsl:variable name="Monk" select="'Monk'" />
        <xsl:variable name="Paladin" select="'Paladin'" />
        <xsl:variable name="Ranger" select="'Ranger'" />
        <xsl:variable name="Rogue" select="'Rogue'" />
        <xsl:variable name="Sorcerer" select="'Sorcerer'" />
        <xsl:variable name="Warlock" select="'Warlock'" />
        <xsl:variable name="Wizard" select="'Wizard'" />
        
        <xsl:variable name="classes">
            <class><xsl:value-of select="$Barbarian" /></class>
            <class><xsl:value-of select="$Bard" /></class>
            <class><xsl:value-of select="$Cleric" /></class>
            <class><xsl:value-of select="$Druid" /></class>
            <class><xsl:value-of select="$Fighter" /></class>
            <class><xsl:value-of select="$Monk" /></class>
            <class><xsl:value-of select="$Paladin" /></class>
            <class><xsl:value-of select="$Ranger" /></class>
            <class><xsl:value-of select="$Rogue" /></class>
            <class><xsl:value-of select="$Sorcerer" /></class>
            <class><xsl:value-of select="$Warlock" /></class>
            <class><xsl:value-of select="$Wizard" /></class>
        </xsl:variable>
        
        <xsl:variable name="class-array" select="exsl:node-set($classes)" />
        
        
        <!-- Loop through each class -->
        <xsl:for-each select="$class-array/class">
            <xsl:variable name="class" select="text()" />
            
            <!-- If at least one of this class exists, create one class element for it -->
            <xsl:if test="$compendium/class/name/text()=$class">
                <class>
                    <name><xsl:value-of select="$class" /></name>
                    
                    <!-- For each one of this class, get the elements within the template -->
                    <!-- Important: Subclasses should only contain "name" and "autolevel" elements -->
                    <xsl:for-each select="$compendium/class[name=$class]">
                        <xsl:call-template name="class" />
                    </xsl:for-each>
                </class>
            </xsl:if>
        </xsl:for-each>
        
        <!-- Get the remaining classes -->
        <xsl:copy-of select="$compendium/class[name!=$Barbarian and name!=$Bard and name!=$Cleric and name!=$Druid and
        name!=$Fighter and name!=$Monk and name!=$Paladin and name!=$Ranger and
        name!=$Rogue and name!=$Sorcerer and name!=$Warlock and name!=$Wizard]" />
    </xsl:template>
</xsl:transform>
