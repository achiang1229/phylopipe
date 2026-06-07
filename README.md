# PhyloPipe

A lightweight, automated pipeline for constructing phylogenetic trees
from orthologous gene sequences.

## Overview

PhyloPipe takes preformatted FASTA files containing orthologous sequences
across multiple species and produces publication-ready phylogenetic trees
with minimal user configuration. The pipeline is built around three
well-established tools: MAFFT for multiple sequence alignment, chosen for
its balance of speed and accuracy and its flexible --auto mode; trimAl for
alignment trimming, chosen for its lightweight performance on large datasets;
and IQ-TREE 3 for tree inference, which features automatic best-fit model
selection via ModelFinder, making it robust across a wide variety of input
data. Bootstrap support values are planned for a future version.

PhyloPipe is designed for users who want sensible, well-supported phylogenetic
trees without manually tuning parameters at each step. While some familiarity
with phylogenetics is helpful for interpreting results, no deep bioinformatics
expertise is required to run the pipeline. Note that in the current version,
users are expected to supply their own FASTA files; automated sequence fetching
from NCBI is planned for a future release.

## Pipeline Workflow

PhyloPipe runs the following steps in order, orchestrated by Snakemake:

1. **Header reformatting** — sequence headers are standardized to
   `Genus_species_accession` format
2. **Config validation** — outgroup names are resolved and verified
   before any computation begins
3. **Alignment** — sequences are aligned with MAFFT
4. **Trimming** — poorly aligned regions are removed with trimAl
5. **Tree inference** — a maximum likelihood tree is inferred with IQ-TREE 3
6. **Visualization** — the final tree is rendered locally with ETE4 as a PNG

```
input FASTA(s)
      │
      ▼
reformat_headers
      │
      ▼
validate_config
      │
      ▼
mafft_align
      │
      ▼
trimal_trim
      │
      ▼
iqtree_infer
      │
      ▼
render_tree
      │
      ▼
output tree (.png)
```

## Dependencies

PhyloPipe requires the following tools:

- **Snakemake** (9.19.0) — workflow orchestration
- **MAFFT** (7.526) — multiple sequence alignment
- **trimAl** (1.5.1) — alignment trimming
- **IQ-TREE 3** (3.1.1) — maximum likelihood tree inference
- **ETE4** (4.3.0) — tree visualization
- **Biopython** (1.87) — sequence parsing and header reformatting
- **PyQt6** — required by ETE4 for image rendering; install via the
  `pyqt` package on conda-forge

All dependencies can be installed by reproducing the provided Conda
environment:

```bash
conda env create -f environment.yaml
conda activate phylopipe
```

A `environment.yaml` file is included in the repository for full
reproducibility.

## Quickstart

### 1. Clone the repository

```bash
git clone https://github.com/achiang1229/phylopipe.git
cd phylopipe
```

### 2. Set up the Conda environment

```bash
conda env create -f environment.yaml
conda activate phylopipe
```

### 3. Add your input files

Place one or more FASTA files containing orthologous sequences in the
`data/` directory:

```
phylopipe/
├── data/
│   └── your_sequences.fasta
├── scripts/
├── config.yaml
└── Snakefile
```

### 4. Configure the pipeline

Open `config.yaml` and add an outgroup entry for each input file:

```yaml
outgroup:
  your_sequences: "Genus species"
```

The key should match your FASTA filename without the `.fasta` extension.
The value should be the genus and species name of your chosen outgroup,
exactly as it appears in the FASTA headers (spaces or underscores both
accepted). **Outgroup values must be enclosed in quotation marks** as
shown above, or the pipeline will fail to parse the config correctly.

### 5. Run the pipeline

From the `phylopipe/` directory:

```bash
snakemake --cores 1
```

### 6. Output

For each input file `data/your_sequences.fasta`, the final rendered tree
will be written to:

```
tree/your_sequences.png
```

Intermediate outputs (cleaned FASTA, alignment, trimmed alignment, and
IQ-TREE files) are written to `cleaned/`, `aligned/`, `trimmed/`, and
`tree/` respectively. A list of valid outgroup names for each input is
available at `logs/your_sequences_labels.txt` if needed.

## Configuration

PhyloPipe is configured via `config.yaml` in the root directory.

| Key | Type | Description |
|---|---|---|
| `outgroup` | dictionary | Maps each input FASTA filename (without extension) to the genus and species name of the desired outgroup taxon |

**Example:**

```yaml
outgroup:
  formicidae_coi: "Vespula germanica"
  felidae_coi: "Crocuta crocuta"
```

Outgroup values must be enclosed in quotation marks as shown above.
Outgroup names are matched against sequence headers case-insensitively.
Both spaces and underscores are accepted. If the specified name matches
multiple sequences or no sequences, the pipeline will exit with a
descriptive error message and a pointer to
`logs/{input_name}_labels.txt` for valid options.

## Output Files

For each input file `data/{name}.fasta`, PhyloPipe produces the following
outputs:

| File | Description |
|---|---|
| `cleaned/{name}_clean.fasta` | Input sequences with standardized headers (`Genus_species_accession`) |
| `aligned/{name}_aln.fasta` | MAFFT multiple sequence alignment |
| `trimmed/{name}_aln_trim.phy` | trimAl-trimmed alignment in phylip format |
| `tree/{name}.treefile` | Maximum likelihood tree in Newick format |
| `tree/{name}.iqtree` | Full IQ-TREE report including best-fit model, substitution rate parameters, base frequencies, and tree statistics — recommended reading for users who want to understand the analysis in depth |
| `tree/{name}.log` | IQ-TREE runtime log |
| `tree/{name}.png` | Rendered tree image |
| `logs/{name}_labels.txt` | List of valid outgroup names for this input |
| `logs/{name}_validated.flag` | Internal Snakemake flag confirming successful config validation |

## Test Data

A test dataset is included at `data/formicidae_coi.fasta`, containing COI
sequences from 11 Formicidae species with *Vespula germanica* as the
outgroup. This dataset was used to validate the pipeline during development.

To run the pipeline on the test data, add the following to `config.yaml`:

```yaml
outgroup:
  formicidae_coi: "Vespula germanica"
```

Then run:

```bash
snakemake --cores 1
```

The expected output is a rendered tree at `tree/formicidae_coi.png`.

## Notes and Limitations

- **Input format:** PhyloPipe expects input sequences to be orthologous
  and in standard FASTA format. Sequences do not need to be pre-aligned.
  Multi-gene or whole-genome datasets are not currently supported.

- **Outgroup must be present in the input:** The specified outgroup taxon
  must be represented in the input FASTA file. The pipeline will exit with
  a descriptive error message if the outgroup cannot be matched to any
  sequence header.

- **Outgroup selection:** The outgroup should be closely related to the
  ingroup but outside it — a distant outgroup can result in a
  disproportionately long outgroup branch, which compresses the ingroup
  branches and reduces the readability of the rendered tree. For example,
  when analyzing Formicidae (ants), a wasp such as *Vespula germanica*
  is a more appropriate outgroup than a fly such as *Musca domestica*,
  as wasps share a more recent common ancestor with ants (both being
  members of Hymenoptera) compared to flies, which are far more
  distantly related to ants.

- **Single-locus datasets recommended:** The pipeline has been validated
  on single-locus datasets. Performance on highly divergent or incomplete
  datasets has not been formally evaluated.

- **Bootstrap support values:** Branch support values are not displayed
  in the current version. Ultrafast bootstrap analysis (1000 replicates)
  is planned for a future release, along with updated tree visualization.

- **Automated sequence fetching:** Users are currently expected to supply
  their own FASTA files. Integration with the NCBI Entrez API for
  automated sequence retrieval is planned for a future release.

- **Headless rendering:** Tree rendering via ETE4 requires PyQt6, which
  should be installed via the `pyqt` package on conda-forge. On headless
  systems without a display, rendering may require `xvfb-run` — in that
  case, replace the `render_tree` shell command in the Snakefile with:
  `xvfb-run python scripts/render_tree.py {input} {output}`
