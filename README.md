# Fight Club 5e XML

Creating XML files of all official D&D sources compatible with Fight Club 5e and Game Master 5e apps for iOS and Android.


## Usage

Final XML files are released on a shared Dropbox. If you're here to import the files into your app, instructions are in the Dropbox.

This repository is not an application in itself. But you can use it to build your own custom Compendium (see below).


## Contributing

If you'd like to contribute, feel free to fork the repository and submit pull requests with your changes.


## Development

* The XML files in the FightClub5eXML directory are Compendiums organized by source book. 
* The files in Collections define which sources are merged into their own Compendium XML.
* When the master branch is updated, Travis CI validates the XML, builds the Compendiums, and deploys to Dropbox.


### Manual Validation

While you add to XML files, you can manually validate the XML to catch any errors.

You can find an online XML Linter or use xmllint in the command line. The schema files are in the Utilities folder.

Here is an example, running xmllint at the top level of the repo, using the compendium schema to validate an xml file in Sources:

```bash
xmllint --noout --schema Utilities/compendium.xsd FightClub5eXML/Sources/CorePlusUnearthedArcana.xml
```


## Build your own Compendium

### Create a collection file

A collection file is an XML file that lists which sources you would like to merge into your custom Compendium. It must follow this format:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<collection>
    <doc href="../FightClub5eXML/Sources/PlayersHandbook.xml" />
    <doc href="../FightClub5eXML/Sources/DungeonMastersGuide.xml" />
    <doc href="../FightClub5eXML/Sources/MonsterManual.xml" />
</collection>
```
You can have one or more `<doc>` tags. Each doc must reference an xml file with a `<compendium>` root element. 

The name of the collection file will be the name of the final Compendium.

### Execute the merge

With your collection in place, you're ready to build your Compendium by merging the sources together.

Execute this line in your shell at the top level of the repo:

```bash
for i in Collections/*.xml; do xsltproc -o FightClub5eXML/$i Utilities/merge.xslt $i; done
```

This is the same line that is executed in our .travis.yml and will place all combined Compendiums in FightClub5eXML/Collections/