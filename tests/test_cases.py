import pytest
from click.testing import CliRunner


# FIXME: Remove this when the mysterious bug which causes other test to fail stops
@pytest.mark.last
@pytest.mark.parametrize(
    "case",
    [f"lee_moser:{c}_penalty" for c in ("with", "no")]
    + [f"maronga_etal:{c}" for c in ("large", "small")]
    + [
        f"chat_peet:{c}"
        for c in ("small", "small_stretch", "medium", "large", "large_stretch")
    ]
    + ["buoy_test"],
)
@pytest.mark.parametrize("file", ["box", "size", "par"])
def test_parameters(case, file):
    from abl.cli import cli

    runner = CliRunner()
    result = runner.invoke(cli, ["-c", case, "show", file])
    assert result.exit_code == 0
