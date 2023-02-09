/*
 * Functional annontation of the genomes of the cluster reps
*/

include { IPS } from '../modules/interproscan'
include { EGGNOG_MAPPER as EGGNOG_MAPPER_ORTHOLOGS } from '../modules/eggnog'
include { EGGNOG_MAPPER as EGGNOG_MAPPER_ANNOTATIONS } from '../modules/eggnog'
include { PER_GENOME_ANNONTATION_GENERATOR } from '../modules/per_genome_annotations'
include { DETECT_RRNA } from '../modules/detect_rrna'
include { COLLECT_IN_FOLDER as COLLECT_FASTAS } from '../modules/detect_rrna'
include { COLLECT_IN_FOLDER as COLLECT_OUTS } from '../modules/detect_rrna'


workflow ANNOTATE {
    take:
        mmseq_faa
        mmseq_tsv
        prokka_faas
        prokka_fnas
        species_reps_names_list
        interproscan_db
        eggnog_db
        eggnog_diamond_db
        eggnog_data_dir
        cmmodels_db
    main:
        faa_chunks_ch = prokka_faas.collectFile(name: "collected.faa").splitFasta(
            by: 10000,
            file: true
        )

        IPS(
            faa_chunks_ch,
            interproscan_db
        )

        EGGNOG_MAPPER_ORTHOLOGS(
            faa_chunks_ch,
            file("NO_FILE"),
            channel.value('mapper'),
            eggnog_db,
            eggnog_diamond_db,
            eggnog_data_dir
        )

        EGGNOG_MAPPER_ANNOTATIONS(
            file("NO_FILE"),
            EGGNOG_MAPPER_ORTHOLOGS.out.orthologs.collectFile(name: "eggnog_orthologs.tsv"),
            channel.value('annotations'),
            eggnog_db,
            eggnog_diamond_db,
            eggnog_data_dir
        )

        PER_GENOME_ANNONTATION_GENERATOR(
            IPS.out.ips_annontations.collectFile(name: "ips_annotations.tsv"),
            EGGNOG_MAPPER_ANNOTATIONS.out.annotations.collectFile(name: "eggnog_annotations.tsv"),
            species_reps_names_list,
            mmseq_tsv
        )

        DETECT_RRNA(
            prokka_fnas,
            cmmodels_db
        )

        COLLECT_FASTAS(
            DETECT_RRNA.out.rrna_fasta_results.collect(),
            channel.value('rRNA_fastas')
        )

        COLLECT_OUTS(
            DETECT_RRNA.out.rrna_out_results.collect(),
            channel.value('rRNA_outs')
        )

        // Group per genome name //
        per_genome_ips_annotations = PER_GENOME_ANNONTATION_GENERATOR.out.ips_annotation_tsvs | flatten | map { file ->
            def key = file.name.toString().tokenize('_').get(0)
            return tuple(key, file)
        }

        per_genome_eggnog_annotations = PER_GENOME_ANNONTATION_GENERATOR.out.eggnog_annotation_tsvs | flatten | map { file ->
            def key = file.name.toString().tokenize('_').get(0)
            return tuple(key, file)
        }

    emit:
        ips_annotation_tsvs = per_genome_ips_annotations
        eggnog_annotation_tsvs = per_genome_eggnog_annotations
        rrna_fastas = COLLECT_FASTAS.out.collection_folder
        rrna_outs = COLLECT_OUTS.out.collection_folder
}
