#!/bin/bash

#SBATCH --job-name=gatk # Job name
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --time=1440
#SBATCH --mem=40000 # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --partition=production
#SBATCH --reservation=workshop

begin=`date +%s`

SAMPID=$1

# modules
module load samtools
module load picard-tools
module load gatk

# KNOWN_SNPS must be in reference order
# REF must end in .fa or .fasta
REF=../ref/chr18.fa
KNOWN_SNPS=../ref/chr18.vcf

# echo "marking duplicates"
# mark duplicates, assume sorted, has problems with unmapped reads with MQ!=0, so validation needs to be lenient
# picard MarkDuplicates VALIDATION_STRINGENCY=LENIENT AS=true REMOVE_DUPLICATES=true I=${SAMPID}.chr18.all.bam O=${SAMPID}.chr18.markdup.bam M=${SAMPID}.chr18.metrics

# create a dictionary file for the ref
if [ ! -e ${REF%.*}.dict ]
    then
        echo "creating dictionary file for reference"
        picard CreateSequenceDictionary R=$REF O=${REF%.*}.dict
fi

# need to index the reference
if [ ! -e $REF.fai ]
  then
    echo "Indexing reference"
    samtools faidx $REF
fi


echo "replacing read group and platform info"
# have to replace read groups to add platform info
picard AddOrReplaceReadGroups VALIDATION_STRINGENCY=LENIENT I=${SAMPID}.chr18.sorted.bam O=${SAMPID}.chr18.rg.bam RGID=$SAMPID RGLB=$SAMPID RGPL=illumina RGPU=$SAMPID RGSM=$SAMPID

echo "index new bam file"
# index new bam file
samtools index ${SAMPID}.chr18.rg.bam

echo "running BaseRecalibrator"
# run base quality recalibrator to get table for next step
gatk BaseRecalibrator -I ${SAMPID}.chr18.rg.bam -R $REF --known-sites $KNOWN_SNPS -O ${SAMPID}.chr18.recal_data.grp

echo "creating recalibrated BAM file"
# create recalibrated BAM using recalibration data from BaseRecalibrator step
gatk ApplyBQSR -R $REF -I ${SAMPID}.chr18.realigned.bam -bqsr ${SAMPID}.chr18.recal_data.grp -O ${SAMPID}.chr18.recalibrated.bam

echo "running haplotypecaller"
gatk HaplotypeCaller -R $REF -ERC GVCF -I ${SAMPID}.chr18.recalibrated.bam -O ${SAMPID}.chr18.g.vcf

end=`date +%s`
elapsed=`expr $end - $begin`
echo Time taken: $elapsed

