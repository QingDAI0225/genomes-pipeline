#!/usr/bin/env bash

#-----------------------------------------------------------
# Run the following to run this script:
#   srun -A chsi -p chsi -c10 --mem 20G ./download_database.sh 
#-----------------------------------------------------------


set -eo pipefail
set -u

WORK_DIR="/work/qd33/nanopore/QD_ptrap_20230908"
DB_DIR="$WORK_DIR/Mgnify_db"

mkdir $DB_DIR
cd $DB_DIR

# gunc
wget ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/genomes-pipeline/gunc_db_2.0.4.dmnd.gz
gzip -dk gunc_db_2.0.4.dmnd.gz

# eggnog
wget ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/genomes-pipeline/eggnog_db.tgz
mkdir eggnog
tar zxvf eggnog_db.tgz -C ./eggnog/

# rfam
wget -r -np -R "index.html*" ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/genomes-pipeline/rfam_14.9/
# kegg
wget ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/genomes-pipeline/kegg_classes.tsv
# geo
wget ftp://ftp.ebi.ac.uk/pub/databases/metagenomics/genomes-pipeline/continent_countries.csv
# gtdb
wget https://data.ace.uq.edu.au/public/gtdb/data/releases/release214/214.0/auxillary_files/gtdbtk_r214_data.tar.gz

#amrfinder
wget -r -np -R "index.html*" ftp://ftp.ncbi.nlm.nih.gov:21/pathogen/Antimicrobial_resistance/AMRFinderPlus/database/3.11/2023-02-23.1/

# InterProScan5.62-94.0
wget ftp://ftp.ebi.ac.uk/pub/software/unix/iprscan/5/5.62-94.0/interproscan-5.62-94.0-64-bit.tar.gz
tar -xvzf interproscan-5.62-94.0.tar.gz

