# Here we follow shflags. Without reliable packaging, we find it easier to
# just make the library self sufficient.
FLAGS_TRUE=0
FLAGS_FALSE=1

check_path() {
    local RESULT ERROR
    ERROR=1 # bash false
    # We expect to find 'con' and 'git-coveyor' on the PATH. If not, the tests
    # cannot run.
    which con > /dev/null 2> /dev/null
    RESULT=$?
    if [ $RESULT -ne 0 ]; then
	ERROR=0 # bash true
	echo "ERROR: Did not find 'con' on PATH."
    fi
    which git-conveyor > /dev/null 2> /dev/null
    RESULT=$?
    if [ $RESULT -ne 0 ]; then
	ERROR=0 # bash true
	echo "ERROR: Did not find 'git-conveyor' on PATH." >&2
    fi
    if [ $ERROR -eq 0 ]; then
	echo "Please add:" >&2
	echo "'\$HOME/playground/dogfoodsoftware.com/conveyor/core/bin' or custom install" >&2
	echo "location to PATH." >&2
	exit 1
    fi
}

test_output() {
    # Mandatory args
    local COMMAND="$1"; shift
    local EXPECTED_STDOUT_START="$1"; shift
    local EXPECTED_STDERR_START="$1"; shift
    local EXPECTED_EXIT_CODE NO_EXPECTED_STDERR NO_EXPECTED_STDOUT MIN_WORDS ECHO_OUTPUT TMP_OUT TMP_FILE RESULT ERROUT OUTPUT OUTPUT_ARRAY WORD_COUNT IN_ERR
    IN_ERR=1 #bash false

    # Optional args.
    if [ $# -ge 1 ]; then
	EXPECTED_EXIT_CODE="$1"; shift
    else
	EXPECTED_EXIT_CODE=0
    fi
    if [ $# -ge 1 ]; then
	MIN_WORDS="$1"; shift
    else
	MIN_WORDS=''
    fi
    if [ $# -ge 1 ]; then
	ECHO_OUTPUT="$1"
    else
	ECHO_OUTPUT=1 # Bash for false.
    fi

    # Evaluate whether or not we expect output for stdout and stderr.
    if [[ ( x"$EXPECTED_STDOUT_START" == x"") && 
	  ( x"$MIN_WORDS" == x"" || $MIN_WORDS -eq 0 ) ]] ; then
	NO_EXPECTED_STDOUT=${FLAGS_TRUE}
    else
	NO_EXPECTED_STDOUT=${FLAGS_FALSE}
    fi
    if [ x"$EXPECTED_STDERR_START" == x"" ]; then
	NO_EXPECTED_STDERR=${FLAGS_TRUE}
    else
	NO_EXPECTED_STDERR=${FLAGS_FALSE}
    fi
    TMP_OUT="/tmp/$RANDOM"
    TMP_FILE="/tmp/$RANDOM"

#    if ! eval 'OUTPUT=`$COMMAND 2>$TMP_FILE | sed -n 1p`'; then
#    eval 'OUTPUT=`$COMMAND 2>$TMP_FILE`'
    eval $COMMAND > $TMP_OUT 2>$TMP_FILE    
    RESULT=$?
    local OUTPUT=`cat $TMP_OUT`
    if [ $RESULT != $EXPECTED_EXIT_CODE ]; then
	echo "ERROR: expected exit code '$EXPECTED_EXIT_CODE', but got '$RESULT' for '$COMMAND'."
	IN_ERR=0
    fi
    ERROUT=`cat $TMP_FILE | sed -n 1p`

    if [ x"$OUTPUT" == x"" ] &&
	[ "$NO_EXPECTED_STDOUT" != "${FLAGS_TRUE}" ]; then
	# Tested this detects failure by exiting immediately from help mode.
	echo "ERROR: '$COMMAND' did not produce any text on stdout as expected."
	IN_ERR=0
    elif [ x"$OUTPUT" != x"" ] &&
	[ "$NO_EXPECTED_STDOUT" == "${FLAGS_TRUE}" ]; then
	echo -e "ERROR: '$COMMAND' was not expected to produce output, but got:\n$OUTPUT"
	IN_ERR=0
    elif [[ "$OUTPUT" != "$EXPECTED_STDOUT_START"* ]]; then
	# Tested this detects failure by modifying the output of usage,
	# resource_usage, and resource_help.
	echo -e "ERROR: '$COMMAND' output did not start with expected:\n'$EXPECTED_STDOUT_START'; got:\n'$OUTPUT'"
	echo "ERROR: STDERR - $ERROUT"
	IN_ERR=0
    fi

    OUTPUT_ARRAY=( $OUTPUT )
    WORD_COUNT=${#OUTPUT_ARRAY[@]}
    if [[ ( x"$MIN_WORDS" != x"" ) && ( $WORD_COUNT -lt $MIN_WORDS ) ]]; then
	echo "ERROR: '$COMMAND' output was expected to output at least ${MIN_WORDS}, but instead got $WORD_COUNT."
	echo "ERROR: STDERR - $ERROUT"
	IN_ERR=0
    fi

    if [ x"$ERROUT" == x"" ] &&
	[ x"$NO_EXPECTED_STDERR" != x"$FLAGS_TRUE" ]; then
	echo "ERROR: '$COMMAND' did not produce any text on stderr as expected."
	echo "ERROR: STDERR - $ERROUT"
	IN_ERR=0
    elif [ x"$ERROUT" != x"" ] &&
	[ "$NO_EXPECTED_STDERR" == "$FLAGS_TRUE" ]; then
	echo -e "ERROR: '$COMMAND' was not expected to produce error output, but got:\n$ERROUT"
    elif [[ "$ERROUT" != "$EXPECTED_STDERR_START"* ]]; then
	echo -e "ERROR: '$COMMAND' stderr output did not start with expected:\n'$EXPECTED_STDERR_START'; got:\n'$ERROUT'"
	IN_ERR=0
    fi

    rm $TMP_FILE
    rm $TMP_OUT

    if [ $ECHO_OUTPUT -eq 0 ]; then
	echo $OUTPUT
    fi

    [ $IN_ERR -eq 1 ] # bash for 'if not in error'
}

test_help() {
    local COMMAND="$1"; shift
    local EXPECTED_STDOUT_START="$1"; shift
    test_output "$COMMAND" "$EXPECTED_STDOUT_START" "" 0
}

test_significant_output() {
    local COMMAND="$1"; shift
    test_output "$COMMAND" "" "" 0 5
}

#/**
#* Thanks to <a
#* href="http://stackoverflow.com/users/1320169/rintcius">rintcius</a> for his
#* <a
#* href="http://stackoverflow.com/questions/6565357/git-push-requires-username-and-password">answer</a>
#* on StackOverflow.com.
#*/
function automate_github_https() {
    if [ ! -f $HOME/.netrc ]; then
	set_github_origin_data
	cat <<EOF > $HOME/.netrc
machine github.com
   login $GITHUB_AUTH_TOKEN
   password x-oauth-basic
EOF
	trap "{ rm $HOME/.netrc }" EXIT
    fi
}
