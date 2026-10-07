#' Plot heatmap using ComplexHeatmap
#'
#' @param mat matrix, usually columns is tsb, if not matrix, will try to coerce using [as.matrix()]
#' @param colData None, or the data.frame with rownames (is tsb) must be accord with colnames(`mat`) and columns of
#'   colData will be draw at the top annotation of Heatmap, each column a line
#' @param annotation_colors define the colors used for draw top annotation, representing colData
#' @param scale default 'auto', use [yscale_rows()] to standardize each rows
#' @param sel_id_col if colData do not has rownames, use this column as rownames and remove sel_id_col column in colData
#' @param by_group if colData provided, TRUE will use the first column in colData as 
#'        group columnn(sel_id_col does not take into account), if character, search by_group as column name in colData 
#'        and use this column as group column, set to NULL or FALSE to avoid group across columns
#' @param params_top_annotation plotting params to draw top annotation
#' @param cluster_rows pass to ComplexHeatmap::Heatmap()
#' @param cluster_columns pass to ComplexHeatmap::Heatmap()
#' @param clustering_method_columns pass to ComplexHeatmap::Heatmap()
#' @param clustering_method_rows pass to ComplexHeatmap::Heatmap()
#' @param name pass to ComplexHeatmap::Heatmap()
#' @param row_title pass to ComplexHeatmap::Heatmap()
#' @param show_row_dend pass to ComplexHeatmap::Heatmap()
#' @param show_column_dend pass to ComplexHeatmap::Heatmap()
#' @param show_row_names pass to ComplexHeatmap::Heatmap()
#' @param show_column_names pass to ComplexHeatmap::Heatmap()
#' @param color in format 'Num1~Num2',default '-2~2', will be converted to [circlize::colorRamp()] function then pass to
#'   ComplexHeatmap::Heatmap() as col. if the two Nums span 0, then 0 will be inserted into the middle
#'   ELSE you can provide a custom [circlize::colorRamp()] object
#' @param column_split pass to ComplexHeatmap::Heatmap()
#' @param heatmap_legend_param pass to ComplexHeatmap::Heatmap()
#' @param ... other legal params pass to ComplexHeatmap::Heatmap()
#'
#' @return list with ggplot obj, ComplexHeatmap object and other parameters' values
#' @export
#'
#' @examples
#' \dontrun{
#'
#'     mat = matrix(1:12,nrow=4)
#' }
#'
yplot_heatmap = function(
        mat
        ,colData = NULL
        ,annotation_colors = NULL
        ,scale="auto"
        ,by_group = TRUE
        ,params_top_annotation = NULL    
        ,sel_id_col = 'Custom_Label'
        
        ,cluster_rows = TRUE
        ,cluster_columns = TRUE
        ,clustering_method_columns = 'ward.D2'
        ,clustering_method_rows = 'ward.D2'
        ,name = 'Z-Score'
        ,row_title=NA
        ,show_row_dend = TRUE
        ,show_column_dend = TRUE
        ,show_row_names = TRUE
        ,show_column_names = TRUE
        ,color = '-2~2'
        ,column_split = NULL
        ,heatmap_legend_param = NULL
        ,...){

    if (! 'matrix' %in% class(mat)){
        mat %<>% as.matrix
    }

    if (is.null(colData)){
        .ha = NULL
        if (by_group != FALSE){
            by_group = FALSE
            print('colData is None, set by_group = FALSE')
        }
    }else{
        if (! 'data.frame' %in% class(colData)){
            colData %<>% as.data.frame
        }

        .text_width = ComplexHeatmap::max_text_width(
            rownames(mat),
            gp = grid::gpar(fontsize = 12)
        )
        cn = colnames(colData)

        if (!yhas_rownames(colData)){
            if (sel_id_col %in% cn){
                sel = sel_id_col
            } else stop('sel_id_col = ',sel_id_col,' must in colnames(colData)')
            colData %<>% tibble::column_to_rownames(sel)
        }

        colData %<>% mutate(across(!where(is.factor),factor))
        .group = ydeframe(colData)

        if (!is.null(annotation_colors) && !is.na(annotation_colors)){
            .group$col = annotation_colors
        }
        if (!is.null(params_top_annotation)){
            stopifnot(is.list(params_top_annotation))
            .group = utils::modifyList(.group,params_top_annotation)
        }
        .ha = do.call(ComplexHeatmap::HeatmapAnnotation, args = .group)
    }

    if (by_group==TRUE){
        .column_split = .group[[1]]
    }else if (is.character(by_group)){
        stopifnot(by_group %in% names(.group))
        .column_split = .group[[by_group]]
    }else{
        .column_split = column_split
    }

    .text_width = ComplexHeatmap::max_text_width(
        rownames(mat),
        gp = grid::gpar(fontsize = 12)
    )

    if (is.null(scale) || is.na(scale)){
        # pass
        use_scale = FALSE
    }else{
        if (mat %>%
            apply(1,stats::sd) %>%
            { abs(. - 1) < sqrt(.Machine$double.eps) } %>%
            all &&
            mat %>%
            apply(1,mean) %>%
            { abs(.) < sqrt(.Machine$double.eps) } %>%
            all){
            print('mat is already z-scored')
            use_scale = FALSE
        }else{
            use_scale = TRUE
        }
    }
    if (use_scale){
        if (scale == TRUE || scale == 'auto'){
            mat %<>% yscale_rows
            print(paste0("scale == ",scale,", use yscale_rows"))
        }else if (is.function(scale)){
            mat %<>% apply(1, scale)
            print('scale == TRUE, use apply(1, scale)')
        }else if(scale == 'none' || scale == FALSE){
            # pass
        }
    }
    if (is.null(heatmap_legend_param)){
        heatmap_legend_param = list(title=name)
    }
    if ('color' %in% names(heatmap_legend_param)){
        color = heatmap_legend_param$color
        heatmap_legend_param$color = NULL
    }

    if (is.character(color)){
        if (color == '-2~2' || color == 'default'){
            color = circlize::colorRamp2(breaks = c(-2, 0, 2),colors =  c("blue", "white", "red"), space = 'RGB')
        }else if (str_detect(color,'~')){
            tryCatch(expr = {
                x = str_split(color,'~')[[1]] %>% as.numeric
            },warning = function(w){
                stop(w)
            },error=function(e){
                stop(e)
            }
            )
            if (length(x)==2){
                if (x[[1]] * x[[2]] < 0){
                    x = c(x[[1]],0,x[[2]])
                    color = circlize::colorRamp2(breaks = x, colors =  c("blue", "white", "red")[1:length(x)], space = 'RGB')
                }else if (x[[1]] * x[[2]] == 0){
                    if (x[[1]] < x[[2]] && x[[1]]==0) color = circlize::colorRamp2(breaks = x, colors = c("white", "red")[1:length(x)], space = 'RGB')
                    else if(x[[1]] < x[[2]] && x[[2]]==0) color = circlize::colorRamp2(breaks = x, colors = c("blue", "white")[1:length(x)], space = 'RGB') 
                    else if(x[[1]] > x[[2]] && x[[1]]==0) color = circlize::colorRamp2(breaks = x, colors = c("white", "blue")[1:length(x)], space = 'RGB') 
                    else if(x[[1]] > x[[2]] && x[[2]]==0) color = circlize::colorRamp2(breaks = x, colors = c("red", "white")[1:length(x)], space = 'RGB') 
                    else if(x[[1]]==x[[2]]) stop(paste("color prompt string err, boundaries can't be equal:",color))
                    else stop(paste('color prompt string parse err', color))
                }else{
                    color = circlize::colorRamp2(breaks = x, colors = c("blue", "red")[1:length(x)], space = 'RGB')
                }
                
            }else {
                color = circlize::colorRamp2(breaks = x, colors = rainbow(length(x)), space = 'RGB')
            }
        }else{
            # pass
        }
    }else if (is.function(color)){

    }else{
        stop('color must be function or a color vector')
    }
    hm = ComplexHeatmap::Heatmap(mat
                                 ,col = color
                                 ,name = name
                                 ,clustering_method_columns = clustering_method_columns
                                 ,clustering_method_rows = clustering_method_rows
                                 # ,row_names_side = 'left'

                                 ,row_title = row_title
                                 ,show_row_dend = show_row_dend
                                 ,show_column_dend = show_column_dend
                                 ,show_row_names = show_row_names
                                 ,show_column_names = show_column_names

                                 ,heatmap_legend_param = heatmap_legend_param
                                 ,top_annotation = .ha
                                 ,column_split = .column_split
                                 ,row_names_max_width = .text_width
                                 ,cluster_rows = cluster_rows
                                 ,cluster_columns = cluster_columns
                                 # ,row_split = 4
                                 # ,cluster_columns = cluster_within_group(mat, group)
                                 ,...
    )
    gg.hm = ggplotify::as.ggplot(hm)

    list(gg=gg.hm
         ,heatmap=hm
         ,mat=mat
         ,colData=colData
         ,HeatmapAnnotation=.ha
         ,params=list(mat
                      ,clustering_method_columns = clustering_method_columns
                      ,clustering_method_rows = clustering_method_rows
                      ,name = name
                      ,color = color
                      ,row_title = row_title
                      ,show_row_dend = show_row_dend
                      ,show_column_dend = show_column_dend
                      ,show_row_names = show_row_names
                      ,show_column_names = show_column_names
                      ,top_annotation = .ha
                      ,column_split = .column_split
                      ,row_names_max_width = .text_width
                      ,heatmap_legend_param = heatmap_legend_param
                      ,...)
    )
}

#' Plot volcano plot
#'
#' @param diff_expr RNA diff expr, colnames are:
#'   'baseMean','log2FoldChange','abs_log2FC','lfcSE','stat','pvalue','padj'
#' @param value_var ='padj', column name which used for filter
#' @param add_label whether to add the label text of genes
#' @param ...
#' @param logFC_threshold vector of length 2, the log2FoldChange threshold
#' @param p.t pvalue filter threshold which apply to `value_var` column
#'
#' @return list(gg=ggplot,de=data.frame)
#' @export
#'
#' @examples
yplot_volcano_using_de = function (diff_expr,
                                   value_var = "padj",
                                   logFC_threshold = c(-2, 2),
                                   p.t = 0.05,
                                   add_label = FALSE,
                                   ...) {
    if (diff_expr %>% is.data.frame) {
        de = diff_expr
    }
    else {
        de = diff_expr %>% data.frame
    }
    if (length(logFC_threshold)==1){
        logFC_threshold = abs(logFC_threshold)
        logFC_threshold = c(-logFC_threshold,logFC_threshold)
    }
    de$diffexpressed <- "NO"
    de$diffexpressed[de$log2FoldChange > logFC_threshold[2] &
                         de[[value_var]] <
                         p.t] <- "UP"
    de$diffexpressed[de$log2FoldChange < logFC_threshold[1] &
                         de[[value_var]] <
                         p.t] <- "DOWN"
    de$diffexpressed = factor(de$diffexpressed, levels = c('DOWN', 'NO', 'UP'))
    de$y = -log10(de[[value_var]])

    if (add_label) {
        library(ggrepel)
        de$delabel <- NA
        de$gene_symbol = de %>% rownames
        de$delabel[de$diffexpressed != "NO"] <-
            de$gene_symbol[de$diffexpressed !=
                               "NO"]
        g <- ggplot(data = de,
                    aes(
                        x = log2FoldChange,
                        y = y,
                        col = diffexpressed,
                        label = delabel
                    )) + geom_point(alpha = 0.7) +
            geom_text_repel(max.iter = 10, box.padding = 1)
    }
    else {
        g <- ggplot(data = de, aes(x = log2FoldChange, y = y,
                                   col = diffexpressed)) +
            geom_point(alpha = 0.7)
    }
    if (value_var == "padj") {
        old_value_var = value_var
        value_var = "FDR"
    }
    g = g + theme_minimal() +
        ylab(paste0("-log10(", value_var,
                    ")")) +
        scale_color_manual(values = c("blue", "gray",
                                      "red")) +
        geom_vline(xintercept = logFC_threshold,
                   col = "gray",
                   linetype = "longdash") +
        geom_hline(
            yintercept = -log10(p.t),
            col = "gray",
            linetype = "longdash"
        )
    list(gg = g, de = de)
}

#' guess group column name in the data.frame
#'
#' @param df
#'
#' @return colnames vector
#' @export
#'
#' @examples
yinfer_group_col = function(df,group_col=NA,raiseError=TRUE){
    col = colnames(df)
    if (is.na(group_col)) {
        if ("Group" %in% col)
            group_col = "Group"
        else if ("Clin_classification" %in% col)
            group_col = "Clin_classification"
        else if ("g" %in% col)
            group_col = "g"
        else {
            if (raiseError){
                stop("can not determine group_col in df, stop")
            }else
                return(NULL)
        }
    }
    group_col
}

#' t-SNE analysis for mat
#'
#' @param normd data.fram or matrix, only columns will be preserved, rows will be ruduced in dimensions
#' @param colData
#' @param mat
#' @param group_col
#' @param perplexity
#' @param dims
#' @param ...
#'
#' @return if .ret==TRUE return res object else Nothing is returned
#' @export
#'
#' @examples
yplot_tsne = function (normd = NULL, colData = NULL, mat = NULL, color_col = NULL,
                       add_label = FALSE, add_polygon=FALSE,
                       perplexity = NA, dims = 2, .ret=FALSE, ...) {
    if (is.null(mat)) {
        mat = t(normd)
        pids = colnames(normd)
    }
    else {
        pids = rownames(mat)
    }
    if (is.na(perplexity)) {
        perplexity = floor((nrow(mat) - 1)/3)
    }

    stopifnot(!is.null(colData) && !is.null(mat))
    res = Rtsne::Rtsne(mat, perplexity = perplexity, dims = dims, ...)
    df = res$Y %>% data.frame(row.names = pids)
    colData2 = colData[pids, , drop = FALSE]
    df = cbind(df, colData2)
    res$data = df

    if (is.null(color_col)){
        group_col = yinfer_group_col(colData,raiseError = FALSE)
        if (is.null(group_col)){
            print("can not determine group_col in colData, stop plotting")
            return(res)
        }
        color_col = sym(group_col)
    }else{
        color_col = sym(color_col)
    }
    gg = df %>% ggplot(aes(x = X1, y = X2, color = !!color_col)) +
        geom_point(size = 3, alpha = 0.7) + ggtitle("t-SNE")
    if (add_polygon){
        gg = gg + stat_ellipse(aes(fill=!!color_col), show.legend = FALSE,
                     geom = "polygon",
                     alpha=0.1,
                     lwd = 0.5)
    }
    res$gg = gg
    if (.ret==TRUE){
        return(res)
    }else{
        print(gg)
    }
}
