<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="xml" indent="yes" />

    <!-- Merge the compendiums together -->
    <xsl:template match="collection">

        <!-- Store compendium in an intermediate format (firstStage) -->
        <xsl:variable name="merged">
            <xsl:apply-templates mode="firstStage" select="document(doc/@href)" />
        </xsl:variable>

        <!-- Second stage works from the output of the first stage -->
        <xsl:variable name="filtered">
            <xsl:call-template name="items-extendable">
                <xsl:with-param name="items" select="($merged)/compendium/item" />
            </xsl:call-template>
            <xsl:call-template name="race-unique-filter">
                <xsl:with-param name="races" select="($merged)/compendium/race" />
            </xsl:call-template>
            <xsl:call-template name="class-extendable">
                <xsl:with-param name="classes" select="($merged)/compendium/class" />
            </xsl:call-template>
            <xsl:apply-templates mode="secondStage" select="($merged)/compendium/feat"/>
            <xsl:apply-templates mode="secondStage" select="($merged)/compendium/background"/>
            <xsl:call-template name="spells-extendable">
                <xsl:with-param name="spells" select="($merged)/compendium/spell" />
            </xsl:call-template>
            <xsl:call-template name="monster-unique-filter">
                <xsl:with-param name="monsters" select="($merged)/compendium/monster" />
            </xsl:call-template>
        </xsl:variable>

        <compendium version="5" auto_indent="NO">
            <xsl:apply-templates mode="finalStage" select="$filtered" />
        </compendium>
    </xsl:template>

    <!-- First Stage -->

    <xsl:template mode="firstStage" match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates mode="firstStage" select="@* | node()"/>
        </xsl:copy>
    </xsl:template>

    <!-- Convert spell class comma-separated list to <c></c> elements -->

    <xsl:template mode="firstStage" match="compendium/spell/classes">
        <classes>
            <xsl:for-each select="tokenize(replace(., ', ', ','), ',')">
                <spellClass>
                    <xsl:value-of select="." />
                </spellClass>
            </xsl:for-each>
        </classes>
    </xsl:template>

    <!-- Add sorting keys to dice rolls -->
    <xsl:template mode="firstStage" match="roll|dmg1|dmg2">
        <xsl:variable name="extra" select="tokenize(., '[+-]')" />
        <xsl:variable name="bits" select="tokenize($extra[1], 'd')" />
        <xsl:copy>
            <xsl:copy-of select="@*" />
            <xsl:attribute name="num"><xsl:value-of select="$bits[1]" /></xsl:attribute>
            <xsl:attribute name="die"><xsl:value-of select="$bits[2]" /></xsl:attribute>
            <xsl:copy-of select="node()" />
        </xsl:copy>
    </xsl:template>

    <!-- Add elements for rarity, classification (major, minor), and attunement,
        Use only items that have type fields -->
    <xsl:template mode="firstStage" match="item[./type]">
        <xsl:variable name="details" select="./detail" />
        <xsl:variable name="fulltext" select="string-join(./text, '')" />
        <xsl:copy>
            <xsl:apply-templates mode="firstStage" select="@* | node()"/>
            <xsl:analyze-string select="$details" regex=".*?((rarity varies|legendary|(very )?rare|(un)?common)( \(\+\d\))?).*?">
              <xsl:matching-substring>
                <xsl:element name="rarity"><xsl:value-of select="regex-group(1)" /></xsl:element>
              </xsl:matching-substring>
            </xsl:analyze-string>
            <xsl:analyze-string select="$details" regex=".*?(major|minor).*?">
              <xsl:matching-substring>
                <xsl:element name="classification"><xsl:value-of select="regex-group(1)" /></xsl:element>
              </xsl:matching-substring>
            </xsl:analyze-string>
            <xsl:analyze-string select="$details" regex=".*(\(.*?attunement.*?\)).*">
                <xsl:matching-substring>
                    <xsl:element name="attunement"><xsl:value-of select="regex-group(1)" /></xsl:element>
                </xsl:matching-substring>
            </xsl:analyze-string>
            <xsl:analyze-string select="$details" regex=".*?(\(.*?(light|medium|heavy|plate).*\)).*?">
                <xsl:matching-substring>
                    <xsl:element name="armor-detail"><xsl:value-of select="regex-group(1)" /></xsl:element>
                </xsl:matching-substring>
            </xsl:analyze-string>
            <xsl:if test="matches($fulltext, 'Magic Item Table')">
                <xsl:element name="dmg-magic">YES</xsl:element>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="matches($fulltext, 'Magic Item Table A')">
                    <xsl:element name="dmg-rarity">common</xsl:element>
                </xsl:when>
                <xsl:when test="matches($fulltext, 'Magic Item Table [BF]')">
                    <xsl:element name="dmg-rarity">uncommon</xsl:element>
                </xsl:when>
                <xsl:when test="matches($fulltext, 'Magic Item Table [CG]')">
                    <xsl:element name="dmg-rarity">rare</xsl:element>
                </xsl:when>
                <xsl:when test="matches($fulltext, 'Magic Item Table [DH]')">
                    <xsl:element name="dmg-rarity">very rare</xsl:element>
                </xsl:when>
                <xsl:when test="matches($fulltext, 'Magic Item Table [EH]')">
                    <xsl:element name="dmg-rarity">legendary</xsl:element>
                </xsl:when>
            </xsl:choose>
            <xsl:choose>
                <!-- consumables (potions and scrolls) are generally minor items -->
                <xsl:when test="matches($fulltext, 'Magic Item Table [A-E]') or matches(./type, '(P|SC)')">
                    <xsl:element name="dmg-classification">minor</xsl:element>
                </xsl:when>
                <xsl:when test="matches($fulltext, 'Magic Item Table [F-I]')">
                    <xsl:element name="dmg-classification">major</xsl:element>
                </xsl:when>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>

    <!-- Strip rarity / classification / attunement / type from detail string-->
    <xsl:template mode="firstStage" match="detail">
        <xsl:variable name="noClassifier" select="replace(., '(major|minor),? ?', '')" />
        <xsl:variable name="noRarity" select="replace($noClassifier, '(or )?(rarity varies|legendary|(very )?rare|(un)?common)( \(\+\d\))?,? ?', '')" />
        <xsl:variable name="noAttunement" select="replace($noRarity, '(\(.*?attunement.*?\)),? ?', '')" />
        <xsl:variable name="noType" select="replace($noAttunement, '(([Hh]eavy|[Mm]edium|[Ll]ight) Armor|([Ss]imple|[Mm]artial|[Mm]elee|[Rr]anged) [Ww]eapon|[Aa]mmunition|[Ss]hield|[Aa]dventuring [Gg]ear|[Ww]ondrous [Ii]tem|[Rr]od|[Ss]taff|[Ww]and|[Rr]ing|[Pp]otion|[Ss]croll),? ?', '')" />
        <xsl:variable name="danglingComma" select="replace($noType, ',\s*$', '')" />
        <xsl:variable name="spaceBeforeParen" select="replace($danglingComma, '^\(', ' (')" />
        <xsl:element name="detail"><xsl:value-of select="$spaceBeforeParen" /></xsl:element>
    </xsl:template>

    <!-- consistency for magic value -->
    <xsl:template mode="firstStage" match="magic">
        <xsl:if test="matches(., '^(YES|1)$')">
            <xsl:element name="input-magic">YES</xsl:element>
        </xsl:if>
    </xsl:template>

    <!-- Second Stage -->

    <xsl:template mode="secondStage" match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates mode="secondStage" select="@* | node()"/>
        </xsl:copy>
    </xsl:template>

    <!-- Background (second stage)  -->

    <xsl:template mode="secondStage" match="background">
        <background>
            <xsl:apply-templates mode="secondStage" select="name" />
            <xsl:apply-templates mode="secondStage" select="proficiency" />
            <xsl:apply-templates mode="secondStage" select="trait" />
        </background>
    </xsl:template>

    <!-- Merge Classes (second stage)  -->

    <xsl:template name="class-extendable">
        <xsl:param name="classes" />
        <xsl:for-each select="$classes">
            <xsl:sort select="." />
            <xsl:choose>
                <!-- Check if there's a duplicate -->
                <xsl:when test="count($classes[name = current()/name]) &gt; 1">
                    <!-- Use the original class that includes the "hd" element -->
                    <!-- Important: Subclasses should only contain "name" and "autolevel" elements -->
                    <xsl:if test="hd">
                        <xsl:call-template name="single-class">
                            <xsl:with-param name="classes" select="$classes" />
                            <xsl:with-param name="class" select="." />
                        </xsl:call-template>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="single-class">
                        <xsl:with-param name="classes" select="$classes" />
                        <xsl:with-param name="class" select="." />
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="single-class">
        <xsl:param name="class" />
        <xsl:param name="classes" />
        <class>
            <xsl:apply-templates mode="secondStage" select="$class/name" />
            <xsl:apply-templates mode="secondStage" select="$class/hd" />
            <xsl:apply-templates mode="secondStage" select="$class/proficiency" />
            <xsl:apply-templates mode="secondStage" select="$class/spellAbility" />
            <xsl:apply-templates mode="secondStage" select="$class/slotsReset" />
            <xsl:apply-templates mode="secondStage" select="$class/numSkills" />
            <xsl:apply-templates mode="secondStage" select="$class/armor" />
            <xsl:apply-templates mode="secondStage" select="$class/weapons" />
            <xsl:apply-templates mode="secondStage" select="$class/tools" />
            <xsl:apply-templates mode="secondStage" select="$class/wealth" />
            <!-- Important: Subclasses should only contain "name" and "autolevel" elements -->
            <xsl:for-each select="$classes[name = current()/name]">
                <xsl:apply-templates mode="secondStage" select="autolevel"/>
            </xsl:for-each>
        </class>
    </xsl:template>

    <!-- Feat (second stage)  -->

    <xsl:template mode="secondStage" match="feat">
        <feat>
            <xsl:apply-templates mode="secondStage" select="name" />
            <xsl:apply-templates mode="secondStage" select="prerequisite" />
            <xsl:apply-templates mode="secondStage" select="text" />
            <xsl:apply-templates mode="secondStage" select="proficiency" />
            <xsl:apply-templates mode="secondStage" select="modifier" />
        </feat>
    </xsl:template>

    <!-- Merge / extend items (second stage) -->

    <xsl:template name="items-extendable">
        <xsl:param name="items" />
        <xsl:for-each select="$items">
            <xsl:sort select="." />
            <xsl:choose>
                <!-- Check if there's a duplicate -->
                <xsl:when test="count($items[name = current()/name]) &gt; 1">
                    <!-- Use the original class that includes the "type" element -->
                    <!-- Important: Duplicate items should only specify additional attributes like rolls -->
                    <xsl:if test="type">
                        <xsl:call-template name="single-item">
                            <xsl:with-param name="items" select="$items" />
                            <xsl:with-param name="item" select="." />
                        </xsl:call-template>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="single-item">
                        <xsl:with-param name="items" select="$items" />
                        <xsl:with-param name="item" select="." />
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="single-item">
        <xsl:param name="item" />
        <xsl:param name="items" />
        <xsl:variable name="modifier-list">
            <xsl:for-each-group select="$items[name = $item/name]/modifier" group-by=".">
                <xsl:sort select="." />
                <xsl:sequence select='.'/>
            </xsl:for-each-group>
        </xsl:variable>
        <xsl:variable name="item-roll-list">
            <xsl:for-each-group select="$items[name = $item/name]/roll" group-by=".">
                <xsl:sort select="@num" data-type="number"/>
                <xsl:sort select="@die" data-type="number"/>
                <xsl:sequence select='.'/>
            </xsl:for-each-group>
        </xsl:variable>
        <xsl:variable name="item-rarity-list">
            <xsl:for-each-group select="$items[name = $item/name]/rarity" group-by=".">
                <xsl:sort select="starts-with(., 'c')" data-type="number"/>
                <xsl:sort select="starts-with(., 'u')" data-type="number"/>
                <xsl:sort select="starts-with(., 'r')" data-type="number"/>
                <xsl:sort select="starts-with(., 'v')" data-type="number"/>
                <xsl:sort select="starts-with(., 'l')" data-type="number"/>
                <xsl:sequence select='.'/>
            </xsl:for-each-group>
        </xsl:variable>
        <xsl:variable name="item-dmg-rarity-list">
            <xsl:for-each-group select="$items[name = $item/name]/dmg-rarity" group-by=".">
                <xsl:sort select="starts-with(., 'c')" data-type="number"/>
                <xsl:sort select="starts-with(., 'u')" data-type="number"/>
                <xsl:sort select="starts-with(., 'r')" data-type="number"/>
                <xsl:sort select="starts-with(., 'v')" data-type="number"/>
                <xsl:sort select="starts-with(., 'l')" data-type="number"/>
                <xsl:sequence select='.'/>
            </xsl:for-each-group>
        </xsl:variable>
        <xsl:variable name="item-attunement-list">
            <xsl:for-each select="$items[name = $item/name]/attunement">
                <xsl:sort select="."/>
                <xsl:sequence select='.'/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="item-classification-list">
            <xsl:for-each select="$items[name = $item/name]/classification">
                <xsl:sort select="."/>
                <xsl:sequence select='.'/>
            </xsl:for-each>
        </xsl:variable>
        <item>
            <xsl:apply-templates mode="secondStage" select="$item/name" />
            <xsl:apply-templates mode="secondStage" select="$item/type" />
            <xsl:call-template name="single-item-magic-detail">
                <xsl:with-param name="item" select="$item" />
                <xsl:with-param name="item-rarity-list" select="$item-rarity-list" />
                <xsl:with-param name="item-dmg-rarity-list" select="$item-dmg-rarity-list" />
                <xsl:with-param name="item-attunement" select="head($item-attunement-list)" />
                <xsl:with-param name="item-classification" select="head($item-classification-list)" />
            </xsl:call-template>
            <xsl:apply-templates mode="secondStage" select="$item/weight" />
            <xsl:apply-templates mode="secondStage" select="$item/text" />
            <xsl:apply-templates mode="secondStage" select="$item-roll-list" />
            <xsl:apply-templates mode="secondStage" select="$item/value" />
            <xsl:apply-templates mode="secondStage" select="$modifier-list" />
            <xsl:apply-templates mode="secondStage" select="$item/ac" />
            <xsl:apply-templates mode="secondStage" select="$item/strength" />
            <xsl:apply-templates mode="secondStage" select="$item/stealth" />
            <xsl:apply-templates mode="secondStage" select="$item/dmg1" />
            <xsl:apply-templates mode="secondStage" select="$item/dmg2" />
            <xsl:apply-templates mode="secondStage" select="$item/dmgType" />
            <xsl:apply-templates mode="secondStage" select="$item/property" />
            <xsl:apply-templates mode="secondStage" select="$item/range" />
        </item>
    </xsl:template>

    <xsl:template name="single-item-magic-detail">
        <xsl:param name="item" />
        <xsl:param name="item-rarity-list" />
        <xsl:param name="item-dmg-rarity-list" />
        <xsl:param name="item-attunement" />
        <xsl:param name="item-classification" />

        <xsl:apply-templates mode="secondStage" select="$item/detail" />
        <xsl:apply-templates mode="secondStage" select="$item-attunement" />

        <!-- Emit magic if either the item specified it was a magic item, or the dmg indicated it was a magic item -->
        <xsl:if test="$item/input-magic eq 'YES' or $item/dmg-magic eq 'YES'">
            <xsl:element name="magic">YES</xsl:element>
        </xsl:if>
        <!-- Emit rarity: prefer item defined, then dmg defined, or fallback to guesses -->
        <xsl:choose>
            <xsl:when test="$item-rarity-list and $item-rarity-list ne ''">
                <xsl:element name="rarity"><xsl:apply-templates mode="secondStage" select="$item-rarity-list" /></xsl:element>
            </xsl:when>
            <xsl:when test="$item-dmg-rarity-list and $item-dmg-rarity-list ne ''">
                <xsl:element name="rarity"><xsl:apply-templates mode="secondStage" select="$item-dmg-rarity-list" /></xsl:element>
            </xsl:when>
            <!-- Fallback values: Armor has a higher rarity than other items -->
            <xsl:when test="contains($item/name, '+3') and matches($item/type, '(HA|MA|LA)')">
                <xsl:element name="rarity">legendary</xsl:element>
            </xsl:when>
            <xsl:when test="(contains($item/name, '+2') and matches($item/type, '(HA|MA|LA)')) or contains($item/name, '+3')">
                <xsl:element name="rarity">very rare</xsl:element>
            </xsl:when>
            <xsl:when test="(contains($item/name, '+1') and matches($item/type, '(HA|MA|LA)')) or contains($item/name, '+2')">
                <xsl:element name="rarity">rare</xsl:element>
            </xsl:when>
            <xsl:when test="contains($item/name, '+1')">
                <xsl:element name="rarity">uncommon</xsl:element>
            </xsl:when>
        </xsl:choose>
        <xsl:choose>
            <xsl:when test="$item-classification and $item-classification ne ''">
                <xsl:element name="classification"><xsl:value-of select="$item-classification" /></xsl:element>
            </xsl:when>
            <xsl:when test="$item/dmg-classification and $item/dmg-classification ne ''">
                <xsl:element name="classification"><xsl:value-of select="$item/dmg-classification" /></xsl:element>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <!--Convert rarity elements into comma separated string-->
    <xsl:template mode="secondStage" match="rarity">
        <xsl:if test="position() > 1">, <xsl:if test="position()=last()">or </xsl:if></xsl:if>
        <xsl:value-of select="." />
    </xsl:template>

    <!-- Disambiguate monsters (second stage) -->

    <xsl:template name="monster-unique-filter">
        <xsl:param name="monsters" />
        <xsl:for-each-group select="$monsters" group-by="./name">
            <xsl:sort select="."/>
            <xsl:call-template name="single-monster">
                <xsl:with-param name="monster" select="." />
            </xsl:call-template>
        </xsl:for-each-group>
    </xsl:template>

    <xsl:template name="single-monster">
        <xsl:param name="monster" />
        <monster>
            <xsl:apply-templates mode="secondStage" select="$monster/name" />
            <xsl:apply-templates mode="secondStage" select="$monster/size" />
            <xsl:apply-templates mode="secondStage" select="$monster/type" />
            <xsl:apply-templates mode="secondStage" select="$monster/alignment" />
            <xsl:apply-templates mode="secondStage" select="$monster/ac" />
            <xsl:apply-templates mode="secondStage" select="$monster/hp" />
            <xsl:apply-templates mode="secondStage" select="$monster/speed" />
            <xsl:apply-templates mode="secondStage" select="$monster/str" />
            <xsl:apply-templates mode="secondStage" select="$monster/dex" />
            <xsl:apply-templates mode="secondStage" select="$monster/con" />
            <xsl:apply-templates mode="secondStage" select="$monster/int" />
            <xsl:apply-templates mode="secondStage" select="$monster/wis" />
            <xsl:apply-templates mode="secondStage" select="$monster/cha" />
            <xsl:apply-templates mode="secondStage" select="$monster/save" />
            <xsl:apply-templates mode="secondStage" select="$monster/skill" />
            <xsl:apply-templates mode="secondStage" select="$monster/resist" />
            <xsl:apply-templates mode="secondStage" select="$monster/vulnerable" />
            <xsl:apply-templates mode="secondStage" select="$monster/immune" />
            <xsl:apply-templates mode="secondStage" select="$monster/conditionImmune" />
            <xsl:apply-templates mode="secondStage" select="$monster/senses" />
            <xsl:apply-templates mode="secondStage" select="$monster/passive" />
            <xsl:apply-templates mode="secondStage" select="$monster/languages" />
            <xsl:apply-templates mode="secondStage" select="$monster/cr" />
            <xsl:apply-templates mode="secondStage" select="$monster/trait" />
            <xsl:apply-templates mode="secondStage" select="$monster/action" />
            <xsl:apply-templates mode="secondStage" select="$monster/legendary" />
            <xsl:apply-templates mode="secondStage" select="$monster/reaction" />
            <xsl:apply-templates mode="secondStage" select="$monster/spells" />
            <xsl:for-each-group select="$monster/slots" group-by=".">
                <xsl:copy-of select="current-group( )[1]"/>
            </xsl:for-each-group>
            <xsl:apply-templates mode="secondStage" select="$monster/description" />
            <xsl:apply-templates mode="secondStage" select="$monster/environment" />
        </monster>
    </xsl:template>

    <!-- Disambiguate races (second stage) -->

    <xsl:template name="race-unique-filter">
        <xsl:param name="races" />
        <xsl:for-each-group select="$races" group-by="./name">
            <xsl:call-template name="single-race">
                <xsl:with-param name="race" select="." />
            </xsl:call-template>
        </xsl:for-each-group>
    </xsl:template>

    <xsl:template name="single-race">
        <xsl:param name="race" />
        <race>
            <xsl:apply-templates mode="secondStage" select="$race/name" />
            <xsl:apply-templates mode="secondStage" select="$race/size" />
            <xsl:apply-templates mode="secondStage" select="$race/speed" />
            <xsl:apply-templates mode="secondStage" select="$race/ability" />
            <xsl:apply-templates mode="secondStage" select="$race/proficiency" />
            <xsl:apply-templates mode="secondStage" select="$race/spellAbility" />
            <xsl:apply-templates mode="secondStage" select="$race/trait" />
            <xsl:apply-templates mode="secondStage" select="$race/modifier" />
        </race>
    </xsl:template>

    <!-- Merge and extend spells (second stage) -->

    <xsl:template name="spells-extendable">
        <xsl:param name="spells" />
        <xsl:for-each select="$spells">
            <xsl:sort select="."/>
            <xsl:choose>
                <!-- Check if there's a duplicate -->
                <xsl:when test="count($spells[name = current()/name]) &gt; 1">
                    <!-- Use the original spell that includes the "level" element -->
                    <!-- Important: Duplicate spells should only contain "name", and
                         "classes" and/or "roll" elements -->
                    <xsl:if test="level">
                        <xsl:call-template name="single-spell">
                            <xsl:with-param name="spells" select="$spells" />
                            <xsl:with-param name="spell" select="." />
                        </xsl:call-template>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="single-spell">
                        <xsl:with-param name="spells" select="$spells" />
                        <xsl:with-param name="spell" select="." />
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="single-spell">
        <xsl:param name="spell" />
        <xsl:param name="spells" />

        <xsl:variable name="spell_roll_list">
            <xsl:for-each-group select="$spells[name = $spell/name]/roll" group-by=".">
                <xsl:sort select="@num" data-type="number"/>
                <xsl:sort select="@die" data-type="number"/>
                <xsl:sequence select='.'/>
            </xsl:for-each-group>
        </xsl:variable>
        <xsl:variable name="sorted_class_list">
            <xsl:for-each-group select="$spells[name = $spell/name]/classes/spellClass" group-by=".">
                <xsl:sort select="."/>
                <xsl:sequence select='.'/>
            </xsl:for-each-group>
        </xsl:variable>
        <spell>
            <xsl:apply-templates mode="secondStage" select="$spell/name" />
            <xsl:apply-templates mode="secondStage" select="$spell/level" />
            <xsl:apply-templates mode="secondStage" select="$spell/school" />
            <xsl:apply-templates mode="secondStage" select="$spell/ritual" />
            <xsl:apply-templates mode="secondStage" select="$spell/time" />
            <xsl:apply-templates mode="secondStage" select="$spell/range" />
            <xsl:apply-templates mode="secondStage" select="$spell/components" />
            <xsl:apply-templates mode="secondStage" select="$spell/duration" />
            <classes>
                <xsl:apply-templates mode="secondStage" select="$sorted_class_list"/>
            </classes>
            <xsl:apply-templates mode="secondStage" select="$spell/source" />
            <xsl:apply-templates mode="secondStage" select="$spell/text" />
            <xsl:apply-templates mode="secondStage" select="$spell_roll_list" />
        </spell>
    </xsl:template>

    <!-- Final Stage -->

    <!--empty template suppresses these working attributes and elements -->
    <xsl:template mode="finalStage" match="@die" />
    <xsl:template mode="finalStage" match="@num" />
    <xsl:template mode="finalStage" match="rarity" />
    <xsl:template mode="finalStage" match="attunement" />
    <xsl:template mode="finalStage" match="classification" />

    <!-- Flatten all collected magic indicators back into the detail string -->
    <xsl:template mode="finalStage" match="item/detail">
        <xsl:element name="detail">
            <xsl:call-template name="final-detail">
                <xsl:with-param name="item" select="ancestor::item" />
            </xsl:call-template>
        </xsl:element>
    </xsl:template>

    <xsl:template name="final-detail">
        <xsl:param name="item"/>
        <xsl:variable name="classification">
            <xsl:choose>
                <xsl:when test="$item/classification and $item/classification ne ''"><xsl:value-of select="$item/classification" /></xsl:when>
                <xsl:when test="matches($item/rarity, '(legendary|rare)')">major</xsl:when>
                <xsl:when test="$item/rarity and $item/rarity ne ''">minor</xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="rarity">
            <xsl:if test="$item/rarity and $item/rarity ne ''"><xsl:if test="$classification">, </xsl:if><xsl:value-of select="$item/rarity" /></xsl:if>
        </xsl:variable>
        <xsl:variable name="attunement">
            <xsl:if test="$item/attunement and $item/attunement ne ''"><xsl:value-of select="concat(' ', $item/attunement)" /></xsl:if>
        </xsl:variable>
        <xsl:variable name="magic-element">
            <xsl:value-of select="string-join(($classification, $rarity, $attunement), '')" />
        </xsl:variable>
        <xsl:variable name="weapon-kind">
            <xsl:choose>
                <xsl:when test="contains($item/property, 'M')">Martial</xsl:when>
                <xsl:otherwise>Simple</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="typeString">
            <xsl:choose>
                <xsl:when test="$item/type eq 'LA'">Armor (light)</xsl:when>
                <xsl:when test="$item/type eq 'MA'">Armor (medium)</xsl:when>
                <xsl:when test="$item/type eq 'HA'">Armor (heavy)</xsl:when>
                <xsl:when test="$item/type eq 'S'">Armor (shield)</xsl:when>
                <xsl:when test="$item/type eq 'M'">Weapon (<xsl:value-of select="$weapon-kind" /> melee)</xsl:when>
                <xsl:when test="$item/type eq 'R'">Weapon (<xsl:value-of select="$weapon-kind" /> ranged)</xsl:when>
                <xsl:when test="$item/type eq 'A'">Ammunition</xsl:when>
                <xsl:when test="$item/type eq 'G'">Adventuring gear</xsl:when>
                <xsl:when test="$item/type eq 'W'">Wondrous item</xsl:when>
                <xsl:when test="$item/type eq 'RD'">Rod</xsl:when>
                <xsl:when test="$item/type eq 'ST'">Staff</xsl:when>
                <xsl:when test="$item/type eq 'WD'">Wand</xsl:when>
                <xsl:when test="$item/type eq 'RG'">Ring</xsl:when>
                <xsl:when test="$item/type eq 'P'">Potion</xsl:when>
                <xsl:when test="$item/type eq 'SC'">Scroll</xsl:when>
                <xsl:when test="$item/type eq '$'">Coins and gems</xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:for-each select="($typeString, $magic-element, $item/detail)">
            <xsl:if test=". ne '' and not(starts-with(., ' '))and position() > 1">, </xsl:if>
            <xsl:value-of select="." />
        </xsl:for-each>
    </xsl:template>

    <!--Convert spellClass elements into comma separated string-->
    <xsl:template mode="finalStage" match="spellClass">
        <xsl:if test="position() > 1">, </xsl:if>
        <xsl:value-of select="." />
    </xsl:template>

    <xsl:template mode="finalStage" match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates mode="finalStage" select="@* | node()"/>
        </xsl:copy>
    </xsl:template>

</xsl:transform>
