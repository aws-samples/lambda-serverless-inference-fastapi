#!/bin/sh

set -e

PROJECT_ROOT_DIR=$PWD

# Transform long options to short ones
for arg in "$@"; do
  shift
  case "$arg" in
    '--api')    set -- "$@" '-a'   ;;
    '--help')   set -- "$@" '-h'   ;;
    *)          set -- "$@" "$arg" ;;
  esac
done

# process flags preceeding positional parameters
while getopts "a" flag; do
  case $flag in
    a)
      TEMPLATE_TYPE="API"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

shift "$((OPTIND-1))" # remove options already parsed by getops from arg list

if [[ $# -lt 2 ]]; then
    echo "Illegal number of arguments."
    echo "2 positional were expected."
    echo "Usage: init-lambda-code.sh [OPTIONS] <COMPONENT_NAME> <PACKAGE_NAME> [OPTIONS]"
    exit 1
fi

COMPONENT_NAME=$1
PACKAGE_NAME=$2

shift 2 # remove the two positional arguments from arg list


# process any flags after positional parameters
while getopts "a" flag; do
  case $flag in
    a)
      TEMPLATE_TYPE="API"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done



if [[ -d "$COMPONENT_NAME"/runtime ]]; then
    # Control will enter here if $COMPONENT_NAME exists.
    echo "Component folder does exist already."
else
    echo "Component folder does not exist yet. Creating new component"
    mkdir -p "$COMPONENT_NAME"/"runtime"
fi


cd "$COMPONENT_NAME"/runtime
mkdir -p "$PACKAGE_NAME"


# choose what template to use for initialization of lambda
if [[ "$TEMPLATE_TYPE" == "API" ]]; then
    echo "Creating API dummy lambda."
    cp "$PROJECT_ROOT_DIR"/templates/api/api.py \
    "$PACKAGE_NAME"/"$PACKAGE_NAME".py
else
    echo "Creating default dummy lambda."
    cp "$PROJECT_ROOT_DIR"/templates/dummy/dummy.py \
    "$PACKAGE_NAME"/"$PACKAGE_NAME".py
fi

