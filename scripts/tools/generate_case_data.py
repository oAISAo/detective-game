#!/usr/bin/env python3
"""Write the canonical Riverside case JSON to a target directory.

The checked-in JSON under ``data/cases/riverside_apartment`` is the
authoritative Riverside case content. This script re-emits those files either
back into the live case folder or into another directory for safe verification.

Run from project root:
    python3 scripts/tools/generate_case_data.py
    python3 scripts/tools/generate_case_data.py --output-dir /tmp/riverside_case
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import shutil


REPO_ROOT = Path(__file__).resolve().parents[2]
SOURCE_DIR = REPO_ROOT / "data" / "cases" / "riverside_apartment"
DEFAULT_OUTPUT_DIR = SOURCE_DIR


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Write the canonical Riverside case JSON to the target directory."
    )
    parser.add_argument(
        "--output-dir",
        default=str(DEFAULT_OUTPUT_DIR),
        help="Directory to write the JSON files to. Defaults to the live Riverside case folder.",
    )
    return parser.parse_args()


def load_json(filename: str) -> dict:
    path = SOURCE_DIR / filename
    with path.open("r", encoding="utf-8") as source_file:
        return json.load(source_file)


CASE = load_json("case.json")
SUSPECTS = load_json("suspects.json")
LOCATIONS = load_json("locations.json")
EVIDENCE = load_json("evidence.json")
TIMELINE = load_json("timeline.json")
EVENTS = load_json("events.json")
DISCOVERY_RULES = load_json("discovery_rules.json")

DATA_FILES = (
    ("case.json", CASE),
    ("suspects.json", SUSPECTS),
    ("locations.json", LOCATIONS),
    ("evidence.json", EVIDENCE),
    ("timeline.json", TIMELINE),
    ("events.json", EVENTS),
    ("discovery_rules.json", DISCOVERY_RULES),
)

FILE_NAMES = tuple(filename for filename, _ in DATA_FILES)


def write_case_file(output_dir: Path, filename: str) -> None:
    source_path = SOURCE_DIR / filename
    output_path = output_dir / filename
    if source_path.resolve() == output_path.resolve():
        print(f"  Verified: {filename}")
        return
    shutil.copyfile(source_path, output_path)
    print(f"  Written: {filename}")


def main() -> None:
    args = parse_args()
    output_dir = Path(args.output_dir).expanduser().resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    print(f"Writing Riverside case data to: {output_dir}")
    for filename in FILE_NAMES:
        write_case_file(output_dir, filename)


if __name__ == "__main__":
    main()
