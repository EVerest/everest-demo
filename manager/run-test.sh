#! /bin/sh
pip install pytest pytest-asyncio
pytest --everest-prefix /workspace/dist core_tests/startup_tests.py 
