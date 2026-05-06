process MACS3_CHIP_BROAD {
    tag "$meta.id"
    label 'process_medium'
    container 'quay.io/biocontainers/macs3:3.0.1--py311h0152c62_3'

    input:
    // Qui definiamo come si chiamano le variabili (ip_bam e control_bam)
    tuple val(meta), path(ip_bam), path(control_bam)

    output:
    tuple val(meta), path("*.broadPeak")  , emit: peaks
    tuple val(meta), path("*.xls")        , emit: xls
    path "*.broad_counts.txt"             , emit: count_broad
    path "versions.yml"                   , emit: versions

    script:
    def prefix   = "${meta.id}_broad"
    def format   = meta.single_end ? 'BAM' : 'BAMPE'
    
    // Gestione dinamica del genoma (manteniamola coerente con narrow)
    def genome_map = [
        'hg38': 'hs', 'GRCh38': 'hs', 'hg19': 'hs',
        'mm10': 'mm', 'mm9': 'mm', 'GRCm38': 'mm'
    ]
    def m_genome = genome_map[params.genome] ?: params.genome

    // Gestione del controllo: se control_bam è vuoto o nullo, non passiamo -c
    def args_control = control_bam ? "-c $control_bam" : ""

    """
    macs3 callpeak \
        -t $ip_bam \
        $args_control \
        -f $format \
        -g $m_genome \
        -n $prefix \
        --broad \
        --broad-cutoff 0.1

    # Controllo esistenza file per evitare il crash del wc -l
    if [ -f ${prefix}_peaks.broadPeak ]; then
        count=\$(wc -l < ${prefix}_peaks.broadPeak)
    else
        count=0
    fi

    echo -e "${meta.id}\\t\$count" > ${meta.id}.broad_counts.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        macs3: \$(macs3 --version | sed 's/macs3 //g')
    END_VERSIONS
    """
}
