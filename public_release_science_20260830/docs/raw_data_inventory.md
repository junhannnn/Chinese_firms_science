# Raw Data Inventory

The original project used local raw data under `dataset/` plus a few legacy
external raw-data paths that have been documented here for replacement by
public users. Raw data are not included in this release.

## Expected folders from `config/dataset.yml`

- `dataset/OpenAlex/`: OpenAlex works, authorship, institution, and topic files.
- `dataset/PCS/`: Reliance-on-Science and patent-paper citation/link inputs.
- `dataset/WOS/`: Web of Science publication data.
- `dataset/CNKI/`: CNKI publication data and journal/JIF support files.
- `dataset/Miscellaneous/`: Entity-list, firm-name, and other auxiliary inputs.
- `dataset/CSMAR/`: legacy CSMAR raw files referenced by some upstream or
  archival runners.
- `dataset/CSMAR_subsidiary/`: CSMAR listed-firm subsidiary files used by listed-firm supplementary workflows.
- `dataset/CN_patents/`: Chinese patent raw and cleaned source files.
- `dataset/US_patents/`: PatentsView/U.S. patent source files.
- `dataset/DISCERN/`: DISCERN output files used by supplementary U.S.-firm plots.

## Public-source notes

- Reliance on Science / MAG version 64 is cited in the original runner notes as
  the June 3, 2024 Zenodo release.
- PatentsView is cited in the original runner notes as the April 22, 2024
  release.
- OpenAlex is used for publication, authorship, institution, and topic metadata.

## Non-public or user-provided inputs

Some Stata runners in the original workspace pointed to local external folders
outside `.`, including Chinese patent grant dumps,
CSMAR raw folders, and PatentsView/PCS mirrors. For public reproduction, place
equivalent files under the `dataset/` subfolders above and update
`config/dataset.yml` or the relevant runner globals.