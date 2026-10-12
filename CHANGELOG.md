# Changelog

## v2.1.0-rc.1 — packaging preview (2026-10-12)

- Added academically oriented English GitHub project description, README, installation guide, technical specification, calibration method, data dictionary, validation plan, reproducibility policy, limitations, references, contributor guidance and citation template.
- Preserved the original v2.1 `.ipf` file byte-for-byte.
- Added a second candidate `.ipf` changing **only** the undefined menu callback `BCIGE_PrepareTimedInfo()` to the existing `BCIGE_PrepareTimedTable()`.
- Added Python standard-library export sanity checks and synthetic fixtures, not a substitute for native Igor runtime verification.
- Explicitly marked particle statistics as requiring a native-wave/export regression audit; optical coating results remain unsupported.
- No changes to the physical/numerical analysis functions, calibration coefficients, threshold values, or raw data processing.

## v2.1 — historical laboratory build

- See `docs/ORIGINAL_V2_1_VALIDATION_NOTES.md` and the source comments. Historical build notes are not equivalent to a public software acceptance test.
