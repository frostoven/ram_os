#!/bin/sh -e

## === Change to the directory containing the script ============ ##

shell="$0"

while [ -h "$shell" ] ; do
   shell="$(readlink "$shell")"
done

script_dir="$(dirname "$shell")"

cd "$script_dir"
echo "Working in: $script_dir"

## === Include needed files ===================================== ##

if ! test -f ./vars.include; then
  echo "./vars.include is missing; please copy and modify ./vars.include.example"
  exit 1
fi

. ./vars.include

## === Do safety check ========================================== ##

# This will remove the ramdisk dir only if it's empty. Nothing will happen if it
# contains files, or doesn't exist.
rmdir "$RAMDISK_DIR" 2>/dev/null || true

if test -f "$RAMDISK_DIR/ram_os_active_1166877"; then
  echo 'This system is already active; your OS should be in RAM.'
  echo 'You may reboot your system when you are ready to undo this.'
  exit 0
fi

if test -d "$RAMDISK_DIR"; then
  echo 'This system is already active, or has failed to start.'
  echo 'This script will now terminate. If you previously received an error,'
  echo 'then your system is in an incomplete state and should be rebooted'
  echo 'to undo the all this before doing any work.'
  exit 1
fi

## === Start the process ======================================== ##

# Flush the disk.
sync

# Stop the display manager.
echo "Stopping the display manager."
echo "$DM_STOP_COMMAND"
$DM_STOP_COMMAND
sleep 3

cd utils
. ./create_needed_dirs.sh
. ./setup_ram_disk.sh

touch "$RAMDISK_DIR/ram_os_active_1166877"

echo
echo 'Setup complete.'
echo 'You may reboot your system when you want to undo this.'
echo 'Please restart your display manager to start working.'
