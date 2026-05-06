process MULTIQC {
    label 'process_medium'
    container 'quay.io/biocontainers/multiqc:1.21--pyhdfd78af_0'

    publishDir "${params.outdir}/00_MultiQC", mode: 'copy'

    input:
    path multiqc_config
    path workflow_summary
    path ('fastqc/*')
    path ('trimgalore/*')
    path ('alignment/*')
    path ('picard/*')
    path ('samtools/*')
    path ('deeptools/*')
    path ('macs3/*')       // Qui MultiQC cercherà i log di MACS3
    path ('counts/*')      // <--- AGGIUNTO: Qui passerai i file .narrow_counts.txt e .broad_counts.txt
    path ('frip/*')
    path ('homer/*')       // Assicurati che i file qui finiscano come definito nel config
    path versions

    output:
    path "*multiqc_report.html", emit: report
    path "*_data"              , emit: data
    path "versions.yml"        , emit: versions

    script:
    def args = task.ext.args ?: ''
    def config = multiqc_config.name != 'empty_config' ? "--config $multiqc_config" : ''
    """
    multiqc \\
        -f \\
        $args \\
        $config \\
        .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$(multiqc --version | sed 's/multiqc, version //g')
    END_VERSIONS
    """
}
