# Data dictionary and units

This file distinguishes waves implemented in the Igor v2.1 source from columns that may appear only in a downstream spreadsheet. The native procedure creates **Igor waves**; it does not itself provide a validated XLSX exporter.

## Timed input waves

| Name | Meaning | Required format or unit |
|---|---|---|
| `FileDate` | Raw acquisition date | `YYYYMMDD` text |
| `FileNumList` | Instrument file number(s) to load/concatenate | Text accepted by PSI loader |
| `SampleID` | Laboratory identifier (including standards/blanks) | Text |
| `StartTime`, `StopTime` | Requested measurement interval | `hh:mm:ss`, same `FileDate` |
| `TrimStart_s`, `TrimEnd_s` | Explicit excluded time from beginning/end | s |
| `LiqSampleFlow` | Liquid introduced into nebulizer | **mL/min** |
| `LiqDrainFlow` | Liquid removed by drain | **mL/min** |
| `PurgeAirFlow` | Purge-air flow for concentration conversion | **L/min** |

**A downstream column called `Flow` containing values around 108–110 records the laboratory liquid rate in µL/min, not 108–110 mL/min.** Convert exactly once before storing it in `LiqSampleFlow` (`108 µL/min = 0.108 mL/min`).

## Timed concentration and calibration waves

| Name | Meaning | Unit |
|---|---|---|
| `WindowSec` | Effective window length after trims | s |
| `Ntriggers_Window` | All acquisition triggers in window | count |
| `BBHG_Aerosol_ugm3`, `BHBL_Aerosol_ugm3` | PSI aerosol-phase rBC concentrations | µg/m³ |
| `BBHG_LiquidSampleMassConc`, `BHBL_LiquidSampleMassConc` | Uncorrected liquid-equivalent concentration | µg/L |
| `StdNominal_ppb` | Nominal AquaDAG standard concentration | nominal ppb |
| `StdTarget_rBC_ppb` | Standard nominal × AquaDAG rBC fraction | nominal rBC ppb |
| `BBHG_BCcorr_ppb`, `BHBL_BCcorr_ppb` | Primary concentration corrected by channel-specific AquaDAG efficiency (no intercept subtraction) | nominally µg/L (reported as ppb) |
| `BBHG_BCcorrInt_ppb`, `BHBL_BCcorrInt_ppb` | Intercept-corrected diagnostic concentration | nominally µg/L |
| `BBHG_Recovery_pct`, `BHBL_Recovery_pct` | Measured/target standard recovery | % |
| `BBHG_Residual_ppb`, `BHBL_Residual_ppb` | Difference from AquaDAG-based target | nominal ppb |
| `QCFlag` | Per-row concentration/standard diagnostic | enumerated text |
| `CalStatus` | Batch-level calibration summary | text |

The reporting equivalence between `ppb` and `µg/L` assumes sufficiently dilute aqueous samples and density near 1 kg/L; prefer explicit `µg/L` labels where possible.

## Native SP2 post-processing waves (external dependency)

| Name | Interpretation | Unit |
|---|---|---|
| `BBHG_BCmass` | Particle-level rBC mass, broadband high gain | fg |
| `BHBL_BCmass` | Particle-level rBC mass, combined gain | fg |
| `BBHG_BCdiam` | rBC *mass-equivalent* diameter | nm |
| `BHBL_BCdiam` | rBC *mass-equivalent* diameter | nm |
| `BBHG_saturated`, `BBLG_saturated`, `BHBL_saturated` | Channel saturation flags | flag |

`BHBL` is a composite high-/low-gain incandescence product; it is **not** a scattering-derived total particle diameter. `M` in percentile names means **mass-weighting**, not mass concentration or optical diameter.

## Optional particle-result waves

| Name | Meaning | Unit |
|---|---|---|
| `Particle_Ntriggers` | All triggers in particle-analysis effective window | count |
| `Particle_TriggerRate_Hz` | All triggers divided by window duration | s⁻¹ (Hz) |
| `BBHG_Nparticles`, `BHBL_Nparticles` | Finite native mass+diameter events passing current source criterion | count |
| `BHBL_MeanMass_fg`, `BHBL_MedianMass_fg` | Mean and median individual BHBL rBC mass | fg |
| `BHBL_D10N_nm`, `BHBL_D50N_nm`, `BHBL_D90N_nm` | rBC mass-equivalent diameter percentiles by **number** | nm |
| `BHBL_D10M_nm`, `BHBL_D50M_nm`, `BHBL_D90M_nm` | Same diameters weighted by individual **rBC mass** | nm |
| `BBHG_D50N_nm`, `BBHG_D50M_nm` | BBHG median rBC diameter by number/mass | nm |
| `BBHG_SatAll_pct`, `BBLG_SatAll_pct`, `BHBL_SatAll_pct` | Saturation flags relative to **all** triggers | % |
| `ParticleQCFlag` | Optional particle-module QC state | text |
| `BHBL_Diam_nm`, `BBHG_Diam_nm` | Native PSI size-distribution diameter axes | nm |
| `BHBL_dNdlogDp_cm3`, `BBHG_dNdlogDp_cm3` | Number size distributions per aerosol volume | particles/cm³ per log-size interval |
| `BHBL_dMdlogDp_ugm3`, `BBHG_dMdlogDp_ugm3` | Mass size distributions per aerosol volume | µg/m³ per log-size interval |

**Not currently exported by source v2.1:** `BBHG_MeanMass_fg`, `BBHG_MedianMass_fg`, full BBHG D10/D90 statistics. The code reads individual BBHG mass and diameter waves, so these could be added in a future validated release. Do not fabricate values by copying BHBL statistics.

## Common supplementary spreadsheet-only fields

`Num`, `Muestra de campo`, `Profundidad (cm)`, `Flow`, and sampling-region labels may be added from field logs or a subsequent spreadsheet joining step. They are **not** all generated as native inputs/outputs by the supplied Igor procedure. Preserve source file, join key, original unit, measured depth interval and provenance for every such field.

## Optical metrics

`D_optical`, `LEO optical diameter`, and `coating thickness` are **not validated outputs**. No quantity in this dictionary should be relabeled as optical diameter or total particle diameter.
