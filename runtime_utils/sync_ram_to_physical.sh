#!/bin/bash -feu

# This script syncs any HOME_DIR_OVERRIDES directories back to the physical
# disk. It does not sync OS paths like /bin, /usr, /etc.

## === Change to the directory containing the script ============ ##

shell="$0"

while [ -h "$shell" ] ; do
   shell="$(readlink "$shell")"
done

script_dir="$(dirname "$shell")"

echo "Working in: $script_dir"
cd "$script_dir"

## === Include needed files ===================================== ##

. ../vars.include

## === Perform needed actions =================================== ##

if [ "${#HOME_DIR_OVERRIDES[@]}" = '0' ]; then
  echo 'No home overrides have been specified in vars.include.'
  echo 'Nothing to do.'
  exit 1
fi

if test -z "$HOME_MOUNT_COMMAND" || test -z "$HOME_SYNC_LOCATION" || test -z "$HOME_UNADULTERATED"; then
  echo 'This script is used to copy home dir overrides in RAM back to the real disk.'
  echo 'The following variables needs to be defined to use this script:'
  echo '* HOME_MOUNT_COMMAND'
  echo '* HOME_SYNC_LOCATION'
  echo '* HOME_UNADULTERATED'
  exit 1
fi

sync_to_physical() {
  action="$1"
  # A base path might look something like /home/user/some_dir
  for base_path in "${HOME_DIR_OVERRIDES[@]}"; do
    ramdir="$RAMDISK_DIR/$base_path"
    physical="$HOME_UNADULTERATED/$base_path"

    if ! test -d "$ramdir"; then
      echo "Warning: directory not found, will be skipped: $ramdir"
      continue
    fi

    if [ "$(readlink -f "$physical")" = '/' ] || [ "$(readlink -f "$ramdir")" = '/' ]; then
      echo "Error: one or more paths resolves to /"
      echo "source='$physical'"
      echo "destination='$ramdir'"
      echo 'Stopping execution for safety reasons.'
      exit 1
    fi
    if [ "$action" = "dry" ]; then
      echo "* Copy $ramdir to $physical"
    elif [ "$action" = "start" ]; then
      echo "* Copying $ramdir to $physical"
      $RSYNC -v "$ramdir/" "$physical"
    fi
  done
}

echo
echo "The following operations will performed:"
echo
# 'dry' here means dry run.
sync_to_physical 'dry'

echo
echo "Press enter to continue, or Ctrl+C to cancel."
read answer
echo

# Sync files to physical drive.
sync_to_physical 'start'

echo
echo "All operations completed successfully."
