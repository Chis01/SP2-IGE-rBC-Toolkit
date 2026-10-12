#!/usr/bin/env python3
"""Conservative, standard-library-only QC of a *named-column* SP2 particle CSV.

This is a post-export consistency gate, NOT instrument calibration or Igor
validation. Missing columns are reported as SKIP rather than treated as proof
that the output is correct.
"""

import argparse
import csv
import math
import pathlib
import statistics
import sys
from collections import Counter


def number(row, col):
    value = row.get(col, "")
    if value is None or str(value).strip().lower() in ("", "nan", "na", "none", "n/a"):
        return None
    try:
        val = float(str(value).strip().replace(",", "."))
    except ValueError:
        return None
    return val if math.isfinite(val) else None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("csv_path", type=pathlib.Path, help="Named-column particle summary CSV")
    parser.add_argument("--tolerance", type=float, default=1e-7, help="absolute numerical comparison tolerance")
    parser.add_argument("--strict-missing", action="store_true", help="fail when an expected check cannot be evaluated")
    args = parser.parse_args()

    with args.csv_path.open("r", encoding="utf-8-sig", newline="") as file:
        reader = csv.DictReader(file)
        columns = set(reader.fieldnames or [])
        rows = list(reader)
    tol = args.tolerance
    if not rows:
        print("FAIL: the CSV has no data rows")
        return 1
    checks = 0
    issues = []
    skipped = set()
    equal_pairs = Counter()

    for idx, row in enumerate(rows, start=2):
        identifier = row.get("SampleID") or row.get("ID") or f"CSV row {idx}"
        for channel in ("BHBL", "BBHG"):
            for weighting in ("N", "M"):
                cols = [f"{channel}_D{q}{weighting}_nm" for q in (10, 50, 90)]
                if any(col not in columns for col in cols):
                    skipped.add("Missing percentile triplet: " + ", ".join(col for col in cols if col not in columns))
                    continue
                vals = [number(row, col) for col in cols]
                if any(v is None for v in vals):
                    skipped.add(f"Missing numerical value in {channel} {weighting} percentile triplet")
                    continue
                checks += 1
                if vals[0] < -tol or vals[0] > vals[1] + tol or vals[1] > vals[2] + tol:
                    issues.append((idx, identifier, f"{channel} {weighting} quantiles not ordered: {list(zip(cols, vals))}"))

        for channel in ("BHBL", "BBHG"):
            median_col = f"{channel}_MedianMass_fg"
            mean_col = f"{channel}_MeanMass_fg"
            if median_col not in columns or mean_col not in columns:
                skipped.add(f"Missing mean/median columns for {channel}")
                continue
            median = number(row, median_col)
            mean = number(row, mean_col)
            if mean is None or median is None:
                skipped.add(f"Missing numerical mean/median values for {channel}")
                continue
            checks += 1
            if median < -tol or mean < -tol or median > 2 * mean + tol:
                issues.append((idx, identifier, f"{channel} mean/median inconsistent for nonnegative masses: median={median}, mean={mean}"))

        if {"BBHG_D50M_nm", "BHBL_D50N_nm"}.issubset(columns):
            bg = number(row, "BBHG_D50M_nm")
            bh = number(row, "BHBL_D50N_nm")
            if bg is not None and bh is not None:
                equal_pairs["eligible"] += 1
                if abs(bg - bh) <= tol:
                    equal_pairs["equal"] += 1

    print(f"Rows: {len(rows)} | Invariants tested: {checks} | Errors: {len(issues)}")
    for idx, ident, msg in issues[:40]:
        print(f"ERROR row {idx} [{ident}]: {msg}")
    if len(issues) > 40:
        print(f"... {len(issues)-40} additional row-level errors omitted")
    if equal_pairs["eligible"] >= 10 and equal_pairs["equal"] == equal_pairs["eligible"]:
        msg = ("Suspicious identical values in ALL records: BBHG_D50M_nm == "
               f"BHBL_D50N_nm ({equal_pairs['equal']}/{equal_pairs['eligible']}); "
               "verify name-to-wave column mapping")
        issues.append((0, "all", msg))
        print("ERROR:", msg)
    if skipped:
        print("SKIPPED checks (not evidence of validity):")
        for item in sorted(skipped):
            print(" -", item)
    if args.strict_missing and skipped:
        print("FAIL: strict-missing mode")
        return 2
    if issues:
        print("FAIL: numerical consistency checks; do not publish as validated particle statistics")
        return 1
    print("PASS: numerical consistency checks only (not instrumental validation)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
