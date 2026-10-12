# Laboratory user guide — a reproducible processing example

> **Illustrative only:** use measured laboratory values and actual identifiers. This guide does not establish that the software or any example result has passed Igor runtime validation.

## A. Prepare a clean acquisition manifest

Record every sample, blank and AquaDAG standard as a separate timed row, with the source `.sp2b` date/number, actual acquisition start and stop, and justified trim intervals. You may store multiple timed records against the same SP2 raw file.

The `templates/timed_input_example.csv` is a **documentation template only**: the v2.1 Igor procedure creates its own native input waves; it does not automatically import this CSV. Copy the fields to the corresponding Igor input table or implement an independently tested importer.

## B. Convert measured flow to native input units

For example, a physically measured liquid flow of `110 µL/min` requires `LiqSampleFlow = 0.110 mL/min` in the toolkit. The code's `DefaultLiqFlow = 0.109 mL/min` is only a default and must not overwrite a field measurement. The purge-air flow is in `L/min` and the drain flow is in `mL/min`.

## C. Verify the native calibration

Confirm that the chosen Igor experiment contains the correct **incandescence** calibration for the physical SP2. This build references `IGE_BACON_20210222_DMA_AQ`. If the selected instrument differs, stop and adapt the software under a documented calibration protocol. Do not claim portability based only on compilation.

## D. Run the timed concentration workflow

From `SP2 IGE`, prepare the native timed table, enter or paste each row, and choose `Run timed analysis + calibration`. Review the raw concentration, calibrated response and `QCFlag` columns, and confirm the data are associated with their exact windows.

The code will only automatically recognize correctly named AquaDAG nominal levels. Keep a record of the blank flags and standard recovery before interpreting sample concentration.

## E. Examine optional single-particle statistics

Go to `Particle Properties`, enter the **zero-based** row number, and press `Analyze selected row`. Start with one medium AquaDAG standard, one low standard, one high standard and a natural sample. Verify `BHBL_BCmass`, `BHBL_BCdiam`, `BBHG_BCmass` and `BBHG_BCdiam` are present in the native PSI post-processing folder.

Check all D10/D50/D90 order relationships, event counts, mean/median mass, and saturation flags in the Igor waves *before* generating tables for external software. If exporting CSV, validate the copied column names against the Igor wave names.

## F. Do not interpret unsupported quantities

Particle-level `BCdiam` is the **rBC mass-equivalent diameter** computed using instrument-specific incandescence calibration and the PSI model density. It is not optical size. The code does not produce validated PSL/LEO coating thickness.

## G. Record and archive the analysis

Store the original raw hashes, experiment version and source hash, calibration, measured flow, standard/blank QC results, selected and trimmed windows, generated Igor wave names and provenance of any external CSV/XLSX. Use `docs/VALIDATION.md` before including size statistics in a scientific publication.
