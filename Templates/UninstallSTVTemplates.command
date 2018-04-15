#! /bin/sh

set -e

echo "\n\n**** Uninstalling STV 5.0 Templates..."

DestinationFolder="$HOME/Library/Developer/Xcode/Templates"

rm -rf "$DestinationFolder/Project Templates/iOS/Sensible TableView"
rm -rf "$DestinationFolder/File Templates/iOS/Sensible TableView"

echo "\n\n** Uninstall complete!\n\n** Make sure you RESTART Xcode for the changes to take effect. **\n\n"

