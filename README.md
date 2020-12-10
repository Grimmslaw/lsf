# lsf
File and directory results with `stat`-based filters.

This script acts as the `ls` command with `-al` options, but results can be filtered based on fields provided by some of the results provided by the `stat` command.

# Installation

## Simple Installation
To simply install this script and make it available on the command line, use the following one-liner (in any directory that you have write and execute privileges):

`$(git clone https://github.com/Grimmslaw/lsf.git; ./lsf/setup.sh [-s script] [-m manpage] install; rm -rf lsf/)`

Where `[-s script]` and `[-m manpage]` allow you to optionally specify locations to add the script and/or the script's man page that are different from your OS's default locations (e.g. `/usr/local/bin/lsf` and `/usr/local/share/man/man1/lsf.1` for OSX).

For a copy-paste, default installation:

`$(git clone https://github.com/Grimmslaw/lsf.git; ./lsf/setup.sh install; rm -rf lsf/)`

## Updateable Installation
If you would like to be able to update the command-line command based on any changes you make to the script, use the following (wherever you would like the editable script to live):

`$(git clone https://github.com/Grimmslaw/lsf.git; ./lsf/setup.sh [-s script] [-m manpage] install)`

Where, as above, `[-s script]` and `[-m manpage]` allow you to optionally specify alternate locations for the script and/or the script's man page. Then, if you make changes to the script, you can `cd` into the scripts parent directory, then run

`./setup.sh [-x] [-s script] [-m manpage] update`

Where `[-s script] [-m manpage]` are as above and `[-x]` is an optional flag that deletes the contents of the `./*/bak/` directories before updating the command-line command.

Again, for a copy-paste, default (updateable) installation:

`$(git clone https://github.com/Grimmslaw/lsf.git; ./lsf/setup.sh install)`

# Contributing
If you would like to contribute:
1. Clone the project (for instance, using the steps in *Updateable Installation*)
2. Create an issue (for a feature, a fix, or even just a name \[your name or just some name\] for ongoing contributions)

# Use
The basic usage is as follows:
`lsf [ -F | -D ] [ -m mode ] [ -l links ] [ -U | -u user ] [ -G | -g group ] [ -b size ] [ -T | -t days ] [ -n filename ] dirname`
* `dirname`
    * the base directory to search (with a depth of 1)
### Options
* `[ -F, -D ]`
    * display only files or directories, respectively
* `[ -m mode ]`
    * filter out entries that do not match the given filemode; can be a string (e.g. `drwxr-xr-x`), in which case it must be an exact match [WIP], or as an octal number (e.g. 20755), in which case the criteria can be a comparison (e.g. `">=20755"` -- [this will be made more robust in the future])
* `[ -l links ]`
    * filter out entries that do not match the inequality given for the number of hard links to that file/directory (e.g. `-l ">10"`)
* `[ -U | -u user ]`
    * filter out entries that do not match the given user criteria, whether a string (username) is provided, in which case it must be an exact match [WIP], or a number (uid), in which case the criteria can be a comparison
    * the `-U` option is the same as `-u {current user}`
* `[ -G | -g group ]`
    * filter out entries that do not match the given group criteria, whether a string (group name) is provided, in which case it must be an exact match [WIP], or a number (gid), in which case the criteria should be a comparison
    * the `-G` option is the same as `-g {current user's group}`
* `[ -b size ]`
    * filter out entries that do not match the given criteria for the size of the file/directory (in bytes)
* `[ -T | -t days ]`
    * filter out entries that were not modified earlier or later than the given number of days
    * the `-T` option filters out entries that were modified more than 6 months ago, where the "month" itself is sticky (i.e. only the month is taken into consideration, not the progress within the month)
* `[ -n filename ]`
    * filter out entries either that do or that do not match the given filename
        * `-F -n somefile.txt` will only include files named "somefile.txt" in the results
        * `-D -n !somedir` will exlude any directory named "somedir" from the results

