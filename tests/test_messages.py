import inspect
import os

script_dir: str = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
if os.getenv('PWD') == "/app":
    script_dir = "/app/tests"
script: str = f"{script_dir}/../libs/messages.sh"


def test_show_message(bash):
    assert bash.run_script(script, ['show_message', 'msg']) == 'msg'


def test_show_message_info(bash):
    assert bash.run_script(script, ['show_message', 'info', 0]) == 'info'


def test_show_message_warning(bash):
    assert bash.run_script(script, ['show_message', 'warning', -1]) == 'warning'


def test_show_message_error(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['show_message', 'error1', 1]) == 'error1'
        assert s.last_return_code == 0


def test_show_message_error_2(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['show_message', 'error2', 2]) == 'error2'
        assert s.last_return_code == 0


def test_show_message_invalid_level(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['show_message', 'invalid_level', 'test']) == 'Invalid level option'
        assert s.last_return_code == 1


def test_confirm_message_no_answer(bash):
    assert bash.run_script(script, [
        'confirm_message', 'confirm_message_no_answer', '', 'no_answer']) == ''


def test_confirm_message_no_answer_not_empty(bash):
    assert bash.run_script(script, [
        'confirm_message', 'confirm_message_no_answer_not_empty', 'not_empty', 'no_answer']) == 'not_empty'


def test_confirm_message_answer_y(bash):
    assert bash.run_script(script, [
        'confirm_message', 'confirm_message_answer_y', '', 'y']) == 'y'


def test_confirm_message_answer_y_uppercase(bash):
    assert bash.run_script(script, [
        'confirm_message', 'test_confirm_message_answer_y_uppercase', '', 'Y']) == 'y'


def test_confirm_message_answer_yes(bash):
    assert bash.run_script(script, [
        'confirm_message', 'confirm_message_answer_yes', '', 'yes']) == 'y'


def test_confirm_message_answer_yes_uppercase(bash):
    assert bash.run_script(script, [
        'confirm_message', 'confirm_message_answer_yes_uppercase', '', 'YES']) == 'y'


def test_confirm_message_answer_y_not_empty(bash):
    assert bash.run_script(script, [
        'confirm_message', 'confirm_message_answer_y_not_empty', 'not_empty', 'y']) == 'y'


def test_confirm_message_answer_n(bash):
    assert bash.run_script(script, [
        'confirm_message', 'confirm_message_answer_n', '', 'n']) == ''


def test_confirm_message_answer_not_empty(bash):
    assert bash.run_script(script, [
        'confirm_message', 'confirm_message_answer_not_empty', 'not_empty', 'n']) == ''
