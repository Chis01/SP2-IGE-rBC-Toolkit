# SP2 IGE — Boite a Outils IGE v2.1
## Stable Particle Properties build

### Design correction
This build starts from the last user-validated v1.1 concentration/calibration PXP.
Particle-property extraction is **not executed inside the main concentration batch**.
It is an on-demand module, so failure or absence of particle-size products cannot
invalidate the already validated timed concentration and AquaDAG calibration workflow.

### Particle variables
For a selected row and its effective time window:
`StartTime + TrimStart_s <= t < StopTime - TrimEnd_s`

The module uses native PSI Toolkit 4.111 post-processing waves:
- `BHBL_BCmass`, `BBHG_BCmass`: calibrated single-particle rBC mass [fg].
- `BHBL_BCdiam`, `BBHG_BCdiam`: rBC mass-equivalent diameter [nm].
- `BBHG_saturated`, `BBLG_saturated`, `BHBL_saturated`: saturation flags.
- `SP2_SizeDistTimeSeriesExtractor(... IntSec=-1 ...)`: native timed size distributions.

It calculates:
- number of valid BHBL/BBHG rBC particles;
- mean/median BHBL particle mass;
- BHBL D10/D50/D90 by number;
- BHBL D10/D50/D90 weighted by rBC mass;
- BBHG D50 by number and mass;
- trigger rate;
- high-/low-/combined-gain saturation as percent of all triggers;
- compact event-level waves (maximum 5000 points) for plotting;
- native PSI dN/dlogDp [#/cm3] and dM/dlogDp [ug/m3].

### QC correction
For valid AquaDAG standards the successful-window `QCFlag` now has the requested
four recovery states:
- `OK`
- `STD_RECOVERY_BBHG`
- `STD_RECOVERY_BHBL`
- `STD_RECOVERY_BOTH`

Re-running the calibration first clears a previous `STD_RECOVERY_*` flag back to `OK`,
then recalculates the current recovery status, avoiding stale QC flags.

### Why this build is safer than the previous particle build
- The validated main run no longer calls particle extraction.
- Particle analysis reloads only the selected raw file if its PBP folder was already released.
- Array lengths are bounded with `min(...)` before event-by-event indexing.
- The native PSI size distribution is copied to a compact per-row folder before optional cleanup.
- Optical diameter/coating are still excluded until YAG/scattering/LEO validation.

### Static build checks
- PXP records: 975
- Inline compact `if ... endif`: none
- Required particle/QC routines present: all
- Main v1.1 Proc Picture retained: yes
- SHA-256: `76a4523fb59f41bf0824393f1f618ee720b246843bce658beb549e2b6583baad`

### First runtime validation
1. Open the PXP in Igor Pro 6.37.
2. Re-run the same timed concentration batch that already worked in v1.1.
3. Confirm concentration/calibration results are unchanged.
4. Open `Particle Properties`.
5. Select one row, click `Analyze selected row`.
6. First test: 5 or 10 ppb standard.
7. Then test 0.1 ppb, 100 ppb, and one glacier sample.
8. Only after these tests use `Analyze all rows (slow)`.
