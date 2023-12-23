import inspect
import os
import pytest

script_dir: str = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
if os.getenv('PWD') == "/app":
    script_dir = "/app/tests"
project_folder: str = os.path.abspath(f"{script_dir}/../config/docker_compose")
script: str = os.path.abspath(f"{script_dir}/../libs/docker_compose.sh")


@pytest.fixture(autouse=True)
def pytest_fixture(bash):
    bash.run_script(script, ["init", "test", "docker_compose", "", "profile_test1", "test.env", "dc_test1"])


def test_dc_build_docker_compose_file_empty(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ["dc_build_docker_compose"]) == "Please provide a docker compose file"
        assert s.last_return_code == 1


def test_dc_build_docker_compose_without_cmd(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ["dc_build_docker_compose", f"{project_folder}/docker-compose.yml"
                                     ]) == "Please provide a command"
        assert s.last_return_code == 1


def test_dc_build_docker_compose_not_exist(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ["dc_build_docker_compose", f"{project_folder}/docker-compose.yml", "test"
                                     ]) == "Unknown docker command: test"
        assert s.last_return_code == 1


def test_dc_build_docker_compose(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ["dc_build_docker_compose", f"{project_folder}/docker-compose.yml", "start"
                                     ]) == f"docker compose -f {project_folder}/docker-compose.yml start"
        assert s.last_return_code == 0


def test_dc_build_docker_compose_with_opts(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ["dc_build_docker_compose", f"{project_folder}/docker-compose.yml", "start",
                                     "--env test1"
                                     ]) == f"docker compose -f {project_folder}/docker-compose.yml --env test1 start"
        assert s.last_return_code == 0


def test_dc_build_options(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ["_dc_build_options", "1"]
                            ) == f" --profile profile_test1 --env-file {project_folder}/test.env"
        assert s.last_return_code == 0


def test_dc_build_options_with_opts(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ["_dc_build_options", "1", "-p=test1"
                                     ]) == f"-p=test1 --profile profile_test1 --env-file {project_folder}/test.env"
        assert s.last_return_code == 0


def test_exec_command_file_empty(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ["dc_exec_command"]) == "Please provide a docker compose file"
        assert s.last_return_code == 1


def test_exec_command_empty(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ["dc_exec_command", f"{project_folder}/docker-compose.yml"
                                     ]) == "Please provide a docker compose command"
        assert s.last_return_code == 1


def test_exec_command_not_exist(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ["dc_exec_command", f"{project_folder}/docker-compose.yml", "1", "test"
                                     ]) == "Unknown docker command: test"
        assert s.last_return_code == 1


def test_exec_command(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ["dc_exec_command", f"{project_folder}/docker-compose.yml", "1", "start"]
                            ) == f"docker compose -f {project_folder}/docker-compose.yml start"
        assert s.last_return_code == 0


def test_exec_command_with_opts(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ["dc_exec_command",
                                     f"{project_folder}/docker-compose.yml", "1", "start", "--test test1"]
                            ) == f"docker compose -f {project_folder}/docker-compose.yml --test test1 start"
        assert s.last_return_code == 0


def test_exec_command_with_env_file_empty(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ["_dc_exec_command"]) == "Please provide a docker compose command"
        assert s.last_return_code == 1


def test_exec_command_with_env(bash):
    with bash() as s:
        s.auto_return_code_error = False
        opts: str = f"--profile profile_test1 --env-file {project_folder}/test.env"
        assert s.run_script(script, ["_dc_exec_command", "1", "build"]
    ) == f"docker compose -f {project_folder}/docker-compose.yml {opts} build"
        assert s.last_return_code == 0


def test_exec_command_with_env_and_opts(bash):
    with bash() as s:
        s.auto_return_code_error = False
        opts: str = f"--test test1 --profile profile_test1 --env-file {project_folder}/test.env"
        assert s.run_script(script, ["_dc_exec_command", "1", "build", "--test test1"]
                            ) == f"docker compose -f {project_folder}/docker-compose.yml {opts} build"
        assert s.last_return_code == 0


def test_status_file_empty_1(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ["dc_status"]) == "Please provide a docker compose file"
        assert s.last_return_code == 1


def test_status_file_empty_2(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ["dc_status", f"{project_folder}/test"]
                            ) == "Please provide a docker compose file"
        assert s.last_return_code == 1


def test_status_service_empty(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ["dc_status", f"{project_folder}/docker-compose.yml"]
                            ) == "Please provide a docker compose service name"
        assert s.last_return_code == 1


def test_status_service_not_exist(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ["dc_status", f"{project_folder}/docker-compose.yml", "service_fake"]
                            ) == "no such service: service_fake"
        assert s.last_return_code == 1


# def test_status_service(bash):
#     with bash() as s:
#         s.auto_return_code_error = False
#         s.run_script(script, ["_up", 0])
#         assert s.run_script(script, ["status", f"{script_dir}/src/docker_compose", "", "dc_test1"]
#                             ) == "running"
#         assert s.last_return_code == 0
#         s.run_script(script, ["_down", 0])
