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

## Prerequisites

If you're unsure why you'd need this, or if you're fairly new to Linux, please
don't use this system. It's powerful and somewhat stable, but nonetheless
dangerous. Users who don't fully understand the processes involved are likely
to lose files or suffer OS corruption.

This system was made specifically for Linux, and tested almost exclusively on
Ubuntu and Mint.

## Safety notes

* Do not install any new software or make any system changes while this system
  is active; reboot your machine first. There's no clean way to undo what this
  script does, except for a reboot. Disable all auto-updaters before running
  this system.
* There's a good chance this system won't work out of the box. You need to
  modify `vars.include` to set everything up as needed.
* All new application and system logs generated while this system is active
  will be lost. Log files already open will continue to receive updates until
  log rotation, service restart, or file invalidation, but won't be visible
  until reboot.
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
  sending to RAM process. If you don't yet have a `vars.include` file, copy
  [`vars.include.example`](/vars.include.example) template.
* If your `/tmp` dir is already RAM-mounted, ensure you remove that from
  `vars.include -> OS_DIRS`.
* `/opt` is not included by default. Add that to `vars.include -> OS_DIRS` if
  you want it sent to RAM.

Running the script:

* Reboot your machine before running this script; it assumes you have not
  logged into any X sessions since boot (it's fine to reach the GUI login
  screen,
  but don't log in there).
* Switch to a TTY.
* Run `send_os_to_ram.sh` as root. This sends the OS to RAM. It can be run from
  anywhere.
* If the script completes successfully, you'll get a message saying so. There's
  small chance the script can die silently for uncaught errors, though all
  previously-known occurrences of these have been fixed.
  
All operations take just over 5 minutes to complete on my system.

Additional info:

The scripts within the `utils` directory are internal scripts used by
`send_os_to_ram.sh` and are not intended for regular users. Avoid running them
manually unless you are an advanced user who has examined their source code and
understands their purpose. These scripts assume they are being executed from
their containing directory.

## How it works

* Stops the display manager
* Creates a ramdisk at `/mnt/ram_os_1166877`
* Mount binds your home to `/mnt/physical_home_1166877`
* Copies your OS dirs (excluding home) into `/mnt/ram_os_1166877`
* Performs a mount bind operation, redirecting all system directories to the
  RAM disk (e.g., `/bin` now silently points to `/mnt/ram_os_1166877/bin`)
* After that, it's done. It will not restart the display manager; it expects
  you to do that manually in case you want to double-check things first.

## Live OS substitution

You can use this system to load an entirely different OS (and even a
[chroot](https://en.wikipedia.org/wiki/Chroot)
setup), which will replace the host OS until reboot. See `OS_ROOT` in
`vars.include` for documentation.

Note that live OS substitution has only been tested with very similar operating
systems (for example, `Mint 19.2 -> Mint 19.2`, `Ubuntu 18.04 -> Ubuntu 18.04`,
an so forth). This script is expected to work with any OS that has the same
base dirs, but note that, if loading a very different OS, you may need to
terminate additional services (such a those stationed in `/run`) to prevent
already-running essential services from referencing now non-existent installed
files.
