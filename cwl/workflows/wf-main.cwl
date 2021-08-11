#!/usr/bin/env cwl-runner
cwlVersion: v1.2.0-dev2
class: Workflow

requirements:
  SubworkflowFeatureRequirement: {}
  MultipleInputFeatureRequirement: {}
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}
  ScatterFeatureRequirement: {}

inputs:
  genomes_ena: Directory?
  ena_csv: File?
  genomes_ncbi: Directory?

  # no gtdbtk
  skip_gtdbtk_step: string

  # common input
  mmseqs_limit_c: float
  mmseqs_limit_i: float[]

  gunc_db_path: File

  InterProScan_databases: [string, Directory]
  chunk_size_IPS: int
  chunk_size_eggnog: int
  db_diamond_eggnog: [string?, File?]
  db_eggnog: [string?, File?]
  data_dir_eggnog: [string?, Directory?]

outputs:
  output_csv:
    type: File
    outputSource: unite_folders/csv

  mash_folder:
    type: Directory?
    outputSource: clusters_annotation/mash_folder

  many_genomes:
    type: Directory[]?
    outputSource: clusters_annotation/many_genomes
  many_genomes_panaroo:
    type: Directory[]?
    outputSource: clusters_annotation/many_genomes_panaroo
  many_genomes_prokka:
    type:
      - 'null'
      - type: array
        items:
          type: array
          items: Directory
    outputSource: clusters_annotation/many_genomes_prokka
  many_genomes_genomes:
    type: Directory[]?
    outputSource: clusters_annotation/many_genomes_genomes

  one_genome:
    type: Directory[]?
    outputSource: clusters_annotation/one_genome
  one_genome_prokka:
    type: Directory[]?
    outputSource: clusters_annotation/one_genome_prokka
  one_genome_genomes:
    type: Directory[]?
    outputSource: clusters_annotation/one_genome_genomes

  mmseqs:
    type: Directory
    outputSource: clusters_annotation/mmseqs_output

  gtdbtk:
    type: Directory
    outputSource: gtdbtk/gtdbtk_folder

  weights:
    type: File
    outputSource: drep_subwf/weights_file


steps:

# ----------- << checkm for NCBI>> -----------
  checkm_subwf:
    run: sub-wf/checkm-subwf.cwl
    when: $(Boolean(inputs.genomes_folder))
    in:
      genomes_folder: genomes_ncbi
    out:
      - checkm_csv

# unite NCBI and ENA
  unite_folders:
    run: ../tools/unite_ena_ncbi/unite.cwl
    in:
      ena_folder: genomes_ena
      ncbi_folder: genomes_ncbi
      ena_csv: ena_csv
      ncbi_csv: checkm_subwf/checkm_csv
      outputname: { default: "genomes"}
    out:
      - genomes
      - csv

# ---------- dRep + split
  drep_subwf:
    run: sub-wf/drep-subwf.cwl
    in:
      genomes_folder: unite_folders/genomes
      input_csv: unite_folders/csv
    out:
      - many_genomes
      - one_genome
      - mash_folder
      - dereplicated_genomes
      - weights_file

# ---------- annotation
  clusters_annotation:
    run: sub-wf/subwf-process_clusters.cwl
    in:
      many_genomes: drep_subwf/many_genomes
      mash_folder: drep_subwf/mash_folder
      one_genome: drep_subwf/one_genome
      mmseqs_limit_c: mmseqs_limit_c
      mmseqs_limit_i: mmseqs_limit_i
      gunc_db_path: gunc_db_path
      InterProScan_databases: InterProScan_databases
      chunk_size_IPS: chunk_size_IPS
      chunk_size_eggnog: chunk_size_eggnog
      db_diamond_eggnog: db_diamond_eggnog
      db_eggnog: db_eggnog
      data_dir_eggnog: data_dir_eggnog
      csv:
        source:
          - checkm_subwf/checkm_csv
          - download/stats_ena  # for ENA / NCBI
          - csv  # for no fetch
        pickValue: first_non_null
    out:
      - mash_folder
      - many_genomes
      - many_genomes_panaroo
      - many_genomes_prokka
      - many_genomes_genomes
      - one_genome
      - one_genome_prokka
      - one_genome_genomes
      - mmseqs_output

# ----------- << GTDB - Tk >> -----------
  gtdbtk:
    when: $(inputs.skip_flag !== 'skip')
    run: ../tools/gtdbtk/gtdbtk.cwl
    in:
      skip_flag: skip_gtdbtk_step
      drep_folder: drep_subwf/dereplicated_genomes
      gtdb_outfolder: { default: 'gtdb-tk_output' }
    out: [ gtdbtk_folder ]