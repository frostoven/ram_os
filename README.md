# RAM OS Shunt

The purpose of this script is to make your OS roughly 100x faster at the
expense of making it mostly read-only and consuming massive chunks of RAM.

It is _specifically_ designed for situations where an entire OS is installed on
a slow flash disk, but you have a lot of RAM. This script will offer
little-to-no advantages for the average computer set up in a standard way.

## Summary

This script copies most of the OS into RAM (by creating a 
[ramdisk](https://en.wikipedia.org/wiki/Tmpfs)),
and then forces the
system to now recognise the newly created ramdisk as the "real" disk. In my own
experience, my applications would go from freezing minutes at a time to never
freezing at all.

Your home dir will be the only directory still pointing to the real disk. This
can be changed such that specific parts of your home dir reside in RAM for
situations where some applications do heavy disk I/O from within your home.

## Do I need this?

If you're unsure why you'd need this, or if you're fairly new to Linux, please
don't use this system. It's powerful and somewhat stable, but nonetheless
dangerous. Users who don't fully understand the processes involved are likely
to lose files or suffer OS corruption.

## Safety notes

* Do not install any new software or make any system changes while this system
  is active; reboot your machine first. There's no clean way to undo what this
  does, except for a reboot. Disable all auto-updaters before running this
  system.
* There's a good chance this system won't work out of the box. You need to
  modify `vars.include` to set everything up as needed.
* All new application and system logs generated while this system is active
  will be lost. Log files already open will continue to receive updates until
  log rotation, service restart, or file invalidation.
* I have used this method for nearly 10 years at the time of writing, and have
  never experienced system instability while doing this. Having said that,
  please
  back up your data before running this, and, importantly, **understand that
  you will lose files if you save them in the wrong place**. This turns most of
  your OS into a ramdisk. This means that you run the risk of accidentally
  saving files to RAM, which is cleared on reboot.

## Instructions

Pre-setup:

* Do not clone this repo to a directory you want sent to RAM; safe default
  locations to store this repo is `/ram_os`, `/root/ram_os`, and `/mnt/ram_os`.
  Do not store it in `/home` if changing to a custom `OS_ROOT`.
* Configure `vars.include` before starting. It needs to know things like your
  display manager name, and will stop your display manager before starting the
  sending to RAM process. If you don't yet have a `vars.include` file, copy the
  template from `vars.include.example`.
* If your `/tmp` dir is already RAM-mounted, ensure you remove that from
  `vars.include`.
* `/opt` is not included by default. Add that to `vars.include` if you want it
  sent to RAM as well.

Running the script:

* Reboot your machine before running this script; it assumes you have not
  logged into any X sessions since boot (it's fine to reach the GUI login
  screen,
  but don't log in there).
* Switch to a TTY.
* The main script you should run is `send_os_to_ram.sh`. It can be run from
  anywhere.
* If the script completes successfully, you'll get a message saying so. There's
  small chance the script can die silently for uncaught errors, though all
  previously-known occurrences of these have been fixed.
  
All operations take just over 5 minutes to complete on my system.

Additional info:

The scripts in `utils` are internals used by `send_os_to_ram.sh` and not meant
for users. They should not be run manually unless you're an advanced user that
have read their source and know what you are doing. Those scripts assume
they're being run from their containing directory.

You can use this system to load a whole different OS or chroot setup, which
will replace the host OS until reboot. See `OS_ROOT` in `vars.include` for
documentation.

## How it works

* Stops your display manager
* Creates a ramdisk in `/mnt/ram_os_1166877`
* Mount binds your home to `/mnt/physical_home_1166877`
* Copies your OS dirs (excluding home) into `/mnt/ram_os_1166877`
* Performs a mount bind of all system dirs in the RAM disk over the physical
  dirs (for example, `/bin` now silently points to `/mnt/ram_os_1166877/bin`)
* After that, it's done. It will not restart your display manager; it expects
  you
  to do that manually in case your want to double-check things first.
