#!/usr/bin/env python3
"""Genereer docs/controlmatrix.csv uit docs/controlmatrix.md.

De markdown is de bron; de CSV is voor Excel/GRC-tooling. Draai na elke
wijziging aan de matrix:  python3 ci/matrix-to-csv.py
"""
import csv
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "docs" / "controlmatrix.md"
OUT = ROOT / "docs" / "controlmatrix.csv"


def rows(line):
    return [c.strip().replace("`", "") for c in line.strip().strip("|").split("|")]


def parse(text):
    generic, per_system, system = [], [], None
    for line in text.splitlines():
        heading = re.match(r"^## Per systeem: (\S+)", line)
        if heading:
            system = heading.group(1)
            continue
        if not line.startswith("|") or set(line) <= set("|-: "):
            continue
        cells = rows(line)
        if cells[0] in ("ID", "Control"):
            continue
        if system is None:
            generic.append(cells)
        else:
            per_system.append([system, *cells])
    return generic, per_system


def main():
    if not SRC.exists():
        sys.exit(f"niet gevonden: {SRC}")
    generic, per_system = parse(SRC.read_text(encoding="utf-8"))
    status = {(s, c): (st, note) for s, c, st, note in per_system}
    systems = sorted({s for s, _ in status})

    header = [
        "control_id", "artikel", "verplichting", "control",
        "implementatiemechanisme", "scope", "eigenaar", "evidence", "frequentie",
    ] + [f"status:{s}" for s in systems] + [f"toelichting:{s}" for s in systems]

    with OUT.open("w", newline="", encoding="utf-8-sig") as fh:
        writer = csv.writer(fh, delimiter=";")
        writer.writerow(header)
        for control in generic:
            cid = control[0]
            writer.writerow(
                control
                + [status.get((s, cid), ("", ""))[0] for s in systems]
                + [status.get((s, cid), ("", ""))[1] for s in systems]
            )
    print(f"{OUT} geschreven: {len(generic)} controls, {len(systems)} systemen")


if __name__ == "__main__":
    main()
