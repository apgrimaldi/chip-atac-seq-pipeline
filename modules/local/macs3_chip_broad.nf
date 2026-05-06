process MACS3_CHIP_BROAD {
    tag "$meta.id"
    label 'process_medium'
    container 'quay.io/biocontainers/macs3:3.0.1--py311h0152c62_3'

    input:
    tuple val(meta), path(ip_bam), path(control_bam)

    output:
    tuple val(meta), path("*.broadPeak") , emit: peaks
    tuple val(meta), path("*.gappedPeak"), emit: gapped_peaks
    path "*.broad_counts.txt"            , emit: count_broad // <--- Output per MultiQC
    path "versions.yml"                  , emit: versions

    script:
    def prefix = "${meta.id}_broad"
    """
    macs3 callpeak \
        -t $bam \
        $args_control \
        -f BAM \
        -g hs \
        -n $prefix \
        --broad \
        --broad-cutoff 0.1

    # CORREZIONE: MACS3 aggiunge "_peaks" al nome indicato con -n
    if [ -f ${prefix}_peaks.broadPeak ]; then
        count=\$(wc -l < ${prefix}_peaks.broadPeak)
    else
        count=0
    fi

    echo -e "${meta.id}\t\$count" > ${meta.id}.broad_counts.txt
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        macs3: \$(macs3 --version | sed 's/macs3 //g')
    END_VERSIONS
    """
}
