process LANCEOTRON {
    tag "${meta.id}"
    label 'process_high'
    container 'quay.io/biocontainers/lanceotron:1.2.7--pyhdfd78af_0'

    publishDir "${params.outdir}/05_peak_calling/lanceotron", mode: 'copy'

    input:
    tuple val(meta), path(bam_ip), path(bw_ip), path(bam_ctrl), path(bw_ctrl)

    output:
    tuple val(meta), path("*_peaks.bed")      , emit: peaks
    tuple val(meta), path("*_counts.txt")     , emit: counts_mqc, optional: true
    path "versions.yml"                        , emit: versions

    script:
    def prefix = "${meta.id}"
    // Gestiamo i comandi in base alla presenza del controllo
    def command = (bam_ctrl && bw_ctrl) ? "callPeaksInput ${bw_ip} -i ${bw_ctrl}" : "callPeaks ${bw_ip}"
    
    """
    # Esecuzione LanceOtron
    lanceotron ${command} \\
        -f . \\
        -t 0.9 \\
        -w 1000

    # 1. Ricerca dinamica del file prodotto (LanceOtron è imprevedibile sui nomi)
    # Cerchiamo qualsiasi file .bed che contenga 'peaks'
    FOUND_BED=\$(ls *peaks.bed 2>/dev/null | head -n 1)

    # 2. Rinomina o creazione file di emergenza
    if [ -n "\$FOUND_BED" ]; then
        mv "\$FOUND_BED" ${prefix}_lanceotron_peaks.bed
    else
        # Se LanceOtron non ha generato nulla (zero picchi o errore silente), 
        # creiamo un file vuoto per non far fallire la pipeline
        touch ${prefix}_lanceotron_peaks.bed
    fi

    # 3. Generazione report per MultiQC
    echo "Sample Peaks" > ${prefix}.lanceotron_counts.txt
    COUNT=\$(grep -v "^#" ${prefix}_lanceotron_peaks.bed | wc -l || echo 0)
    echo "${prefix} \$COUNT" >> ${prefix}.lanceotron_counts.txt

    # 4. Versioning
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        lanceotron: 1.2.7
    END_VERSIONS
    """
}
