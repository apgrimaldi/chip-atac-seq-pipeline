process MACS3_CHIP_NARROW {
    tag "$meta.id"
    label 'process_medium'
    container 'quay.io/biocontainers/macs3:3.0.1--py311h0152c62_3'

    input:
    tuple val(meta), path(ip_bam), path(control_bam)

    output:
    tuple val(meta), path("*.narrowPeak")   , emit: peaks
    tuple val(meta), path("*.xls")          , emit: xls
    tuple val(meta), path("*.narrow_counts.txt"), emit: count_narrow
    path "versions.yml"                     , emit: versions

    script:
    def prefix   = "${meta.id}_narrow"
    def format   = meta.single_end ? 'BAM' : 'BAMPE'
    
    def genome_map = [
        'hg38': 'hs', 'GRCh38': 'hs', 'hg19': 'hs',
        'mm10': 'mm', 'mm9': 'mm', 'GRCm38': 'mm',
        'dm6': 'dm', 'ce11': 'ce'
    ]
    def m_genome = genome_map[params.genome] ?: params.genome

    // Gestione opzionale del controllo (se presente)
    def args_control = control_bam ? "-c $control_bam" : ""

    """
    macs3 callpeak \\
        -t $ip_bam \\
        $args_control \\
        -f $format \\
        -g $m_genome \\
        -n $prefix \\
        --qvalue 0.05

    # Controllo esistenza file per il conteggio
    if [ -f ${prefix}_peaks.narrowPeak ]; then
        count=\$(wc -l < ${prefix}_peaks.narrowPeak)
    else
        count=0
    fi

    # Generazione file per MultiQC con Header e nome univoco
    echo -e "Sample\\tNarrow_Peaks" > ${prefix}.narrow_counts.txt
    echo -e "${meta.id}\\t\$count" >> ${prefix}.narrow_counts.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        macs3: \$(macs3 --version | sed 's/macs3 //g')
    END_VERSIONS
    """
}
