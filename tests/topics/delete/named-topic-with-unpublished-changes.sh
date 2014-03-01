#!/bin/bash

#/**
#* <pre>
#* Feature: Informs user they cannot delete a local topic with unpublished
#* changes.
#*
#* Scenario: 'git convey topics delete changed-topic' from master
#* Given 'git-convey' is installed
#*   And I am on the 'master' branch
#*   And there exists a topic 'changed-topic'
#*   And the topic has unpublished changes
#* When I type 'git convey topics delete changed-topic'
#* Then text "Topic 'changed-topic' has local changes; cannot delete." is printed to stdout
#*   And I am on branch 'master'
#*   And the script exits with exit code 1.
#* </pre>
#*/

source `dirname $0`/../../lib/cli-lib.sh
setup_path `dirname $0`/../../../runnable
source `dirname $0`/../../lib/environment-lib.sh
init_test_environment `dirname $0`/../../.. `basename $0`
cd $WORKING_REPO_PATH

git checkout -q master
if ! git convey topics start --checkout changed-topic >/dev/null; then
    echo "ERROR: could not start topic 'changed-topic'; test inconclusive."
    exit
fi
touch foo
git add foo
git commit -q -m "added file foo"
if ! git checkout -q master; then
    echo "ERROR: Could not reset to master; test inconclusive."
fi
test_output 'git convey topics delete changed-topic' '' "Topic 'changed-topic' has local changes. Please publish or abandon." 1
if ! git rev-parse --verify -q topics-changed-topic > /dev/null; then
    echo "ERROR: Looks like the topic branch was erroneously deleted."
fi
