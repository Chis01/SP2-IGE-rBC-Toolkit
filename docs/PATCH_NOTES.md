# Source patch note — public repository candidate

This archive contains **two mutually exclusive alternative versions** of one Igor Pro extension:

| Original | Candidate menu-fix |
|---|---|
| `src/SP2_IGE_v2_1_STABLE_PARTICLES_source.ipf` | `src/SP2_IGE_v2_1_RC1_menu_fix.ipf` |

The original `Menu "SP2 IGE"` refers to `BCIGE_PrepareTimedInfo()`, which is not present among the custom `BCIGE_...` function definitions in this source. The existing implemented procedure is `BCIGE_PrepareTimedTable([BatchFldrFP,nSamples])`, which prompts for inputs when called without arguments.

The candidate changes one line **only**:

```diff
-    "Prepare timed sample table", BCIGE_PrepareTimedInfo()
+    "Prepare timed sample table", BCIGE_PrepareTimedTable()
```

This is a source-level consistency repair only. **The candidate has not been compiled or tested within Igor Pro 6.37 as part of preparing this public package.** Do not present it as a fully validated bug fix; compile and record the result before tagging stable.

The source embeds a binary-encoded institutional banner. Confirm redistribution rights before publishing either version publicly.
