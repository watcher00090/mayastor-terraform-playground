#! /bin/sh

# SYNOPSIS: . ./bin/export-kubeconfig.sh
#
# Include this shell snippet in your shell to configure KUBECONFIG variable and
# use kubectl and other tools with your new cluster
#
# FIXME: terraform output is relatively slow - enough to bug me when using it,
# digging in potentialy changing terraform state with jq might not be best way
# to do this

if [ -n "$BASH_SOURCE" ]; then
# > In POSIX sh, array references are undefined.
# for sure, I'm trying to support systems which use bash as sh
# shellcheck disable=SC3054
	THIS_SCRIPT="${BASH_SOURCE[0]}"
else
	THIS_SCRIPT="$0"
fi

# get_kubectl_path() {
# 	(
# 		cd "$(dirname "$0")"/..
# 		terraform output kubeconfig
# 	)
# }
get_kubectl_path() {
	jq -r .outputs.kubeconfig.value < "$(dirname "$THIS_SCRIPT")"/../terraform.tfstate
}

export KUBECONFIG="$(get_kubectl_path)"

