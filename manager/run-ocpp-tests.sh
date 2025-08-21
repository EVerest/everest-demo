#!/bin/bash

cmake --build /ext/build --target install_everest_testing
. /ext/build/venv/bin/activate
cmake --build /ext/build --target everestpy_pip_install_dist
cmake --build /ext/build --target everest-testing_pip_install_dist
cmake --build /ext/build --target iso15118_pip_install_dist
python3 -m pip install aiofile>=3.7.4
python3 -m pip install netifaces>=0.11.0

cd /ext/source/tests/ocpp_tests
python3 -m pip install -r requirements.txt

PYTHON_INTERPRETER="${PYTHON_INTERPRETER:-python3}"
echo "Using python: $PYTHON_INTERPRETER"

PARALLEL_TESTS=$(nproc)
if [ $# -eq 1 ] ; then
    PARALLEL_TESTS="$1"
fi

echo "Running $PARALLEL_TESTS tests in parallel"

$(cd test_sets/everest-aux/ && ./install_certs.sh "/ext/dist" && ./install_configs.sh "/ext/dist")

"$PYTHON_INTERPRETER" -m pytest -d --tx "$PARALLEL_TESTS"*popen//python="$PYTHON_INTERPRETER" -rA --junitxml=result.xml --html=report.html --self-contained-html --max-worker-restart=0 --timeout=300 --dist loadgroup test_sets/ocpp16/*.py test_sets/ocpp201/*.py test_sets/ocpp21/*.py --everest-prefix "/ext/dist"

