#!/usr/bin/env python
import os
import shutil
from pathlib import Path

import abl
import click
from bullet import Bullet, YesNo, colors, styles
from fluiddyn.io import FLUIDDYN_PATH_SCRATCH
from fluiddyn.util.terminal_colors import cstring
from snakemake import snakemake
from snakemake.executors import change_working_directory as change_dir
from snek5000 import logger
from snek5000.util import get_status

STYLE = styles.Greece
STYLE.update(
    dict(
        indent=2,
        shift=1,
        align=0,
        margin=1,
        background_on_switch=colors.background["black"],
        background_color=colors.background["black"],
    )
)


def prompt_once(run):
    logger.info(f"Directory: {run.name}")
    status, msg = get_status(run)
    if status >= 400:
        logger.warning(f"{status}: {msg}")
    else:
        logger.info(f"{status}: {msg}")

    cli = Bullet(
        prompt="\nWhat do you want to do?",
        choices=[
            "list contents*",
            "tail log",
            "continue",
            "force update Snakefile*",
            "unlock*",
            "compile*",
            "archive+",
            "remove",
            "quit",
        ],
        **STYLE,
    )
    action = cli.launch()
    print()

    def snakemake_target(target):
        with change_dir(run):
            if not snakemake(
                "Snakefile", targets=[target], debug=True, dryrun=False
            ):
                cli = YesNo(f"Snakemake failure to {target}. Try again?")
                return cli.launch()
            else:
                return False  # do not recurse

    recurse = False
    if action in ("quit", "continue"):
        return action
    elif action == "list contents*":
        os.system(f"ls -F --color {run}")
        os.system(f"ls -F --color {run}/data")
        recurse = True
    elif action == "tail log":
        os.system(f"ls -F --color {run}/abl.log")
        os.system(f"less +F {run}/abl.log")
        recurse = True
    elif action == "force update Snakefile*":
        (run / "Snakefile").unlink()
        shutil.copy2(abl.get_root() / "Snakefile", run)
        recurse = True
    elif action == "unlock*":
        with change_dir(run):
            snakemake("Snakefile", unlock=True)
        recurse = True
    elif action == "compile*":
        recurse = snakemake_target("compile")
    elif action == "archive+":
        recurse = snakemake_target("archive")
    elif action == "remove":
        cli = YesNo("Are you 100% sure?")
        if cli.launch():
            shutil.rmtree(run)
    else:
        raise ValueError("Unconfigured action!")

    if recurse:
        return prompt_once(run)
    else:
        logger.info("Proceeding to next directory ...")
        return "OK"


def prompt_all(runs):
    print(f"Organize runs in {runs[0].parent}")
    cli = Bullet(
        prompt=cstring("\nWhich run to inspect?", bold=True, color="LIGHTBLUE"),
        choices=["all", "quit", *(run.name for run in runs if run.exists())],
        **STYLE,
    )
    action = cli.launch()
    print()

    if action == "all":
        for run in runs:
            if prompt_once(run) == "quit":
                break
    elif action == "quit":
        return
    else:
        # Get Path object
        run = next(run for run in runs if run.name == action)
        if prompt_once(run) == "quit":
            return
        else:
            # recurse
            return prompt_all(runs)


@click.command()
@click.argument("name_run", type=str)
def organize(name_run):
    subdir = Path(FLUIDDYN_PATH_SCRATCH) / name_run

    runs = sorted(d for d in subdir.iterdir() if d.is_dir())
    prompt_all(runs)


if __name__ == "__main__":
    organize()
