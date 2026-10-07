#' DO diff expr analysis of paired or unpaired data
#'
#' @description assert colnames(cnt.sorted)==rownames(colData.sorted)
#'
#' @param cnt.sorted rows are genes, columns are TSBs (Tumor Sample Barcode of samples)
#' @param colData.sorted rows are TSBs and columns are groups, 列名至少包含['Tumor_Sample_Barcode','Clin_classification'] for
#'   @paired=F 列名至少包含['ap','a','g'] for @paired=T, make sure all this columns are not factors!
#' @param paired Do paired test or un-paired test
#' @param levels set compare order, the first in @levels is used as the control group.
#' @param ...
#'
#' @return list named c(diff_expr,compare_order,tag_to_add,diff_expr_details)
#' @export
#'
#' @examples
ydo_count_diffexpr_deseq2 = function(cnt.sorted,colData.sorted, col.id='Tumor_Sample_Barcode'
                                     ,col.group='Clin_classification',paired=FALSE,levels=NULL,.retSimpleTable=TRUE,...){

    if (is.null(levels)){
        if (paired==TRUE){
            stopifnot('g' %in% colnames(colData.sorted))
            if (col.group=='Clin_classification'){
                col.group = 'g'
            }
        }
        if (is.factor(colData.sorted[[col.group]])){
            print(paste('warning',col.group,'is factor convert it into charactors'))
            colData.sorted[[col.group]] = as.character(colData.sorted[[col.group]])
        }
        levels = colData.sorted[[col.group]] %>% unique
    }

    if (colData.sorted %>% has_rownames) {
        stopifnot((colnames(cnt.sorted) == rownames(colData.sorted)) %>% all)
        colData.sorted = colData.sorted %>% rownames_to_column(col.id)
    }else{
        stopifnot((colnames(cnt.sorted) == colData.sorted[[col.id]]) %>% all)
    }

    if (is.data.frame(cnt.sorted)){
        cnt.sorted = as.matrix(cnt.sorted)
    }
    sym.col.id = sym(col.id)
    sym.col.group = sym(col.group)

    if (paired==TRUE){
        #         stopifnot(colData.sorted %>% has_colnames('a'))
        #         stopifnot(colData.sorted %>% has_colnames('g'))
        colData = colData.sorted %>%
            select(!!sym.col.id,a,g) %>%
            mutate(a=factor(a),g=factor(g,levels=levels)) %>%
            arrange(a,g) %>%
            column_to_rownames(col.id)
    }else{
        colData = colData.sorted %>%
            select(a=!!sym.col.id,!!sym.col.group) %>%
            mutate(g=factor(!!sym.col.group,levels=levels)) %>%
            arrange(a,g) %>%
            column_to_rownames("a")
    }

    cnt.sorted = cnt.sorted[,row.names(colData)]

    x = alist()
    x$compare_ref_group = levels[[1]]
    x$compare_order = rev(levels)
    x$tag_to_add = x$compare_order %>% str_flatten(collapse = '_vs_')

    if(paired==TRUE){
        dds_paired  = DESeq2::DESeqDataSetFromMatrix(cnt.sorted, colData = colData, design= ~ a + g)
        paired_prop = 'paired'
    }else{
        dds_paired  = DESeq2::DESeqDataSetFromMatrix(cnt.sorted, colData = colData, design= ~ g)
        paired_prop = 'unpaired'
    }
    print('-------------------------------------------------------------')
    print(paste0('Comparing > ',paired_prop,' < ',x$tag_to_add,', REF_GROUP = ',x$compare_ref_group))
    print('-------------------------------------------------------------')

    # set control group for comparation
    dds_paired$group <- relevel(dds_paired$g, ref = levels[[1]])
    dds_paired <- DESeq2::DESeq(dds_paired)
    # get result table
    diff_expr <- as.data.frame(DESeq2::results(dds_paired)) %>%
        mutate(abs_log2FC = abs(log2FoldChange),.before = lfcSE) %>%
        arrange(pvalue,log2FoldChange)
    # pack add info
    x$cnt_table = cnt.sorted
    x$colData = colData
    x$diff_expr = diff_expr
    x$paired = paired
    # x$dds_dif_exp_matrix=ddsDifExpMatrix
    class(x) <- c('DEA.results',class(x))
    print('Done')
    return (x)
}

# library(limma)

#' @description  like ydo_count_diffexpr_deseq2,  but used with numeric value but not count values
#'
#' @param numeric.sorted rows are genes, columns are TSBs (Tumor Sample Barcode of samples)
#' @param colData.sorted rows are TSBs and columns are groups, 列名至少包含[col.id = 'Tumor_Sample_Barcode',col.group = 'Clin_classification']
#' @param col.id id as rownames of colData.sorted, usually Tumor_Sample_Barcode
#' @param col.group group column in colData.sorted
#' @param level_order compare order, The first level in levels will be control group(Denominator) in DEG
#'   results. the first one is used as the control CTL, for example, if levels = c(CTL, EXP) then
#'   the result log2FoldChange > 0 if EXP > CTL
#'
#'
#' @return
#' @export
#'
#' @examples
ydo_numeric_DEG_limma = function (numeric.sorted, colData.sorted, col.id = "Tumor_Sample_Barcode", 
    col.group = "Clin_classification", paired=FALSE, col.paired=NULL, level_order = NULL) {
    if (!colData.sorted %>% has_rownames) {
        colData.sorted = colData.sorted %>% column_to_rownames(col.id)
    }
    stopifnot((colnames(numeric.sorted) == rownames(colData.sorted)) %>% 
        all)
    if (is.data.frame(numeric.sorted)) {
        numeric.sorted = as.matrix(numeric.sorted)
    }
    stopifnot(col.group %in% colnames(colData.sorted))

    cn.ori = colnames(numeric.sorted)
    cn.ok = cn.ori %>% make.names
    rownames(colData.sorted) = cn.ok
    colnames(numeric.sorted) = cn.ok
    gval.ori = colData.sorted[[col.group]]
    gval.ok = gval.ori %>% make.names
    colData.sorted[[col.group]] = gval.ok
    
    if (is.null(level_order)) {
        lvls = colData.sorted[[col.group]] %>% unique()
        lvl.ori = lvls 
        lvls = lvls %>% make.names
        map.lvls = structure(lvl.ori, names = lvls)
        print(lvls)
    }
    else {
        lvl.ori = level_order 
        lvls = lvl.ori %>% make.names
        map.lvls = structure(lvl.ori, names = lvls)
        .i = lvls[1]
        lvls = c(lvls[2:length(lvls)], .i)
    }
    if (paired==FALSE){
        contrast_order = stringr::str_flatten(lvls, collapse = " - ")
        colData.sorted = colData.sorted %>% 
            mutate(!!sym(col.group):= !!sym(col.group) %>% factor(levels = lvls))
        cat("-------------------------------------------------------------\n")
        cat("Comparing > ", "unpaired", " < ", contrast_order, 
            ", REF_GROUP = ", lvls[length(lvls)],'\n')
        cat("-------------------------------------------------------------\n")
        #return(list(contrast_order,colData.sorted,numeric.sorted,col.paired,col.group,lvls))
        design <- stats::model.matrix(~ factor(colData.sorted[[col.group]]) - 1)
        colnames(design) = lvls
        fit <- limma::lmFit(numeric.sorted, design)
        contrast.matrix <- limma::makeContrasts(contrasts = contrast_order, 
            levels = design)
        fit2 = limma::contrasts.fit(fit, contrast.matrix)
        fit2 <- limma::eBayes(fit2)
        results <- limma::topTable(fit2, coef = 1, number = Inf)
    }else{
        stopifnot(!is.null(col.paired) && col.paired %in% colnames(colData.sorted))
        pe = colData.sorted[colData.sorted[[col.group]] == lvls[1], col.paired] %>% sort
        pc = colData.sorted[colData.sorted[[col.group]] == lvls[2], col.paired] %>% sort
        if (!(length(pe)==length(pc) && all(pe == pc))){
            stop('! 两组间的患者id数目/名称不匹配' )
        }
        colData.sorted[[col.paired]] = colData.sorted[[col.paired]] %>% make.names
        contrast_order = paste0(' - ', col.group, lvls[[length(lvls)]])
        cat("-------------------------------------------------------------\n")
        cat("Comparing > ", "paired", " < paired by ", col.paired ,', ordered by ', lvl.ori,
            ", REF_GROUP = ", map.lvls[[lvls[length(lvls)]]],'\n')
        cat("-------------------------------------------------------------\n")
        colData.sorted = colData.sorted %>% 
            mutate(!!sym(col.paired):= !!sym(col.paired) %>% factor(),
                    !!sym(col.group):= !!sym(col.group) %>% factor(levels = lvls),
                   )
        #return(list(contrast_order,colData.sorted,numeric.sorted,col.paired,col.group))
        formu = as.formula(paste('~',col.paired,'+',col.group))
        design <- stats::model.matrix(formu, data = colData.sorted)
        fit <- limma::lmFit(numeric.sorted, design)
        contrast.matrix <- limma::makeContrasts(contrasts = contrast_order, levels = design)
        rn = rownames(contrast.matrix)
        if (rn[1] == 'Intercept'){
            rn = c('(Intercept)',rn[2:length(rn)])
            rownames(contrast.matrix) = rn
        }
        fit2 = limma::contrasts.fit(fit, contrast.matrix)
        fit2 <- limma::eBayes(fit2)
        results <- limma::topTable(fit2, number = Inf)
    }
    
    colnames(results) = c("DeltaValue", "baseMean", "t", 
        "pvalue", "padj", "B")
    results$stat = results$t
    results$abs_DeltaValue = abs(results$DeltaValue)
    results$Delta_Ins = results$DeltaValue > 0
    

    for (i in lvls) {
        mat = numeric.sorted[rownames(results), gval.ok == i]
        results[[paste0("median_", map.lvls[[i]])]] = matrixStats::rowMedians(mat)
        results[[paste0("mean_", map.lvls[[i]])]] = matrixStats::rowMeans2(mat)
    }
    max_range = max(results$abs_DeltaValue)
    # results$log2FoldChange = log2(results[[paste0("mean_", map.lvls[length(map.lvls)])]]/results[[paste0("mean_", map.lvls[1])]])
    results = results %>% mutate(log2Delta = log2(DeltaValue+0.0001*max_range),
                             abs_log2Delta = abs(log2Delta)
                            )
    results %>% rownames_to_column("symbol")
}
