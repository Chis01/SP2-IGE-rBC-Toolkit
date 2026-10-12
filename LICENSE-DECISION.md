# Software licensing and rights clearance — action required

Public visibility is not equivalent to open-source licensing. Before declaring the repository open source, choose an explicit license and confirm the ownership and redistribution rights of every component.

## Suggested license options

- **BSD 3-Clause:** permissive reuse with source/binary attribution and non-endorsement language.
- **MIT:** short permissive terms with attribution and warranty disclaimer.
- A reciprocal license could be considered if the owner wishes derivatives to remain open, but it requires the same third-party review.

**Do not apply a license to source components owned by another group without permission.** Specifically inspect the embedded IGE/UGA image (`Picture IGE_UGA_BC_Banner`) and any inherited PSI Toolkit material, and confirm whether institutional, collaborative or employer policies affect ownership.

## Actions to take before public release

1. Determine ownership and confirm coauthor/institutional approval where needed.
2. Identify whether the source is wholly original or contains portions governed by the PSI toolkit's terms; document provenance.
3. Verify authorization to redistribute the embedded logo/banner or replace it with an original unbranded graphic using an authorized source edit.
4. Select a license and create a real root `LICENSE` file with its complete official text and correct copyright holder/year.
5. Review `CITATION.cff` attribution and release version before publishing.
6. Do not upload proprietary `.pxp`, licensed executables, secret calibration packages, personal data or raw results without authorization.

A **LICENSE file has intentionally not been generated** because neither the ownership assessment nor the license choice was supplied.

See [GitHub's licensing guidance](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/licensing-a-repository).
