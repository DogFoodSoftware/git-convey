#!/bin/bash

#/**
#* <pre>
#* Feature: 'git convey status' reports GitHub login (for repo origin)
#*
#* Scenario: 'git convey status' on a repo cloned from GitHub 
#* Given 'git-convey' is installed
#*   And the current repository has been cloned from GitHub
#*   And $HOME/.git-convey is in place
#*   And $HOME/.git-convey defines GITHUB_AUTH_TOKEN
#*   And the token has the necessary 'user' scope
#* When I type 'git convey status
#* Then I should find the text 'Connected to GitHub as: xxx' in the output
#*   And the script exits with exit code 0.
#* </pre>
#*/

TEST_BASE=`dirname $0`/../..
source $TEST_BASE/lib/cli-lib.sh
setup_path $TEST_BASE/../runnable
source $TEST_BASE/lib/environment-lib.sh
source $TEST_BASE/lib/start-lib.sh
init_github_test_environment $TEST_BASE/.. `basename $0` 'https://github.com/DogFoodSoftware/test-repo.git'
cd $WORKING_REPO_PATH

OUTPUT=`test_output 'git convey status | grep "Connected to GitHub as:"' 'Connected to GitHub' '' 0 4 0`
if [ ${#OUTPUT} -le 24 ]; then
    echo "ERROR: Expected non-empty GitHub login name."
fi