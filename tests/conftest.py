import pytest


def pytest_addoption(parser):
    # https://pytest.readthedocs.io/en/latest/example/simple.html#control-skipping-of-tests-according-to-command-line-option
    parser.addoption(
        "--runslow", action="store_true", default=False, help="run slow tests"
    )


def pytest_configure(config):
    config.addinivalue_line("markers", "slow: mark test as slow to run")


def pytest_collection_modifyitems(config, items):
    if config.getoption("--runslow"):
        # --runslow given in cli: do not skip slow tests
        return
    skip_slow = pytest.mark.skip(reason="need --runslow option to run")
    for item in items:
        if "slow" in item.keywords:
            item.add_marker(skip_slow)


@pytest.fixture(
    scope="session",
    params=[
        "vreman",
        pytest.param("constant", marks=pytest.mark.slow),
        # Unconditional skip below, because these models will not be used
        pytest.param("shear_imp", marks=pytest.mark.skip),
        pytest.param("dynamic", marks=pytest.mark.skip),
    ],
)
def sim(request):
    sgs_model = request.param

    from abl.solver import Simul

    params = Simul.create_default_params()
    params.output.sub_directory = "test"

    params.nek.general.stop_at = "numSteps"
    params.nek.general.num_steps = 9

    params.oper.nproc_min = 4
    params.oper.Lx = params.oper.Ly = params.oper.Lz = 1280
    params.oper.nx = params.oper.ny = params.oper.nz = 6

    params.output.sgs_model = sgs_model

    params.nek.stat.av_step = 3
    params.nek.stat.io_step = 9

    return Simul(params)
