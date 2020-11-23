#!/usr/bin/env bash

. "$HOME/.__login.debug" ".bash_profile__cat" || __echo() { :; }
__echo "[.bash_profile__cat] starting"


aws.credentials() {
	local CREDENTIALS="$HOME/.aws/credentials"
	bak --move --overwrite "$CREDENTIALS"

	"$HOME/.aws/aws_get_credentialsv2.py" \
		--user pierzt \
		--account 900182000710 \
		--role DatahubDeveloper \
		--timeout 3600 \
		--allowmfa
	[[ -e "$CREDENTIALS" ]] || return

	sed -e "s/=/\\$CR/;" "$CREDENTIALS" |tee /dev/stdout | pbcopy
	printf '\n'
}

cat.proxy() {
	shopt -s extglob
	local action= 
	local SH_VERBOSE="$SH_VERBOSE" SH_QUIET="$SH_QUIET"

	[[ "$1" =~ -v|--verbose ]] && SH_VERBOSE=1 && SH_QUIET= && shift
	[[ "$1" =~ -q|--quiet ]] && SH_QUIET=1 && SH_VERBOSE= && shift
	case "$1" in
		?(--)on |  1)
			action="on";;
		?(--)off | 0)
			action="off";;
		'' | ?(--)list|-l|ls | ?(--)st?(atus)|?(--)show|-s)
			action="show";;
		*)
			1>&2 echo "cat.proxy: $1: usage: cat.proxy on|off|list"
			return 1;;
	esac

	if [[ "$action" == "off" ]]; then
		((SH_VERBOSE)) && echo "Disabling CAT HTTP_PROXY..."
		unset HTTP_PROXY HTTPS_PROXY NO_PROXY
	elif [[ "$action" == "on" ]]; then
		((SH_VERBOSE)) && echo "Enabling CAT HTTP_PROXY..."
		export HTTP_PROXY="http://proxy.cat.com:80"
		export HTTPS_PROXY="http://proxy.cat.com:80"
		export NO_PROXY="localhost, .cat.com, 169.254.169.254"
	fi

	((! SH_QUIET)) && 1>&2 printf "%s='%s' %s='%s'  %s='%s'\n" \
		"HTTP_PROXY" "$HTTP_PROXY" \
		"HTTPS_PROXY" "$HTTPS_PROXY" \
		"NO_PROXY" "$NO_PROXY"
}

psql.local() {
	pbcopy <<< "test123"
	psql -h localhost \
			-p 5432 \
	 		-U postgres \
	 		-d postgres     

}
pgcli.local() {
	pbcopy <<< "test123"
	pgcli -h localhost \
			-p 5432 \
	 		-U postgres \
	 		-d postgres     

}

psql.dev() {
	 psql -h pfm-infra-usdca-master-main.cjkhtclrrvd4.us-east-2.rds.amazonaws.com \
	 		-p 5432 \
	 		-U master \
	 		-d application     
}


export PAA_HOME="$HOME/git/P-Apigee-APIResources"
export PGA_HOME="$HOME/git/P-Global-Asset"
export PICL_HOME="$HOME/git/P-Infra-Common-Libs"
export PIUSDC_HOME="$HOME/git/P-Infra-USDC"
export PIUSDCA_HOME="$HOME/git/P-Infra-USDCA"
export PCL_HOME="$HOME/git/P-common-library"

cd.paa() { cd "$PAA_HOME"; } && alias cd.api='cd.paa'
cd.pga() { cd "$PGA_HOME"; } && alias cd.ga='cd.pga'
cd.picl() { cd "$PICL_HOME"; } && alias cd.icl='cd.picl'
cd.pusdc() { cd "$PIUSDC_HOME"; } && alias cd.usdc='cd.pusdc'
cd.pusdca() { cd "$PIUSDCA_HOME"; } && alias cd.usdca='cd.pusdca'
cd.pcl() { cd "$PCL_HOME"; } && alias cd.cl='cd.cl'


d.compose() {
	local did_cd=
	[[ -d "./local" ]] && pushd "./local" && did_cd=1
	docker-compose "$@"
	(( did_cd )) && popd
}


export PPF_HOME="$HOME/git/P-Pipeline-Framework"
export PPF_LIB="$PPF_HOME/Components/pipeline_framework/src/lib"

# python; Optional $1 can be ROOT/HOME, lib, or any path to add to $PPF_HOME.
cd.ppf() {
	. "$PPF_HOME/.venv/bin/activate"

	[[ -z "$1" ]] && cd "$PPF_LIB" && return 0

	if [[ "$1" =~ ^$|H(OME)?|R(OOT)? ]]; then
		shift && cd "$PPF_HOME"
		return 0
	elif [[ "$1" =~ l(ib)? ]]; then
		shift && cd "$PPF_LIB"
		return 0
	elif [[ -d "$PPF_LIB/$1" ]]; then
		cd "$PPF_LIB/$1"
	else
		cd "$PPF_HOME/$1"
	fi
}

[[ -e "$HOME/bin/toxx.sh" ]] && source "$HOME/bin/toxx.sh"


__echo "[.bash_profile__cat] finished"
