process BOWTIE2 {
    tag "$meta.id"
    label 'process_high'
    // Container multi-tool con bowtie2 e samtools
    container 'quay.io/biocontainers/mulled-v2-ac74a7f02cebcfcc07d8e8d1d750af9c83b4d45a:f70b31a2db15c023d641c32f433fb02cd04df5a6-0'

    input:
    tuple val(meta), path(reads)
    path index // Riceve la lista di file .bt2 (grazie al .collect() nel workflow)

    output:
    tuple val(meta), path("*.raw.bam"), emit: bam
    tuple val(meta), path("*.log")     , emit: log
    path "versions.yml"                , emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def rg_args = "--rg-id ${prefix} --rg SM:${prefix} --rg PL:ILLUMINA --rg LB:lib1"
    
    // Gestione Single-End vs Paired-End
    def input_reads = meta.single_end ? "-U ${reads}" : "-1 ${reads[0]} -2 ${reads[1]}"
    
    // Parametri specifici per protocollo
    def extra_args = params.protocol == 'atac' ? "--no-mixed --no-discordant" : ""

    """
    # 1. Identifica il nome base dell'indice (cerca il file .1.bt2 nella directory corrente)
    # Usiamo 'ls' invece di 'find' per semplicità, dato che i file sono linkati direttamente
    INDEX_BASE=\$(ls *.1.bt2* | sed 's/\\.1\\.bt2.*//')

    # 2. Esecuzione Allineamento e conversione immediata in BAM
    bowtie2 \\
        -x \$INDEX_BASE \\
        $input_reads \\
        -p $task.cpus \\
        $rg_args \\
        --very-sensitive \\
        $extra_args \\
        -X 2000 \\
        2> ${prefix}.bowtie2.log \\
        | samtools view -@ $task.cpus -b -o ${prefix}.raw.bam

    # 3. Tracciamento versioni
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bowtie2: \$(echo \$(bowtie2 --version 2>&1) | sed 's/^.*bowtie2-align-s version //; s/ .*\$//')
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
