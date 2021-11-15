import sys
from snek5000 import load_for_restart


params, Simul = load_for_restart(sys.argv[1])
sim = Simul(params)
sim.make.exec("run_fg")
