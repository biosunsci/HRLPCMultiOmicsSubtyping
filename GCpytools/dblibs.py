"""
dblibs -- minimal file I/O helpers used by the analysis notebooks.

This module is a stripped-down version of the original in-house helper library.
All database-related code (SQL access, DB configuration, data queries) has been
removed; only the pieces needed by the published notebooks are kept:

* ``Database``      thin wrapper around :class:`log_system.Log_system`; provides
                    ``db.importing(...)`` / ``db.exporting(...)`` for reading and writing
                    tables, figures, json, excel files. (The name is kept for notebook
                    compatibility; no database is involved.)
* ``echo``          pretty display of long DataFrames in notebooks
* ``write_excel`` / ``read_excel``   multi-sheet excel helpers
* ``plot_venns``    venn diagram helper
* a few small pandas conveniences (``groupby(...).count_desc()``, ``.drop_index()``,
  ``Series.u()``, ``Series.un()``)
"""
import os
from os.path import join as J, exists as E
from typing import Union, Literal

import numpy as np
import pandas as pd

from log_system import Log_system, Dict

try:
    from IPython.display import display
except ImportError:  # not in a notebook environment
    display = print

__all__ = ['Database', 'Dict', 'Log_system', 'write_excel', 'read_excel',
           'plot_venns', 'echo', 'pd', 'np']


# ------------------------------------------------------------------ display
class Echo:
    def set(self, reset=None, reset_col=None, maxrow=None, maxcol=None):
        if reset is not None:
            self._reset = reset
            pd.set_option('display.max_rows', reset)
        if reset_col is not None:
            self._reset_col = reset_col
            pd.set_option('display.max_columns', reset_col)
        if maxrow is not None:
            self._maxrow = maxrow
        if maxcol is not None:
            self._maxcol = maxcol
        
    def __init__(self, reset=None, reset_col = 60, maxrow=100, maxcol=100):
        if reset is None:
            self._reset = pd.get_option('display.max_rows')
        else:
            self._reset = reset
    
        if maxrow is None:
            self._maxrow = self._reset
        else:
            self._maxrow = maxrow

        if maxcol is None:
            self._maxcol = pd.get_option('display.max_columns')
        else:
            self._maxcol = maxcol
        
        if reset_col is None:
            self._reset_col = pd.get_option('display.max_columns')
        else:
            self._reset_col = reset_col

    def _echo(self, df=None, maxrow=None, maxcol=None, reset=None, reset_col=None): 
        if df is None:
            return None
        if reset is None:
            reset = self._reset
        if reset_col is None:
            reset_col = self._reset_col
        
        if maxrow is None:
            maxrow = self._maxrow
        else:
            self._maxrow = maxrow
        if maxcol is None:
            maxcol = self._maxcol
        else:
            self._maxcol = maxcol
        
        if df is not None:
            pd.set_option('display.max_rows', maxrow)
            pd.set_option("display.max_columns", maxcol)
            display(df)

        pd.set_option('display.max_rows', reset)
        pd.set_option('display.max_columns', reset_col)
    def __call__(self, *args, **kwargs):
        self._echo(*args,**kwargs)
echo = Echo()


# ------------------------------------------------------------------ file I/O
class Database(Log_system):
    """File-based importing/exporting helper (no database connection).

    :outputdir: default directory for ``exporting``
    :input_dir: default directory for ``importing``
    :set_used_db: accepted for backward compatibility with old notebooks and ignored.
    """
    def __init__(self, outputdir=None, input_dir=None, set_used_db=None):
        super().__init__(outputdir=outputdir, input_dir=input_dir)


# ------------------------------------------------------------------ plotting
def plot_venns(*args, labels = None, export=False,outputdir='report/',ret=False, **kwargs):
    """
    :*args: arg list of plotting array/set/Series, like glx.G1,glx.G2, etc, max number of args is 5
    :lables: plotting label of each arg, ordered
    :export: whether output plot fig, if True use default out name, if str, use str.pdf as out name
    """
    import matplotlib.pyplot as plt
    fig, ax = plt.subplots(1, 1)
    l = len(args)
    if l == 2:
        from matplotlib_venn import venn2 as venn
    elif l == 3:
        from matplotlib_venn import venn3 as venn
    elif l == 4:
        from matplotlib_venn import venn4 as venn
    elif l == 5:
        from matplotlib_venn import venn5 as venn
    else:
        raise ValueError('args length must <= 5')
    sets = []
    for i in args:
        sets.append(set(i))

    venn(subsets=sets,
         set_labels=labels,
         **kwargs
         )
    if export == True:
        export = f'default_venn{l}'
    if type(export) == str and export!="":
        if export[-4:] != '.pdf':
            export += '.pdf'
        out = J(outputdir,export)
        print("put one pdf at ", out)
        fig.savefig(out)
        
    if ret == True:
        return fig


# ------------------------------------------------------------------ excel
def write_excel(d,fname,outputdir='report',force_ext:Union[None,Literal['xls','xlsx']]=None,max_row=50_000,index=True):
    """
    :engine: 'xlsxwriter' for .xlsx, 'xlwt' for .xls
    ext will be auto determined by the fname when force_ext is None
        if not provide in fname, default is .xlsx
    :max_row: max row number for each sheet, if exceed, skip
    """
    _ = fname.split('.')
    if len(_) > 1:
        ext = _[-1]
        name = ".".join(_[:-1])
    else:
        name = fname
        ext = 'xlsx'
    if force_ext is not None:
        assert type(force_ext) == str, "force_ext must be in ['xls','xlsx']"
        ext = force_ext
    if ext == 'xlsx':
        engine = 'xlsxwriter'
    elif ext == 'xls':
        engine = 'xlwt'
    else:
        raise Exception(f'auto deteminded ext = {ext}, this is not supported, mainly due to there is dot (.) in your current fname,  please manually set ext to .xlsx or .xls')
    out = J(outputdir, name + '.' + ext)

    with pd.ExcelWriter(out, engine=engine) as writer:
        EXCEL_SHEETS_LIMIT = 255
        count = 0
        sheet_names_used = {}
        l = len(d.keys())
        if  l < EXCEL_SHEETS_LIMIT:
            temp = f'{{:0{len(str(l))}d}}'
        else:
            raise  ValueError(f'too many DataFrames({l}) to be written, maximal 255!')
        for name,df in d.items():
            tp = type(df)
            if tp != pd.DataFrame:
                try:
                    df = pd.DataFrame(df)
                    print(f'covert {name}: {tp} -> {type(df)}')
                except Exception as e:
                    print(f'skip {name}, illegal type {type(df)}')
                    continue
            l = len(df) 
            if l <= max_row:
                count  = count + 1
                cc = temp.format(count)
                print(f'  append #{cc} Sheet [{name}]')
                if len(name) > 30:
                    name = name[:28]
                if name in sheet_names_used.keys():
                    suffix = sheet_names_used[name]
                    if suffix > 100:
                        print(f'[ERR] too many(>100) sheets with the same name! skip sheet {name} : {suffix}')
                    name = name + str(suffix)
                    sheet_names_used[name] += 1
                else:
                    sheet_names_used[name] = 0
                # change any df column with dtype of datetime64+time zone to str, as current xlwt does not support datetime with time zone info format
                mask = pd.Series([pd.api.types.is_datetime64_any_dtype(i) for i in df.dtypes])
                df = df.astype({i:str for i in df.columns[mask]})
                df.to_excel(writer,sheet_name=name,index=index)
            else:
                print(f'⛔ skip [{name}.dfx] for it contains {l} rows exceeding max_row setting.')
    print(f'writing 1 .xls @ {out}')

def read_excel(fname,frm='./export/',index_col=0):
    res = Dict()
    if '.' not in fname:
        fname = fname + '.xls'
    path = J(frm,fname)
    xl = pd.ExcelFile(path)
    sheet_names = xl.sheet_names  # see all sheet names
    # xl.close()
    for name in sheet_names:
        res[name] = xl.parse(name,index_col=index_col)
        print(f'reading {name}')
    xl.close()
    print('-'*5)
    print(f'  all sheets read from [{fname}]')
    return res


# ------------------------------------------------------------------ pandas conveniences
def count_desc(self,col=None,ascending=False,reset_index=False):
    x = self.count()
    if type(x) == pd.Series:
        res = x.sort_values(ascending=ascending)
    elif type(x) == pd.DataFrame:
        if col is None:
            col = x.columns[0]
        res = x.sort_values(col,ascending=ascending)
    else:
        raise Exception('!')
    if reset_index == True:
        return res.reset_index()
    else:
        return res
setattr(pd.core.groupby.generic.DataFrameGroupBy,'count_desc',count_desc)

def count_desc(self,col=None,ascending=False,reset_index=False):
    res = self.count().sort_values(ascending=ascending)
    if reset_index == True:
        return res.reset_index()
    else:
        return res
setattr(pd.core.groupby.generic.SeriesGroupBy,'count_desc',count_desc)

info = """
function:
    count_desc
    used after df.groupby(col2).count_desc(col), combination of count().sort_values(col,ascending=False)
parameters:
    :col: col names used for sort_values
        if None sort by the first column
        if you slice df into Series after groupby then the returned value is a Series sorted desc
    :reset_index:
        default False
        whether apply reset_index or not before returning, 
        if True your groupby(`key`) `key` will be a columns
        else the `key` is the index of the returnning DataFrame/Series
"""
pd.core.groupby.generic.DataFrameGroupBy.count_desc.__doc__ = info
pd.core.groupby.generic.SeriesGroupBy.count_desc.__doc__ = info
del count_desc

if not hasattr(pd.DataFrame,'drop_index'):
    info = """
    function:
        drop_index
        drop_index with reset=True
    """
    def drop_index(self,):
        return self.reset_index(drop=True)
    pd.DataFrame.drop_index = drop_index
    pd.Series.drop_index = drop_index
    pd.DataFrame.drop_index.__doc__ = info
    pd.Series.drop_index.__doc__ = info
    del drop_index

    
if not hasattr(pd.Series,'u'):
    info = """
    function:
        u
        short for unique
    """
    def u(self,**kwargs):
        return self.unique(**kwargs)
    
    pd.Series.u = u
    pd.Series.u.__doc__ = info
    del u

if not hasattr(pd.Series,'un'):
    info = """
    function:
        un
        short for unique().shape()
    """
    def un(self,**kwargs):
        x = self.unique(**kwargs).shape
        if len(x)==1:
            return x[0]
        else:
            return x
    
    pd.Series.un = un
    pd.Series.un.__doc__ = info
    del un
