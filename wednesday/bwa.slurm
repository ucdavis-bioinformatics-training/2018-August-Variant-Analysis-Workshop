#!/bin/bash

#SBATCH --job-name=align # Job name
#SBATCH --nodes=1
#SBATCH --cpus-per-task=6
#SBATCH --time=1000
#SBATCH --mem=20000 # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --partition=production
#SBATCH --reservation=workshop


begin=`date +%s`

sample=$1
R1=${sample}_R1.fastq.gz
R2=${sample}_R2.fastq.gz

REF=

echo $sample

module load bwa
module load samtools

bwa mem -t 6 -R "@RG\tID:$sample\tSM:$sample" $REF $R1 $R2 > ${sample}.chr18.sam

samtools view -@ 6 -b ${sample}.chr18.sam > ${sample}.chr18.bam

samtools sort -@ 6 -o ${sample}.chr18.sorted.bam ${sample}.chr18.bam

samtools index ${sample}.chr18.sorted.bam

end=`date +%s`
elapsed=`expr $end - $begin`
echo Time taken: $elapsed

