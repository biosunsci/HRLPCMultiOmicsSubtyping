# GCpytools (minimal I/O version)

Small file-I/O helper library imported by the Python data-preparation notebooks
(`GET_ext_data`, `GEN_EXT_SURVIVAL_DATA_PY`, `GET_DATA_Glycosylation_Phosphorylation`) via

```python
import sys
sys.path.insert(0, '<path to this directory>')   # DBLIBPATH in the notebooks
from dblibs import *
db = Database(outputdir=OUTPUTROOT, input_dir=INPUTROOT)
```

All database access code of the original in-house package (SQL queries, DB configuration, clinical/sequencing data
retrieval) has been removed. What remains:

| File | Content |
|---|---|
| `dblibs.py` | `Database` (file-based `importing` / `exporting`, no DB connection; `set_used_db` is accepted and ignored for backward compatibility), `echo` (DataFrame display), `write_excel` / `read_excel` (multi-sheet excel), `plot_venns`, small pandas helpers (`groupby(...).count_desc()`, `.drop_index()`, `Series.u()`, `Series.un()`) |
| `log_system.py` | `Log_system` base class implementing `importing` / `exporting` (tab-separated `.dfx`, csv/tsv, excel, json, dill, figures, text) and the JavaScript-like `Dict` |

Requirements: `pandas`, `numpy`; `openpyxl` / `xlsxwriter` (excel), `matplotlib` and `matplotlib_venn` (figures, venn diagrams), optionally `plotly`, `dill`.

Note: methods that required the database (e.g. `db.get_the_gene_set_by_tagname`) no longer exist.
