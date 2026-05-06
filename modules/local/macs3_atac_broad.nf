process MACS3_ATAC_BROAD {
    tag "$meta.id"
    label 'process_medium'
    container 'quay.io/biocontainers/macs3:3.0.1--py311h0152c62_3'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.broadPeak") , emit: peaks
    path "*.broad_counts.txt"            , emit: count_broad // AGGIUNTO PER MULTIQC
    path "versions.yml"                  , emit: versions

    script:
    def prefix   = "${meta.id}_atac_broad"
    def format   = meta.single_end ? 'BAM' : 'BAMPE'
    
    // Mappa dinamica per convertire i nomi genoma nei codici MACS3
    def genome_map = [
        'hg38': 'hs', 'GRCh38': 'hs', 'hg19': 'hs',
        'mm10': 'mm', 'mm9': 'mm', 'GRCm38': 'mm',
        'dm6': 'dm', 'ce11': 'ce'
    ]
    
    // Se il genoma è in mappa usa il codice (hs, mm..), altrimenti usa params.genome
    def m_genome = genome_map[params.genome] ?: params.genome

    """
    macs3 callpeak \\
        -t $bam \\
        -f $format \\
        -g $m_genome \\
        -n $prefix \\
        --nomodel --shift -100 --extsize 200 \\
        --broad \\
        --broad-cutoff 0.1

    # Estrazione automatica del conteggio per il grafico MultiQC
    # Conta le righe del file broadPeak
    count=\$(wc -l < ${prefix}_peaks.broadPeak)
    echo -e "${meta.id}\t\$count" > ${meta.id}.broad_counts.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        macs3: \$(macs3 --version | sed 's/macs3 //g')
    END_VERSIONS
    """
}
