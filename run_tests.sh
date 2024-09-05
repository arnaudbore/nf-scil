#!/usr/bin/env bash

function run_test_suites () {

local component=$1
local workdir=$2

for module_category in $component/nf-scil/*
do

for module_tool in $module_category/*
do

module_identifier="$(basename $module_category)/$(basename $module_tool)"

if [[ ${EXCLUDES[@]} =~ $module_identifier ]]
then

echo "Skipping $module_identifier"

else

echo "Running $module_identifier"

if [ -d $module_tool/tests ]
then

echo "Command : $NFCORE_COMMAND $module_identifier"

{
    declare -gx NFCORE_${component^^}_GIT_REMOTE=https://github.com/scilus/nf-scil.git
    $NFCORE_COMMAND $module_identifier &&
    echo "$component/$module_identifier" >> $workdir/successful_tests.txt
} || echo "$component/$module_identifier" >> $workdir/failed_tests.txt

fi

fi

done

done

echo "Ran tests for $component"
if [ -f $workdir/failed_tests.txt ]
then
    echo "Failed tests:"
    cat $workdir/failed_tests.txt
else
    echo "All tests were successful !"
fi

}


DESCRIPTION="""

Run all tests for all modules and subworkflows in the nf-scil library.

Usage:
    run_tests.sh [-e <exclude_test_1>] [-e <exclude_test_2>] [-u] [-o] [-p <profile>]

Options:

    -e <exclude_test>       Exclude a test from the test suite. Can be used multiple times.
    -u                      Update the test snapshot after running the tests.
    -o                      Run the tests only once, without retrying failed tests.
    -p <profile>            Run the tests with the specified Nextflow profile.

"""

EXCLUDES=( )
UPDATE_SNAPS=false
ONCE=false
PROFILE="docker"

while getopts "e:uoph:" opt; do
    case $opt in
        e) EXCLUDES+=($OPTARG)
        ;;
        u) UPDATE_SNAPS=true
        ;;
        o) ONCE=true
        ;;
        p) PROFILE="$OPTARG"
        ;;
        h) echo "$DESCRIPTION"
        ;;
        \?) echo "Invalid option -$OPTARG" >&2
            echo "$DESCRIPTION"
        ;;
    esac
done


TMPDIR=$(mktemp -d)
NFCORE_COMMAND="nf-core modules test --no-prompts"

if [ -n "$PROFILE" ]
then
    echo "adding profile"
    NFCORE_COMMAND="$NFCORE_COMMAND --profile $PROFILE"
fi

if [ "$UPDATE_SNAPS" = true ]
then
    NFCORE_COMMAND="$NFCORE_COMMAND --update"
fi

if [ "$ONCE" = true ]
then
    NFCORE_COMMAND="$NFCORE_COMMAND --once"
fi

run_test_suites modules $TMPDIR
run_test_suites subworkflows $TMPDIR
