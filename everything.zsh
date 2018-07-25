: ${ZZ_TOP:=${0:A:h}}

declare -A ZZ_TOP_LOCO

zmodload zsh/zutil


function zz-top--iii
{
	printf ' :: [33mzz-top[0;0m: %s\n' "$*"
}

function zz-top--xxx
{
	printf ' :: [33mzz-top[0;0m: [1;31mXXX[0;0m: %s\n' "$*" 1>&2
	return 1
}

function zz-top--antenna
{
	case $1 in
		"" )             return 1 ;;
		*://* )          print -l "${1}" ;;
		/* | ./* | ~/* ) print -l "${1:a}" ;;
		*/* )            print -l "https://github.com/${1}" ;;
		* )              print -l "${1:a}" ;;
	esac
}

# Usage:
#   zz-top--fandango [options] <name> <plugdir> <confdir>
#
function zz-top--fandango
{
	if [[ -d $2/functions ]] ; then
		fpath+=( "$2/functions" )
		autoload -U "$2/functions"/*(.:t)
	fi

	local -a candidates=( "$2/$1.plugin.zsh" "$2/$1.zsh" )
	if [[ $1 = zsh-* ]] ; then
		candidates+=( "$2/${1#zsh-}.plugin.zsh" "$2/${1#zsh-}.zsh" )
	fi

	local p
	for p in "${candidates[@]}" ; do
		if [[ -r ${p} ]] ; then
			# zz-top --iii 'Loading:' "[35m$1[0m · [30;1m${p}[0;0m"
			ZZ_TOP_LOCO[$1]=$2
			source "${p}"
			return
		fi
	done

	zz-top --xxx 'Cannot determine files to load for' "$1" || true
}

function zz-top--loco
{
	[[ $# -gt 0 && -n ${(k)ZZ_TOP_LOCO[$1]} ]]
}

function zz-top--recycler
{
	emulate -L zsh
	setopt local_options err_return nullglob

	local plugdir confdir name
	local curdir=$(pwd)

	for plugdir in "${ZZ_TOP}"/plug/*/.git(/) ; do
		plugdir=${plugdir:h}
		name=${plugdir:t}
		local confdir="${ZZ_TOP}/conf/${name}"
		local url=$(< "${confdir}/cloneurl")
		if [[ -r ${confdir}/pending || ! -r ${plugdir}/.git/config ]] ; then
			zz-top --iii 'Installing:' "[35m${name}[0m · [30;1m${url}[0;0m"
			rm -rf "${plugdir}"
			git clone --recurse-submodules --depth=1 "${url}" "${plugdir}" \
				|| continue
			rm "${confdir}/pending"
		elif [[ -e ${confdir}/frozen ]] ; then
			zz-top --iii 'Skipping:' "[35m${name}[0m · [1;33mfrozen[0;0m"
		else
			zz-top --iii 'Updating:' "[35m${name}[0m · [30;1m${url}[0;0m"
			cd "${plugdir}"
			git pull || continue
		fi
	done
	cd "${curdir}"
}

# Usage:
#   zz-top opts           → Declare plugins
#   zz-top --fandango     → Load one plugin
#   zz-top --recycler     → Update plugins
#   zz-top --antenna      → Resolve URI
#   zz-top --iii          → Show info string
#   zz-top --xxx          → Error string and return false
#
function zz-top
{
	emulate -L zsh
	setopt local_options err_return

	if [[ $# -eq 0 ]] ; then
		zz-top --recycler
		return 0
	fi
	if [[ $1 = --* ]] ; then
		local cmd=${1}
		shift
		"zz-top${cmd}" "$@"
		return
	fi

	# If we arrive here, none of the --subcommands was chosen, so
	# it's just a plugin load declaration: load if already available,
	# mark as missing if not.

	local -A opt
	zparseopts -E -D -A opt -- \
		-local:

	local location=$(zz-top --antenna "$1")
	if [[ -z ${location} ]] ; then
		zz-top --xxx 'Invalid plugin spec:' "$1"
	fi

	local name=${location:t}
	local confdir="${ZZ_TOP}/conf/${name}"
	local plugdir="${ZZ_TOP}/plug/${name}"
	local plugstatus='missing'

	if [[ -n ${opt[--local]} && -d ${opt[--local]} ]] ; then
		location=${opt[--local]}
	fi

	if [[ ${location} = /* ]] ; then
		plugdir=${location}
		location=''
		plugstatus='loadable'
	elif [[ -r ${plugdir}/.git/config ]] ; then
		plugstatus='loadable'
	fi

	if [[ -r ${confdir}/pending ]] ; then
		plugstatus='pending'
	fi

	case ${plugstatus} in
		loadable)
			shift
			zz-top --fandango "${name}" "${plugdir}" "${confdir}"
			;;
		missing)
			# Plugin does not exist: mark for installation.
			zz-top --iii 'Missing:' "${name}"
			mkdir -p "${confdir}" "${plugdir}/.git"
			printf '%s' "${location}" > "${confdir}/cloneurl"
			touch "${confdir}/pending"
			;;
		pending)
			mkdir -p "${plugdir}/.git"
			;;
	esac
}
