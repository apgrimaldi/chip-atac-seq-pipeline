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
    path ('macs3/*')         
    path ('frip/*')          // I tuoi file .FRiP.txt finiscono qui
    path ('annotations/*')   // Aggiunto per le annotazioni (Homer/ChIPseeker)
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
