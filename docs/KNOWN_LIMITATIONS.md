# Known limitations, release blockers and outstanding questions

## Release-blocking issues

**R1. Instrument calibration is hard-coded.** Both `BCIGE_RunTimedAnalysis` and `BCIGE_AnalyzeParticleRow` use `root:SP2toolkit:CalibData:IGE_BACON_20210222_DMA_AQ`. Changing the path alone is not a calibration transfer. Per-instrument configuration, identification, validity checks and calibration provenance are needed before multi-instrument claims.

**R2. Historical source contains an undefined menu function reference.** `Menu "SP2 IGE"` calls `BCIGE_PrepareTimedInfo()`, while the declared function is `BCIGE_PrepareTimedTable()`. The candidate file `SP2_IGE_v2_1_RC1_menu_fix.ipf` modifies only this menu call; it has **not** been compiled in Igor in this packaging environment. Do not claim successful independent clean installation.

**R3. Particle-statistics export must be revalidated.** A separately handled 116-record spreadsheet reportedly exhibited nonmonotonic D10/D90 relationships and inconsistencies among mean/median particle masses and BBHG/BHBL percentiles. The native source's sorting and quantile structure does not by itself prove that the spreadsheet headers correctly map to Igor waves. A **native Igor wave → extracted rows → CSV/XLSX** audit and tests on matched raw acquisitions remain essential. The `.ipf` does not itself contain an XLSX exporter.

**R4. Third-party and institutional assets require permission review.** The `.ipf` embeds an institutional banner encoded as an Igor `Picture`; PSI Toolkit procedures, original `.pxp` experiments and instrument-specific calibrations may be subject to separate licenses/permissions. Avoid distributing them until rights and ownership are confirmed.

## Scientific limitations

- **Optical scattering unavailable as a validated result:** The referenced BACON data did not contain verified, usable `SCHG`/`SCLG` PSL coefficients in prior inspection. YAG housekeeping stability does not substitute for a scattering calibration.
- **LEO/coating not validated:** Split-detector availability, timing, incandescence/scattering alignment, optical model assumptions, instrument configuration and potential high-signal saturation must be resolved.
- **Melted-snow matrix effects:** Nebulization and possible drying/aggregation/salts can alter the measured suspended population relative to deposition in the glacier.
- **Detector coverage:** BBHG may be preferable for low particle masses, while BHBL can extend mass range using lower gain, if both native calibrations are valid. **Low liquid rBC concentration is not equivalent to low per-particle rBC mass.**
- **Size lower threshold:** Near-limit particles can truncate number and mass distributions; no universal detection interval is supplied by this extension.
- **Event selection:** `BCIGE_AnalyzeParticleRow` currently checks finite mass/diameter and positive diameter, but does not explicitly demand strictly positive mass for all summary computations. Confirm treatment of zeros/negative mass and saturated particles.
- **Quantile functions:** The `Percentile_of_ListNaN` routine is a PSI dependency. Independently verify its percentile convention and the resulting D10–D90 order in Igor.
- **QC coverage:** `ParticleQCFlag="OK"` does not independently certify all quantiles, mass statistics, optical properties, or post-export data integrity.
- **Mean/median:** A median greater than twice the arithmetic mean for a nonnegative mass distribution is a major inconsistency that should be investigated, not interpreted scientifically.
- **AquaDAG fraction:** Default `0.87` must be justified for the calibration material/lot in use. The code does not derive this number from each batch.
- **Blank limits:** The mean+3SD / mean+10SD procedures are operational limits and do not replace a full uncertainty assessment.
- **Excel downstream processing:** No native validated XLSX writer is supplied; spreadsheets require documented provenance and independent checks.

## Compatibility not established

Compilation of the patch on a clean Igor Pro 6.37 + PSI Toolkit 4.111 installation; other Igor versions; other SP2 instruments; Linux-based Igor alternatives; all sizes and concentration matrices.

## Minimum criteria before a `v2.1.0` stable release

Successful Igor compilation; regression of raw timed concentration against established results; calibrated standard/blank checks; event-wave vs summary-wave comparisons; strictly monotonic D10/D50/D90 for all valid distributions; mass median/mean consistency; saturation handling; documented export pipeline and successful independent test; instrument and banner/license permissions.
