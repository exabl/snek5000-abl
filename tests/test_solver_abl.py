from eturb.solvers.abl import Simul


def test_init():
    params = Simul.create_default_params()
    params.output.sub_directory = "test"
    sim = Simul(params)
    sim.make.list()
    sim.make.exec(["mesh", "compile", "run"])
