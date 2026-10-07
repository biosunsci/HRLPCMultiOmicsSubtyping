#' same as Reduce
#'
#' @description same as Reduce except for x,f position exchanged for compilable with pipe op %>%
#'
#' @param x
#' @param f
#' @param init
#' @param ...
#'
#' @return reduce results
#'
#' @examples
reduce = function(x,f,init,...){
    Reduce(f,x,init,...)
}

#'
#' Log messages
#'
#' Log messages with timestamps to the stdout or stderr
#'
#' @param ... parameters of string, which will be concat to print to
#' @param verbose if verbose is FALSE, stop logging anything
#' @param .addtime add timestamp at the front when print
#' @param .dev in [1,2] default 2(stderr), .dev==2 mean stderr, .dev==1 means stdout
#'
#' @return Nothing is returned
#' @export
#'
#' @examples
#' \dontrun{
#' file = 'abc.txt'
#' dir = '/path/to/save'
#' ylog(file,'is written at',dir)
#' }
#'
ylog = function(...,verbose=TRUE, .addtime=TRUE, .dev=2){
    if (verbose==TRUE){
        if (.addtime){
            msg = c(list('[',Sys.time() |> as.character(),'] '),list(...)) %>%
                unlist %>%
                as.character %>%
                str_flatten(collapse = ' ')
        }else{
            msg = list(...) %>% unlist %>% as.character %>% str_flatten(collapse = ' ')
        }
        print(msg)
        # message(msg)
    }
}

# -------------- list utils ----------------

#' ypush up-sert (upsert) items to list
#'
#' Unlike append, ypush is an update-append(like SQL upsert) version of append
#'
#' @param ...
#' @param .expand
#' @param .as.whole
#' @param iter an iterable obj like list
#'
#' @return updated `iter`
#' @export
#'
#' @examples
#' \dontrun{
#' list(a=1,b=2) %>% append(list(a=3,c=4)) # list(a=1,b=2,a=3,c=4)
#' list(a=1,b=2) %>% ypush(list(a=3,c=4)) # list(a=3,b=2,c=4)
#' list(a=1,b=2) %>% ypush(list(a=3,c=4),.expand=F) # list(a=3,b=2,c=4)
#' }
ypush = function(iter, ..., .expand=TRUE,.as.whole=FALSE) {
    # update on keys for named list, push for unnamed list
    # you must let var = ypush(var,...) to update var, for the convenience of do.call
    # if partial named list, all no name items is ignored
    # if (iter %>% class =='character') iter = get(iter ,envir = parent.env(environment()))
    items = list(...)
    if (.expand==TRUE && length(items) == 1 && names(items) %>% is.null && 'list'%in%class(items[[1]])){
        items = items[[1]]
    }
    un_named = names(items) %>% is.null()
    if (un_named){
        if (.as.whole == FALSE){
            return(c(iter,items))
        }else{
            # .as.whole == TRUE
            iter[[length(iter)+1]] = items
            return(iter)
        }
    }else{
        # items is named list
        if (.as.whole == FALSE){
            ns = names(items)
            for (i in 1:length(items)){
                n = ns[[i]]
                v = items[[i]]
                if (n == ""){
                    if (is.null(v)){
                        iter[length(iter)+1] = list(NULL)
                    }else{
                        iter[[length(iter)+1]] = v
                    }
                }else{
                    if (is.null(v)){
                        iter[n] = list(NULL)
                    }else{
                        iter[[n]] = v
                    }
                }
            }
        }else{
            # .as.whole == TRUE
            iter[[length(iter)+1]] = items
            return(iter)
        }
        return(iter)
    }
}

#' subset named list by keys
#'
#' @description subset the list x by names(keys) if keys is named list or vector
#' subset the list x by keys if keys is not named list or vector
#'
#' @param x is.list(x) must be TRUE
#' @param keys vector or list, return the element in x which match the keys, others in the keys are ignored.
#'  if names(keys) is null, use values of keys
#'  else use names(keys) to subset
#'
#' @return list with only names in intersect(names(x),~keys) is returned
#' @export
#'
#' @examples
#' a = list(a=1,b=2,c=3)
#' k1 = c('a','c','d')
#' k2 = c(a="x",b=9,d='qq')
#' k3 = list(a='x',x='x2',c='ff')
#' ysubset_list_named(a,k1) # list(a=1,c=3)
#' ysubset_list_named(a,k2) # list(a=1,b=2)
#' ysubset_list_named(a,k3) # list(a=1,c=3)
#'
ysubset_list_named = function(x,keys){
    stopifnot(is.list(x))
    xnames = names(x)
    knames = names(keys)
    if (is.null(knames)){
        knames = keys
    }
    nm = intersect(xnames,knames)
    return(x[nm])
}

# ----------- df utils ----------------
#' Check whether a DataFrame has true rownames
#'
#' @details check whether a data.frame has rownames or not TRUE if there is a rownames vector not like 1:N (The natural one) else FALSE 一般用来确定diff expr等data.frame是否有symbol作为rownames，还是没有rownames，symbol为data.frame的一列
#'
#' @param df must be an obj whose class is data.frame
#'
#' @return TRUE or FALSE
#' @export
#'
#' @examples
yhas_rownames = function(df){
    if(is.data.frame(df)){
        rn = .row_names_info(df)
        if (rn <= 0) return(FALSE)
        else return(TRUE)
    }else{
        stop('df must be data.frame type')
    }
}

#' Convert column named data.frame to named list
#'
#' Convert a data.frame into list in length of ncol(df), with names(list) is the df's colnames
#' and each
#'
#' @param df a data.frame object
#'
#' @return list
#' @export
#'
#' @examples
ydeframe = function(df){
    rn = rownames(df)
    res = list()
    for (col in colnames(df)){
        res[[col]] = df[,col]
        names(res[[col]]) <- rn
    }
    res
}

#' display a dataframe/matrix table with more rows and columns displayed
#'
#' @description used with Jupyter notebook display of data table, Need View function available at Global.Env
#'
#' @param mat the dataframe/matrix to be displayed
#' @param nrowmax the max number of rows to display
#' @param ncolmax the max number of columns to display
#'
#' @return NULL
#' @export
#'
#' @examples
#'
#' \dontrun{
#'  data(mtcars)
#'  echo(mtcars)
#' }
#'
#'
echo = function(mat,nrowmax = 100,ncolmax=100){
    cur_nrow = getOption("repr.matrix.max.rows")
    cur_ncol = getOption("repr.matrix.max.cols")
    col = min(ncolmax,ncol(mat))
    row = min(nrowmax,nrow(mat))
    options(repr.matrix.max.cols=max(30,col))
    options(repr.matrix.max.rows=max(10,row))
    View(mat)
    options(repr.matrix.max.cols=cur_ncol)
    options(repr.matrix.max.rows=cur_nrow)
}

#' fill NA values in a mat, prefer to be used with pipe \%>\% operators
#'
#' @description  can be easily placed in a pipe line \%>\%
#'
#' @param mat a matrix or data.frame
#' @param value value to replace NA values in the mat
#'
#' @return mat with NA filled with value
#' @export
#'
#' @examples
fill_na = function(mat,value){
    mat[is.na(mat)] <- value
    mat
}

#' calculate Z-score of each row
#'
#' Z-score = (x-mean) / sd, calculate Z-score of each row
#'
#' @param x matrix of number
#'
#' @return row Z-scored matrix
#' @export
#'
#' @examples
#'
yscale_rows = function(x){
    m = apply(x, 1, mean, na.rm = T)
    s = apply(x, 1, stats::sd, na.rm = T)
    return((x - m) / s)
}

# ----------- view utils ----------------

#' Set the size for the following plots
#' @description  basically, this function affects the following plot function which will use global var WIDTH and HEIGHT
#'   to determine the display repr.plot.width and repr.plot.height, set global variables depend on the third parameter
#'   `.set_global`
#' @param w set global WIDHT,  in inch, if length(w) == 2
#' @param h set global HEIGHT, in inch
#' @param .set_global TRUE, set global vars, else no global variables set
#'
#' @return Nothing is returned
#' @export
#'
#' @examples
make.custom = function (w=NULL, h=NULL, .set_global = TRUE) {
    if (is.null(w) && is.null(h)){
        return(c(WIDTH,HEIGHT))
    }
    l = length(w)
    if (l==2){
        h = w[[2]]
        w = w[[1]]
    }else if(l == 1){
        stopifnot(!is.null(h))
    }else{
        stop('wrong w,h value')
    }
    options(repr.plot.width = w, repr.plot.height = h)
    if (.set_global == TRUE) {
        assign("WIDTH", value = w, envir = .GlobalEnv)
        assign("HEIGHT", value = h, envir = .GlobalEnv)
    }
}

#' Title
#'
#' @param .set_global
#'
#' @return Nothing is returned
#' @export
#'
#' @examples
make.tall = function(.set_global=TRUE){
    options(repr.plot.width=6
            ,repr.plot.height=8
            #         ,repr.matrix.max.cols=30
            #         ,repr.matrix.max.rows=10
    )
    if (.set_global==TRUE){
        assign('WIDTH',value = 6, envir = .GlobalEnv)
        assign('HEIGHT',value = 8, envir = .GlobalEnv)
    }
}

#' Title
#'
#' @param .set_global
#'
#' @return
#' @export
#'
#' @examples
make.wide = function(.set_global=TRUE){
    options(repr.plot.width=12
            ,repr.plot.height=8
            #         ,repr.matrix.max.cols=30
            #         ,repr.matrix.max.rows=10
    )
    if (.set_global==TRUE){
        assign('WIDTH',value = 12, envir = .GlobalEnv)
        assign('HEIGHT',value = 8, envir = .GlobalEnv)
    }
}

#' @export
print.y.GSEA.plots <- function(x) {
    # Display only the ggplot object
    for (n in names(x)){
        IRdisplay::display(x[[n]]$gg)
    }
}

#' @export
print.y.GSEA.plot <- function(x) {
    # Display only the ggplot object
    make.custom(x$figsize)
    IRdisplay::display(x$gg)
}

#' @export
print.y.GSEA.resx <- function(x){
    print(paste(length(x),'y.GSEA.res objects.','You can use yplot_GSEA_res to generate and view the plots.'))
    for (n in names(x)){
        print(x[[n]])
    }
}

#' @export
print.y.GSEA.res <- function(x){
    msg = str_flatten(c('GSEA of ',x$gsea.set,' with ranked ',length(x$gene_list),' genes resulting in ',nrow(x$res.tb.gsea),'significant enrichments under filters:'))
    msg = c(msg, paste0('p.adjust.t = ',x$p.adjust.t),
            paste0('p.t = ',x$p.t),
            paste0('pvalueCutoff = ', x$pvalueCutoff)
    )
    print(str_flatten(msg,collapse = '  '))
}

#' Title
#'
#' @param pvalues a numeric vector
#'
#' @return character, * formatted pvalues
#' @export
#'
#' @examples
ypvalue_add_asterisks = function(pvalues) {
    pvalues %>% purrr::map_chr(function(p){
        if (p < 0.0001){
            return('****')
        }else if (p < 0.001) {
            return("***")
        } else if (p < 0.01) {
            return("**")
        } else if (p < 0.05) {
            return("*")
        } else {
            return("ns") # not significant
        }
    })
}
