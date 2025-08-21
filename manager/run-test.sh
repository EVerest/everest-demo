#!/bin/bash
#! /bin/sh
cmake --build /ext/build --target install_everest_testing
. /ext/build/venv/bin/activate
pytest --everest-prefix /ext/dist core_tests/*.py framework_tests/*.py
