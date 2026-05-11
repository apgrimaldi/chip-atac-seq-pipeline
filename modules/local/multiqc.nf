process MULTIQC {
    label 'process_medium'
    container 'quay.io/biocontainers/multiqc:1.21--pyhdfd78af_0'

    publishDir "${params.outdir}/00_MultiQC_Report", mode: 'copy'

    input:
    path multiqc_config      // File YAML di configurazione assets/multiqc_config.yml
    path workflow_summary    // File summary.txt
    path ('fastqc/*')
    path ('trimgalore/*')
    path ('alignment/*')
    path ('picard/*')
    path ('samtools/*')
    path ('deeptools/*')
    path ('macs3/*')
    path ('counts/*')        
    path ('frip/*')
    path ('homer/*')
    path ('diffbind/*')      // NUOVO: Input per i file HTML/PNG di DiffBind
    path versions

    output:
    path "*multiqc_report.html", emit: report
    path "*_data"              , emit: data
    path "versions.yml"        , emit: versions

    script:
    def args = task.ext.args ?: ''
    // Forza l'uso del config se presente, altrimenti usa i default
    def config_opt = multiqc_config && multiqc_config.name != 'empty_config' ? "--config $multiqc_config" : ''
    
    // Titolo personalizzato per verificare il caricamento del config
    def report_title = params.protocol == 'atac' ? "ATAC-seq Analysis Report" : "ChIP-seq Analysis Report"

    """
    multiqc \\
        -f \\
        $args \\
        $config_opt \\
        --title "$report_title" \\
        .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$(multiqc --version | sed 's/multiqc, version //g')
    END_VERSIONS
    """
}
