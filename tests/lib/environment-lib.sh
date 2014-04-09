export GIT_CONVEY_TEST_MODE=0

# TODO: change to 'init_local_test_environment'
function init_test_environment() {
    TEST_SCRIPT="$1"; shift
    source $HOME/.conveyor/config
    GIT_CONVEY_HOME="$CONVEYOR_HOME/workflow"
    export GIT_CONVEY_HOME
    export GIT_CONVEY_TEST_DIR="$GIT_CONVEY_HOME/data/test"
    export ORIGIN_REPO="$TEST_SCRIPT.git"
    export WORKING_REPO="$TEST_SCRIPT"
    export ORIGIN_REPO_PATH="$GIT_CONVEY_TEST_DIR/$ORIGIN_REPO"
    export WORKING_REPO_PATH="$GIT_CONVEY_TEST_DIR/$WORKING_REPO"

    rm -rf $ORIGIN_REPO_PATH $WORKING_REPO_PATH

    if [ ! -d $GIT_CONVEY_HOME ]; then
	echo "Did not find standard conveyor-workflow install." >&2
	exit 2
    fi
    cd $GIT_CONVEY_HOME 2>/dev/null
    mkdir -p data
    cd data
    rm -rf test
    mkdir test
    cd test

    # TODO: we should support '-q/--quiet' for the following two commands.
    # Notice we use the 'working repo', without the '.git' extension because
    # init adds the extension. Users do not generally deal with the '.git'.
    con init $WORKING_REPO > /dev/null
    con sync "file://$ORIGIN_REPO_PATH" "$WORKING_REPO_PATH" > /dev/null
}

function init_github_test_environment() {
    local TEST_SCRIPT="$1"; shift

    local ORIGIN_REPO_URL='https://github.com/DogFoodSoftware/test-repo.git'

    source $HOME/.conveyor/config
    source $HOME/.conveyor-workflow/github
    source $TEST_BASE/../runnable/lib/github-hooks.sh

    local TEST_REPO='DogFoodSoftware/test-repo'
    GIT_CONVEY_HOME=$CONVEYOR_HOME/workflow
    export GIT_CONVEY_HOME
    export GIT_CONVEY_TEST_DIR="$GIT_CONVEY_HOME/data/test"
    export WORKING_REPO="$TEST_SCRIPT"
    export WORKING_REPO_PATH="$GIT_CONVEY_TEST_DIR/$WORKING_REPO"

    if ! does_repo_exist "$TEST_REPO"; then
	create_repo "$TEST_REPO"
	con init --github "$TEST_REPO" > /dev/null
    fi
    rm -rf $WORKING_REPO_PATH

    if [ ! -d $GIT_CONVEY_HOME ]; then
	echo "Did not find standard conveyor-workflow install." >&2
	exit 2
    fi
    cd $GIT_CONVEY_HOME 2>/dev/null
    mkdir -p data
    cd data
    rm -rf test
    mkdir test
    cd test

    # TODO: we should support '-q/--quiet' for the following command.  Notice
    # we use the 'working repo', without the '.git' extension because init
    # adds the extension. Users do not generally deal with the '.git'.
    (con sync "$ORIGIN_REPO_URL" "$WORKING_REPO_PATH" > /dev/null 2>&1; local RESULT=$?) | grep -v "warning: You appear to have cloned an empty repository" >&2
    return $RESULT
}

function populate_test_environment() {
    cd $GIT_CONVEY_TEST_DIR 2>/dev/null || (echo "Did not find standard conveyor-workflow data dir." >&2; exit 2)
    cd $WORKING_REPO_PATH 2>/dev/null || (echo "Did not find working repo: '$WORKING_REPO_PATH'." >&2; exit 2)
    # Notice we don't use the conveyor-workflow porcelain here as we don't want to
    # use what we're trying to test. I guess ideally we wouldn't use git
    # porcelain either, but git plumbing is tedious.
    git checkout --quiet -b topic-add-foo
    echo "foo" > foo
    git add foo
    git commit --quiet -am "added foo"
    git push --quiet origin topic-add-foo
    git checkout --quiet master
    git checkout --quiet -b topic-add-bar
    echo "bar" > bar
    git add bar
    git commit --quiet -am "added bar"
    git push --quiet origin topic-add-bar
}
