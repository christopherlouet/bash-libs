import inspect
import os

script_dir: str = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
script: str = f"{script_dir}/../libs/messages.sh"


def test_show_message(bash):
    assert bash.run_script(script, ['show_message', 'msg']) == 'msg'


def test_show_message_info(bash):
    assert bash.run_script(script, ['show_message', 'info', 0]) == 'info'


def test_show_message_warning(bash):
    assert bash.run_script(script, ['show_message', 'warning', -1]) == 'warning'


def test_show_message_error(bash):
    try:
        bash.run_script(script, ['show_message', 'error', 1])
    except:
        assert bash.connection.last == 'error'
        assert bash.last_return_code == 1


def test_show_message_error_invalid(bash):
    try:
        bash.run_script(script, ['show_message', 'invalid', 'test'])
    except:
        assert bash.connection.last == 'Invalid level option'
        assert bash.last_return_code == 1


def test_show_confirm_message(bash):
    assert bash.run_script(script, ['show_confirm_message', 'test', 'y', 'y']) == 'y'
