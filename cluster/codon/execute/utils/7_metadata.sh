#!/bin/bash

usage()
{
cat << EOF
usage: $0 options
Run genomes-pipeline metadata generation and phylo.tree
OPTIONS:
   -o      Path to general output catalogue directory
   -p      Path to installed pipeline location
   -l      Path to logs folder
   -n      Catalogue name
   -q      LSF queue to run in
   -y      Path to folder to save yml file
   -j      LSF step Job name to submit
   -v      Catalogue version
   -i      Path to folder with intermediate files generated by dRep step
   -g      Path to GTDB-Tk taxonomy output file
   -r      Path to rRNA_outs folder (result of annotation step)
   -f      Path to folder with all filtered fna files
   -s      Initial input genomes.csv
   -z      Memory to execute in Gb
   -t      Number of threads
EOF
}

export GEO="/hps/nobackup/rdf/metagenomics/service-team/production/ref-dbs/genomes-pipeline/continent_countries.csv"

while getopts ho:p:l:n:q:y:v:i:g:r:j:f:s:z:t: option; do
	case "$option" in
		h)
            usage
            exit 1
            ;;
		o)
		    OUT=${OPTARG}
		    ;;
		p)
		    P=${OPTARG}
		    ;;
		l)
		    LOGS=${OPTARG}
		    ;;
		n)
		    DIRNAME=${OPTARG}
		    ;;
		q)
		    QUEUE=${OPTARG}
		    ;;
		y)
		    YML=${OPTARG}
		    ;;
		v)
		    VERSION=${OPTARG}
		    ;;
		i)
		    INTERMEDIATE_FILES=${OPTARG}
		    ;;
		g)
		    GTDB_TAXONOMY=${OPTARG}
		    ;;
		r)
		    RRNA=${OPTARG}
		    ;;
		j)
		    JOB=${OPTARG}
		    ;;
		f)
		    ALL_FNA=${OPTARG}
		    ;;
		s)
		    INPUT_CSV=${OPTARG}
		    ;;
        z)
		    MEM=${OPTARG}
		    ;;
		t)
		    THREADS=${OPTARG}
		    ;;
		?)
		    usage
            exit
            ;;
	esac
done

echo "Creating yml"
NAME="$(basename -- "${INPUT_CSV}")"
export YML_FILE="${YML}"/metadata.yml
echo \
"
extra_weights_table:
  class: File
  path: ${INTERMEDIATE_FILES}/extra_weight_table.txt
checkm_results_table:
  class: File
  path: ${INTERMEDIATE_FILES}/renamed_${NAME}
rrna_dir:
  class: Directory
  path: ${RRNA}
naming_table:
  class: File
  path: ${INTERMEDIATE_FILES}/names.tsv
clusters_split:
  class: File
  path: ${INTERMEDIATE_FILES}/clusters_split.txt
metadata_outname: genomes-all_metadata.tsv
ftp_name_catalogue: ${DIRNAME}
ftp_version_catalogue: ${VERSION}
geo_file:
  class: File
  path: ${GEO}
gunc_failed_genomes:
  class: File
  path: ${OUT}/gunc-failed.txt
gtdb_taxonomy:
  class: File
  path: ${GTDB_TAXONOMY}
all_fna_dir:
  class: Directory
  path: ${ALL_FNA}
" > "${YML_FILE}"

export CWL=${P}/cwl/sub-wfs/5_gtdb/metadata_and_phylo_tree.cwl
echo "Submitting GTDB-Tk metadata and phylo.tree generation"
bsub \
    -J "${JOB}.${DIRNAME}.run" \
    -q "${QUEUE}" \
    -e "${LOGS}"/metadata.err \
    -o "${LOGS}"/metadata.out \
    -M "${MEM}" \
    -n "${THREADS}" \
    bash "${P}"/cluster/codon/run-cwltool.sh \
        -d False \
        -p "${P}" \
        -o "${OUT}" \
        -n "${DIRNAME}_metadata" \
        -c "${CWL}" \
        -y "${YML_FILE}"