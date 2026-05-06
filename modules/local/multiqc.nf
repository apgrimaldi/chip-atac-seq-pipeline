process MULTIQC {
    label 'process_medium'
    container 'quay.io/biocontainers/multiqc:1.21--pyhdfd78af_0'

    publishDir "${params.outdir}/00_MultiQC", mode: 'copy'

    input:
    path multiqc_config      // File YAML di configurazione
    path workflow_summary    // File summary.txt
    path ('fastqc/*')
    path ('trimgalore/*')
    path ('alignment/*')
    path ('picard/*')
    path ('samtools/*')
    path ('deeptools/*')
    path ('macs3/*')
    path ('counts/*')        // Qui arriveranno i file .narrow_counts.txt e .broad_counts.txt univoci
    path ('frip/*')
    path ('homer/*')
    path versions

    output:
    path "*multiqc_report.html", emit: report
    path "*_data"              , emit: data
    path "versions.yml"        , emit: versions

    script:
    def args = task.ext.args ?: ''
    // Verifica robusta per il file di config
    def config_opt = multiqc_config && multiqc_config.name != 'empty_config' ? "--config $multiqc_config" : ''
    """
    multiqc \\
        -f \\
        $args \\
        $config_opt \\
        .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$(multiqc --version | sed 's/multiqc, version //g')
    END_VERSIONS
    """
}
