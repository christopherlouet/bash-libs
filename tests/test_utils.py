import inspect
import os
import pytest

script_dir: str = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
if os.getenv('PWD') == "/app":
    script_dir = "/app/tests"
script: str = os.path.abspath(f"{script_dir}/../libs/utils.sh")


def test_check_function_params_empty(bash):
    with (bash() as s):
        s.auto_return_code_error = False
        assert s.run_script(script) == ""
        assert s.last_return_code == 0


def test_check_function_params_function_not_exist(bash):
    with (bash() as s):
        s.auto_return_code_error = False
        s.run_script(script, ['check_args_function_not_exist'])
        assert s.last_return_code == 127


@pytest.mark.skipif(os.getenv('PWD') == "/app", reason="Do not launch in a docker container")
def test_check_function_params(bash):
    with (bash() as s):
        s.auto_return_code_error = False
        assert s.run_script(script, ['test_check_args']) == 'test_check_args'
        assert s.last_return_code == 0


@pytest.mark.skipif(os.getenv('PWD') == "/app", reason="Do not launch in a docker container")
def test_check_function_params_with_env(bash):
    with (bash() as s):
        s.auto_return_code_error = False
        assert s.run_script(script, ['_test_check_args_with_env']) == 'TEST_ENV_KEY=TEST_ENV_VALUE'
        assert s.last_return_code == 0
