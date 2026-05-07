process BOWTIE2_BUILD {
    tag "$fasta"
    label 'process_high'
    container 'quay.io/biocontainers/bowtie2:2.5.2--py39h6fed5c7_0' 

    input:
    path fasta

    output:
    path "bowtie2_index"  , emit: index
    path "versions.yml"   , emit: versions

    script:
    """
    mkdir bowtie2_index
    bowtie2-build --threads $task.cpus $fasta bowtie2_index/${fasta.baseName}
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bowtie2: \$(echo \$(bowtie2 --version 2>&1) | sed 's/^.*bowtie2-align-s version //; s/ .*\$//')
    END_VERSIONS
    """
}
