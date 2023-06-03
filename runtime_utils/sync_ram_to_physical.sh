#!/bin/sh -e

## === Change to the directory containing the script ============ ##

shell="$0"

while [ -h "$shell" ] ; do
   shell="$(readlink "$shell")"
done

script_dir="$(dirname "$shell")"

echo "Script dir: $script_dir"

## === Include needed files ===================================== ##

. ../vars.include

## === Perform needed actions =================================== ##

echo "Not yet implemented - please raise an issue if you have an exact use-case."
