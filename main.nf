nextflow.enable.dsl=2

// --- IMPORTAZIONE WORKFLOW ---
include { ATAC_CHIP_PIPELINE } from './workflows/analysis' 

def create_fastq_channel(LinkedHashMap row) {
    def meta = [:]
    meta.id         = row.sample.trim()
    meta.antibody   = (row.antibody && row.antibody.trim() != "") ? row.antibody.trim() : 'none'
    meta.control    = (row.control && row.control.trim() != "") ? row.control.trim() : 'none'
    meta.single_end = (row.fastq_2 == null || row.fastq_2.trim() == "") ? true : false

    // --- LOGICA FONDAMENTALE PER SBLOCCARE MACS3 ---
    // Se l'antibody è IgG, marchiamo il campione come controllo per il workflow analysis.nf
    meta.is_control = (meta.antibody.toLowerCase() == 'igg' || row.is_control == 'true') ? true : false

    def fastq_1 = file(row.fastq_1, checkIfExists: true)
    def fastqs = [ fastq_1 ]
    
    if (!meta.single_end) {
        def fastq_2 = file(row.fastq_2, checkIfExists: true)
        fastqs << fastq_2
    }
    return [ meta, fastqs ]
}

workflow {
    if (!params.input) { error "Errore: Specifica --input samplesheet.csv" }
    
    log.info """
    ===========================================
    P I P E L I N E   A T A C / C H I P
    ===========================================
    Protocollo : ${params.protocol?.toUpperCase()}
    Genoma     : ${params.genome}
    Input      : ${params.input}
    ===========================================
    """

    // Lettura Samplesheet
    ch_input = Channel
        .fromPath(params.input, checkIfExists: true)
        .splitCsv(header:true, sep:',')
        .map { row -> create_fastq_channel(row) }
    
    // --- RIGA DI DEBUG (Puoi rimuoverla quando tutto funziona) ---
    ch_input.view { meta, reads -> 
        "LOG: Lettura campioni -> ID: ${meta.id} | Antibody: ${meta.antibody} | Is_Control: ${meta.is_control}" 
    }

    // Lancio della Pipeline
    ATAC_CHIP_PIPELINE ( ch_input )
    
    workflow.onComplete {
        log.info "Pipeline completata con successo!"
    }
}
