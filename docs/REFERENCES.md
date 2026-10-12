# Scientific background and software references

## Analytical methodology

Lim, S., Faïn, X., Zanatta, M., Cozic, J., Jaffrezo, J.-L., Ginot, P., & Laj, P. (2014). Refractory black carbon mass concentrations in snow and ice: Method evaluation and inter-comparison with elemental carbon measurement. *Atmospheric Measurement Techniques, 7*, 3307–3324. https://doi.org/10.5194/amt-7-3307-2014

This article provides published context for nebulization-SP2 analysis of rBC in snow and ice; it does **not** validate the present software implementation or a particular 2026 instrument calibration.

## Software dependencies

- Igor Pro, WaveMetrics: https://www.wavemetrics.com/ and [Procedure Windows documentation](https://docs.wavemetrics.com/igorpro/programming/procedure-windows).
- PSI SP2 Toolkit 4.111: third-party toolkit used by the present Igor procedure; verify the original distribution and required attribution with its maintainers before adding download instructions or redistributing any part of it.
- Droplet Measurement Technologies SP2: instrument-specific documentation should be cited when reporting instrument configuration, flow calibration and incandescence mass calibration.

## Suggested manuscript statement (adapt and validate)

> Single-particle refractory black carbon masses and mass-equivalent diameters were processed using an instrument-calibrated SP2 workflow in PSI SP2 Toolkit 4.111 (Igor Pro 6.37), with laboratory-specific time-window selection and AquaDAG liquid-sample recovery correction implemented in the SP2 IGE rBC Toolkit (software version and release DOI to be specified). Concentration and particle-size uncertainty were evaluated using the instrument calibration, recovery experiments, blank measurements and size-range sensitivity analyses.

This template is **not** evidence that such validation has been completed; update it only after fulfilling `VALIDATION.md`.
