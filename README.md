# Analysis code for the HRLPC multi-omics subtyping study

This repository contains the Jupyter notebooks used to generate the bioinformatics figures of the manuscript on molecular classification of high-risk localized and locally advanced prostate cancer (HRLPC) after neoadjuvant hormonal therapy (NHT), based on transcriptomic, proteomic, N-glycoproteomic and genomic profiling (subtypes C1–C3, IHC-based classifier, and patient-derived organoid validation).

> **Data are not included.** The repository ships code only. Raw/processed data files are not deployed here; the expected directory layout and the file each notebook reads are described below. A figure-by-figure map is given in [`FIG_CODE_MAP.md`](FIG_CODE_MAP.md).

## Repository layout

```
.
├── Fig1_S1S2_xR_PLOT.ipynb                  # R      Fig 1, S1, S2, S3D–H
├── Fig2_S3_xR_PLOT.ipynb                    # R      Fig 2, S4
├── Fig3_S4_xR_PLOT.ipynb                    # R      Fig 3, S2J–M, S5
├── Fig4_Fig5_xPY_PLOT.ipynb                 # Python Fig 4, 5C, S6
├── PY_ANALYSIS_Fig2_Fig3.ipynb              # Python pre-ranked GSEA plots (Fig 2C, S4G–I)
├── GEN_EXT_SURVIVAL_DATA_PY.ipynb           # Python external-cohort data + subtype prediction (for Fig S3F–H)
├── GET_ext_data.ipynb                       # Python external proteogenomic cohort preparation
├── GET_DATA_Glycosylation_Phosphorylation.ipynb  # Python glyco/phospho search-result processing (also Fig S2H–J)
├── GET_DATA_cmap_drugs.ipynb                # Python CMap drug-score preparation (Fig 5D)
├── figS9_R_response_R.ipynb                 # R      reviewer-response analyses
├── figS10_PY_response_PY.ipynb              # Python reviewer-response analyses (model search / validation)
├── GCrtools/                                # in-house R package (installed as `GCrutils`)
├── GCpytools/                               # in-house Python package (file I/O helpers: dblibs, log_system)
├── FIG_CODE_MAP.md                          # figure -> notebook -> input/output map
└── README.md
```

Directories expected at run time (relative to the repository root, which is the notebooks' working directory):

| Directory | Role |
|---|---|
| `external_data/` | Raw / curated inputs (clinical tables, signature gene sets, public cohorts, glycoproteomic search results, IHC scores, CMap query results, MSigDB `h.all.v7.5.symbols.gmt`, …) |
| `export_by2_86_pCR_nonpCR/`, `export_86_7/` | Processed omics matrices of the retrospective cohort (protein/RNA matrices, ssGSEA scores, sample annotation, WES tables) |
| `export_c3/` | Intermediate files produced and consumed by the notebooks (see below) |
| `export_big/` | Large intermediate files (Timer2 estimates, filtered glycopeptide matrices, …) |
| `report_c3/` | **Final results** – figure PDFs and source-data `.xlsx`, named after the manuscript panels (`fig.<panel>.<description>`) |
| `report_reply/` | Outputs of the reviewer-response notebooks |

## Build environment

Tested layout: Linux/macOS, R ≥ 4.1, Python ≥ 3.9. Everything except the two in-house packages is installed with conda; the in-house packages are then installed locally from this repository.

**1. Create the conda environment (R + Python + all third-party packages)**

```bash
conda create -n hrlpc -c conda-forge -c bioconda --strict-channel-priority \
  python=3.11 r-base=4.3 \
  jupyterlab ipykernel r-irkernel r-irdisplay rpy2 \
  r-tidyverse r-magrittr r-data.table r-readxl r-openxlsx r-jsonlite r-fs r-scales \
  r-survival r-survminer r-rstatix r-ggpubr r-ggrepel r-ggsci r-ggplotify \
  r-ggbeeswarm r-cowplot r-circlize r-dendextend r-rtsne r-matrixstats r-purrr \
  r-vegan r-ade4 r-remotes \
  bioconductor-complexheatmap bioconductor-clusterprofiler bioconductor-org.hs.eg.db \
  bioconductor-maftools bioconductor-deseq2 bioconductor-limma bioconductor-gsva \
  numpy pandas scipy scikit-learn statsmodels matplotlib seaborn matplotlib-venn plotly \
  openpyxl xlsxwriter joblib dill tqdm requests pyyaml jinja2 gseapy

conda activate hrlpc

# register the R kernel for Jupyter
Rscript -e 'IRkernel::installspec(name = "ir", displayname = "R (hrlpc)")'

# ggcor is only available from GitHub (used for the Hallmark mantel-test plot in Fig 2 / S4B)
Rscript -e 'remotes::install_github("hannet91/ggcor")'
```

If a package name is not found on your channels, install it from within R instead (`install.packages()` for CRAN, `BiocManager::install()` for Bioconductor).

**2. Install the in-house R package (`GCrutils`, source in `GCrtools/`)**

```bash
R CMD INSTALL GCrtools/
```

**3. Install the in-house Python package (`GCpytools`: `dblibs`, `log_system`)**

```bash
pip install ./GCpytools
```

The Python data-preparation notebooks do `from dblibs import *`; after the local install the module is importable directly, so `DBLIBPATH` in their first cell can be left as is or pointed at `GCpytools/`.

**4. Check**

```bash
Rscript -e 'library(GCrutils); library(ComplexHeatmap); library(survminer)'
python -c "from dblibs import Database, echo, write_excel; print('ok')"
```

## Where each figure is generated

| Manuscript figure | Notebook |
|---|---|
| Fig 1B–1H, S1D–S1F, S2B (data), S2C–S2G, S3D–S3H | `Fig1_S1S2_xR_PLOT.ipynb` |
| Fig 2A–2F, S4A–S4E (+ violins of 2B/S4H/S4I) | `Fig2_S3_xR_PLOT.ipynb` |
| Fig 2C and S4G–S4I (GSEA enrichment plots) | `PY_ANALYSIS_Fig2_Fig3.ipynb` |
| Fig 3A–3F, 3K, data for 3H–3J, S2J–S2M, S5A–S5I | `Fig3_S4_xR_PLOT.ipynb` |
| Fig 4C–4G, 4I, 4J, 5C, S6B–S6E, S6G, S6H | `Fig4_Fig5_xPY_PLOT.ipynb` |
| Fig 5D | CMap scores from `GET_DATA_cmap_drugs.ipynb`; plotted manually |
| Fig S2H–S2I (protein identifications per sample) | `GET_DATA_Glycosylation_Phosphorylation.ipynb` |
| Fig S2J (glycopeptides per sample) | `Fig3_S4_xR_PLOT.ipynb` |
| Reviewer responses | `figS9_R_response_R.ipynb`, `figS10_PY_response_PY.ipynb` |

Panels that are schematics, histology/IF images, organoid experiments or other wet-lab results (e.g. Fig 1A, 2G–2I, 4A/4B/4H, 5A/5B/5E–5L, S1A–S1C, S5J–L, S7, S8) have no code here. Several computational panels (3G, 3H–3J, 4K/4L, S3A–S3C, S4F, S5C, S6A, S2B plot) were drawn manually and are marked as such in the notebooks; see `FIG_CODE_MAP.md` for the status of every panel.

## Suggested execution order

1. **Data preparation** (once): `GET_ext_data` → `GET_DATA_Glycosylation_Phosphorylation` → `GET_DATA_cmap_drugs`.
2. **Subtype definition**: the consensus-clustering outputs (`export_c3/fig1_subtype_heatmap_mat.dfx`, `fig1_subtype_row_cluster.dfx`, `fig1_subtype_column_cluster.dfx`, `glx_86.dfx`, `wes_glx.dfx`) come from an upstream clustering step that is not part of this repository.
3. **Subtype labels for all 126 non-pCR cases**: run the section *"Subtype labels for all 126 non-pCR cases"* in `Fig4_Fig5_xPY_PLOT.ipynb` first (after its *Prepare Data* section). It writes `export_c3/fig1_subtype_predict_and_pca_data.xlsx` (and a copy in `report_c3/`), which `Fig1_S1S2_xR_PLOT` and `Fig2_S3_xR_PLOT` read. It uses the trained random-forest model `export_c3/fig4_gsea_rf_model_evenly_dis`.
4. `GEN_EXT_SURVIVAL_DATA_PY` produces `export_c3/ext_data_*` used for Fig S3F–H.
5. **Figures**: `Fig2_S3_xR_PLOT` (writes `fig2_*` intermediates and `report_c3/gsea_input/fig.2C_data_DEG_DAP.xlsx`) → `PY_ANALYSIS_Fig2_Fig3` → `Fig1_S1S2_xR_PLOT` → `Fig3_S4_xR_PLOT` (writes `fig3_*` intermediates) → rest of `Fig4_Fig5_xPY_PLOT` (writes `fig4_*` intermediates, needed by Fig 5C).
6. **Reviewer responses**: `figS9_R_response_R`, `figS10_PY_response_PY`.

Panels marked **"manually generated"** inside the notebooks (Fig 3G, 3H–3J, 4K/4L, S2B plot, S3A–S3C, S4F, S5C, S6A, plus schematics, images and wet-lab panels) were drawn manually with external tools from the source data produced here; no plotting code is provided for them.

## Intermediate file naming

Files in `export_*` folders that belong to a main figure are named `figN_<short description>.<ext>`, e.g.

- `fig1_subtype_heatmap_mat.dfx`, `fig1_subtype_row_cluster.dfx`, `fig1_subtype_column_cluster.dfx`
- `fig2_deg_dap.RDS`, `fig2_ar_activity_score.txt`, `fig2_c1_kegg_gsea_df.RDS`
- `fig3_de_glycoprotein.RDS`, `fig3_4grps_mat_prt_rna_gly.Rdata`, `fig3_gly_omics_rho.Rdata`
- `fig4_ihc_mat_retrospective.dfx`, `fig4_ssgsea_mat_prospective.dfx`, `fig4_gsea_rf_model_evenly_dis`

Files in `report_c3/` are named by manuscript panel, e.g. `fig.3F.DE_Gly_volcano.pdf` (figure) with a matching `.xlsx` (source data).

## Software requirements

See **Build environment** above. In short: R packages (`tidyverse`, `survival`, `survminer`, `ComplexHeatmap`, `circlize`, `ggsci`, `ggcor`, `cowplot`, …) plus the in-house `GCrutils` (`GCrtools/`; I/O helpers `db.importing`, `ysave`, `ydumpto`, plotting/GSEA wrappers); Python packages (`numpy`, `pandas`, `scipy`, `scikit-learn`, `matplotlib`, `seaborn`, `gseapy`, `joblib`, `dill`, `openpyxl`, `xlsxwriter`, `matplotlib_venn`, `rpy2`) plus the in-house `gcpytools` (`GCpytools/`).

Server-specific paths and internal identifiers in the notebooks were replaced by placeholders such as `[PROJECT_ROOT]` / `[GCpytools_path]`; set them to match your environment.

## Notes

- Notebooks keep their saved outputs from the original run; figure numbers in the code, markdown and saved text outputs follow the final manuscript numbering. Embedded images in saved outputs were not regenerated.
- Statistical tests and thresholds are those stated in the figure legends of the manuscript.

## Citation

Please cite the associated manuscript (details to be added upon publication).
