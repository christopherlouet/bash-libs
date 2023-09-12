import inspect
import os
import pytest

script_dir: str = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
script: str = f"{script_dir}/../libs/github.sh"


@pytest.fixture(autouse=True)
def pytest_fixture(bash):
    bash.run_script(script, ['init', 'christopherlouet/bash-libs', f'{script_dir}/src/github'])


def test_release_latest(bash):
    assert bash.run_script(script, ['release_latest']) == 'v1.0.0'


def test_release_verify_parameter_not_exist(bash):
    assert bash.run_script(script, ['release_verify']) == 'Please provide a release name'


def test_release_verify_parameter_empty(bash):
    assert bash.run_script(script, ['release_verify', '']) == 'Please provide a release name'


def test_release_verify(bash):
    assert bash.run_script(script, ['release_verify', 'v1.0.0']) == 'v1.0.0'


def test_release_verify_not_exist(bash):
    assert bash.run_script(script, ['release_verify', 'v1.0.1']) == ''


def test_release_choice(bash):
    assert bash.run_script(script, ['release_choice', 'v1.0.0']) == "v1.0.0"


def test_release_choice_not_exist(bash):
    assert bash.run_script(script, ['release_choice', 'v1.0.1']) == "Please provide a release name"


def test_release_choice_no_answer(bash):
    assert bash.run_script(script, ['release_choice', 'no_answer']) == "Please provide a release name"
