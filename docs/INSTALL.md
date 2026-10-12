# Installation and compatibility

## 1. Verified requirements

The v2.1 source header identifies **Igor Pro 6.37** and **PSI SP2 Toolkit 4.111**. These are the development targets, not a blanket claim of backward or forward compatibility. No compatibility test for Igor Pro 7–10, macOS, or a clean machine is supplied.

You require: (a) a licensed installation of Igor Pro, (b) the matching PSI SP2 Toolkit installation, (c) an instrument calibration accessible under `root:SP2toolkit:CalibData`, (d) local SP2 `.sp2b` data, and (e) acquisition metadata with measurement windows and sample-flow measurements.

The source **hard-codes** the calibration path `root:SP2toolkit:CalibData:IGE_BACON_20210222_DMA_AQ` in the concentration and particle procedures. A similarly named calibration wave does not authorize transferring it to another physical instrument. See `KNOWN_LIMITATIONS.md` before adapting this path.

## 2. Safest route: an existing functional PSI experiment

1. In Igor Pro 6.37, open a **copy**, never the only copy, of the laboratory experiment that already runs PSI Toolkit 4.111 successfully.
2. Confirm that native PSI raw-data loading, particle-by-particle mass post-processing, and `SP2_ConcTimeSeriesExtractor` work independently.
3. Confirm the actual contents and applicability of `IGE_BACON_20210222_DMA_AQ` to the instrument and campaign.
4. Save a working backup experiment and note the Igor, PSI Toolkit and SP2 instrument versions.
5. **Load only one source file** from `src/`: the historical original or the clearly identified RC1 menu-fix candidate. Opening both will duplicate the same function names.
6. Use `Windows → Procedure Windows` to open the `.ipf` as an external procedure, or place it in Igor's `User Procedures` directory and include it through the experiment procedure window (see below).
7. Compile procedures; inspect every error. The `AfterCompiledHook()` in this source opens a panel. Confirm this does not conflict with existing hooks or other procedures.
8. Verify the `SP2 IGE` menu and `Boite a Outils IGE v2.1` panel appear. Do not process real samples until your dry-run has passed.

### Optional `#include` mechanism

Place the selected source in a directory searched by Igor as `User Procedures` and add to the experiment's built-in procedure window:

```igorpro
#include "SP2_IGE_v2_1_RC1_menu_fix"
```

The Igor `#include` syntax omits `.ipf`. If compiling the historical original instead, use its basename and expect its known menu-reference issue. Documentation: [WaveMetrics Procedure Windows](https://docs.wavemetrics.com/igorpro/programming/procedure-windows).

**CAUTION:** These are procedural steps for a compatible, pre-existing PSI installation. The packaged code has not been validated by launching a new Igor instance in this repository build environment. A successful compile and pilot measurement are required.

## 3. Version difference between packaged source files

- `src/SP2_IGE_v2_1_STABLE_PARTICLES_source.ipf`: byte-for-byte original, preserved for reproducibility.
- `src/SP2_IGE_v2_1_RC1_menu_fix.ipf`: contains exactly one modification: `BCIGE_PrepareTimedInfo()` → `BCIGE_PrepareTimedTable()` in the `SP2 IGE` menu definition. This resolves one missing function name at source level but has **not** been runtime tested in Igor.

The RC1 patch does not change mathematical calculations, calibration constants, numerical arrays, or scientific outputs.

## 4. Setting up the timed table

From the `SP2 IGE` panel, choose **Prepare timed sample table**. Enter a folder path and number of records; every row can correspond to a distinct timed interval within the same raw `.sp2b` file.

**Required fields:** `FileDate` (YYYYMMDD), `FileNumList` (instrument file number(s), as accepted by the PSI loader), `SampleID`, `StartTime` and `StopTime` (hh:mm:ss), `TrimStart_s`, `TrimEnd_s`, `LiqSampleFlow`, `LiqDrainFlow`, `PurgeAirFlow`.

**CRITICAL UNIT DIFFERENCE:** A laboratory measurement around **110 µL/min** of liquid corresponds to **0.110 mL/min** in the `LiqSampleFlow` input. Do not enter `110` as though it were in mL/min. Defaults in the source are 0.109 mL/min liquid flow, 0 mL/min liquid drain, and 1 L/min purge-air flow; replace the defaults with your measured, validated values.

Timed extraction uses the half-open interval:

```
[ StartTime + max(0, TrimStart_s), StopTime - max(0, TrimEnd_s) )
```

Do not infer trim durations automatically from concentration peaks. Deliberately document every blank/sample transition and instrument flushing interval.

## 5. Run a pilot

1. Test at least one blank, representative AquaDAG standards, and one natural sample.
2. Check that `QCFlag`, `Ntriggers_Window`, and the raw concentrations are populated.
3. Confirm the calibration standards are actually recognized by `BCIGE_StdNominal` (supported exact identifiers in `CALIBRATION.md`).
4. Inspect channel-specific regression slopes, intercepts, R², recovery and flags.
5. Only after concentration results reproduce the laboratory baseline, invoke `Particle Properties → Analyze selected row` on a standard, then on a natural sample.
6. Use `Particle Properties → Analyze all rows (slow)` only after the single-row test passes and sufficient RAM and disk space are available.
7. Check numerical invariants in the native Igor waves **before any spreadsheet export**. Run the provided CSV checker after an external CSV export.

## 6. Troubleshooting

| Symptom | First check |
|---|---|
| `SP2_...` function undefined | PSI SP2 Toolkit 4.111 is absent/not compiled or its expected version differs. |
| `BCIGE_PrepareTimedInfo` undefined | Use the RC1 patched source or correct the single menu reference manually. |
| Calibration folder not found | The fixed BACON path is missing; do not substitute another instrument's coefficients without validation. |
| No `.sp2b` loaded | Confirm raw directory, date, file numbers, PSI loader expectations. |
| `INVALID_TIME_FORMAT` | `FileDate` must be YYYYMMDD and time hh:mm:ss. |
| `INVALID_TIME_WINDOW` | Adjust start/stop or recorded trims. |
| `INVALID_FLOW` | `LiqSampleFlow > LiqDrainFlow` and `PurgeAirFlow > 0`. |
| `NO_TRIGGERS_IN_WINDOW` | Check clocks, acquisition, trim interval and selected raw file. |
| `STD_RECOVERY_*` | Examine individual standards, preparation, concentration range and regression. |
| Size distributions missing | Check native PSI `SizeDistTser`, instrument calibration, wave names, classification limits. |

## 7. Do not upload proprietary dependencies

The laboratory `.pxp` may contain PSI procedures/calibration waves, experimental data, laboratory identifiers and an embedded institutional image. Do **not** publish it or the raw `.sp2b` measurements without checking licensing, metadata sensitivity and contributor/institutional permissions. The source contains an embedded picture; review image rights separately.
