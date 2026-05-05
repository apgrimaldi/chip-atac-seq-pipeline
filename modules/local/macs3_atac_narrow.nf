process MACS3_ATAC_NARROW {
    tag "$meta.id"
    label 'process_medium'
    container 'quay.io/biocontainers/macs3:3.0.1--py311h0152c62_3'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.narrowPeak"), emit: peaks
    path "versions.yml"                  , emit: versions

    script:
    def prefix   = "${meta.id}_atac_narrow"
    def format   = meta.single_end ? 'BAM' : 'BAMPE'
    
    // Mappa universale per i codici genoma di MACS3
    def genome_map = [
        'hg38': 'hs', 'GRCh38': 'hs', 'hg19': 'hs',
        'mm10': 'mm', 'mm9': 'mm', 'GRCm38': 'mm',
        'dm6': 'dm', 'ce11': 'ce'
    ]
    
    // Se il genoma è in mappa usa il codice (hs, mm...), 
    // altrimenti usa params.genome (utile se passi direttamente la dimensione in pb)
    def m_genome = genome_map[params.genome] ?: params.genome

    """
    macs3 callpeak \\
        -t $bam \\
        -f $format \\
        -g $m_genome \\
        -n $prefix \\
        --nomodel --shift -100 --extsize 200 \\
        --qvalue 0.05

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        macs3: \$(macs3 --version | sed 's/macs3 //g')
    END_VERSIONS
    """
}
