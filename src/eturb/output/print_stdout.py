"""Load and parse stdout from Nek5000.

"""
import re
import sys
from pathlib import Path
import numpy as np

from eturb.log import logger
from eturb.solvers.abl import Simul

# Uses awkupy
# %load_ext iawk

class PrintStdOut:
    
    _tag = "print_stdout"

    def __init__(self, output=None, file=None):
        self.output = output
        self._file = None        

    @property
    def file(self):
        output = self.output
        if output and not self._file:
            logger.info("Searching for a log file...")
            path_run = Path(output.path_run)
            logfiles = sorted(path_run.glob("*.log"))
            if logfiles:
                self._file = logfiles[-1]
            else:
                raise FileNotFoundError(f"Cannot find a .log to parse in {path_run}: {logfiles}")

                
        return self._file

    @file.setter
    def file(self, path_log_file):
        self._file = path_log_file

    @property
    def text(self):
        with open(self.file) as fp:
            return fp.read()
        
    @property
    def path_run(self):
        """Parse path_run from log file"""
        par_file = re.findall(
            'Reading.*par',
            self.text
        )[-1].split()[-1]
        path = Path(par_file).parent
        return path

    @property
    def params(self):
        return Simul.load_params_from_file(path_xml=self.path_run / "params.xml")

    @property
    def text_steps(self):
        """Parse text starting with Step
        
        https://regex101.com/r/enFOAg/1
        """
        pattern = re.compile(
            r"""^Step          # For all lines starting with Step
                \s*            # Followed by some whitespaces
                (\d+)          # 0: Capture timestep which are integers
                .*             # Followed by some characters until
                t=\s*          # t=spaces
                (\S+)          # 1: Capture t: any non-whitespace char
                ,\s*           # comma and spaces
                DT=\s*         # DT=spaces
                (\S+)          # 2: Capture DT: any non-whitespace char
                ,\s*           # comma and spaces
                C=\s*          # C=spaces
                (.+)           # 3: Capture C: any char
    """,
            re.VERBOSE|re.MULTILINE
        )
        return pattern.findall(self.text)
    
    @property
    def dt(self):
        """Extract time step dt over the course of a simulation."""
        # Alternate implementations
        # 1. awkup
        # dts = %awk -F, -e '/Step/{print $3}' {self.file}
        # 
        # 2. Basic regex
        # steps = re.findall("Step.*DT.*", self.text)
        # try:
        #     dt_strings = [step.split(',')[2] for step in steps if step]
        #     dts = [float(s.split("= ")[1]) for s in dt_strings if s] 
        # except IndexError:
        #     print(steps)
        dt = [float(field[2]) for field in self.text_steps]
        return np.array(dt)
