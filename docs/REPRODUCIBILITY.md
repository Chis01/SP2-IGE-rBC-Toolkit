# Reproducibility, data management and provenance

## Run manifest fields

Every analytical run should capture:

- UTC/local date and time and timezone; responsible analyst; instrument identifier and firmware (if available).
- Igor Pro version/build, PSI SP2 Toolkit version, extension source SHA-256 and `.pxp` experiment identifier.
- Instrument's incandescence calibration name, calibration date, rBC density assumption, calibrated mass range, valid gain channels and saturation thresholds.
- Raw `.sp2b` path/filename(s), raw file hashes, sample ID, field ID, glacier, depth/interval, measurement date and preparation protocol.
- Exact start/end times, trims, reason for trimming and acquisition-event count.
- Measured liquid and purge flows **with original units** and conversion notes.
- AquaDAG standard preparation: nominal series, material/lot, assumed rBC fraction, blanks, regression slopes/intercepts/R² and recovery flags.
- Output versions, exporter/transformation script hash, join keys, excluded observations, audit logs and QC disposition.

## Data tiers

**Public by default:** source code after license/permission review; documentation; synthetic tests; empty input-table templates; figures generated from non-sensitive synthetic examples; release changelog.

**Controlled/not automatically public:** raw `.sp2b` measurements, calibration packages, original institutional `.pxp` projects, laboratory workbooks, sample identifiers with non-public provenance, instrument access credentials and any private correspondence. Depositing scientific data should be done under a data-management plan and approved by relevant contributors.

## Provenance flow

```text
Raw .sp2b (immutable; SHA-256)
   -> PSI native particle-by-particle data with instrument calibration
   -> SP2 IGE effective time-window analysis
   -> raw liquid-equivalent concentration and correction/QC
   -> optional native particle summary with event QC
   -> versioned CSV/XLSX export via independent documented mechanism
   -> numerical sanity gates, manuscript-ready curated table
```

A publication-grade dataset must preserve both raw signals and the exact provenance of every derived value. Never replace a raw data file or original instrument calibration with an undocumented modified copy.

## Versioning conventions

- Tag scientific releases semantically (`v2.1.0-rc.1`, eventual stable `v2.1.0`).
- Treat any change in calibration, event filters, percentile formula, missing-data semantics or column mapping as scientifically consequential; document it in `CHANGELOG.md` and re-run validation.
- Store example instrument configuration in documentation only, not as a universal default that applies to other instruments.
