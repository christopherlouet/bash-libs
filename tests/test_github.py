import inspect
import os
import pytest
from dotenv import load_dotenv

script_dir: str = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
if os.getenv('PWD') == "/app":
    script_dir = "/app/tests"
script: str = os.path.abspath(f"{script_dir}/../libs/github.sh")


@pytest.fixture(autouse=True)
def pytest_fixture(bash):
    load_dotenv(dotenv_path=f"{script_dir}/.env")
    github_api_token: str = os.getenv('GITHUB_API_TOKEN')
    if github_api_token is None:
        bash.run_script(script, ['init', 'christopherlouet/bash-libs', f'{script_dir}/src/github'])
    else:
        bash.run_script(script, ['init', 'christopherlouet/bash-libs', f'{script_dir}/src/github', github_api_token])


def test_check_api_rate(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['_gh_check_api_rate', 0]) == ''
        assert s.last_return_code == 0


def test_check_api_rate_with_display(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['_gh_check_api_rate', 1]) == 'ok'
        assert s.last_return_code == 0


def test_release_latest(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['_gh_release_latest', 0]) == ''
        assert s.last_return_code == 0


def test_release_latest_with_display(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['_gh_release_latest', 1]) == 'v1.0.0'
        assert s.last_return_code == 0


def test_release_verify_parameter_not_exist(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['_gh_release_verify']) == 'Please provide a release name'
        assert s.last_return_code == 1


def test_release_verify_parameter_empty(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['_gh_release_verify', ""]) == 'Please provide a release name'
        assert s.last_return_code == 1


def test_release_verify(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['_gh_release_verify', "v1.0.0"]) == 'v1.0.0 exist'
        assert s.last_return_code == 0


def test_release_verify_not_exist(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['_gh_release_verify', "v1.0.1"]) == 'v1.0.1 not exist'
        assert s.last_return_code == 1


def test_release_choice(bash):
    with bash() as s:
        s.auto_return_code_error = False
        s.run_script(script, ['_gh_release_choice', "v1.0.0"])
        assert s.last_return_code == 0


def test_release_choice_not_exist(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['_gh_release_choice', 'v1.0.1']) == 'Not a valid version'
        assert s.last_return_code == 1


def test_release_choice_no_answer(bash):
    with bash() as s:
        s.auto_return_code_error = False
        s.run_script(script, ['_gh_release_choice', 'no_answer'])
        assert s.last_return_code == 1
