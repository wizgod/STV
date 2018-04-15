#! /bin/sh

set -e

echo "\n\n**** Installing STV 5.0 Templates..."

STVFolder="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
STVTemplatesPath="$STVFolder"
DestinationFolder="$HOME/Library/Developer/Xcode/Templates"

# first uninstall old templates
/bin/bash "$STVFolder/UninstallSTVTemplates.command" > /dev/null


mkdir -p "$DestinationFolder"

# install Project Templates
if cp -rf "$STVTemplatesPath/Project Templates" "$DestinationFolder"
then
	echo "** Project Templates installed."
else
	echo "\n\n** Error installing $STVTemplatesPath/Project Templates to $DestinationFolder"
	exit 1
fi

# install File Templates
if cp -rf "$STVTemplatesPath/File Templates" "$DestinationFolder"
then
	echo "** File Templates installed."
else
	echo "\n\n** Error installing $STVTemplatesPath/File Templates to $DestinationFolder"
	exit 1
fi

echo "\n\n** Installation successful!\n\n** Make sure you RESTART Xcode for the templates to get loaded **\n\n"