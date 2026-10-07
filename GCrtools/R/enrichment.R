#  ----------------- Private Global VAR ---------------
SSGSEA_BASE_REF_DIR = './extdata/'

COMMON_GMT_TAGS = c('hm', 'kegg', 'im', 'im_jnj')

npg = ggsci::pal_npg()(10)

# ---------------- Enrich Func -----------------------------

#' GSEA analysis using different expression results
#'
#' @param gene_list list, gene symbols as names and `stat` or `p-value` as values, decreasing
#'   arranged. will overrite the diff as input
#' @param set set in c('all','all3','gsea','hm','kegg','im','im_jnj') 'all' - all the gmt sets in
#'   the  refs, currently: Hallmark, KEGG, Immune, Immune2(im_jnj) 'all3' - hm, kegg, immune do the
#'   3 gmt sets 'gsea' - hm, kegg do the 2 gmt sets 'hm','kegg','im','im_jnj' use the corresponding
#'   single gmt set
#' @param minGSSize will be passed to clusterProfiler::GSEA()
#' @param maxGSSize will be passed to clusterProfiler::GSEA()
#' @param ... will be passed to  clusterProfiler::GSEA()
#' @param p.adjust.t manual filter for GSEA result table, applied to FDR (`p.adjust`) column
#' @param p.t manual filter for GSEA result table, applied to p value (`pvalue`) column
#' @param pvalueCutoff passed into  clusterProfiler::GSEA(), controls the filter of the function,set
#'   to 1 to avoid filter at this step.
#'
#' @return a list obj of class 'y.GO.res', used for input for yplot_GO_res
#' @export
#'
#' @examples
ydo_GSEA = function (gene_list = NULL,
                     set = "gsea",
                     minGSSize = 10,
                     maxGSSize = 500,
                     p.adjust.t = 0.05,
                     p.t = 0.2,
                     pvalueCutoff = 1,
                     ...) {
    refs = list(
        hm = c(figureTitle = "Hallmark Enrichment",
               Name = "Hallmark"),
        kegg = c(figureTitle = "KEGG Enrichment",
                 Name = "KEGG"),
        im = c(figureTitle = "Immune Infiltration Enrichment",
               Name = "Immune"),
        im_jnj = c(figureTitle = "Immune Infiltration Enrichment",
                   Name = "Immune2")
    )
    if (length(set)==1){
        if (set == "all") {
            run = refs
        }
        else if (set == "gsea") {
            run = refs[c("hm", "kegg")]
        }
        else if (set == "all3") {
            run = refs[c("hm", "kegg", "im")]
        }
        else if (set %in% c("hm", "kegg", "im", "im_jnj")) {
            run = refs[set]
        }
        else {
            stop("set must in in c('all','all3','gsea','hm','kegg','im','im_jnj')")
        }
    }else{
        run = intersect(set,c("hm", "kegg", "im", "im_jnj"))
        run = refs[run]
    }
    stopifnot(length(run)>0)
    message('run ',length(run),' Enrichments ',names(run) %>% str_flatten_comma())

    res = list()
    for (key in names(run)) {
        v = run[[key]]
        figureTitle = v["figureTitle"]
        Name = v["Name"]
        gmt = yload_gmt(key)
        res.gsea = clusterProfiler::GSEA(
            geneList = gene_list,
            TERM2GENE = gmt,
            minGSSize = minGSSize,
            maxGSSize = maxGSSize,
            pAdjustMethod = "BH",
            pvalueCutoff = pvalueCutoff,
            ...
        )
        res.tb.gsea = res.gsea@result %>%
            dplyr::filter(p.adjust < p.adjust.t, pvalue < p.t)
        n.res = res.tb.gsea %>% nrow

        print(paste("after filter,", n.res, "significant results left"))
        if (n.res > 0) {
            res.tb.gsea
        }
        else {
            print(paste0(
                "[!] Handling ",  key,
                ": too less res got after filtering, consider to increase @p.adjust.t and @p.t"))
        }
        res[[key]] = list(
            gsea.set = Name,
            gene_list = gene_list,
            res.gsea = res.gsea,
            res.tb.gsea = res.tb.gsea,
            p.adjust.t = p.adjust.t,
            p.t = p.t,
            pvalueCutoff = pvalueCutoff,
            minGSSize = 10,
            maxGSSize = 500
        )
        attr(res[[key]], 'class') = c('y.GSEA.res',class(res[[key]]))
    }
    attr(res, 'class') = c('y.GSEA.resx',class(res))
    message("GSEA analysis done, now you can use yplot_")
    res
}

#' do_ssGSEA analysis
#'
#' @description depends on yload_list_gmt
#'  use the GSVA::gsea method which need 2 critical parameters
#'  a <expr_matrix> is the numeric matrix of expression, normed count of DSeq2 or tpm
#'  a <ref_gmt_list> which is the returns of yload_list_gmt, see details of yload_list_gmt documentation
#'
#' @param expr_matrix a numeric matrix witch rows are genes and columns are patients
#' @param todo list, combinations of elements in list('hm','kegg','im','im_jnj')
#'  the collections todo ssGSEA, default run all 4 process, all the keys is the keys of parameter
#'  <ref> in function `yload_list_gmt`
#' @param ref.gmt =NULL, if provided, must be a list like yload_list_gmt returns
#'  or a file_path to a gmt.txt file like in yload_list_gmt <ref>, use it as <ref_gmt_list> todo ssGSEA
#' @param ref.gmt.name =NULL, if `ref.gmt` is provided, this will be the key-name of the returned results list
#'  if is NULL, the returned list is unamed
#' @param mx.diff,verbose,method,kcdf,parallel.sz,... pass to GSVA::gsva, details see GSVA::gsva docs
#'  please keep `method` 'ssgsea' to do ssGSEA analysis
#' @return list
#' @export
#'
#' @examples
ydo_ssGSEA = function(expr_matrix,
                      todo = list('hm', 'kegg', 'im', 'im_jnj'),
                      ref.gmt = NULL,
                      ref.gmt.name = NULL,
                      mx.diff = FALSE,
                      verbose = FALSE,
                      method = 'ssgsea',
                      kcdf = 'Gaussian',
                      parallel.sz = 1,
                      ...) {
    res = list()
    if (!is.null(ref.gmt)) {
        if (is.character(ref.gmt)) {
            ref_df = yload_list_gmt(ref.gmt)
        }
        if (is.null(ref.gmt.name)) {
            ref.gmt.name = 1
        }
        es = GSVA::gsva(
            expr_matrix,
            ref_df,
            mx.diff = mx.diff,
            verbose = verbose,
            method = method,
            kcdf = kcdf,
            parallel.sz = 1
        )
        res[[ref.gmt.name]] = es
    } else{
        for (i in 1:length(todo)) {
            k = todo[[i]]
            if (!is.null(ref.gmt)) {
                ref_df = ref.gmt
            } else{
                ref_df = yload_list_gmt(k)
            }
            es = GSVA::gsva(
                expr_matrix,
                ref_df,
                mx.diff = mx.diff,
                verbose = verbose,
                method = method,
                kcdf = kcdf,
                parallel.sz = 1,
                ...
            )
            # es %>% ydumpto(flag='ssGSEA_result_',export=k,outputdir=OUTPUTROOT,row.names=T)
            res[[k]] = es
        }
    }
    res
}

# ------------- helpers --------------

#' load symbol.gmt files using [clusterProfile::read.gmt()] into data.frame format obj
#'
#' @description see docs of yload_list_gmt, yload_gmt
#'
#' @details The source of the gmt file is:
#' hm = 'h.all.v7.5.symbols.gmt',
#' kegg = 'c2.cp.kegg.v7.5.symbols.gmt',
#' im = 'immune.cell.rep.symbols.gmt',
#' im_jnj = 'immune.jnj.immunity.symbols.gmt'
#'
#' ref = list( hm='hm.df', kegg='kegg.df', im='im.df',im_jnj='im_jnj.df')
#'
#'
#' @param key one of names(`ref`), default one of c('hm','kegg','im','im_jnj'),
#' @param ref key=filename pairs list, the `key` is search in. No need to change
#' @param base_ref_dir =NULL, if NULL use global SSGSEA_BASE_REF_DIR value
#' search gmt files in the base_ref_dir folder
#'
#' @return data.frame with first column is term, and second columns is gene, like
#'                               term    gene
#' 1 HALLMARK_TNFA_SIGNALING_VIA_NFKB    JUNB
#' 2 HALLMARK_TNFA_SIGNALING_VIA_NFKB   CXCL2
#' 3 HALLMARK_TNFA_SIGNALING_VIA_NFKB    ATF3
#' 4 HALLMARK_TNFA_SIGNALING_VIA_NFKB  NFKBIA
#' 5 HALLMARK_TNFA_SIGNALING_VIA_NFKB TNFAIP3
#' ...
#' @export
#'
#' @examples
#'\dontrun{
#' gmt = yload_gmt('hm')
#' }
#'
yload_gmt = function(key = NULL,
                     base_ref_dir = NULL) {
    if (key %in% COMMON_GMT_TAGS) {
        f = file.path('extdata/', paste0(key, '.symbol.df.RDS'))
        f = system.file(f, package = 'GCrutils')
        gmt = readRDS(f)
    } else{
        print('else')
        if (is.null(base_ref_dir)) {
            base_ref_dir = SSGSEA_BASE_REF_DIR
        }
        path = file.path(base_ref_dir, key)
        stopifnot(file.exists(path))
        gmt = clusterProfiler::read.gmt(path)
    }
    gmt
}

#' read gmt file as a list
#'
#' read Gene Matrix Transposed (gmt) file and output a list with the the first
#' column as the names of items in the list. see
#' \href{http://www.broadinstitute.org/cancer/software/gsea/wiki/index.php/Data_formats}{Gene Matrix Transposed file format}
#' for more details.
#' @seealso yload_gmt
#'
#' @param gmtfile a gmt file. Examples are from MSigDB Collections.
#' A list of gene set could be find in the vignette of cogena
#' @return a gmt list
#' @export
#'
#' @seealso gmtlist2file
#' @examples
#' \dontrun{
#' anno <- "c2.cp.kegg.v7.01.symbols.gmt.xz"
#' gmtfile <- system.file("extdata", anno, package="cogena")
#' gl <- gmt2list(gmtfile)
#' }
#'
yload_gmtfile2list <- function(gmtfile) {
    if (!file.exists(gmtfile)) {
        stop("There is no such a gmt file!")
    }
    if (tools::file_ext(gmtfile) == "xz") {
        gmtfile <- xzfile(gmtfile)
        x <- scan(gmtfile,
                  what = "",
                  sep = "\n",
                  quiet = TRUE)
        close(gmtfile)
    } else if (tools::file_ext(gmtfile) == "gmt") {
        x <- scan(gmtfile,
                  what = "",
                  sep = "\n",
                  quiet = TRUE)
    } else {
        stop ("Only gmt and gmt.xz are accepted for gmt2list")
    }

    y <- strsplit(x, "\t")
    names(y) <- sapply(y, `[[`, 1)

    annoList <- lapply(y, `[`, c(-1, -2))
    return(annoList)
}

#' load gmt files using read.table into list format obj
#'
#' @description see docs of yload_list_gmt, yload_gmt
#' @seealso yload_gmt
#' @param key one of names(`ref`), default one of c('hm','kegg','im','im_jnj')
#' @param ref key=filename pairs list, the `key` is search in. No need to change
#' @param base_ref_dir =NULL, if NULL use global SSGSEA_BASE_REF_DIR value
#' @param gmt_txt_file_path =NULL, a file path string, file must the same as the files listed in the `ref`
#'  if provided, read the file of the gmt_txt_file_path, ignore all other parameters
#' @return list with names is term, and value is corresponding genes, like
#'  list(HALLMARK_ADIPOGENESIS=c('FABP4','ADIPOQ','PPARG',...),
#'      HALLMARK_ALLOGRAFT_REJECTION=c('PTPRC','IL12B','TGFB1','IL12A','CD3E',...),
#'      HALLMARK_ANDROGEN_RESPONSE=c('KLK3','KLK2','ACSL3','PIAS1','CAMKK2',...),
#'      HALLMARK_ANGIOGENESIS=c('VCAN','POSTN','FSTL1',...),
#'      ...)
#' @export
#'
#' @examples
#' \dontrun{
#' gmt.list = yload_list_gmt('hm')
#' }
yload_list_gmt = function(key = NULL,
                          base_ref_dir = NULL) {
    if (key %in% COMMON_GMT_TAGS) {
        f = file.path('extdata/', paste0(key, '.symbol.list.RDS'))
        f = system.file(f, package = 'GCrutils')
        gmt_list = readRDS(f)

    } else{
        if (is.null(base_ref_dir)){
            base_ref_dir = SSGSEA_BASE_REF_DIR
        }
        path = file.path(base_ref_dir, key)
        stopifnot(file.exists(path))
        # tmp = read.table(
        #     path,
        #     quote = '"',
        #     header = T,
        #     sep = ',',
        #     row.names = 1
        # )
        # gmt_list = split(tmp[, 1], tmp[, 2])
        gmt_list = yload_gmtfile2list(path)

    }
    gmt_list
}
