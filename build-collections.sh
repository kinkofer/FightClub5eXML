cd Collections
for i in *.xml; do xsltproc -o ../Compendiums/$i ../Utilities/merge.xslt $i; done
