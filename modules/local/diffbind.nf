process DIFFBIND {
    tag "diffbind_analysis"
    label 'process_high'
    container 'quay.io/biocontainers/bioconductor-diffbind:3.20.0--r45ha27e39d_0'

    input:
    path samplesheet
    path bams
    path bais
    path peaks

    output:
    path "*.pdf"                       , emit: pdf, optional: true
    path "*.csv"                       , emit: csv, optional: true
    path "*_mqc.html"                  , emit: mqc_html, optional: true
    path "diffbind_correlation_mqc.txt", emit: mqc_txt, optional: true
    path "*.png"                       , emit: png, optional: true
    path "versions.yml"                , emit: versions

    script:
    """
    #!/usr/bin/env Rscript
    library(DiffBind)

    # 1. Load and fix paths
    samples <- read.csv("${samplesheet}")
    samples\$bamReads <- basename(as.character(samples\$bamReads))
    samples\$Peaks    <- basename(as.character(samples\$Peaks))
    
    if ("bamControl" %in% colnames(samples)) {
        samples\$bamControl <- basename(as.character(samples\$bamControl))
    }

    # 2. Initialize DiffBind object
    db_obj <- dba(sampleSheet=samples)
    
    # 3. Quality Control Plots (Before counting)
    pdf("diffbind_correlation_heatmap.pdf")
    plot(db_obj)
    dev.off()

    # 4. Counting
    db_obj <- dba.count(db_obj, bParallel=TRUE)

    # 5. Extract Correlation Matrix for MultiQC
    try({
        cor_matrix <- dba.overlap(db_obj, mode=DBA_OL_COR)
        write.table(cor_matrix, file="diffbind_correlation_mqc.txt", sep="\t", quote=FALSE, col.names=NA)
    }, silent=TRUE)

    # 6. Differential Analysis
    # We use DBA_ANTIBODY because that's where you are storing your groups (e.g., gH2AX, Sano, Doxo)
    analysis_status <- try({
        # If the user didn't provide 'Condition', we use 'Antibody' for the contrast
        contrast_category <- if ("Condition" %in% colnames(samples) && length(unique(samples\$Condition)) > 1) DBA_CONDITION else DBA_ANTIBODY
        
        db_obj <- dba.contrast(db_obj, categories=contrast_category, minMembers=2)
        db_obj <- dba.analyze(db_obj)
    }, silent=FALSE)

    # 7. Reporting Results (only if analysis succeeded)
    if (!inherits(analysis_status, "try-error") && !is.null(db_obj\$contrasts)) {
        res_db <- dba.report(db_obj)
        write.csv(as.data.frame(res_db), "diff_bind_results.csv")

        png("diffbind_pca.png", width=1000, height=800, res=120)
        dba.plotPCA(db_obj, attributes=DBA_ANTIBODY, label=DBA_ID)
        dev.off()

        pdf("diffbind_volcano.pdf")
        dba.plotVolcano(db_obj)
        dev.off()
    } else {
        print("Comparison not possible: Not enough replicates or groups found.")
    }
    
    # 8. Versions
    writeLines(c(
        "\\"${task.process}\\":",
        paste0("    diffbind: ", packageVersion("DiffBind"))
    ), "versions.yml")
    """
}
