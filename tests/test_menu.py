import inspect
import os
import pytest

script_dir: str = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
if os.getenv('PWD') == "/app":
    script_dir = "/app/tests"
project_folder: str = os.path.abspath(f"{script_dir}/../config/menu")
script: str = os.path.abspath(f"{script_dir}/../libs/menu.sh")
menu_path_file = f"{project_folder}/menu.yml"


@pytest.fixture(autouse=True)
def pytest_fixture(bash):
    bash.run_script(script, ["init", "test", "menu", 'menu.yml'])


def test_check_menu_entries_file_empty(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['check_menu_entries']) == "Please provide a menu configuration file"
        assert s.last_return_code == 1


def test_check_menu_opts_empty(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['check_menu_entries', f"{menu_path_file}"]) == ""
        assert s.last_return_code == 0


def test_check_menu_opts_not_exist(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['check_menu_entries', f"{menu_path_file}", "toto"]) == "Option toto does not exist"
        assert s.last_return_code == 1


def test_check_menu_opts_exist(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['check_menu_entries', f"{menu_path_file}", "test1"]) == ""
        assert s.last_return_code == 0


def test_build_mandatory_opts_file_empty(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['build_mandatory_opts']) == "Please provide a menu configuration file"
        assert s.last_return_code == 1


def test_build_mandatory_opts_empty(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['build_mandatory_opts', f"{menu_path_file}"]) == ""
        assert s.last_return_code == 0


def test_build_mandatory_opts_one(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['build_mandatory_opts', f"{menu_path_file}", 1, "test1"]) == "[test1]"
        assert s.last_return_code == 0


def test_build_mandatory_opts_many(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['build_mandatory_opts', f"{menu_path_file}", 1, "test1", "test2"
                                     ]) == "[test1|--test2]"
        assert s.last_return_code == 0


def test_build_optional_opts_file_empty(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['build_optional_opts']) == "Please provide a menu configuration file"
        assert s.last_return_code == 1


def test_build_optional_opts_empty(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['build_optional_opts', f"{menu_path_file}"]) == ""
        assert s.last_return_code == 0


def test_build_optional_opts_one(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['build_optional_opts', f"{menu_path_file}", 1, "test5"]) == "{test5}"
        assert s.last_return_code == 0


def test_build_optional_opts_many(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['build_optional_opts', f"{menu_path_file}", 1, "test5", "test6"
                                     ]) == "{test5|test6}"
        assert s.last_return_code == 0


def test_build_cmd_file_empty(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['build_cmd_opts']) == "Please provide a menu configuration file"
        assert s.last_return_code == 1


def test_build_cmd_empty(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['build_cmd_opts', f"{menu_path_file}", 1
                                     ]) == "[test1|--test2|test3|test4] {test5|test6}"
        assert s.last_return_code == 0


def test_build_cmd_with_regex_test1(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['build_cmd_opts', f"{menu_path_file}", 1, ".opts .test1"
                                     ]) == "[--test1|test2|test3]"
        assert s.last_return_code == 0


def test_build_cmd_with_regex_test2(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['build_cmd_opts', f"{menu_path_file}", 1, ".opts .test6"
                                     ]) == "[--test1|test2|test3] {test4}"
        assert s.last_return_code == 0


def test_display_help_file_empty(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['display_help']) == "Please provide a menu configuration file"
        assert s.last_return_code == 1


def test_display_help_without_opts(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['display_help', f"{menu_path_file}"
                                     ]) == "Usage: test.sh [test1|--test2|test3|test4] {test5|test6}"
        assert s.last_return_code == 0


def test_display_help_with_opts_test1(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['display_help', f"{menu_path_file}", "test1"
                                     ]) == "Usage: test.sh test1 [--test1|test2|test3]"
        assert s.last_return_code == 0


def test_display_help_with_opts_test2(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['display_help', f"{menu_path_file}", "test6"
                                     ]) == "Usage: test.sh test6 [--test1|test2|test3] {test4}"
        assert s.last_return_code == 0


def test_display_help_with_env_file(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['_display_help']) == "Usage: test.sh [test1|--test2|test3|test4] {test5|test6}"
        assert s.last_return_code == 0


def test_display_help_with_env_file_and_opts_test1(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['_display_help', "test1"]) == "Usage: test.sh test1 [--test1|test2|test3]"
        assert s.last_return_code == 0


def test_display_help_with_env_file_and_opts_test2(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['_display_help', "test6"]) == "Usage: test.sh test6 [--test1|test2|test3] {test4}"
        assert s.last_return_code == 0
