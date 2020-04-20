#!/usr/bin/env python
import os
import shutil
from pathlib import Path

import click
from bullet import Bullet, YesNo, colors
from fluiddyn.io import FLUIDDYN_PATH_SCRATCH
from snakemake import snakemake
from snakemake.executors import change_working_directory as change_dir

import abl
from eturb.util import get_status

STYLE = dict(
    indent=0,
    align=5,
    margin=2,
    bullet="★",
    bullet_color=colors.bright(colors.foreground["cyan"]),
    word_color=colors.bright(colors.foreground["yellow"]),
    word_on_switch=colors.bright(colors.foreground["yellow"]),
    background_color=colors.background["black"],
    background_on_switch=colors.background["black"],
    pad_right=5,
)


def prompt_once(run):
    print("Directory:", run.name)
    status, msg = get_status(run)
    print(f"{status}: {msg}")

    cli = Bullet(
        prompt="\nWhat do you want to do?",
        choices=[
            "list contents*",
            "force update Snakefile*",
            "unlock*",
            "archive+",
            "remove☠️",
            "continue",
            "quit",
        ],
        **STYLE,
    )
    action = cli.launch()

    recurse = False
    if action in ("quit", "continue"):
        return action
    elif action == "list contents*":
        os.system(f"ls -F --color {run}")
        recurse = True
    elif action == "force update Snakefile*":
        (run / "Snakefile").unlink()
        shutil.copy2(abl.get_root() / "Snakefile", run)
        recurse = True
    elif action == "unlock*":
        with change_dir(run):
            os.system("snakemake --unlock")
        recurse = True
    elif action == "archive+":
        with change_dir(run):
            if not snakemake("Snakefile", targets=["archive"], dryrun=False):
                cli = YesNo("Snakemake failure to archive. Try again?")
                recurse = cli.launch()
    elif action == "remove☠️":
        cli = YesNo("Are you 100% sure?")
        if cli.launch():
            shutil.rmtree(run)
    else:
        raise ValueError("Unconfigured action!")

    if recurse:
        return prompt_once(run)

    return "OK"


def prompt_all(runs):
    print(f"Organize runs in {runs[0].parent}")
    cli = Bullet(
        prompt="\nWhich run to inspect?",
        choices=["all", "quit", *(run.name for run in runs if run.exists())],
        **STYLE,
    )
    action = cli.launch()
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
@click.argument(
    "name_run", type=str,
)
def organize(name_run):
    subdir = Path(FLUIDDYN_PATH_SCRATCH) / name_run

    runs = [d for d in subdir.iterdir() if d.is_dir()]
    prompt_all(runs)


if __name__ == "__main__":
    organize()
