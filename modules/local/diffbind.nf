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

    samples <- read.csv("${samplesheet}")
    samples\$bamReads <- basename(samples\$bamReads)
    samples\$Peaks    <- basename(samples\$Peaks)
    
    if ("ControlID" %in% colnames(samples)) {
        samples\$bamControl <- basename(samples\$bamControl)
    }

    db_obj <- dba(sampleSheet=samples)
    db_obj <- dba.blacklist(db_obj, blacklist=FALSE, greylist=FALSE)
    db_obj <- dba.count(db_obj, bParallel=TRUE)

    try({
        cor_matrix <- dba.overlap(db_obj, mode=DBA_OL_COR)
        write.table(cor_matrix, file="diffbind_correlation_mqc.txt", sep="\t", quote=FALSE, col.names=NA)
    }, silent=TRUE)

    analysis_status <- try({
        db_obj <- dba.contrast(db_obj, categories=DBA_CONDITION, minMembers=2)
        db_obj <- dba.analyze(db_obj)
    }, silent=FALSE)

    if (!inherits(analysis_status, "try-error") && !is.null(db_obj\$contrasts)) {
        res_db <- dba.report(db_obj)
        write.csv(as.data.frame(res_db), "diff_bind_results.csv")

        png("diffbind_profile.png", width=1000, height=800, res=120)
        try(dba.plotProfile(db_obj, contrast=1))
        dev.off()

        cat(paste0(
            "# id: 'diffbind_profile'\\n",
            "# section_name: 'DiffBind: Differential Binding Profile'\\n",
            "<div style='text-align: center;'>\\n",
            "  <img src='diffbind_profile.png' style='max-width: 100%; height: auto;'>\\n",
            "</div>"
        ), file="diffbind_profile_mqc.html")
        
        pdf("diffbind_pca.pdf")
        dba.plotPCA(db_obj, attributes=DBA_CONDITION, label=DBA_ID)
        dev.off()
    }
    
    writeLines(c(
        "\\"${task.process}\\":",
        paste0("    diffbind: ", packageVersion("DiffBind"))
    ), "versions.yml")
    """
}
