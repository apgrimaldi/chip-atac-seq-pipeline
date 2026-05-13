process LANCEOTRON {
    tag "${meta.id}"
    label 'process_high'
    container 'quay.io/biocontainers/lanceotron:1.2.7--pyhdfd78af_0'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*.bed"), emit: peaks
    tuple val(meta), path("*.bw") , emit: bigwig_res1
    path "versions.yml"           , emit: versions

    script:
    """
    # 1. Creazione BigWig a risoluzione 1bp (necessario per LanceOtron)
    # Usiamo bamCoverage che è incluso nelle dipendenze di LanceOtron
    bamCoverage --bam ${bam} \\
                --outFileName ${meta.id}_res1.bw \\
                --binSize 1 \\
                --numberOfProcessors ${task.cpus} \\
                --normalizeUsing RPKM

    # 2. Peak calling con Deep Learning
    # LanceOtron analizza la forma del segnale nel BW a 1bp
    lanceotron score_and_peak ${meta.id}_res1.bw \\
               --output_directory . \\
               --threshold 0.9 \\
               --window_size 1000

    # Rinominiamo l'output per chiarezza
    mv L_extract_peaks.bed ${meta.id}_lanceotron_peaks.bed

    cat <<EOF > versions.yml
    "${task.process}":
        lanceotron: 1.2.7
    EOF
    """
}
