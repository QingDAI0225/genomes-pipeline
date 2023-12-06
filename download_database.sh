#!/usr/bin/env bash

WORK_DIR="/work/qd33/nanopore/QD_ptrap_20230908"
cd $WORK_DIR
mkdir MGnify_db && cd MGnify_db && 

# gunc
wget ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/genomes-pipeline/gunc_db_2.0.4.dmnd.gz
# eggnog
wget ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/genomes-pipeline/eggnog_db.tgz
# rfam
wget ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/genomes-pipeline/rfam_14.9/
# kegg
wget ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/genomes-pipeline/kegg_classes.tsv
# geo
wget ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/genomes-pipeline/continent_countries.csv
# gtdb
wget https://data.ace.uq.edu.au/public/gtdb/data/releases/release214/214.0/auxillary_files/gtdbtk_r214_data.tar.gz
#amrfinder
wget ftp://ftp.ncbi.nlm.nih.gov/pathogen/Antimicrobial_resistance/AMRFinderPlus/database/3.11/2023-02-23.1
# InterProScan5.62-94.0
wget ftp://ftp.ebi.ac.uk/pub/software/unix/iprscan/5/5.36-75.0/interproscan-5.62-94.0.tar.gz
tar --extract --gzip interproscan-5.62-94.0.tar.gz

