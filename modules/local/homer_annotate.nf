process HOMER_ANNOTATEPEAKS {
    tag "$meta.id"
    label 'process_medium'
    container 'quay.io/biocontainers/homer:4.11--pl526hc9558a2_3'

    input:
    tuple val(meta), path(peak)
    path fasta
    path gtf

    output:
    tuple val(meta), path("*.annotatePeaks.txt"), emit: txt
    tuple val(meta), path("*.homer_stats.txt") , emit: stats // AGGIUNTO PER MULTIQC
    path "versions.yml"                         , emit: versions

    script:
    def type = peak.name.contains('narrow') ? 'narrow' : 'broad'
    def prefix = "${meta.id}.${type}"
    """
    annotatePeaks.pl \\
        $peak \\
        $fasta \\
        -gtf $gtf \\
        -cpu $task.cpus \\
        > ${prefix}.annotatePeaks.txt

    # --- GENERAZIONE STATISTICHE PER MULTIQC (Screenshot 11.05.16) ---
    # Creiamo l'header con le categorie esatte
    echo -e "Sample\\tIntergenic\\tTTS\\texon\\tintron\\tpromoter-TSS" > ${prefix}.homer_stats.txt
    
    # Contiamo le occorrenze di ogni categoria nel file di output di HOMER
    INTERGENIC=\$(grep -c "Intergenic" ${prefix}.annotatePeaks.txt || true)
    TTS=\$(grep -c "TTS" ${prefix}.annotatePeaks.txt || true)
    EXON=\$(grep -c "exon" ${prefix}.annotatePeaks.txt || true)
    INTRON=\$(grep -c "intron" ${prefix}.annotatePeaks.txt || true)
    PROMOTER=\$(grep -i -c "promoter-TSS" ${prefix}.annotatePeaks.txt || true)
    
    # Scriviamo i dati (usiamo il meta.id pulito o il prefix per distinguere narrow/broad)
    echo -e "${prefix}\\t\$INTERGENIC\\t\$TTS\\t\$EXON\\t\$INTRON\\t\$PROMOTER" >> ${prefix}.homer_stats.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        homer: 4.11
    END_VERSIONS
    """
}
