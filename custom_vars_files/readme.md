This is a space to keep multiple configs. All files in this directory matching
`var[something]include` and ending with `.sh` are ignored by git.

Example of how to use this:
* Create a file for disk-to-ram called `vars.disk_to_ram.include`
* Create a file for live OS replacement called `vars.live_replace.include`
* When disk-to-ram is needed, run `cp vars.disk_to_ram.include ../vars.include`
* When live OS replacement needed, run `cp vars.live_replace.include ../vars.include`
