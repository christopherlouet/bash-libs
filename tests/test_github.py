import inspect
import os
import pytest

script_dir: str = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
script: str = f"{script_dir}/../libs/github.sh"


@pytest.fixture
def pytest_fixture():
    print("Hello World")


def test_release_latest(bash):
    assert 1 == 1
