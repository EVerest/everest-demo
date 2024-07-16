#!/bin/bash
TEST_TYPE=$1
exit_code=0
if [ "$TEST_TYPE" == "success" ]; then
    exit_code=0
elif [ "$TEST_TYPE" == "failure" ]; then
    exit_code=1
fi

echo "Exit Code from test-exit-code.sh: $exit_code"
exit $exit_code