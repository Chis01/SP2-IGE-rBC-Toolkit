# Validation and verification plan

**Status:** verification protocol, not a validation certificate. The source-derived mathematical definitions and external spreadsheets must be tested in the actual Igor 6.37 / PSI 4.111 environment.

## A. Source and build integrity

- Preserve the exact original `.ipf` and its SHA-256.
- Compile the candidate in Igor Pro 6.37; capture the complete Igor compile log, PSI version and instrument calibration name.
- Confirm that both menus and panel tabs work, including `BCIGE_PrepareTimedTable` and `Particle Properties`.
- Confirm the candidate modifies no numeric/scientific routine compared with the original.
- Run the main timed concentration batch on a backup experiment, checking that the optional particle module is not invoked automatically.

## B. Input and concentration regression tests

| Test | Expected behavior |
|---|---|
| Same `.sp2b` file with multiple nonoverlapping windows | Separate `Ntriggers_Window`, `WindowSec` and concentration results, correct file reuse |
| Wrong time format | `INVALID_TIME_FORMAT` |
| Stop <= start after trimming | `INVALID_TIME_WINDOW` |
| Liquid flow <= drain or purge <= 0 | `INVALID_FLOW` |
| Time window with no triggers | `NO_TRIGGERS_IN_WINDOW` |
| Standard names recognized | Calibrations use only intended AquaDAG rows |
| Three or more standards | Calculate OLS when sufficient valid data are present |
| Blank counts below 10 | Leave formal `LOD_BHBL`/`LOQ_BHBL` unavailable |
| Changing unit from 110 µL/min to 0.110 mL/min | Must be numerically identical physical flow; never 110 mL/min |

## C. Calibration/QC tests

Repeat with 0.1, 5 or 10, and 100 ppb AquaDAG levels (where available), at least one representative low-signal blank and an actual glacier sample. Record raw concentration, corrected concentration, slopes, intercepts, recovery, R² and out-of-range QC flags. Compare with laboratory baseline values from the historical workbook.

At least 10 *independent* blanks must be justified before using operational LOD/LOQ. The laboratory must review whether regression assumptions, diluent composition and matrix effects are scientifically acceptable.

## D. Particle-wave tests in Igor (not optional before publications)

For each selected window, export or inspect the event-matched quadruple:

```
TimeDate, BHBL_BCmass, BHBL_BCdiam, BBHG_BCmass, BBHG_BCdiam
```

and saturation flags. For each reported channel, independently recompute:

1. A fixed sample-specific inclusion mask (`time`, finite `mass`, positive `diameter`, physically acceptable mass and channel validity).
2. The number of accepted rBC particles and the arithmetic mean and median of **the same** event masses.
3. D10N, D50N, D90N as conventional increasing percentiles of the same diameter population.
4. D10M, D50M, D90M from the cumulative **positive** mass, sorted by increasing diameter.
5. BBHG D50N/D50M separately from its own waves; BHBL separately from its own waves.
6. Channel saturation ratios with *all window triggers* as the documented denominator.

**Invariants to check for each valid row**:

- `0 <= D10N <= D50N <= D90N` and `0 <= D10M <= D50M <= D90M` (rounding tolerance only).
- For nonnegative mass data, `median_mass <= 2 × mean_mass` (assuming ordinary median/mean definitions), with small tolerance for numerical precision.
- Diameter/mass relationships use an explicitly recorded rBC density from the native PSI calibration; do **not** interpret the computed diameter as optical diameter.
- NaN/empty groups should not yield plausible default numbers.
- Saturated or out-of-range events are handled consistently across masses, diameters and channel selection.
- Quantiles must reflect the same event population before and after export. Review all exact equalities between unrelated columns across many rows.

## E. Spreadsheet and CSV checks

The Igor source does **not** write `.xlsx`. Preserve a complete, versioned export script or manual export protocol. Never rely on column *position* when naming fields; map by explicit wave name and log the Igor folder path, batch ID, file date and file list.

Run:

```bash
python tests/validate_particle_csv.py path/to/particle_summary.csv
```

This script checks supported scalar invariants and prints row-level errors. A passed CSV check does **not** guarantee correct instrument calibrations or valid physical sample populations.

Synthetic input fixtures and an automated smoke test are included solely to check the CSV-validator behavior, not to validate SP2 physics or Igor compilation.

## F. Required acceptance evidence

Document experiment filename/hash, `.ipf` hash, Igor and PSI versions, calibration folder/version, AquaDAG material/lot and fraction, sample preparation, flow measurement, raw `.sp2b` file IDs, timed intervals/trims, raw wave summary, calibration and blank QC, matched event-level comparisons, exports and their checksums, independent analyst reviewer, and unresolved deviations.

Maintain an issue register, especially for suspicious exports or nonmonotonic quantile order, until root cause is identified and repeat processing confirms a valid fix.
