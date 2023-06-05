#!/bin/bash -feu

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

# This will remove the ramdisk dir only if it's empty. Nothing will happen if
# it contains files, or doesn't exist. This is used for sanity checks below.
rmdir "$RAMDISK_DIR" 2>/dev/null || true

# Check if the "things have completed" file exists.
if test -f "$RAMDISK_DIR/ram_os_active_1166877"; then
  echo 'This system is already active; your OS should be in RAM.'
  echo 'You may reboot your system when you are ready to undo this.'
  exit 0
fi

# Ramdisk should not exist at this stage. If it does, something's wrong.
if test -d "$RAMDISK_DIR"; then
  echo 'This system is already active, or has failed to start.'
  echo 'This script will now terminate. If you previously received an error,'
  echo 'then your system is in an incomplete state and should be rebooted'
  echo 'to undo the all this before doing any work.'
  exit 1
fi

# Do brute crash if one of more needed vars are not set.
echo "Checking that all needed variables in vars.include have been defined."
_void="$VERSION $OS_DIRS $DM_STOP_COMMAND $HOME_DIR"
_void="$CHECK_AVAILABLE_RAM $ADDITIONAL_RAM_GB ${#HOME_DIR_OVERRIDES[@]}"
_void="$HOME_UNADULTERATED $HOME_MOUNT_COMMAND $HOME_SYNC_LOCATION"
_void="$RAMDISK_DIR $UPDATE_SYSCTL $OS_ROOT"
_void=""
echo "...done"

# Do simple version check.
template_version="$(grep -o 'VERSION.*"$' vars.include.example)"
actual_version="VERSION=\"$VERSION\""
if [ "$template_version" != "$actual_version" ]; then
  echo "Your vars.include file is out of date. Please import all new variables"
  echo "from vars.include.example into vars.example, and then update the version"
  echo "number in your copy of vars.include"
  echo "Expected: $template_version; got: $actual_version."
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
. ./prepare_needed_dirs.sh
. ./setup_ram_disk.sh

# The critical parts of the script is done; set the completion flag to prevent
# additional runs until reboot.
touch "$RAMDISK_DIR/ram_os_active_1166877" || \
  echo "Warning: could not create $RAMDISK_DIR/ram_os_active_1166877"

if [ "$UPDATE_SYSCTL" = '1' ]; then
  echo 'Applying new /etc/sysctl.conf file.'
  sysctl -p || echo 'Warning: failed to run "sysctl -p"'
fi

echo
echo 'Setup complete.'
echo 'You may reboot your system when you want to undo this.'
echo 'Please restart your display manager to start working.'
