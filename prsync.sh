#!/bin/bash
##############################################################
#  Workaround for using rsync in parallel. Joined some ideas
#  from around the web throughout the years, and gave them a
#  deterministic way of ensuring that we know what process
#  is exactly what we want.
#
#  prsync uses one rsync thread for each toplevel directory
#  excluding the parent directory '.'
#
#  you can pass more directories to exclude via the '-e' option, the
#  directory names should be their fullnames, no regular
#  expressions, and should be separated by commas.
#
#  by default prsync will launch four rsyncs, if there are enough
#  directories, of course.
#
#  the modes passed to rsync, for the sake of repetition and
#  statefulness are aAHX which will keep user, group, mode,
#  mtimes, acl, extended attributes symlinks and hardlinks.
#
#  feel free to contribute to the tool at https://github.com/t0rrant/prsync/
#
#  Author: Manuel Torrinha <manuel _dot_ torrinha _at_ tecnico.ulisboa.pt>
#
##############################################################
function usage(){
  echo -e "Usage:\n\t$0 -s <source> -d <destination> [-t <n_threads>][-e <comma separated dirnames to exclude>]"
  exit 1
}

threads=4
sleep_t=5
excluded='^\.$'

declare -a pids

while getopts ":t:e:s:d:" opt; do
  case $opt in
    s)
      source=$OPTARG
      ;;
    d)
      target=$OPTARG
      ;;
    t)
      threads=$OPTARG
      ;;
    e)
      excluded="${excluded}|^${OPTARG//,/$|^}$"
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      usage
      ;;
  esac
done

if [[ -z "${source}" || -z "${target}" ]]; then
    usage
fi

cd "${source}"

find * -maxdepth 0 -type d | egrep -v ${excluded} | while read dir
do
    # make sure only $threads number of rsync are running
    while [[ ${#pids[@]} -ge ${threads} ]];
    do
        sleep ${sleep_t}
        # update pids to running pids only
        for pid in ${pids[@]}; do
            ps -q ${pid} -o cmd=
            if [[ ! $? -eq 0 ]]; then
                # it's no longer running, remove pid from the array
                unset pids[${pid}]
            fi
        done
    done
    # Run rsync in background for the current folder - copy permissions, hardlinks, acls and extended attributes
    rsync -aAXH "${dir}" "${target}/${dir}" &> /dev/null &
    # save the pid
    pids[$!]=$!
    echo "Running rsync for $!"
done
