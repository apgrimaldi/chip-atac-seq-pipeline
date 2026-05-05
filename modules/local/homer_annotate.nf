process HOMER_ANNOTATEPEAKS {
    tag "$meta.id"
    label 'process_medium'

    // Questa versione è verificata e stabile su quay.io
    container 'quay.io/biocontainers/homer:4.11--pl526hc9558a2_3'

    input:
    tuple val(meta), path(peak)
    path  fasta
    path  gtf

    output:
    // Manteniamo esattamente il nome che si aspetta il tuo workflow
    tuple val(meta), path("*.annotatePeaks.txt"), emit: txt
    path  "versions.yml"                        , emit: versions

    script:
    // USA meta.id: è una stringa garantita, evita l'errore 'null object'
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    annotatePeaks.pl \\
        $peak \\
        $fasta \\
        -gtf $gtf \\
        -cpu $task.cpus \\
        > ${prefix}.annotatePeaks.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        homer: 4.11
    END_VERSIONS
    """
}
