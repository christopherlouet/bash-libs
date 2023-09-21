import inspect
import os

script_dir: str = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
script: str = f"{script_dir}/../libs/utils.sh"


def test_check_function_params_empty(bash):
    with (bash() as s):
        s.auto_return_code_error = False
        assert s.run_script(script) == "Please provide a function name"


def test_check_function_params_function_not_exist(bash):
    with (bash() as s):
        s.auto_return_code_error = False
        assert s.run_script(script, ['check_args_function_not_exist']
                            ) == "Function with name 'check_args_function_not_exist' not exists"


def test_check_function_params(bash):
    assert bash.run_script(script, ['test_check_args']) == 'test_check_args'


def test_check_function_params_with_env(bash):
    assert bash.run_script(script, ['_test_check_args_with_env']) == 'load_env'


def test_init_env(bash):
    env_file: str = f"{script_dir}/../libs/.utils"
    bash.run_script(script, ['test_init_env'])

    if os.path.isfile(env_file):
        stream = open(env_file, "r")
        content = stream.read()
        stream.close()
        assert content == "TEST_ENV_KEY=TEST_ENV_VALUE\n"
    else:
        assert False
