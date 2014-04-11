#!/bin/bash

#/**
#* <pre>
#* Feature: topics start
#*
#* Scenario: Attempt to start an assigned issue
#*
#* Given 'conveyor-workflow' is installed
#*   And the current repository has been cloned from GitHub
#*   And that repo has an open issue #1
#*   And that issue is assigned to another user
#*   And $HOME/.conveyor-workflow/github is in place
#*   And $HOME/.conveyor-workflow/github defines GITHUB_AUTH_TOKEN
#*   And the token has the necessary 'user' scope
#* When I type 'con topics start 1-foo'
#* Then I should find the text "Issue #1 exists, but has been assigned to 'foo'." in the output
#*   And the script exits with exit code 1.
#* </pre>
#*/

TEST_BASE=`dirname $0`/../../..
TEST_BASE=`realpath $TEST_BASE`
source $TEST_BASE/lib/cli-lib.sh
setup_path $TEST_BASE/../runnable
source $TEST_BASE/lib/environment-lib.sh
source $TEST_BASE/lib/start-lib.sh
source $TEST_BASE/../runnable/lib/github-hooks.sh
init_github_test_environment `basename $0`
cd $WORKING_REPO_PATH
source $HOME/.conveyor-workflow/github-authentication-default-test
ISSUE_NUMBER=`create_issue "DogFoodSoftware/test-repo" "$0"`
TEST_ACCOUNT_NAME="$GITHUB_ACCOUNT_NAME"
if [ $? -ne 0 ]; then echo "ERROR: Could not create issue; test inconclusive." >&2; exit 2; fi
# rm ~/.conveyor-workflow/github-login
set_assignee $ISSUE_NUMBER "$TEST_ACCOUNT_NAME" > /dev/null
if [ $? -ne 0 ]; then echo "ERROR: Could not create issue; test inconclusive." >&2; exit 2; fi
unset GITHUB_AUTH_TOKEN

ISSUE_DESC=`uuidgen`
test_output "con topics start $ISSUE_NUMBER-$ISSUE_DESC" "" "Issue #$ISSUE-NUMBER exists but has been assigned to '$TEST_ACCOUNT_NAME'." 1
