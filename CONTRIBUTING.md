# Contributing

Contributions should improve reproducibility and physical accuracy without altering existing laboratory results silently.

## Before opening a pull request

- Open an issue describing the bug or scientific motivation, the relevant instrument/software versions, and the affected functions.
- Separate interface-only patches from changes to event filters, calibration, quantiles, saturation logic, and concentration conversion.
- Include a synthetic minimal reproducer with no proprietary SP2/PSI data if possible.
- Document a before/after table, numerical invariants, Igor compile output and validation on an independently reviewed batch.
- Add/update tests and `CHANGELOG.md`, and explicitly record any change to the interpretation of published column names.
- Do not commit original `.sp2b` data, unredacted `.pxp` experiments, credentials, proprietary PSI procedures, or institutionally restricted calibrations.

**Review policy:** scientific functionality requires at least one independent data/QA review before release. A successful Python CSV-validator run is necessary but not sufficient for acceptance.

## Issue categories

- Instrument compatibility and compilation
- Raw-data/time-window selection
- AquaDAG calibration and blanks
- BBHG/BHBL per-particle mass and quantiles
- Saturation/limits of detection
- Data export and provenance
- Optical scattering and LEO (future research)
