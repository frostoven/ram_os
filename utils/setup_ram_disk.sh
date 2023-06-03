#!/bin/sh -e

## === Include needed files ===================================== ##

. ../vars.include

## === Perform needed actions =================================== ##


# Note: do not quote OS_DIRS and HOME_DIR_OVERRIDES; these vars rely on
# splitting to work.
all_files_list=''
for dir in $OS_DIRS $HOME_DIR_OVERRIDES; do 
  all_files_list="$all_files_list $OS_ROOT/$dir"
done 

if [ "$CHECK_AVAILABLE_RAM" = '1' ]; then
  echo 'Calculating RAM requirements. This check can be disabled in vars.include'

  # Dev note: don't quote $all_files_list, it relies on splitting.
  ram_needed="$(du -cb -- $all_files_list 2>/dev/null | tail -n1 | awk '{ printf $1 }')"
  ram_available="$(grep 'MemAvailable:' /proc/meminfo | awk '{ printf $2 }')"

  # ram_available is in Kb. Bump 3 orders.
  ram_available="$(echo "$ram_available 1000" | awk '{ printf $1 * $2 }')"

  needed_friendly="$(echo "$ram_needed 1000 1000 1000" | awk '{ printf("%.0f\n", ($1 / $2 / $3 / $4)); }')"
  have_friendly="$(echo "$ram_available 1000 1000 1000" | awk '{ printf("%.0f\n", ($1 / $2 / $3 / $4)); }')"

  if [ "$ram_needed" -gt "$ram_available" ]; then
    echo "Fatal error: You appear to have too little RAM to run this script."
    echo "             Needed: $needed_friendly""G; have: $have_friendly""G"
    exit 1
  else
    echo "RAM is sufficient; needed: $needed_friendly""G; have: $have_friendly""G"

    total_assigned="$(echo "$needed_friendly $ADDITIONAL_RAM_GB" | awk '{ printf $1 + $2 }')"
    echo "Assigning $total_assigned""G to ramdisk."
    mount -t tmpfs -o size="$total_assigned""G" tmpfs "$RAMDISK_DIR"
  fi
else
  echo 'Skipping RAM check. Half of total RAM capacity will be assigned.'
  # This will create a disk with size 50% of total RAM capacity.
  mount -t tmpfs none "$RAMDISK_DIR"
fi

# Bind /home* to /mnt/home*.
mount -o bind "$HOME_DIR" "$HOME_NEW_DIR"

# Do safety checks and create all the needed ramdisk dirs. It then copies all
# OS dirs to ramdisk. This operation is idempotent.
rsync_files() {
  # If this is the first run, we do additional safety checks. This should be
  # either 'y' for yes or 'n' for no.
  first_run="$1"

  # Dev note: don't quote $OS_DIRS, it relies on splitting.
  for dir in $OS_DIRS; do
    source_path="$OS_ROOT/$dir"
    ramdisk_path="$RAMDISK_DIR/$dir"

    if ! test -d "$source_path"; then
      echo "Fatal error: '$source_path' does not exist."
      echo "Your machine is now in an inconsistent state. Please reboot ASAP."
      exit 1
    fi

    echo "* Mirroring '$source_path' to '$ramdisk_path'"

    # Look for obvious problems.
    if [ "$first_run" = 'y' ]; then

      # I'd personally prefer putting this after the safety check, but the safety
      # requires this be done, first.
      mkdir -p "$ramdisk_path"

      abs_source_path="$(readlink -f "$source_path")"
      abs_ramdisk_path="$(readlink -f "$ramdisk_path")"

      # Safety checks.
      if [ "$abs_source_path" = '/' ] || [ "$abs_ramdisk_path" = '/' ] || \
         [ "$abs_source_path" = "$abs_ramdisk_path" ];
      then
        echo "Safety check failed; one or more path are pointing to dangerous locations."
        echo "Trace:"
        echo " * 'source_path' should not resolve to '/'; actual value: '$abs_source_path'"
        echo " * 'ramdisk_path' should not resolve to '/'; actual value: '$abs_ramdisk_path'"
        echo " * 'source_path' and 'abs_ramdisk_path' may not resolve to the same path; actual: source_path is '$abs_source_path', ramdisk_path is '$abs_ramdisk_path'"
        exit 1
      else
        echo " * Safety checks passed; source points to '$abs_source_path', target points to '$abs_ramdisk_path'"
      fi

      # Note: the trailing slashes are important; they ensure rsync merges the
      # directories. This is somewhat dangerous in automation, which is why the
      # check above ensures everything is pointing to the correct place.
      rsync -a "$source_path/" "$ramdisk_path/"
    else
      # Note: to support live OS replacements, don't use OS_ROOT in the target.
      echo "* Overlaying: '$ramdisk_path' => '/$dir'"

      # Repeat the process, just to be safe. Things are always faster the
      # second time, which slightly reduces the possibility of newly created
      # files not existing. The delete flag removes any stale files that may
      # have come into existence.
      rsync -a --delete "$source_path/" "$ramdisk_path/"

      # Note: to support live OS replacements, don't use OS_ROOT in the target.
      mount -o bind "$ramdisk_path" "/$dir"
    fi
  done
}

echo "Flushing disks."

# Flush the disk so it doesn't slow us down later.
sync

echo "Performing initial sync."

# Sync OS to ramdisk. 'y' means 'first run'.
rsync_files 'y'

# Flush the disk again. We need things I/O ro be fast for the next part.
sync

echo "Re-syncing to lower the chance of stagnant files coming into existence."

# Sync OS to ramdisk again. 'n' means 'second run', and is somewhat faster.
rsync_files 'n'

# Live OS replacement support: mount the phantom OS's home over the host's.
if [ "$(readlink -f "$OS_ROOT")" != '/' ]; then
  echo "Setup is live OS substitution; performing a mount bind:"
  echo " * $OS_ROOT/home => /home"
  mount -o bind "$OS_ROOT/home" /home
fi

# Push any user-requested home dirs into ram.
if test -n "$HOME_DIR_OVERRIDES"; then
  echo "Syncing home dir overrides."

  # Flush disk.
  sync

  # Dev note: don't quote $HOME_DIR_OVERRIDES, it relies on splitting.
  for dir in $HOME_DIR_OVERRIDES; do
    source_path="$OS_ROOT/$dir"
    ramdisk_path="$RAMDISK_DIR/$dir"

    if ! test -d "$source_path"; then
      echo
      echo "=================================================================="
      echo "WARNING: Home override '$source_path' does not exist."
      echo "Please double-check your home overrides in vars.include"
      echo "=================================================================="
      continue
    fi

    mkdir -p "$ramdisk_path"

    abs_source_path="$(readlink -f "$source_path")"
    abs_ramdisk_path="$(readlink -f "$ramdisk_path")"

    # Safety checks.
    if [ "$abs_source_path" = '/' ] || [ "$abs_ramdisk_path" = '/' ] || \
       [ "$abs_source_path" = "$abs_ramdisk_path" ];
    then
      echo "Safety check failed; one or more path are pointing to dangerous locations."
      echo "Trace:"
      echo " * 'source_path' should not resolve to '/'; actual value: '$abs_source_path'"
      echo " * 'ramdisk_path' should not resolve to '/'; actual value: '$abs_ramdisk_path'"
      echo " * 'source_path' and 'abs_ramdisk_path' may not resolve to the same path; actual: source_path is '$abs_source_path', ramdisk_path is '$abs_ramdisk_path'"
      exit 1
    else
      echo " * Safety checks passed; source points to '$abs_source_path', target points to '$abs_ramdisk_path'"
    fi

    echo "* Copying '$source_path' to '$ramdisk_path'"
    cp -a "$source_path" "$ramdisk_path"

    # Note: use OS_ROOT in the target even for live OS replacements, because
    # /the_other_os/home was mounted over /home above.
    echo "* Overlaying: '$ramdisk_path' => '$source_path'"
    mount -o bind "$ramdisk_path" "$source_path"
  done
else
  echo "No home overrides specified; skipping."
fi

