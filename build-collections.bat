@echo off
if "%1"=="" (
	echo "Usage: build-collections.bat path-to-collections/collection-file.xml path-to-utilities/merge.xml [optional path-to-compendium-destination-directory]
	echo "Include path to XML collection file(s) as the first parameter to this batch script."
	exit /b
)

if "%2"=="" (
	echo "Usage: build-collections.bat path-to-collections/collection-file.xml path-to-utilities/merge.xml [optional path-to-compendium-destination-directory]
	echo "Include the path to the merge.xml file, typically at {repository}/Utilities/merge.xml, as the second parameter to this batch script."
	exit /b
)

for %%A in ("%1") do (
	if "%3"=="" (
		xsltproc -o "%%~nxA" "%~f2" "%%~fA"
	) else (
		if exist "%3\" (
			xsltproc -o "%~f3\%%~nxA" "%~f2" "%%~fA"
		) else (
			mkdir %3
			xsltproc -o "%~f3\%%~nxA" "%~f2" "%%~fA"
		)
	)
)