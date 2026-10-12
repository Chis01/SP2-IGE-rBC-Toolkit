# Architecture and design rationale

## Modules

1. **Instrument dependency layer (external):** PSI SP2 Toolkit 4.111 reads `.sp2b`, creates post-processed folders, and supplies calibrated incandescence mass/diameter waves.
2. **Timetable/data layer:** `BCIGE_PrepareTimedTable` creates a row-addressed, explicit time-window input structure; rows can share raw acquisitions.
3. **Concentration layer:** `BCIGE_RunTimedAnalysis` extracts native PSI concentrations for precisely bounded intervals and converts aerosol to liquid concentration with measured flow data.
4. **AquaDAG layer:** `BCIGE_AutoCalibration` computes BBHG/BHBL empirical corrections and QC diagnostics.
5. **Optional particle layer:** `BCIGE_AnalyzeParticleRow` operates on demand; native PSI single-particle results feed weighted quantiles, event counts, saturation and distributions.
6. **Presentation:** Igor panel/table and graphs; no validated XLSX output engine in the supplied source.

## Why particle analysis is separate

The v2.1 changes were explicitly designed to protect the historical timed-concentration workflow from particle-analysis errors, missing native size waves or high computational cost. Thus the main batch does not automatically calculate particle-size distributions. The user deliberately starts the particle module by selecting a row or running all rows.

## Source-level extension points

- Convert hard-coded BACON calibration to explicit, validated instrument configuration.
- Implement mass and diameter event-mask transparency with logged thresholds.
- Add BBHG mean/median mass and D10/D90 within its valid range.
- Add a tested, versioned CSV exporter that maps Igor wave **names** to output columns.
- Implement QA gates directly within Igor and refuse publication export on violation.
- Add optional PSL/LEO optical processing **only after** instrument-specific calibration and model validation.
