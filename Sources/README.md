# Sources

## Adding a Source

New material is added to D&D 5e quite frequently, especially through Unearthed Arcana which is typically used for beta testing. Keeping each source in its own file makes it easier to add new content and select which sources you want to include in your Compendium.

Each source is like its own Compendium, and could potentially be imported on its own, with two exceptions (classes and spells) which are explained below. The structure of the XML file should be:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<compendium version="5" auto_indent="NO">
	<!-- Items -->
	<!-- Races -->
	<!-- Classes -->
	<!-- Feats -->
	<!-- Backgrounds -->
	<!-- Spells -->
	<!-- Monsters -->
</compendium>
```

Add the specific elements under the appropriate comment (e.g. `<item>...</item>` goes under `<!-- Items -->`). See the Fight Club Import Tutorial for the format of each element, or use our existing sources as a foundation. You can also check out the schema we use for validation in `Utilities/compendium.xsd`.

When merged with other sources (see "Build Your Own Compendium" below), items, races, feats, backgrounds, and monsters are all added to the resulting Compendium. It's recommended that subraces be added as their own race. Classes and spells, however, are merged when their names match, making it easier to add subclasses without modifying existing sources.

#### Subclasses

Adding a subclass in Fight Club is as easy as adding new `<autolevel>` tags to a class. When selecting sources for a Compendium, the merge finds classes with matching `<name>` tags and appends the `<autolevel>` tags to the end.

```xml
<class>
	<name>Barbarian</name>
	<autolevel level="3">
		<feature optional="YES">...</feature>
	</autolevel>
	...
</class>
```

Because the rest of the class data is not included, this means you would need to include the original source of the class in your Compendium as well.

#### Spells

In the Fight Club compendium, spell lists are defined by the spell, not the class. If you want to add a spell to a class list, you would need to modify the spell's `<classes>` tag. This can be done without modifying the original spell by adding only the name and new class in your source XML. During the Compendium merge, the value of `<classes>` is concatenated to any matching spells.

New source:

```xml
<spell>
	<name>Acid Splash</name>
	<classes>Artificer</classes>
</spell>
```

Resulting merge with original source:

```xml
  <spell>
    <name>Acid Splash</name>
    <level>0</level>
    <school>C</school>
    ...
    <classes>Fighter, Rogue, Sorcerer, Wizard, Artificer</classes>
    ...
  </spell>
```

Just like classes, the original source would be required in order for the full spell details to appear in the Compendium.

## Manual Validation

While you add to XML source files, you can manually validate the XML to catch any errors.

You can find an online XML Linter or use xmllint in the command line. The schema files are in the Utilities folder.

Here is an example, running xmllint at the top level of the repo, using the compendium schema to validate an xml file in Sources:

```bash
xmllint --noout --schema Utilities/compendium.xsd Sources/CoreRulebooks.xml
```

## Build Your Own Compendium

### Create a collection file

A collection file is an XML file that lists which sources you would like to merge into your custom Compendium. It must follow this format (assuming you create your file within the `Collections` directory):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<collection>
    <doc href="../Sources/PlayersHandbook.xml" />
    <doc href="../Sources/DungeonMastersGuide.xml" />
    <doc href="../Sources/MonsterManual.xml" />
</collection>
```
You can have one or more `<doc>` tags. Each doc must reference an xml file with a `<compendium>` root element. 

The name of the collection file will be the name of the final Compendium.

### Execute the merge

With your collection in place, you're ready to build your Compendium by merging the sources together.

See the instructions to `Compile a Collection Into a Compendium` in the root-level [README](/README.md).
