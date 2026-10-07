"""
log_system -- file importing / exporting helpers (Log_system) and a JavaScript-like Dict.
"""
import os
import re
from os.path import join as J, exists as E
from os import listdir as L
from datetime import datetime
import pandas as pd
import numpy as np
try:
    from matplotlib.figure import Figure as pltFigure
except ImportError:  # matplotlib is optional (only needed to export figures)
    pltFigure = None
try:
    from plotly.graph_objs._figure import Figure as plotly_Figure
except ImportError:  # plotly is optional
    plotly_Figure = None
from typing import Any, Union, Callable, TypeVar, Generic, Literal



# PLEASE USE AFTER YOU UNDERSTAND THE TRUE LOGIC OF THIS CLASS Dict
# a dict which treat . and [] alike and do not raise KeyError
# make python `dict` behaving like javascript `object`
class Dict(dict):
    """
     JavaScript Object like python dict
    """
    def __init__(self, *args, **kwargs):
        for arg in args:
            if arg is not None:
                self.__dict__.update(arg)
            else:
                # if self._verbose:
                print('⛔ None has been passed to __init__, ignore it.')
        self.__dict__.update(kwargs)


    def __getitem__(self, name):
        if type(name)==str:
            return self.__dict__.get(name, None)
        elif hasattr(name,"__iter__"):
            res = []
            for i in name:
                # condition if type(i)==str ommitted, if i not hashable, will raise error
                res.append(self.__dict__.get(i, None))
            return res
        else:
            raise KeyError(f'bad key {name}')

    def __setitem__(self, name, val):
        return self.__dict__.__setitem__(name, val)

    def __delitem__(self, name):
        if name in self.__dict__:
            del self.__dict__[name]

    def __getattr__(self, name):
        return self.__getitem__(name)

    def __setattr__(self, name, val):
        return self.__setitem__(name, val)

    def __delattr__(self, name):
        return self.__delitem__(name)
    
    def __len__(self):
        return self.__dict__.__len__()
    
    def __iter__(self):
        return self.__dict__.__iter__()

    def __repr__(self):
        # res = '  i\tkey\tvalue\tinfo\n'
        res_cols = ['key', 'type', 'info','#a','#NotNA_a']
        res = []
        for k, v in self.__dict__.items():
            t = type(v)
            a = '/'
            cnt = '/'
            if t == str:
                if len(v) < 30:
                    inf = v
                else:
                    inf = f'{len(v)} chars'
            elif t == list:
                inf = f'{len(v)} items'
            elif t == pd.DataFrame:
                inf = f'{v.shape}'
                t = '<pd.DataFrame>'
                if 'a' in v.columns:
                    if 'Hugo_Symbol' in v.columns:
                        cnt = len(v[v['Hugo_Symbol']!='.']['a'].unique())
                    a = len(v['a'].unique())
                elif 'patient_id' in v.columns:
                    if 'Hugo_Symbol' in v.columns:
                        cnt = len(v[v['Hugo_Symbol']!='.']['patient_id'].unique())
                    a = len(v['patient_id'].unique())
            elif t == pd.Series:
                inf = f'{v.shape}'
                t = '<pd.Series>'
                if t.name =='a':
                    a = len(v.unique())
                elif t.name == 'patient_id':
                    a = len(v.unique())
            elif t == np.ndarray:
                inf = f'{v.shape}'
            elif t == int or t == float or t == complex:
                inf = str(v)
            else:
                inf = np.nan
            if len(k)>25:
                k = k[:20]+'...'+k[-5:]
            res.append([k, t, inf,a, cnt])
        preset = pd.options.display.max_rows
        pd.options.display.max_rows = 999
        k = str(pd.DataFrame(res, columns=res_cols))
        pd.options.display.max_rows = preset
        return k

    def __str__(self):
        return self.__dict__.__str__()

    def keys(self):
        return self.__dict__.keys()

    def items(self):
        return self.__dict__.items()

    def values(self):
        return self.__dict__.values()

    def copy(self):
        return self.__dict__.copy()

    def __add__(self, b, verbose=False):
        replaced = []
        res = self.copy()
        for i in b.keys():
            if i in res.keys():
                replaced.append(i)
            res[i] = b[i]
        l = len(replaced)
        if verbose == True and l > 0:
            print(f'{l} keys updated: {replaced}')
        return Dict(res)

    def __sub__(self, b, verbose=True):
        t = type(b)
        keys = self.keys()
        res = self.copy()
        removed = []
        if t == dict or t == Dict:
            it = b.keys()
        elif t == list:
            it = t
        for i in it:
            if i in keys:
                del res[i]
                removed.append(i)
        l = len(removed)
        if verbose == True and l > 0:
            print(f'{l} keys removed: {removed}')
        return res


# Log_system
# r_stdout_orig = rpy2.rinterface_lib.callbacks.consolewrite_print
# r_stderr_orig = rpy2.rinterface_lib.callbacks.consolewrite_warnerror
# for managing input and output behavior with generating logs informations
class Log_system:
    # Keep the old functions #

    # Keep the old functions #

    # @staticmethod
    # def _r_stdout_orig(msg):
    #     return r_stdout_orig(msg)

    # @staticmethod
    # def _r_stderr_orig(msg):
    #     return r_stderr_orig(msg)
    def __repr__(self):
        return f'Log_system(outputdir="{self.OUTPUTDIR}",input_dir="{self.INPUT_DIR}", use_full_path={self.USE_FULL_PATH})'
    def __init__(self, outputdir=None, input_dir = None, title="dev",use_full_path=True):
        self.USE_FULL_PATH = use_full_path
        self.last_exported_file_path = ""
        self.OUTPUTDIR = outputdir or J(os.getcwd(),'export')
        self.INPUT_DIR = input_dir or self.OUTPUTDIR
        
        # self._LOGS = []
        self.TITLE = title
        self._LAST_MESSAGE = ""
        self._TOTAL_OUT_FILE_NUM = 0
        self._OUTPUTFILES = {}
        self._DEFAULT_OUT_LOG_NAME = 'DEFAULT_OUT_LOG_NAME'
        # set rpy2 stdout
        # self._silent_r_stdout = True
        # self._silent_r_stderr = False
        # self._capture_r_console_outputs()
        # self.__dict__['_OUTPUT_ROOT'] = ""
        # self.__dict__['OUTPUTDIR'] = os.getcwd()
        self._verbose = True

    def verbosing(self, msg, verbose: Literal[True, False, None]=None, boxed=False):
        """
        :msg: the information to print
        :verbose: boolean, if verbose is True, then force to print msg, if False do not print inf, if None using system default self._verbose to determine whether printing the msg, default None
        :boxed: if True, output will be inside a box like a card, for obvious vision
        :boxed: alias of boxed, for compatible with lower versions
        """
        assert type(boxed) == bool, 'boxed must be boolean'
        if verbose is None:
            on = self._verbose or False
        else:
            assert type(verbose) == bool, 'TypeError [verbose]'
            on = verbose
        if on == True:
            if boxed == True:
                msg = pd.Series(msg.split('\n'))
                l = msg.str.len().max()
                print("+" + "-" * (l + 2) + "+")
                print("| " + " " * (l) + " |")
                for m in msg:
                    self._logger(f"| {m}" + " " * (l - len(m)) + " |", overwrite_msg=True,at=False, o=False, a2=False)
                print("| " + " " * (l) + " |")
                print("+" + "-" * (l + 2) + "+")
            else:
                self._logger(msg, overwrite_msg=True, o=False, a2=False)
        else:
            pass

    # @property
    # def logs(self):
    #     return self._LOGS

    def _logger(self, info, overwrite_msg=False, o=True, at=True, outputfile=None, a2=True, **kwargs):
        """
        :at: add time tag, default True
        :a2: add to current loop lineage, deprecated
        :o:outputfile: hint on wether this @info is a description on file IO
        """
        assert type(at) == bool and type(a2) == bool
        if outputfile is None:
            outputfile = o
        if outputfile and overwrite_msg == False:
            # info is output file name:
            self._LAST_MESSAGE = f"{info} 1 file written at {self.OUTPUTDIR}"
        else:
             # info is output file with path massage or
             # info there is no outputfile
            self._LAST_MESSAGE = info
        # 输出信息加时间戳
        if at == True:
            self._LAST_MESSAGE = f"[{datetime.now().strftime('%m/%d %H:%M:%S')}]" + self._LAST_MESSAGE
        print(self._LAST_MESSAGE)
        if a2 == True:
            pass
            # self._LOGS.append(f"[python] {self._LAST_MESSAGE}\n")

    # def _logs_export(self,fname=None,outputdir=None):
    #     if outputdir is None:
    #         outputdir = self.OUTPUTDIR
    #     if fname is None:
    #         fname = self._DEFAULT_OUT_LOG_NAME
    #     log_file_fullpath = J(outputdir, fname)
    #     with open(log_file_fullpath, 'w') as f:
    #         f.write(self._LOGS)
    #         f.close()
    #         self._logger(self._DEFAULT_OUT_LOG_NAME,
    #                      a2=False)
    #         self._TOTAL_OUT_FILE_NUM = 0
    #         self.last_exported_file_path = log_file_fullpath

    def exporting(self, x=None, export=None, outputdir=None, 
                    fname=None,
                    worker=None, flag="", prefix="", suffix="",
                    verbose=True, 
                    use_full_path=True,
                    method_name="to_csv",
                    add2downloadlist=True, retopath = False, **kwargs):
        """
        :fname: output file name. if you give a name with path, then use the given path instead of outputdir value, else file will be output to path <outputdir>
        :worker: :flag: :prefix: :suffix:
            tags added to the final output filename, in the order of worker_flag_prefix_fname_suffix.extname. each tag only appears when it is not None or empty string ""
        :verbose: print output file info to stdout or not, default True
        :use_full_path: {True,Flase,None} if True output info using full path, if False output info using relative path, if None use default setting self.USE_FULL_PATH
        :outputdir: if not None, output file redirected to outputdir indicated location, else use default path self.OUTPUT_ROOT
        :method_name: if x is an x with output file functions like to_csv, use x call method_name to output files, default to_csv
        :x: the x containing data to output, the behavior differs if x is string type, using function open(fname,'w') as f, f.write(x) .
        :add2downloadlist: if True, file name and path will be added to self._OUTPUTFILES for generating scp bash for download to local disc from the server side
        """
        if x is None:
            raise ValueError('x must be not None')
        
        if export is not None:
            if export == False:
                self.verbosing('stop export when export==False',verbose=verbose)
                return None
            elif type(export)==str:
                fname = export
            elif export == True:
                if fname is None:
                    fname = "default"
        assert fname is not None, "ValueError('fname and export both None)"
        
        if use_full_path is None:
            use_full_path = self.USE_FULL_PATH

        if fname is None or fname == "":
            raise ValueError('fname must not be empty!')

        # fname contains path, overwrite outputdir values
        if '/' in fname:
            outputdir = os.path.dirname(fname)
            fname = os.path.basename(fname)
        else:
            if outputdir is None:
                outputdir = self.OUTPUTDIR

        if use_full_path == True:
            # absolute path
            if outputdir[0] == '/':
                pass
            # relative path
            else:
                outputdir = J(os.getcwd(), outputdir)

        if '.' in fname:
            ext = fname.split('.')[-1]
            name = ".".join(fname.split('.')[:-1])
        else:
            # default output dfx
            name = fname
            tt = type(x)
            if tt == str:
                ext = 'txt'
            elif tt == pltFigure:
                ext = 'pdf'
            elif tt in (pd.DataFrame, pd.Series, np.ndarray, list,pd.Index):
                ext = 'dfx'
            elif tt == plotly_Figure:
                ext = 'pdf'
            else:
                raise TypeError(f'{tt} is unsurported output var type')
        
        o=[]
        for i in [worker,flag,prefix,name,suffix]:
            if i is not None and i!='':
                o.append(i)

        out_full_path = J(outputdir,'_'.join(o)+ '.' + ext)
        
        if os.path.exists(out_full_path):
            KEYWORD = 'overwritting'
        else:
            KEYWORD = 'writing'
        if ext == 'json':
            import json
            if type(x) == pd.DataFrame:
                x = x.to_dict('records')
            elif type(x) == pd.Series:
                x = x.to_dict()
            elif type(x) == np.ndarray:
                x = x.tolist()
            if isinstance(x, dict):
                add_token = '[json] with ' + str(len(x.keys()))+' keys'
            else:
                add_token = ' with ' + str(len(x))+' in length'
            with open(out_full_path,'w') as f:
                json.dump(x,f)
        elif ext in ['pkl','pickle']:
            raise ValueError('do not use pickle, using dill instead')
        elif ext == 'dill':
            import dill
            with open(out_full_path,'wb') as f:
                dill.dump(x,f)
        elif ext in ['xlsx','xls']:
            if type(x) == pd.DataFrame:
                method_name = 'to_excel'
                method = getattr(x,method_name)
                method(out_full_path, **kwargs)
                add_token = f"{len(x)} lines"
            elif type(x) in [Dict,dict]:
                ## :engine: 'xlsxwriter' for .xlsx, 'xlwt' for .xls
                if ext=='xlsx':
                    writer = pd.ExcelWriter(out_full_path, engine='xlsxwriter')
                elif ext=='xls':
                    writer = pd.ExcelWriter(out_full_path, engine='xlwt')
                else:
                    raise ValueError('only xlsx,xls is supported at current')
                EXCEL_SHEETS_LIMIT = 255
                max_row=50_000
                if 'index' not in kwargs:
                    kwargs['index'] = True
                count = 0
                sheet_names_used = {}
                l = len(x.keys())
                if  l < EXCEL_SHEETS_LIMIT:
                    temp = f'{{:0{len(str(l))}d}}'
                else:
                    raise ValueError(f'too many DataFrames({l}) to be written, maximal 255!')
                cnt = 0
                for name,df in x.items():
                    if type(df) not in [pd.DataFrame,pd.Series]:
                        self.verbosing(f'⚠ skip {name} for {type(df)} is not df/series')
                        continue
                    l = len(df) 
                    if l <= max_row:
                        count  = count + 1
                        cc = temp.format(count)
                        self.verbosing(f'  append #{cc} Sheet [{name}]')
                        if len(name) > 30:
                            name = name[:28]
                        if name in sheet_names_used.keys():
                            suffix = sheet_names_used[name]
                            if suffix > 100:
                                print(f'⛔ too many(>100) sheets with the same name! skip sheet {name} : {suffix}')
                            name = name + str(suffix)
                            sheet_names_used[name] += 1
                        else:
                            sheet_names_used[name] = 0
                        # change any df column with dtype of datetime64+time zone to str, as current xlwt does not support datetime with time zone info format
                        mask = pd.Series([pd.api.types.is_datetime64_any_dtype(i) for i in df.dtypes])
                        df = df.astype({i:str for i in df.columns[mask]})
                        df.to_excel(writer,sheet_name=name,**kwargs)
                        cnt = cnt + 1
                    else:
                         self.verbosing(f'⛔ skip [{name}.dfx] for it contains {l} rows exceeding max_row setting.')
                writer.close()
                add_token = f"{cnt} sheets"
                print(f'writing 1 excel @ {out_full_path}')
            else:
                raise ValueError(f'x type {type(x)} not supported to excel')
        else:
        # ext in ['txt','csv','tsv','dfx','svg','pdf','png','tif','tiff'], etc
            tt = type(x)
            if tt == str:
                with open(out_full_path, 'w') as f:
                    f.write(x)
                    f.close()
                add_token = f"{len(x)} chars"
            elif tt == pltFigure:
                method_name = 'savefig'
                add_token = 'plt'
                method = getattr(x, method_name)
                method(out_full_path, **kwargs)
            elif tt == plotly_Figure:
                method_name = 'write_image'
                add_token = 'plotly'
                method = getattr(x, method_name)
                method(out_full_path, **kwargs)
            elif tt in (pd.DataFrame, pd.Series, np.ndarray, list,pd.Index):
                if tt in (np.ndarray, list,pd.Index):
                    x = pd.DataFrame(x).squeeze()
                if method_name == 'to_csv':
                    if "sep" not in kwargs:
                        kwargs['sep'] = '\t'
                    if "index" not in kwargs:
                        if type(x.index) == pd.RangeIndex:
                            kwargs['index'] = False
                        else:
                            kwargs['index'] = True
                    
                add_token = f"{len(x)} lines"
                method = getattr(x, method_name)
                method(out_full_path, **kwargs)
            else:
                raise TypeError(f'{tt} is unsurported output var type')
        # else:
        #     raise ValueError(f'un-surported type {ext}')
        if verbose == True:
            self.verbosing(f" {KEYWORD} 1 file with {add_token} at \n\t{out_full_path}", verbose=verbose)

        self.last_exported_file_path = out_full_path

        if add2downloadlist == True:
            self._OUTPUTFILES[fname] = out_full_path
            self._TOTAL_OUT_FILE_NUM += 1
        if retopath:
            return out_full_path
        return None
    
    def _read_json(self,path):
        import json
        with open(path) as f:
            j = json.load(f)
        return j
    
    def importing(self, fname, frm=None, worker=None,flag="", prefix=None, suffix=None, method: Union[Callable,Literal['read_csv']]="read_csv", verbose=True, raise_error = True, show_all_sheets=True, **kwargs):
        """
        :fname: file name to import, if '/' in fname, override frm value
        :frm: import fname from <frm>
        :prefix: fname will add prefix on search, fname = pre+'_+fname
        :worker: if not None, the file name searched is worker_fname, if worker_fname not found, retry with fname alone
        :method: method to import files, default "read_csv", for reading pd.read_csv
        :show_all_sheets: show all the sheets in the excel file, default False, only used when reading excel file xlsx, xls
        """
        
        if frm is None:
            frm = self.INPUT_DIR
        
        if '/' in fname:
            frm = os.path.dirname(fname)
            fname = os.path.basename(fname)
        else:
            if frm is None:
                frm = self.OUTPUTDIR

        if '.' in fname:
            ext = fname.split('.')[-1]
            name = ".".join(fname.split('.')[:-1])
        else:
            # default output dfx
            name = fname
            ext = 'dfx'

        if ext in ['xlsx','xls']:
            read_method = getattr(pd,'read_excel')
        elif ext in ['json']:
            read_method = self._read_json
        elif method == 'read_csv':
            read_method = getattr(pd,method)
            if "sep" not in kwargs:
                kwargs["sep"] = '\t'
            if "index_col" not in kwargs:
                kwargs["index_col"] = None
        o=[]
      
        link = [i for i in [flag,prefix,name,suffix] if i is not None and i!='' ]
        name = '_'.join(link)  
        if worker is not None and re.match('^[A-Z][0-9]$',worker):
            full_path = J(frm, worker + "_"+ name + '.' + ext)
            backup_full_path = J(frm, name + '.' + ext)
        else:
            full_path = J(frm,name + '.' + ext)
            backup_full_path = None
        
        if verbose == True:
            self._logger(f"reading {full_path}", overwrite_msg=True,at=True, a2=False)

        if ext in ['xlsx','xls']:
            # show additional info of xls sheet names
            with pd.ExcelFile(full_path) as xl:
                sheets = xl.sheet_names
                sheet_name = kwargs.get('sheet_name',0)
                if type(sheet_name) == int:
                    sheet_i = sheet_name
                    sheet_name = sheets[sheet_i]
                elif type(sheet_name) == str and sheet_name in sheets:
                    sheet_i = sheets.index(sheet_name)
                else:
                    raise ValueError(f'sheet_name {sheet_name} not found in {sheets}')
                if show_all_sheets:
                    print(f'  Sheets list: {sheets}')
                print(f'  Read the {sheet_i + 1} / {len(sheets)} sheet named <{sheet_name}>')

        if os.path.exists(full_path):
            return read_method(full_path, **kwargs)
        elif backup_full_path:
            self._logger(f"not found, retry reading {backup_full_path}", overwrite_msg=True,at=True, a2=False)
            return read_method(full_path, **kwargs)
        else:
            if raise_error:
                raise IOError(f'{full_path} does not exist!')
