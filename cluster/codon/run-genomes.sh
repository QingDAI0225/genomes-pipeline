#!/bin/bash
#BSUB -n 1
#BSUB -R "rusage[mem=4096]"
#BSUB -J genomes-pipeline
#BSUB -o output.txt
#BSUB -e error.txt

# CONSTANTS
# Wrapper for genomes-pipeline.sh
WORKDIR="/hps/nobackup/rdf/metagenomics/toil-workdir"

# Production scripts and env
GENOMES_SH="/nfs/production/rdf/metagenomics/pipelines/dev/genomes-pipeline/cluster/codon/genomes-pipeline.sh"
#ENV_FILE="/nfs/production/rdf/metagenomics/pipelines/prod/emg-viral-pipeline/cwl/ebi/virify-env.sh"

set -e

usage () {
    echo ""
    echo "Virify pipeline BSUB"
    echo ""
    echo "-n the name for the job *a timestamp will be added to folder* [mandatory]"
    echo "-i contigs input fasta [mandatory]"
    echo "-o output folder [mandatory]"
    echo ""
    echo "Example:"
    echo ""
    echo "bsub-virify.sh -n test-run -i input_fasta -o /data/results/"
    echo ""
    echo "NOTE:"
    echo "- The results folder will be /data/results/{job_name}."
    echo "- The logs will be stored in /data/results/{job_name}/logs"
    echo ""
    echo "Settings files and executable scripts:"
    echo "- toil work dir: ${WORKDIR} * toil will create a folder in this path"
    echo "- virify.sh: ${VIRIFY_SH}"
    echo "- virify env: ${ENV_FILE}"
    echo ""
}

# PARAMS
NAME=""
CONTIGS=""
RESULTS_FOLDER=""

while getopts "n:i:o:h" opt; do
  case $opt in
    n)
        NAME="$OPTARG"
        ;;
    i)
        CONTIGS="$OPTARG"
        # if [ ! -f "$NAME_RUN" ];
        # then
        #     echo ""
        #     echo "ERROR '${OPTARG}' doesn't exist." >&2
        #     usage;
        #     exit 1
        # fi
        ;;
    o)
        RESULTS_FOLDER="$OPTARG"
        ;;
    :)
        usage;
        exit 1
        ;;
    \?)
        usage;
        exit 1;
    ;;
  esac
done

if ((OPTIND == 1))
then
    echo ""
    echo "ERROR! No options specified"
    usage;
    exit 1
fi

${VIRIFY_SH} \
-e ${ENV_FILE} \
-n ${NAME} \
-j ${WORKDIR} \
-o ${RESULTS_FOLDER} \
-p CODON \
-c 1 -m 12000 \
-i ${CONTIGS}