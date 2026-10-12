# Technical specification (source-derived, v2.1)

This specification describes the observed implementation in `src/SP2_IGE_v2_1_STABLE_PARTICLES_source.ipf`. It is **not** a claim that every calculation has passed independent analytical validation.

## Execution sequence

```text
Row metadata and explicit QC trims
    ↓
PSI SP2_LoadRawData → SP2_RawFldrFP2PBPfldrFP
    ↓
PSI SP2_PBPpostprocessing (fixed IGE BACON incandescence calibration)
    ↓
PSI SP2_ConcTimeSeriesExtractor(..., IntSec=-1, StartTime=t0, EndTime=t1)
    ↓
Timed BBHG and BHBL aerosol mass concentrations
    ↓
Liquid-sample flow conversion
    ↓
AquaDAG linear fits, recovery correction, QC and blank statistics
    ↓
Optional ON-DEMAND particle analysis: native mass/diameter waves,
quantiles, saturation fractions, native size distributions and plots
```

The main concentration batch does **not** automatically invoke particle extraction. Multiple timed samples can share a `.sp2b` file; the source reuses its loaded post-processed folder until the last relevant row if `KeepPBPData=0`.

## Time window

`FileDate` and `StartTime`/`StopTime` are parsed through `BCIGE_ParseTime`. For one row,

```
t0 = parsed_start + max(0, TrimStart_s)
t1 = parsed_stop  - max(0, TrimEnd_s)
include a trigger if t0 <= TimeDate[i] < t1
WindowSec = t1 - t0
```

Invalid formats, nonpositive windows and invalid flows receive distinct QC flags. When present, `Ntriggers_Window` counts the TimeDate events falling into the window; it is not an rBC particle count.

## Native concentration extraction and units

The native PSI concentration waves `BBHG_MassConc` and `BHBL_MassConc` are interpreted in **µg/m³ of sampled aerosol**. Liquid concentrations in **µg/L** are computed numerically as

```
C_liquid = C_aerosol × PurgeAirFlow / (LiqSampleFlow - LiqDrainFlow)
```

**Input units must be** `PurgeAirFlow` in **L/min** and both liquid flows in **mL/min**. These particular volumetric unit ratios account for the µg/m³ → µg/L change. Always record measured rather than assumed flows. A laboratory pump reading of **110 µL/min** must be entered as **0.110 mL/min**.

The code defaults (not universal instrument specifications) are `LiqSampleFlow=0.109 mL/min`, `LiqDrainFlow=0`, `PurgeAirFlow=1 L/min`.

## AquaDAG regression and correction

`BCIGE_StdNominal` recognizes nominal standard strings: `0.1`, `0.5`, `1`, `5`, `10`, `25`, `50`, `100` followed by ` ppb` or `ppb`. Unrecognized sample names are not treated as standards. The laboratory fraction defaults to `f_AQ=0.87` as a *configurable assumption* requiring standard-lot justification.

For BBHG and BHBL separately, `BCIGE_OLS` fits:

```
C_liquid,raw = intercept + slope × C_AquaDAG,nominal
eta = slope / f_AQ
C_rBC,primary = C_liquid,raw / eta
C_rBC,intercept-diagnostic = (C_liquid,raw - intercept) / eta
C_rBC,target,standard = f_AQ × C_AquaDAG,nominal
recovery_% = 100 × C_rBC,primary / C_rBC,target,standard
```

The **primary** corrected concentration deliberately follows the historical spreadsheet workflow and **does not subtract the fitted intercept**. An intercept-subtracted concentration is retained as a diagnostic but is not the primary output. `eta` is a derived empirical recovery factor under this operational definition; it is not an independent first-principles nebulizer efficiency. Distinguish such regression correction from the SP2 **particle incandescence mass calibration**, which is supplied by native PSI processing.

Calibration requires at least three recognized standards for the function to proceed; the eight supported levels are checked for completeness. `MinCalR2` defaults to `0.995`, and a warning is generated if a finite R² falls below that value. Per-standard recovery outside 80–120% produces `STD_RECOVERY_BBHG`, `STD_RECOVERY_BHBL`, or `STD_RECOVERY_BOTH` if the prior row QC flag is `OK`.

## Blank statistics and detection limits

Blanks are identified using identifiers beginning `BLC` or `BLANK` (case variations encoded in the source). Their corrected BHBL values are used for `BlankMean_BHBL` and a sample standard deviation `BlankSD_BHBL`. If **at least 10** qualifying blanks are present, the implementation calculates:

```
LOD_BHBL = mean(blank corrected BHBL) + 3 × SD(blank corrected BHBL)
LOQ_BHBL = mean(blank corrected BHBL) + 10 × SD(blank corrected BHBL)
```

If fewer than 10 blanks are available, LOD/LOQ are `NaN`. **These are operational formulas, not a universal demonstration of detection capability.** Assess independence, background drift, matrix effects and uncertainty before publication.

## On-demand particle analysis

The v2.1 source reads the PSI post-processing waves:

```
BHBL_BCmass       BBHG_BCmass        [fg per rBC particle]
BHBL_BCdiam       BBHG_BCdiam        [nm, rBC mass-equivalent diameter]
BHBL_saturated    BBHG_saturated     [event flags]
BBLG_saturated                         [event flag]
```

It checks each event against the effective time window and requires finite mass and diameter with positive diameter. The current source does not explicitly impose strictly positive mass in the event-count filter. This requires scrutiny in the validation phase.

Current v2.1 summary waves include:

```
Particle_Ntriggers             Particle_TriggerRate_Hz
BBHG_Nparticles                BHBL_Nparticles
BHBL_MeanMass_fg               BHBL_MedianMass_fg
BHBL_D10N_nm  BHBL_D50N_nm     BHBL_D90N_nm
BHBL_D10M_nm  BHBL_D50M_nm     BHBL_D90M_nm
BBHG_D50N_nm BBHG_D50M_nm
BBHG_SatAll_pct BBLG_SatAll_pct BHBL_SatAll_pct
ParticleQCFlag
```

Number percentiles call PSI `Percentile_of_ListNaN(..., q)` with `q=0.1, 0.5, 0.9`. Mass-weighted percentiles call `BCIGE_WeightedQuantile(diameter, mass, q)`: sort diameters ascending and find the first bin/event whose cumulative **positive** mass reaches fraction `q` of positive mass. Both definitions need runtime and post-export verification, particularly for older spreadsheet exports.

The mean mass is computed with `WaveStats/Q` and median mass with `Percentile_of_ListNaN`. Mass units (`fg`) and diameter definitions depend on the PSI calibration and its assumed rBC material density. The density value is **not set or certified** by this extension.

`Particle_TriggerRate_Hz = Particle_Ntriggers / WindowSec`.

`*_SatAll_pct = 100 × number_of_events_flagged_saturated / Particle_Ntriggers`.

These saturation percentages use **all triggers** as the denominator, not only valid detected rBC particles. Sums across channels are not generally meaningful because flags may overlap.

The source requests native PSI size distributions via `SP2_SizeDistTimeSeriesExtractor(..., IntSec=-1, nSizeBins=nBins)`, by default `nSizeBins=60` (clamped 20–200), saving `dN/dlogDp` and `dM/dlogDp` per aerosol volume. Event-level plot arrays retain at most `ParticleMaxPlotPoints=5000` entries by deterministic stride; this cap applies to **plot data**, not summary quantile computation.

## Output model and scope

Results are stored as waves in the selected Igor data folder; associated particle plots/waves are stored under a per-row `ParticleProps:RowN` folder. **The supplied `.ipf` does not implement a validated native `.xlsx` writer.** Any spreadsheet was created through a separate export/transformation process, which must be documented and independently audited.

### Deliberately unsupported outputs

No validated scattering calibration is available in the referenced IGE BACON mass-calibration configuration (`SCHG_CalCoef`, `SCLG_CalCoef` were found unset in prior calibration inspection). The code does **not** deliver scientifically validated particle optical diameter, LEO-derived pre-evaporation scattering size or apparent coating thickness. YAG housekeeping alone cannot substitute for PSL calibration.

## Function map

| Source function | Role |
|---|---|
| `BCIGE_Init` | Defaults and global state |
| `BCIGE_PrepareTimedTable` | Metadata-input waves and Igor table |
| `BCIGE_RunTimedAnalysis` | Timed native PSI processing and liquid concentrations |
| `BCIGE_OLS` | Linear regression and R² |
| `BCIGE_AutoCalibration` | AquaDAG correction, standards, blanks and QC |
| `BCIGE_EnsureParticleSummary` | Particle-summary output wave allocation |
| `BCIGE_WeightedQuantile` | Mass-weighted quantile helper |
| `BCIGE_AnalyzeParticleRow` | Event subset, particle statistics and PSI distributions |
| `BCIGE_OpenPanel` | User interface entry point |

Consult the actual source for all exceptions and edge cases; this is a methodology contract, not a substitute for code review.
