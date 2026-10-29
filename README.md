<sub>This readme is Summarized by Claude and supervised by the authors</sub>

# Analysis code for the HRLPC multi-omics subtyping study

This repository contains the Jupyter notebooks used to generate the bioinformatics figures of the manuscript on molecular classification of high-risk localized and locally advanced prostate cancer (HRLPC) after neoadjuvant hormonal therapy (NHT), based on transcriptomic, proteomic, N-glycoproteomic and genomic profiling (subtypes C1–C3, IHC-based classifier, and patient-derived organoid validation).

> **Data are not included.** The repository ships code only. Raw/processed data files are not deployed here; the expected directory layout and the file each notebook reads are described below. A figure-by-figure map is given in `Detailed figure → code map` section.

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
| Fig 4C–4G, 4I, 4J, 5C (t-SNE of proteomic ssGSEA pathway / immune-signature scores), S6B–S6E, S6G, S6H | `Fig4_Fig5_xPY_PLOT.ipynb` |
| Fig 5D | CMap scores from `GET_DATA_cmap_drugs.ipynb`; plotted manually |
| Fig S2H–S2I (protein identifications per sample) | `GET_DATA_Glycosylation_Phosphorylation.ipynb` |
| Fig S2J (glycopeptides per sample) | `Fig3_S4_xR_PLOT.ipynb` |
| Reviewer responses | `figS9_R_response_R.ipynb`, `figS10_PY_response_PY.ipynb` |

Panels that are schematics, histology/IF images, organoid experiments or other wet-lab results (e.g. Fig 1A, 2G–2I, 4A/4B/4H, 5A/5B/5E–5L, S1A–S1C, S5J–L, S7, S8) have no code here. Several computational panels (3G, 3H–3J, 4K/4L, S3A–S3C, S4F, S5C, S6A, S2B plot) were drawn manually and are marked as such in the notebooks; see `FIG_CODE_MAP.md` for the status of every panel.

### Detailed figure → code map

"cell N" is the 0-based cell index in the notebook. Outputs are in `report_c3/` unless stated otherwise; `ysave('fig.X', ...)` writes the figure (`.pdf`) together with its source data (`.xlsx`). Notebook abbreviations: **F1** = `Fig1_S1S2_xR_PLOT`, **F2** = `Fig2_S3_xR_PLOT`, **F3** = `Fig3_S4_xR_PLOT`, **F45** = `Fig4_Fig5_xPY_PLOT`, **PYG** = `PY_ANALYSIS_Fig2_Fig3`, **GLY** = `GET_DATA_Glycosylation_Phosphorylation`.

| Figure | Notebook (cell) | Output | Notes |
|---|---|---|---|
| Fig 1A | — | — | Schematic, no code |
| Fig 1B / 1C | F1 (23–24 / 26–27) | `fig.1B.1G.S1E.S1F_train86_BCR`, `fig.1C.1H.S1E.S1F_train86_RGR` | Multi-panel composite; pCR vs non-pCR panels are 1B/1C. Multivariate Cox table: `fig.1B.1C.S1E.S1F_cox_multivariate.xlsx` (cell 19) |
| Fig 1D | F1 (42) | `fig.1D_SNA_oncoplot_77_cases` | |
| Fig 1E | F1 (62) | `fig.1E.main_heatmap` | |
| Fig 1F | F1 (76, 80, 82) | `fig.1F_clin`, `fig.1F_clin_data.xlsx`, `fig.1F_clin_AR_score.xlsx` | |
| Fig 1G / 1H | F1 (23–24 / 26–27) | Same composites as 1B/1C | Subtype C1–C3 panels |
| Fig 2A | F2 (18) | `fig.2A_prt.gsea.heatmap` | |
| Fig 2B | F2 (25) | `fig.2B.S4H.S4I_gsea_score` | Same composite contains the S4H/S4I violins |
| Fig 2C | Data: F2 (31); GSEA plots: PYG (14) | `gsea_input/fig.2C_data_DEG_DAP.xlsx`; `gsea_report/rna_c1/*.prerank.pdf` | |
| Fig 2D | F2 (60) | `fig.2D_AR_target_gene` | |
| Fig 2E | F2 (68) | `fig.2E.AR_acti_portion_bar` | |
| Fig 2F | F2 (79) | `fig.2F.AR_surv` | |
| Fig 2G–I | — | — | Organoid experiments, no code |
| Fig 3A | F3 (9–10) | `fig.3A.KEGG.C2.data.xlsx` | Heatmap shown in the notebook; only data saved |
| Fig 3B | F3 (26) | `fig.3B_immune_heatmap` | |
| Fig 3C | F3 (34) | `fig.3C_gly_filtered_Glycopiptides4` | |
| Fig 3D | F3 (70, 80) | `fig.3D.sialylated_glycopeptides_portion`; `fig.3D.data_DE_GLY_C1-C3.xlsx` | |
| Fig 3E | F3 (136–137) | `fig.3E.rho_SIA_heatmap` (+ `.top_anno`) | |
| Fig 3F | F3 (152, 163) | `fig.3F.DE_Gly_volcano`, `fig.3F.2nd.DE_Gly_volcano_log2`, `fig.3F.glyco_protein_DE.xlsx` | Two volcano versions are written (ΔAbundance and log2FC); see the thresholds used in each |
| Fig 3G | — | — | Manually drawn (bubble plot) |
| Fig 3H / 3I / 3J | F3 (185–203) | `fig.3H.3I.3J/fig.3H.3I.3J._C{1,2,3}_GSEA_correlation.xlsx` etc. | Only correlation data generated; panels drawn manually |
| Fig 3K | F3 (216) | `fig.3K.MFAP4.violin` | |
| Fig 3L | — | — | Schematic, no code |
| Fig 4A, 4B, 4H | — | — | Workflow / staining / schematics |
| Fig 4C | F45 (33) | `fig.4C.scatter.IRS_scores.pdf`, `fig.4C.scatter.xlsx` | |
| Fig 4D–4G | F45 (46) | `fig.4D.4E.4F.4G.IHC_maker_AUC.pdf` + `_input/_output.xlsx` | Single-marker / pairwise-marker ROC |
| Fig 4I / 4J | F45 (90 / 99) | `fig.4I.Concordance.retrospective.pdf`, `fig.4J.Concordance.prospective.pdf` | Average PPV computed from the confusion matrix |
| Fig 4K / 4L | — | — | Manually drawn KM curves; labels in `export_c3/fig4_ihc_{trainset,validset}_labeled.dfx` |
| Fig 5A, 5B, 5E–5L | — | — | Experiments / schematics |
| Fig 5C | F45 (113) | `fig.5C.scatter.tSNE.pdf`, `fig.5C.scatter.xlsx` | t-SNE of proteomic ssGSEA pathway and immune-signature scores |
| Fig 5D | Manual; data from `GET_DATA_cmap_drugs` | `external_data/Cmap_drug_screen/_CMAP_DRUGS.xlsx` | |
| Fig S1A–S1C | — | — | Workflow / pathology images |
| Fig S1D | F1 (140) | `fig.S1D.MD_count_barplot` | |
| Fig S1E / S1F | F1 (23–27) | Same composites as 1B/1C | Clinicopathological features / RCB panels |
| Fig S2A | — | — | Schematic |
| Fig S2B | F1 (87–88) | `fig.S2B.data.glyco_4levels.xlsx` | Data only; plot drawn manually |
| Fig S2C | F1 (105–106) | `fig.S2C.frequencies_compare_cohorts` | |
| Fig S2D–S2G | F1 (144, 147, 150, 153; data 134) | `fig.S2D.tSNE.RNA.response`, `fig.S2E.tSNE.prt.response`, `fig.S2F.tSNE.RNA.MD`, `fig.S2G.tSNE.prt.MD` | |
| Fig S2H / S2I | GLY (317) | `fig.S2H.ID_Identifed_Raw.Prt_retrospective.pdf`, `fig.S2I.ID_Identifed_Raw.Prt_prospective.pdf` | Statistics: `fig.S2H.S2I.ID_Identifed_Raw_vs_NA_filled.Statistics.xlsx` (cell 330) |
| Fig S2J | F3 (44) | `fig.S2J_Identified_Number_bar` | |
| Fig S2K | F3 (48) | `fig.S2K.glycosylation_sites_scatter` | |
| Fig S2L / S2M | F3 (57 / 61) | `fig.S2L.glycosites_per_glycoprotein`, `fig.S2M.glycans_per_glycosylation_site` | |
| Fig S3A–S3C | — | — | Manually drawn |
| Fig S3D / S3E | F1 (24 / 27) | `fig.S3D_all138_BCR`, `fig.S3E_all138_RGR` | Only the pCR / C1–C3 panels are used |
| Fig S3F–S3H | F1 (112–113); data from `GEN_EXT_SURVIVAL_DATA_PY` | `fig.S3F.S3G.S3H/fig.S3F.S3G.S3H.ext_<cohort>_<endpoint>.pdf`; `fig.S3F.S3G.S3H.data.ext_survival.xlsx` | |
| Fig S4A | F2 (87) | `fig.S4A.rna_hm_im_heat` | |
| Fig S4B | F2 (98–99) | `fig.S4B.rna`, `fig.S4B.prt`, `fig.S4B.HM.*.data.xlsx` | |
| Fig S4C / S4D | F2 (106 / 107) | `fig.S4C.rna_deg_vol`, `fig.S4D.prt_dap_vol` | |
| Fig S4E | F2 (124) | `fig.S4E.KEGG.C1.data.xlsx` | |
| Fig S4F | — | — | Manually drawn (EnrichmentMap) |
| Fig S4G | PYG (18) | `gsea_report/rna_c1_hm/HALLMARK_{ANDROGEN_RESPONSE,MYC_TARGETS_V1}.prerank.pdf` | |
| Fig S4H / S4I | F2 (25); PYG (18) | `fig.2B.S4H.S4I_gsea_score`; `gsea_report/rna_c1_hm/HALLMARK_{E2F_TARGETS,FATTY_ACID_METABOLISM}.prerank.pdf` | |
| Fig S5A / S5B | F3 (224 / 225) | `fig.S5A.rna_C2_deg_vol`, `fig.S5B.prt_C2_dap_vol` | |
| Fig S5C | — | — | Manually drawn (EnrichmentMap) |
| Fig S5D | F3 (234) | `fig.S5D.cluster_C2_hm_violin` | |
| Fig S5E / S5F | F3 (244) | `fig.S5E.S5F.estimate_imm_score_violin` | |
| Fig S5G | F3 (87) | `fig.S5G.glycan_portion_bar` | |
| Fig S5H | F3 (141) | `fig.S5H.DE.ST.enzymes.boxplot` | |
| Fig S5I | F3 (173, 175, 181) | `fig.S5I.prt_abundance.violin.selected`, `fig.S5I.glyco_ios_stregth.violin.selected` | |
| Fig S5J–S5L | — | — | Staining / blotting experiments |
| Fig S6A | — | — | Manually drawn |
| Fig S6B / S6C | F45 (53) | `fig.S6B.S6C.Prt_abundance_IHC_maker_AUC.pdf` | Protein-abundance ROC of the same marker sets |
| Fig S6D / S6E | F45 (74 / 76) | `fig.S6D.ROC_test_set.pdf`, `fig.S6E.ROC_train_test_set.pdf` | |
| Fig S6F | — | — | Staining images |
| Fig S6G | F45 (39) | `fig.S6G.scatter.IRS_scores.prospective_cohort.pdf` | |
| Fig S6H | F45 (63) | `fig.S6H.IHC_maker_AUC_prospective_cohort.pdf` | |
| Fig S7, S8 | — | — | Organoid experiments |

## Suggested execution order

1. **Data preparation** (once): `GET_ext_data` → `GET_DATA_Glycosylation_Phosphorylation` → `GET_DATA_cmap_drugs`.
2. **Subtype definition**: the consensus-clustering outputs (`export_c3/fig1_subtype_heatmap_mat.dfx`, `fig1_subtype_row_cluster.dfx`, `fig1_subtype_column_cluster.dfx`, `glx_86.dfx`, `wes_glx.dfx`) come from an upstream clustering step that is not part of this repository.
3. **Subtype labels for all 126 non-pCR cases**: run the section *"Subtype labels for all 126 non-pCR cases"* in `Fig4_Fig5_xPY_PLOT.ipynb` first (after its *Prepare Data* section). It writes `export_c3/fig1_subtype_predict_and_pca_data.xlsx` (and a copy in `report_c3/`), which `Fig1_S1S2_xR_PLOT` and `Fig2_S3_xR_PLOT` read. It uses the trained random-forest model `export_c3/fig4_gsea_rf_model_evenly_dis`, which is **trained upstream and is not part of this repository**. Note that the retrospective and prospective ssGSEA matrices are z-scored separately (see the note in that notebook).
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
