import os
from glob import iglob
from pathlib import Path

import snek5000
from snek5000.util.archive import tar_name, archive

PYTHON_DIRECTORIES = ["docs", "src", "tests"]


rule env_export:
    shell:
        """
        conda env export -f environment.yml
        sed -i '/^prefix/d' environment.yml
        sed -i '/eturb/d' environment.yml
        """


rule env_update:
    shell:
        "conda env update --file environment.yml"


rule req:
    shell: 'pip-df sync --extras dev --use-pip-constraints --editable'


rule req_update:
    shell: 'pip-df sync --extras dev --use-pip-constraints --editable --update-all'


rule develop:
    shell:
        "pip install -e .[dev]"


rule docs:
    input:
        "src/",
    shell:
        'cd docs && SPHINXOPTS="-W" make html'


rule docs_clean:
    shell:
        'cd docs && SPHINXOPTS="-W" make cleanall'


rule bin_archive:
    input:
        iglob("bin/SLURM*"),
        iglob("bin/launcher_20*"),
    params:
        tarball=tar_name(
            Path.cwd().name,
            pattern="bin/SLURM*",
            subdir="bin",
            default_prefix="archive",
        ),
    run:
        archive(params.tarball, input, remove=True)
        archive(params.tarball + ".zst", readonly=True)


rule ctags:
    input:
        nek5000="lib/Nek5000/core",
        abl="src/abl",
        snek=Path(snek5000.__file__).parent,
        py_env=os.getenv("VIRTUAL_ENV", os.getenv("CONDA_PREFIX", ""))
    output:
        ".tags",
    params:
        excludes=" ".join(
            (
                f"--exclude={pattern}"
                for pattern in (
                    ".snakemake",
                    "__pycache__",
                    "obj",
                    "logs",
                    "*.tar.gz",
                    "*.f?????",
                    "*.py",
                )
            )
        ),
    shell:
        """
        ctags --verbose -f {output} --language-force=Fortran -R {input.nek5000}
        ctags --verbose -f {output} {params.excludes} --append --language-force=Fortran -R {input.abl}
        ctags -f {output} --append --languages=Python -R {input.abl} {input.snek} {input.py_env}/lib
        """


rule watch:
    params:
        per_second=5,
        rules="docs ctags",
    shell:
        "nohup watch -n {params.per_second} snakemake {params.rules} 2>&1 > /tmp/watch.log&"


rule squeue:
    params:
        per_second=59,
        rules="docs ctags",
    shell:
        "watch -n {params.per_second} squeue -u $USER --start"


rule salloc:
    params:
        project="snic2014-10-3 --reservation=dcs",
        walltime="30:00",
        nproc=8,
    shell:
        "interactive -A {params.project} -t {params.walltime} -n {params.nproc}"


rule ipykernel:
    shell:
        "ipython kernel install --user --name=$(basename $CONDA_PREFIX)"


rule jlab:
    shell:
        """
        echo '-----------------------------------------'
        echo '        Setup an SSH tunnel to           '
        printf '        '
        hostname
        echo '-----------------------------------------'
        set +e
        echo "Killing jupyter-lab sessions if any ..."
        killall jupyter-lab
        set -e
        jupyter-lab --no-browser --port=5656 --notebook-dir=$HOME
        """
