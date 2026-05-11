process FILTERING {
    tag "$meta.id"
    label 'process_medium'
    
    container 'quay.io/biocontainers/bedtools:2.30.0--hc088bd4_0'

    publishDir "${params.outdir}/04_filtered", mode: 'copy'

    input:
    tuple val(meta), path(bam), path(bai)
    path  blacklist

    output:
    tuple val(meta), path("*.filtered.bam"), emit: bam
    path "versions.yml"                    , emit: versions

    script:
    def prefix = "${meta.id}"
    """
    # 1. Gestione Blacklist: 
    # Se il file è .gz lo decomprimiamo, altrimenti creiamo un link simbolico
    if [[ "$blacklist" == *.gz ]]; then
        gunzip -c "$blacklist" > actual_blacklist.bed
    else
        # Usiamo ln -s per non duplicare i dati se la blacklist è già un .bed
        ln -s $blacklist actual_blacklist.bed
    fi

    # 2. Rimozione Blacklist con bedtools
   bedtools intersect \\
        -v \\
        -abam $bam \\
        -b actual_blacklist.bed \\
        > ${prefix}.filtered.bam

    # 3. Statistiche per MultiQC
    RAW_COUNT=\$(samtools view -c $bam)
    FILTERED_COUNT=\$(samtools view -c ${prefix}.filtered.bam)
    
    echo "# id: 'filtering_stats'" > ${prefix}.filtering_mqc.txt
    echo "# section_name: 'Filtering: Blacklist Removal'" >> ${prefix}.filtering_mqc.txt
    echo "# plot_type: 'bargraph'" >> ${prefix}.filtering_mqc.txt
    echo "# pconfig:" >> ${prefix}.filtering_mqc.txt
    echo "#    title: 'Reads before and after Blacklist filtering'" >> ${prefix}.filtering_mqc.txt
    echo "#    ylab: 'Number of Reads'" >> ${prefix}.filtering_mqc.txt
    echo -e "Sample\\tReads_Raw\\tReads_Filtered" >> ${prefix}.filtering_mqc.txt
    echo -e "${prefix}\\t\$RAW_COUNT\\t\$FILTERED_COUNT" >> ${prefix}.filtering_mqc.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bedtools: \$(bedtools --version | sed 's/bedtools v//')
    END_VERSIONS
    """
}
