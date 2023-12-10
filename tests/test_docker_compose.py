import inspect
import os
import pytest

script_dir: str = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
if os.getenv('PWD') == "/app":
    script_dir = "/app/tests"
script: str = f"{script_dir}/../libs/docker_compose.sh"


@pytest.fixture(autouse=True)
def pytest_fixture(bash):
    bash.run_script(script, ["init", "test", f"{script_dir}/src/docker_compose", '', "profile_test1",
                             f"{script_dir}/src/docker_compose/test.env"])


def test_dc_build_docker_compose(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['dc_build_docker_compose', f"{script_dir}/src/docker_compose",
                                     "docker-compose.yml", "test"
                                     ]) == f"docker compose -f {script_dir}/src/docker_compose/docker-compose.yml test"
        assert s.last_return_code == 0


def test_dc_build_docker_compose_without_cmd(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['dc_build_docker_compose', f"{script_dir}/src/docker_compose",
                                     "docker-compose.yml"]) == "Please provide a command"
        assert s.last_return_code == 1


def test_dc_build_docker_compose_with_opts(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['dc_build_docker_compose', f"{script_dir}/src/docker_compose",
                                     "docker-compose.yml", "test", "--env=test1"
            ]) == f"docker compose -f {script_dir}/src/docker_compose/docker-compose.yml test --env=test1"
        assert s.last_return_code == 0


def test_dc_build_options(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['_dc_build_options', "1"
            ]) == f" --profile profile_test1 --env-file {script_dir}/src/docker_compose/test.env"
        assert s.last_return_code == 0


def test_dc_build_options_with_opts(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['_dc_build_options', "1", "-p=test1"
            ]) == f"-p=test1 --profile profile_test1 --env-file {script_dir}/src/docker_compose/test.env"
        assert s.last_return_code == 0


def test_dc_build_command_command_empty(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['dc_build_command']) == "Please provide a docker compose command"
        assert s.last_return_code == 1


def test_dc_build_command_file_empty(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['dc_build_command', 'test']) == "Please provide a docker compose file"
        assert s.last_return_code == 1


def test_dc_build_command(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['dc_build_command', 'test', f"{script_dir}/src/docker_compose"]
                            ) == f"docker compose -f {script_dir}/src/docker_compose/docker-compose.yml test"
        assert s.last_return_code == 0


def test_build_file_empty_1(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['build']) == "Please provide a docker compose file"
        assert s.last_return_code == 1


def test_build_file_empty_2(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['build', f"{script_dir}/src/docker_compose2"]
                            ) == "Please provide a docker compose file"
        assert s.last_return_code == 1


def test_build_file_empty_3(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['build', f"{script_dir}/src/docker_compose", "docker-compose2.yml"]
                            ) == "Please provide a docker compose file"
        assert s.last_return_code == 1


def test_build(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['build', f"{script_dir}/src/docker_compose"]
                            ) == f"docker compose -f {script_dir}/src/docker_compose/docker-compose.yml build"
        assert s.last_return_code == 0


def test_build_with_opts(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['build', f"{script_dir}/src/docker_compose", "", "", "--test=test1"]
           ) == f"docker compose -f {script_dir}/src/docker_compose/docker-compose.yml --test=test1 build"
        assert s.last_return_code == 0


def test_build_with_env(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['_build']
    ) == f"docker compose -f {script_dir}/src/docker_compose/docker-compose.yml --profile profile_test1 --env-file {script_dir}/src/docker_compose/test.env build"
        assert s.last_return_code == 0


def test_build_with_env_and_opts(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['_build', "", "--test=test1"]
                            ) == f"docker compose -f {script_dir}/src/docker_compose/docker-compose.yml --test=test1 --profile profile_test1 --env-file {script_dir}/src/docker_compose/test.env build"
        assert s.last_return_code == 0


def test_status_file_empty_1(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['status']) == "Please provide a docker compose file"
        assert s.last_return_code == 1


def test_status_file_empty_2(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['status', f"{script_dir}/src/docker_compose2"]
                            ) == "Please provide a docker compose file"
        assert s.last_return_code == 1


def test_status_file_empty_3(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['status', f"{script_dir}/src/docker_compose", "docker-compose2.yml"]
                            ) == "Please provide a docker compose file"
        assert s.last_return_code == 1


def test_status_service_empty(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['status', f"{script_dir}/src/docker_compose"]
                            ) == "Please provide a docker compose service name"
        assert s.last_return_code == 1


def test_status_service_not_exist(bash):
    with bash() as s:
        s.auto_return_code_error = False
        assert s.run_script(script, ['status', f"{script_dir}/src/docker_compose", "", "service_fake"]
                            ) == "no such service: service_fake"
        assert s.last_return_code == 1


# def test_status_service(bash):
#     with bash() as s:
#         s.auto_return_code_error = False
#         s.run_script(script, ["_up", 0])
#         assert s.run_script(script, ['status', f"{script_dir}/src/docker_compose", "", "dc_test1"]
#                             ) == "running"
#         assert s.last_return_code == 0
#         s.run_script(script, ["_down", 0])


