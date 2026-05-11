process DIFFBIND {
    tag "diffbind_analysis"
    label 'process_high'
    container 'quay.io/biocontainers/bioconductor-diffbind:3.20.0--r45ha27e39d_0'

    input:
    path samplesheet
    path bams
    path bais
    path peaks

    script:
    """
    #!/usr/bin/env Rscript
    library(DiffBind)

    # Leggiamo la samplesheet
    samples <- read.csv("${samplesheet}")

    # TRUCCO: Forziamo DiffBind a cercare i file nella cartella di lavoro corrente
    # Nextflow ha messo tutti i file (bam e peaks) qui dentro.
    samples\$bamReads <- basename(samples\$bamReads)
    samples\$Peaks    <- basename(samples\$Peaks)
    
    # Se hai dei BAM di controllo (input):
    if ("ControlID" %in% colnames(samples)) {
        samples\$bamControl <- basename(samples\$bamControl)
    }

    # Creiamo l'oggetto DBA usando la tabella modificata "al volo"
    db_obj <- dba(sampleSheet=samples)
    
    # Proseguiamo con l'analisi
    db_obj <- dba.count(db_obj, bParallel=TRUE)
    db_obj <- dba.contrast(db_obj, categories=DBA_CONDITION)
    db_obj <- dba.analyze(db_obj)

 
    res_db <- dba.report(db_obj)
    write.csv(as.data.frame(res_db), "diff_bind_results.csv")

    
    png("diffbind_profile.png", width=1000, height=800, res=120)
    dba.plotProfile(db_obj, contrast=1)
    dev.off()

    pdf("diffbind_profile.pdf", width=10, height=8)
    dba.plotProfile(db_obj, contrast=1)
    dev.off()

    cat(paste0(
        "# id: 'diffbind_profile'\\n",
        "# section_name: 'Differential Binding Profile'\\n",
        "# description: 'Heatmap showing signal intensity at differential sites (Gain vs Loss)'\\n",
        "<div style='text-align: center;'>\\n",
        "  <img src='diffbind_profile.png' style='max-width: 100%; height: auto;'>\\n",
        "</div>"
    ), file="diffbind_profile_mqc.html")

    writeLines(c(
        "\\"${task.process}\\":",
        paste0("    diffbind: ", packageVersion("DiffBind"))
    ), "versions.yml")
    """
}
