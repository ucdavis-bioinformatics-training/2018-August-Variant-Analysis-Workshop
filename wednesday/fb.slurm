#!/bin/bash

#SBATCH --job-name=freebayes # Job name
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --time=300
#SBATCH --mem=40000 # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --partition=production
#SBATCH --reservation=workshop


begin=`date +%s`

BAMLIST=$1
REGION=$2
REF=../ref/chr18.fa

echo Region $REGION

module load freebayes

freebayes -L $BAMLIST -f $REF --region $REGION --vcf freebayes.chr18.$REGION.vcf

end=`date +%s`
elapsed=`expr $end - $begin`
echo Time taken: $elapsed

