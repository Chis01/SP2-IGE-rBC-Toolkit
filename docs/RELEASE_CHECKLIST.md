# Public release acceptance checklist

- [ ] Author(s), contributors and institutions have approved the distribution and naming/branding.
- [ ] Complete source-code/embedded-image provenance reviewed; proprietary PSI Toolkit source or experiment data excluded.
- [ ] Explicit root `LICENSE` file selected and supplied by legitimate copyright owner(s).
- [ ] Igor Pro **6.37** and PSI Toolkit **4.111** demonstrated on a clean or reproducible installation.
- [ ] Candidate `.ipf` menu callback compiles and `AfterCompiledHook` does not conflict.
- [ ] Instrument calibration ID, rBC material density, gain validity and saturation thresholds documented.
- [ ] Raw timed concentration independently reconciled to reference data.
- [ ] AquaDAG standard/blank recovery and matrix effects tested and disclosed.
- [ ] Native event-wave masses and diameters checked against all sample-level statistics.
- [ ] D10/D50/D90, mean/median mass, BHBL/BBHG column maps and saturation tested for all validation samples.
- [ ] Export script or Igor export protocol versioned and included.
- [ ] Native mass-equivalent diameter not confused with optical diameter/coating.
- [ ] Sample-specific measured liquid flow correctly converted from µL/min to mL/min.
- [ ] CI and independent reviewer approval recorded; known deviations resolved or prominently disclosed.
- [ ] CITATION.cff authorship, version, DOI and date verified.
- [ ] GitHub release created with a changelog, software hashes and a reproducibility statement.
