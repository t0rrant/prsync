# prsync

Workaround for using rsync in parallel. Joined some ideas
from around the web throughout the years, and gave them a
deterministic way of ensuring that we know what process
is exactly what we want.

prsync uses one rsync thread for each toplevel directory
excluding the parent directory '.'

you can pass more directories via the '-e' option, the
directory names should be their fullnames, no regular
expressions, and should be separated by commas.

by default prsync will launch four rsyncs, if there are enough
directories, of course.

the modes passed to rsync, for the sake of repetition and
statefulness are aAHX which will keep user, group, mode,
mtimes, acl, extended attributes symlinks and hardlinks.

feel free to contribute to the tool
