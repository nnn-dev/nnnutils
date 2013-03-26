#!/bin/sh
# ############################################################################ #
# NNN utils (http://code.google.com/p/nnnutils/)                               #
# Copyright (C) 2010-2011 3Zen                                                 #
#                                                                              #
# This library is free software; you can redistribute it and/or                #
# modify it under the terms of the GNU Lesser General Public                   #
# License as published by the Free Software Foundation; either                 #
# version 2.1 of the License, or (at your option) any later version.           #
#                                                                              #
# This library is distributed in the hope that it will be useful,              #
# but WITHOUT ANY WARRANTY; without even the implied warranty of               #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU            #
# Lesser General Public License for more details.                              #
#                                                                              #
# You should have received a copy of the GNU Lesser General Public             #
# License along with this library; if not, write to the Free Software          #
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA #
# ############################################################################ #

#2345678901234567890123456789012345678901234567890123456789012345678901234567890

VERSION=1.4.20130324

#TYPE OF SCRIPT Service/Backup/Check/Run
NNNA_MODE='B'

# support of stdbuf ?
type stdbuf >/dev/null 2>&1
if [ "$?" -eq '0' ]; then
 nnna_tr="stdbuf -o0 tr"
else
 nnna_tr='tr'
fi

# support of gettext ?
type gettext >/dev/null 2>/dev/null
if [ "$?" -eq '0' ]; then
 # gettest is found
_()
{
[ -z "$TEXTDOMAINDIR" ] && TEXTDOMAINDIR="$(dirname $0)/messages"
export TEXTDOMAINDIR; gettext -d nnnadmin -- "$(cat <<EOT
$*
EOT
)"
}
elif [ "$HOSTNAME" = 'android' ]; then
_()
{
 echo "$@"
}
else
 # gettest not found => no translation
_()
{
cat <<EOT
$*
EOT
}
fi

#Nb: for translate use xgettext -k'_' -o nnnadmin.fr.po  admin.sh
# after  msgfmt -o /usr/share/locale/fr/LC_MESSAGES/nnnadmin.mo nnnadmin.fr.po

# function to exit on error 
nnna_exit_error()
{
res=$1
fmt="$2"
shift 2
nnna_fn_msgbegin_bad
printf "%s : $fmt\n" "$(_ 'Error' )" "$@" >&2
nnna_fn_msgend
exit $res
}

# function to exit on error + help
nnna_exit_error_help()
{
res=$1
fmt="$2"
shift 2
nnna_fn_msgbegin_bad
printf "%s : $fmt\n" "$(_ 'Error' )" "$@" >&2
nnna_fn_msgend
nnna_fn_help >&2
exit $res
}

# function to suppress endofline
if [ -n "$BASH_VERSION" ]; then
nnna_showwoutnl()
{
"$@" | $nnna_tr '\n\r' '  '
return ${PIPESTATUS[0]}
}
else
nnna_showwoutnl()
{
        unset res
        exec 4>&1
        eval "$(exec 3>&1; eval "{
"$@" 3>&-
echo \"res=\$?\" >&3
} 4>&- | $nnna_tr '\n\r' '  ' 3>&- >&4 4>&- ")"
        exec 4>&-
        return $res
}
fi

#if colors can be used
if   [ -t 1 ] && [ "$TERM" != "" ] && [ "$TERM" != "xdumb" ] \
 && [ -x /usr/bin/tput ] ; then
 
nnna_fn_msgbegin_good()
{
 /usr/bin/tput setaf 2
}

nnna_fn_msgbegin_bad()
{
 /usr/bin/tput setaf 1
}

nnna_fn_msgbegin_warn()
{
 /usr/bin/tput setaf 3
}

nnna_fn_msgend()
{
 /usr/bin/tput op
}

else

nnna_fn_msgbegin_good()
{
 :
}

nnna_fn_msgbegin_bad()
{
 :
}

nnna_fn_msgbegin_warn()
{
 :
}

nnna_fn_msgend()
{
 :
}

fi


# version function
nnna_fn_version()
{
t=""
case $NNNA_MODE in
'R') t='run' ;;
'B') t='backup';;
'C') t='check' ;;
*) t='admin' ;;
esac
printf "$(_ '%s-%s by %s version %s\n')" "NNNADMIN" "$t" "3Zen" "$VERSION"
}

# help function
nnna_fn_help()
{
echo "$(_ 'Syntax')" ':'
if [ "$NNNA_MODE" = 'C' ]; then
printf " %s [opt] [-n] <module> %-7s : %s\n" \
$(basename $0) ' ' "$(_ 'repair (or check) the module')"
else
if [ "$NNNA_MODE" = 'R' ]; then
printf " %s [opt] <module> [launch] %-7s : %s\n" \
$(basename $0) ' ' "$(_ 'launch function for the module')"
elif [ "$NNNA_MODE" != 'B' ]; then
printf " %s [opt] <module> start %-8s : %s\n" \
$(basename $0) ' ' "$(_ 'start the module')"
printf " %s [opt] <module> status %-7s : %s\n" \
$(basename $0) ' ' "$(_ 'show the status of this module')"
printf " %s [opt] <module> stop %-9s : %s\n" \
$(basename $0) ' ' "$(_ 'stop the module')"
printf " %s [opt] <module> restart %-6s : %s\n" \
$(basename $0) ' ' "$(_ '(re)start the module')"
printf " %s [opt] <module> force-reload %-1s : %s\n" \
$(basename $0) ' ' "$(_ 'same as restart (for LSB compatibility)')"
printf " %s [opt] <module> try-restart %-2s : %s\n" \
$(basename $0) ' ' "$(_ 'restart the module if it is launched')"
else
printf " %s [opt] <module> export <rep> %-1s : %s\n" \
$(basename $0) ' ' "$(_ 'export save from the module')"
printf " %s [opt] <module> import <rep> %-1s : %s\n" \
$(basename $0) ' ' "$(_ 'import save into the module')"
fi
fi
echo $(_ 'opt is for options') ':'
printf " -l %-25s : %s\n" \
' ' "$(_ 'show the list of modules')"
printf ' -E <path> %-18s : %s\n' \
' ' "$(_ 'path of application configuration')"
printf ' -M <path> %-18s : %s\n' \
' ' "$(_ 'directory of application modules')"
if [ "$NNNA_MODE" = 'B' ]; then
printf ' -D %-25s : %s\n' \
' ' "$(_ 'delete data before import')"
elif [ "$NNNA_MODE" = 'C' ]; then
printf ' -n %-25s : %s\n' \
' ' "$(_ 'check only instead repair')"
fi
printf -- ' -? %-25s : %s\n' \
' ' "$(_ 'show this help message')"
printf -- ' -h %-25s : %s\n' \
' ' "$(_ 'show the manual')"
printf -- ' -v %-25s : %s\n' \
' ' "$(_ 'show version')"
echo "$(_ 'You can use -A nosys and/or -A allsys instead module :')"
printf -- "$(_ ' -A nosys    : all modules without      sys prefix')\n"
printf -- "$(_ ' -A allsys   : all modules without&with sys prefix')\n"; 
}

# show the list of modules
nnna_fn_showmodules()
{
 printf " %-2s | %-12s | %-27s | %-7s | %-7s | %-3s \n" "$(_ '#')" \
 "$(_ 'Module')" "$(_ 'Description')" "$(_ 'Author')" \
 "$(_ 'Version')" "$(_ 'Sys')"
 echo '---- -------------- ----------------------------' \
 '--------- ---------- ----'
 for module in $(find "$nnna_modules" -maxdepth 1 -type f -print | sort -n); do
  awk -F '[ \t]+' \
 'BEGIN { issystem=0 } { 
 if ($1  ~ /##*/ && $2 == "NNNA") {
 text=""; for(i=4;i<=NF;i++) { text=text" "$i }
  values[tolower($3)]=text }
 } END { n=split(FILENAME,a,"/"); m=split(a[n],b,"_"); i=2
 if (b[2] == "sys")  { issystem=1; i=3 }
 t=b[i]; for(i++;i<=m;i++) {t=t"_"b[i];}
 printf(" %-2s | %-12s | %-27s | %-7s | %-7s | %-3s\n",b[1],t,
 values["description"],values["author"],values["version"],
 issystem) }' $module
 done
}

nnna_fn_getscript()
{
 (find $nnna_modules -name '[0-9][0-9]*_'$1
 find $nnna_modules -name '[0-9][0-9]*_sys_'$1) | head -n 1
}

nnna_fn_checkres()
{
 if [ "$1" -eq '0' ]; then
  nnna_fn_msgbegin_good
  printf '\t%s\n' "$(_ 'OK')"
  nnna_fn_msgend
 else
  if [ "$NNNA_MODE" = 'C' ] && [ "0$NNNA_CHECK" -eq '1' ]; then
   nnna_fn_msgbegin_warn
   printf '\t%s\n' "$(_ 'To repair')"
   nnna_fn_msgend
  else
   nnna_fn_msgbegin_bad
   printf '\t%s\n' "$(_ 'Failed')"
   nnna_fn_msgend
  fi
 fi
 return "$1"
}

nnna_fn_man()
{
case $NNNA_MODE in 
'A') manfile='admin.sh.1' ;;
'B') manfile='backup.sh.1' ;;
'C') manfile='check.sh.1' ;;
'R') manfile='launch.sh.1' ;;
esac
l=$(echo $LANG | cut -f1 -d'_')
[ -z "$PAGER" ] && nnna_pager='more' || nnna_pager="$PAGER"
if [ -f "$(dirname $0)/man/$l/$manfile" ] ; then
 nroff -man $(dirname $0)/man/$l/$manfile | $nnna_pager
else
 nroff -man $(dirname $0)/man/$manfile | $nnna_pager
fi
}

nnnalaunch()
{
 nnna_cmd=$1
 shift 1
 printf "%-20s : %s..." "$nnna_product" "$(_ 'Launching')"
 nnna_showwoutnl fn_$nnna_cmd
 nnna_res=$? 
 nnna_fn_checkres $nnna_res 
 return "$nnna_res"
}


nnnastart()
{
 printf "%-20s : %s..." "$nnna_product" "$(_ 'Starting')"
 fn_status >/dev/null 2>&1
 res=$?
 if [ "$res" -ne '3' ]; then
  if [ "$res" -eq '0' ]; then
   printf '\t%s\n' "$(_ 'not stopped')"
   return 0
  else
    nnna_fn_checkres "$res"
    return "$res"
  fi
 else
  nnna_showwoutnl fn_start
  nnna_res=$? 
  nnna_fn_checkres $nnna_res 
  return "$nnna_res"
 fi
}

nnnastop()
{
 printf "%-20s : %s..." "$nnna_product" "$(_ 'Stopping')"
 fn_status >/dev/null 2>&1
 res=$?
 if [ "$res" -ne '0' ]; then
  if [ "$res" -eq '3' ]; then
   printf '\t%s\n' "$(_ 'not started')"
   return 0
  else
   nnna_fn_checkres $res
   return "$res"
  fi
 else
  nnna_showwoutnl fn_stop
  nnna_res=$? 
  nnna_fn_checkres $nnna_res 
  return $nnna_res
 fi
}

nnnatryrestart()
{
 printf "%-20s : " "$nnna_product"
 fn_status 1>/dev/null 2>&1
 nnna_res=$?
 if [ "$nnna_res" -eq '0' ]; then
  printf "%s..." "$(_ 'Stopping')"
  nnna_showwoutnl fn_stop
  nnna_res=$?
  nnna_fn_checkres $nnna_res
  if [ "$nnna_res" -eq '0' ]; then
   printf "%-20s : %s..." "$nnna_product" "$(_ 'Starting')"
   nnna_showwoutnl fn_start
   nnna_res=$?
   nnna_fn_checkres $nnna_res
  fi
  return $nnna_res
 elif [ "$nnna_res" -eq '3' ]; then
   printf '\t%s\n' "$(_ 'not started')"
   nnna_res=0
   return 0
 else
  nnna_fn_checkres $nnna_res
  return $nnna_res
 fi
}

nnnastatus()
{
 printf "%-20s : " $nnna_product
 nnna_showwoutnl fn_status
 nnna_res=$?
 printf '\t'
 case $nnna_res in
  '0') echo " $(_ 'Running')" ;;
  '1') echo " $(_ 'Dead. Check PID file')" ;;
  '2') echo " $(_ 'Dead. Check lock file')" ;;
  '3') echo " $(_ 'Stopped')" ;;
  *) echo " $(_ 'Unknown')" ;;
 esac
 return $nnna_res
}

nnnaimport()
{
 printf "%-20s : %s..." "$nnna_product" "$(_ 'Importing')"
  nnna_showwoutnl fn_import "$@"
  nnna_res=$?
  nnna_fn_checkres $nnna_res
 return $nnna_res
}


nnnaexport()
{
 printf "%-20s : %s..." "$nnna_product" "$(_ 'Exporting')"
  nnna_showwoutnl  fn_export "$@"
  nnna_res=$?
  nnna_fn_checkres $nnna_res
 return $nnna_res
}


nnnacheck()
{
 printf "%-20s : %s..." "$nnna_product" "$(_ 'Checking')"
  nnna_showwoutnl fn_check "$@"
  nnna_res=$?
  NNNA_CHECK=1
  nnna_fn_checkres $nnna_res
  return $nnna_res
}

nnnarepair()
{
 printf "%-20s : %s..." "$nnna_product" "$(_ 'Repairing')"
  nnna_showwoutnl fn_repair "$@"
  nnna_res=$?
  NNNA_CHECK=0
  nnna_fn_checkres $nnna_res 
  return $nnna_res
}


nnnaactionalllist()
{
r=''
if [ "$1" = '-r' ]; then
 r='-r' 
 shift 1
fi
if [ "$1" -eq '1' ]; then
 find "$nnna_modules" -type f -not -name '*~'  -exec basename {} \; | \
sort $r -n | sed -e \
 '1,$s|[0-9][0-9]*_sys_||g' -e \
 '1,$s|[0-9][0-9]*_||g'
else
 find "$nnna_modules" -type f -not -name '*~' -exec basename {} \; | \
grep -v '[0-9][0-9]*_sys_' | sort $r -n | sed -e \
 '1,$s|[0-9][0-9]*_||g'
fi
}

nnnaactiongo()
{
 $(dirname $0)/$(basename $0) -E "$nnna_env" -M "$nnna_modules" "$@"
 return $?
}

nnnaactionall()
{
 unset nnna_delete
 if [ "$1" = '-D' ]; then
  nnna_delete='-D'
  shift 1
 fi
 nnna_all=$1
 shift 1
 nnna_action=$1 
 shift 1
 nnna_res=0
 nnna_ores=0
 nnna_gres=0
  case $nnna_action in
   'repair') for module in $(nnnaactionalllist $nnna_all); do
     nnnaactiongo -n $module "$@" 
     if [ "$?" -ne '0' ]; then
      nnnaactiongo $module 
      [ "$?" -ne '0' ] && nnna_gres=1
     fi
   done ;;
   'check') for module in $(nnnaactionalllist $nnna_all); do
     nnnaactiongo -n $module "$@" ; nnna_res=$?
     [ "$?" -ne '0' ] && nnna_gres=1
   done ;;
   'export'|'status') for module in $(nnnaactionalllist $nnna_all); do
     nnnaactiongo $module $nnna_action "$@"
     [ "$?" -ne '0' ] && nnna_gres=1
     done ;;
   'import') for module in $(nnnaactionalllist -r $nnna_all); do
     nnnaactiongo $nnna_delete $module $nnna_action "$@"; nnna_res=$?
     [ "$?" -ne '0' ] && nnna_gres=1
     done;;
   'stop')  for module in $(nnnaactionalllist -r $nnna_all); do
     nnnaactiongo $module status "$@" 2>&1 1>/dev/null
     if [ "$?" -eq  '0' ]; then
        nnnaactiongo $module stop "$@" 
        [ "$?" -ne '0' ] && nnna_gres=1
     fi 
    done  ;;
   'start') for module in $(nnnaactionalllist $nnna_all); do
    nnnaactiongo $module status "$@" 2>&1 1>/dev/null
     if [ "$?" -eq  '3' ]; then
        nnnaactiongo $module start "$@"
        [ "$?" -ne '0' ] && nnna_gres=1
     fi 
    done ;;
   'launch') nnna_cmd=$1
    shift 1
    for module in $(nnnaactionalllist $nnna_all); do
     nnnaactiongo $module $nnna_cmd "$@"
     [ "$?" -ne '0' ] && nnna_gres=1
    done ;;
  'try-restart') nnnatryrestart_nb=0
	for module in $(nnnaactionalllist -r $nnna_all); do
		nnnaactiongo $module status "$@" 2>&1 1>/dev/null
		if [ "$?" -eq '0' ]; then
			nnnatryrestart_nb=$(($nnnatryrestart_nb+1))
			eval "nnnatryrestart_${nnnatryrestart_nb}=$module"
			nnnaactiongo $module stop "$@"
			[ "$?" -ne '0' ] && nnna_gres=1
		fi
	done
	while [ "$nnnatryrestart_nb" -gt '0' ]; do
		module=$(eval "echo \$nnnatryrestart_${nnnatryrestart_nb}")
		nnnaactiongo $module start "$@"
		[ "$?" -ne '0' ] && nnna_gres=1
		nnnatryrestart_nb=$(($nnnatryrestart_nb-1))
	done ;;
  esac
 return $nnna_gres
}

# error code
NNNA_EC_BADCOMMAND=127
NNNA_EC_BADCONFIG=127
NNNA_EC_NOPRODUCT=127

# default options
nnna_env="$(dirname $0)/$(basename $0 .sh).env"
nnna_modules="$(dirname $0)/$(basename $0 .sh)-modules"

unset nnna_all
unset nnna_delete
unset nnna_checkcmd
# manage options with getopts
while getopts ":lnDv?hE:M:A:" a; do
 case "$a" in
 'l') nnna_checkcmd='list';;
 'n') nnna_checkcmd='check';;
 'D') nnna_delete='-D' ;;
 'E') nnna_env=$OPTARG ;;
 'M') nnna_modules=$OPTARG ;;
 '?') nnna_fn_help; exit 0 ;;
 'h') nnna_fn_man; exit 0 ;;
 'v') nnna_fn_version; exit 0 ;;
 'A') case $OPTARG in 
 'nosys') nnna_all=0 ;;
 'allsys') nnna_all=1 ;;
 *) nnna_exit_error_help $NNNA_EC_BADCOMMAND \
  "$(_ 'argument %s is incorrect')" "$OPTARG" ;;
 esac ;;
 :) nnna_exit_error_help $NNNA_EC_BADCOMMAND \
 "$(_ 'option %s must have an argument')" "$OPTARG" ;;
  \?) nnna_exit_error_help $NNNA_EC_BADCOMMAND \
  "$(_ 'option %s is an incorrect option')" "$a" ;;
 esac
done
shift $(($OPTIND - 1))


#error checking
#no command
if [ "$NNNA_MODE" != 'C' ] && [ -z "$nnna_checkcmd" ]; then
[ "$#" -eq '0' ] && nnna_exit_error_help $NNNA_EC_BADCOMMAND \
"$(_ 'Bad command line')"
else
[ "$#" -eq '0' ] && [ -z "$nnna_checkcmd" ] && [ -z "$nnna_all" ] && \
nnna_exit_error_help $NNNA_EC_BADCOMMAND \
"$(_ 'Bad command line')"
fi
#modules path must exists
[ -d "$nnna_modules" ] || nnna_exit_error_help $NNNA_EC_BADCONFIG \
"$(_ 'Folder %s must exists')"  "$nnna_modules"
#

if [ "$nnna_checkcmd" = 'list' ] ; then
 nnna_fn_showmodules
 exit $?
fi

[ "$NNNA_MODE" = 'C' ] && [ -z "$nnna_checkcmd" ] && nnna_checkcmd='repair'
[ "$NNNA_MODE" = 'R' ] && [ -z "$nnna_checkcmd" ] && nnna_checkcmd='launch'

if [ -n "$nnna_all" ]; then
 if [ -z "$nnna_checkcmd" ]; then
   nnna_cmd=$1
   shift 1
 else 
  nnna_cmd=$nnna_checkcmd
 fi
 nnna_res=1
 if [ "$NNNA_MODE" = 'R' ]; then
  case $nnna_cmd in
   *) nnnaactionall $nnna_all 'launch' $nnna_cmd "$@" ; nnna_res=$?;;
  esac
 elif [ "$NNNA_MODE" = 'B' ]; then
  case $nnna_cmd in
   'import'|'export') if [ -n "$nnna_delete" ] && [ "$nnna_cmd" != 'import' ]
   then
    unset nnna_delete
   fi
   nnnaactionall $nnna_delete $nnna_all $nnna_cmd "$@" 
   nnna_res=$?;;
  *) nnna_exit_error_help $NNNA_EC_BADCOMMAND "$(_ 'Command %s invalid')" $nnna_cmd;;
  esac
 elif [ "$NNNA_MODE" = 'C' ]; then
   case $nnna_cmd in
   'check'|'repair' ) nnnaactionall $nnna_all $nnna_cmd "$@" ; nnna_res=$?;;
  *) nnna_exit_error_help $NNNA_EC_BADCOMMAND "$(_ 'Command %s invalid')" $nnna_cmd;;
  esac
 else
 case $nnna_cmd in
  'status'|'start'|'stop'|'try-restart') nnnaactionall $nnna_all $nnna_cmd; 
nnna_res=$? ;;
  'restart'|'force-reload') nnnaactionall $nnna_all 'stop'
   nnna_res0=$?
   nnnaactionall $nnna_all 'start' 
   [ "$?" -eq '0' ] && nnna_res=$nnna_res0 || nnna_res=$?  ;;
  *) nnna_exit_error_help $NNNA_EC_BADCOMMAND "$(_ 'Command '%s' invalid')" $nnna_cmd;;
 esac
 fi
 printf -- "$(_ 'Global %-13s :')" $nnna_cmd
 nnna_fn_checkres $nnna_res
 exit $?
fi

nnna_product=$1
shift 1
nnna_filename=$(nnna_fn_getscript $nnna_product)
[ -f "$nnna_filename" ] || nnna_exit_error $NNNA_EC_NOPRODUCT \
"$(_ "The module '%s' don't exists")" $nnna_product

[ -f "$nnna_env" ] && . $nnna_env

. $nnna_filename

if [ -z "$nnna_checkcmd" ] ; then
 if [ "$#" -eq '0' ]; then
  nnna_exit_error_help $NNNA_EC_BADCOMMAND "$(_ 'Bad command line')"
 fi
  nnna_cmd=$1
  shift 1
else
 nnna_cmd=$nnna_checkcmd
fi
nnna_res=0

if [ "$NNNA_MODE" = 'R' ]; then
 nnnalaunch "$nnna_cmd" 
 nnna_res=$?
elif [ "$NNNA_MODE" = 'B' ]; then
 if [ ! -d "$1" ] ; then
  nnna_exit_error_help $NNNA_EC_BADCONFIG \
"$(_ 'Folder %s must exists')"  "$1"
 fi
 case $nnna_cmd in 
  'export') nnnaexport "$@" ;nnna_res=$? ;;
  'import') nnnaimport $nnna_delete "$@" ;nnna_res=$? ;;
  *) nnna_exit_error_help $NNNA_EC_BADCOMMAND "$(_ 'Command %s invalid')" $nnna_cmd;;
  esac
elif [ "$NNNA_MODE" = 'C' ]; then
 case $nnna_cmd in
  'check') nnnacheck "$@"; nnna_res=$? ;;
  'repair') nnnarepair "$@"; nnna_res=$? ;;
   *) nnna_exit_error_help $NNNA_EC_BADCOMMAND "$(_ 'Command %s invalid')" $nnna_cmd;;
  esac
else
 case $nnna_cmd in
  'start') nnnastart ; nnna_res=$?;;
  'stop') nnnastop ; nnna_res=$?;; 
  'status') nnnastatus ; nnna_res=$?;;
  'try-restart') nnnatryrestart ; nnna_res=$?;;
  'restart'|'force-reload') fn_status >/dev/null 2>&1
  nnna_res=$?
  if [ "$nnna_res" -eq '0' ]; then
   nnnastop
   [ "$?" -eq '0' ] && nnna_res=3 #not running
  elif [ "$nnna_res" -ne '3' ]; then
   nnnastatus #show status if error
  fi
   [ "$nnna_res" -eq '3' ] && nnnastart
  nnna_res=$? ;;
  *) nnna_exit_error_help $NNNA_EC_BADCOMMAND "$(_ 'Command %s invalid')" $nnna_cmd;;
  esac
fi

exit $nnna_res

