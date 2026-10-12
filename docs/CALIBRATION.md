# Analytical calibration and laboratory quality control

## Two distinct calibrations

1. **SP2 incandescence calibration:** supplied by the original PSI SP2 environment, with instrument-dependent mapping from detector response to rBC mass and mass-equivalent diameter. The extension selects `IGE_BACON_20210222_DMA_AQ`. No independent mass-calibration replacement is included.
2. **AquaDAG liquid-sample recovery correction:** implemented by this extension using timed measurement windows and the regression-based recovery method described in `TECHNICAL_SPEC.md`.

**Do not equate either process with PSL optical scattering calibration.** PSL standards are required for quantitative optical scattering-to-size characterization, with further instrument/model validation needed for coating thickness.

## Standard procedure: minimum metadata

Document the AquaDAG manufacturer/material, lot number, preparation method, nominal concentration, diluent water, treatment of aggregation, nebulizer setup, exact SP2 instrument and configuration, calibration date, flow rates, blank runs and measured recovery. The source defaults the rBC fraction to `0.87`; do not treat it as an experimentally established property of every AquaDAG lot.

Supported nominal levels for automatic recognition are `0.1`, `0.5`, `1`, `5`, `10`, `25`, `50`, `100` ppb. The exact string conventions are in `BCIGE_StdNominal`; naming errors can silently omit an intended standard from the regression. Do not create calibration standards by averaging repeat runs without recording replicate identity and independence.

## Flow metrology

- Liquid flow: input in **mL/min** (e.g. 110 µL/min = 0.110 mL/min).
- Drain flow: input in **mL/min**.
- Purge-air flow: input in **L/min**.
- Record the measurement and instrument for each flow; the default values are not universal operating specifications.

## QC interpretation

The linear-fit R² threshold `0.995` is a code default, not a validated accuracy threshold. A high R² does not rule out biased dilution, a positive intercept, nonlinear response at the low end, instrumental drift, or matrix effects. The `80–120%` recovery rule is an operational flag for individual standards, not a declaration of measurement uncertainty.

The current blank LOD/LOQ definitions require `Nblank >= 10` and use a 3×/10× SD convention. Independently evaluate background drift, independence of blanks and confidence intervals when formally reporting detection limits.

For published results, include concentrations for blank controls, standards at relevant low levels, slopes, intercepts, residual diagnostics, recovery, calibration date, limits of instrumental detection and the size range represented by the mass calibration.

## Matrix-specific caveat

Melted glacial ice and snow may contain dissolved ions, mineral particles and non-rBC aerosols that affect the nebulized population, triggering and recovery. AquaDAG prepared in ultrapure water is not equivalent to a matrix-matched spike-recovery experiment. Matrix-matched standards or control additions are recommended for claims about interference and recovery.
