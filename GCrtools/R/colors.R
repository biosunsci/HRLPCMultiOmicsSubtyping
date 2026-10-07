#' Title
#'
#' @param name
#'
#' @return list of colors
#' @export
#'
#' @examples
ygen_set_color_scheme = function(name='wjw'){
    gg_color_hue <- function(n,start=15) {
        hues = seq(start, 360 + start, length = n + 1)
        hcl(h = hues, l = 65, c = 100)[1:n]
    }
    if (name=='sh'){
        # 胜寒1
        COL_SNV = c("#464E2B", "#A8352A", "#B2DF8A",
                    "#33A02C", "#FB9A99", "#559FCD",
                    "#FDBF6F", "#F1AE3C", "#CAB2D6",
                    "#8dd3c7", "#6B53BA")
        names(COL_SNV) = c("Frame_Shift_Del", "Missense_Mutation", "Frame_Shift_Ins",
                           "Splice_Site", "Translation_Start_Site","Nonsense_Mutation",
                           "Nonstop_Mutation", "In_Frame_Del","In_Frame_Ins",
                           "5'Flank","Multi_Hit")

        COL_CNV = c("#464E2B", "#559FCD", "#B2DF8A",
                    "#33A02C", "#FB9A99", "#A8352A",
                    "#FDBF6F", "#559FCD", "#A8352A",
                    "#8dd3c7", "#6B4B98")
        names(COL_CNV) = c("Frame_Shift_Del", "Missense_Mutation", "Frame_Shift_Ins",
                           "Splice_Site", "Translation_Start_Site","Nonsense_Mutation",
                           "Nonstop_Mutation", "In_Frame_Del","In_Frame_Ins",
                           "5'Flank","Multi_Hit")

        # # 蓝灰 藏蓝 深蓝 浅蓝
        # COL_ANNO = c('#b1b8d4','#3c2e43','#073763','#0B5394')[1:length(grps)]
        # names(COL_ANNO) = grps

        COL_TITV = c("#36312F",'#8A7D7D','#A8352A','#559FCD','#DAE2ED','#F2AC3C')
        names(COL_TITV) = c("C>A", "C>G", "C>T", "T>C", "T>A", "T>G")

    }else if (name == 'wjw'){
        # 金旺1
        COL_SNV = c("#A6CEE3", "#1F78B4", "#B2DF8A",
                    "#33A02C", "#FB9A99", "#E31A1C",
                    "#FDBF6F", "#FF7F00", "#CAB2D6",
                    "#8dd3c7", "#6A3D9A")
        names(COL_SNV) = c("Frame_Shift_Del", "Missense_Mutation", "Frame_Shift_Ins",
                           "Splice_Site", "Translation_Start_Site","Nonsense_Mutation",
                           "Nonstop_Mutation", "In_Frame_Del","In_Frame_Ins",
                           "5'Flank","Multi_Hit")

        COL_CNV = c("#3653A5","#BFC2D7","#E21A21","#E5B3B8",
                    "#464E2B", "#559FCD", "#B2DF8A", "#33A02C",
                    "#A8352A", "#8dd3c7", "#6B4B98")

        names(COL_CNV) = c("Frame_Shift_Del",'In_Frame_Del',"Frame_Shift_Ins","In_Frame_Ins",
                           "Missense_Mutation", "Splice_Site", "Translation_Start_Site","Nonsense_Mutation",
                           "Nonstop_Mutation","5'Flank","Multi_Hit")
        # COL_ANNO = c('#C2171D','#3A7FB7','#964E9B','#F67C1E','#E7D712',
        #             "#36312F",'#8A7D7D','#A8352A','#559FCD','#DAE2ED','#F2AC3C')[1:length(grps)]
        # names(COL_ANNO) = grps

        COL_TITV = gg_color_hue(6,start=0) #c("#36312F",'#8A7D7D','#A8352A','#559FCD','#DAE2ED','#F2AC3C')
        names(COL_TITV) = c("C>A", "C>G", "C>T", "T>C", "T>A", "T>G")
    } else{
        COL_SNV = c("#464E2B", "#A8352A", "#B2DF8A",
                    "#33A02C", "#FB9A99", "#559FCD",
                    "#FDBF6F", "#F1AE3C", "#CAB2D6",
                    "#8dd3c7", "#6B53BA")
        names(COL_SNV) = c("Frame_Shift_Del", "Missense_Mutation", "Frame_Shift_Ins",
                           "Splice_Site", "Translation_Start_Site","Nonsense_Mutation",
                           "Nonstop_Mutation", "In_Frame_Del","In_Frame_Ins",
                           "5'Flank","Multi_Hit")

        COL_CNV = c("#464E2B", "#559FCD", "#B2DF8A",
                    "#33A02C", "#FB9A99", "#A8352A",
                    "#FDBF6F", "#559FCD", "#A8352A",
                    "#8dd3c7", "#6B4B98")
        names(COL_CNV) = c("Frame_Shift_Del", "Missense_Mutation", "Frame_Shift_Ins",
                           "Splice_Site", "Translation_Start_Site","Nonsense_Mutation",
                           "Nonstop_Mutation", "In_Frame_Del","In_Frame_Ins",
                           "5'Flank","Multi_Hit")
        # COL_ANNO = gg_color_hue(length(grps))
        # names(COL_ANNO) = grps
        COL_TITV = gg_color_hue(6,start=50)#c("#36312F",'#8A7D7D','#A8352A','#559FCD','#DAE2ED','#F2AC3C')
        names(COL_TITV) = c("C>A", "C>G", "C>T", "T>C", "T>A", "T>G")
    }
    assign('COL_CNV', COL_CNV, envir = .GlobalEnv)
    assign('COL_SNV', COL_SNV, envir = .GlobalEnv)
    # assign('COL_ANNO', COL_ANNO, envir = .GlobalEnv)
    assign('COL_TITV', COL_TITV, envir = .GlobalEnv)
    print("global var COL_SNV, COL_CNV, COL_TITV have been set.")
}
