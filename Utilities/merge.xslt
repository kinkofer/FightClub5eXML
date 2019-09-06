<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="xml" indent="yes" />
    
    <xsl:template match="collection">
        <compendium version="5" auto_indent="NO">
            <xsl:copy-of select="document(doc/@href)/compendium/*" />
        </compendium>
    </xsl:template>
</xsl:transform>
