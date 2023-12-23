import inspect
import os
import pytest

script_dir: str = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
if os.getenv('PWD') == "/app":
    script_dir = "/app/tests"
script: str = os.path.abspath(f"{script_dir}/test_all.sh")
dc_project_folder: str = os.path.abspath(f"{script_dir}/../config/docker_compose")


def test_docker_compose(bash):
    with bash() as s:
        s.auto_return_code_error = False
        opts: str = f"--profile profile_test1 --env-file {dc_project_folder}/test.env"
        assert s.run_script(script, ["test_docker_compose"]
                            ) == f"docker compose -f {dc_project_folder}/docker-compose.yml {opts} start"
        assert s.last_return_code == 0


def test_github(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ["test_github"]) == "v1.0.0 exist"
        assert s.last_return_code == 0


def test_menu(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ["test_menu"]) == "Usage: test.sh test1 [--test1|test2|test3]"
        assert s.last_return_code == 0
