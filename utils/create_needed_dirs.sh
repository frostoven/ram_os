#!/bin/sh -e

## === Include needed files ===================================== ##

. ../vars.include

## === Do sanity checks ========================================= ##

if ! test -d "$HOME_DIR"; then
  echo "Request home parent dir ($HOME_DIR) does not exist. This is an error."
  exit 1
fi

## === Perform needed actions =================================== ##

echo "Creating needed directories."

# Create ramdisk dir.
mkdir -p "$RAMDISK_DIR"

# Create physical home dir.
mkdir -p "$HOME_NEW_DIR"
