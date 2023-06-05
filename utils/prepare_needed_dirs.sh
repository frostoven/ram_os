#!/bin/bash -feu

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

# Set up unadulterated home mount.
if test -n "$HOME_MOUNT_COMMAND"; then
  if test -z "$HOME_SYNC_LOCATION"; then
    echo "Error: HOME_MOUNT_COMMAND requires that HOME_SYNC_LOCATION is set."
    exit 1
  fi

  # Create physical home dir.
  mkdir -p "$HOME_UNADULTERATED"

  # Mount the original home.
  echo "$HOME_MOUNT_COMMAND"
  $HOME_MOUNT_COMMAND || (echo "Mount command failed; aborting." && exit 1)

  # Do sanity check.
  if ! test -d "$HOME_SYNC_LOCATION"; then
    echo
    echo "Home sync location ($HOME_SYNC_LOCATION) does not exist."
    echo "Trace:"
    echo " * HOME_MOUNT_COMMAND = $HOME_MOUNT_COMMAND"
    echo " * HOME_UNADULTERATED = $HOME_UNADULTERATED"
    echo " * HOME_SYNC_LOCATION = $HOME_SYNC_LOCATION"
    echo
    echo 'HOME_MOUNT_COMMAND should be the command used to mount your home-containing drive to HOME_UNADULTERATED.'
    echo 'HOME_SYNC_LOCATION should then be a valid /home location inside HOME_UNADULTERATED'
    echo
    echo "Please undo the mount command's effect, double-check your paths, and then try again."
    exit 1
  fi
fi
