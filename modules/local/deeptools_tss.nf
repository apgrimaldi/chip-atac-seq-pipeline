process DEEPTOOLS_TSS {
    tag "$meta.id"
    label 'process_high'
    container 'quay.io/biocontainers/deeptools:3.5.5--pyhdfd78af_0'
    
    publishDir "${params.outdir}/07_advanced_qc/tss_profiles", mode: 'copy'

    input:
    tuple val(meta), path(bw)  // Riceve il .bigWig dal modulo DEEPTOOLS
    path gtf                   // Riceve il GTF del genoma

    output:
    path "*.tss_profile.pdf"    , emit: pdf
    path "*.matrix.gz"          , emit: matrix
    path "versions.yml"         , emit: versions

    script:
    def prefix = "${meta.id}"
    """
    # 1. Calcola la matrice centrata sul TSS
    computeMatrix reference-point \\
        --referencePoint TSS \\
        -S $bw \\
        -R $gtf \\
        -a 3000 -b 3000 \\
        --skipZeros \\
        -o ${prefix}.matrix.gz \\
        --numberOfProcessors $task.cpus

    # 2. Genera il grafico
    plotProfile \\
        -m ${prefix}.matrix.gz \\
        -out ${prefix}.tss_profile.pdf \\
        --plotTitle "${prefix} TSS Profile" \\
        --perGroup

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deeptools: \$(deeptools --version | cut -d' ' -f2)
    END_VERSIONS
    """
}
