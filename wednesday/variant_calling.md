Variant Calling using Freebayes and Delly
==========================================

Now we will call variants (SNPs and indels) using two different programs, 'freebayes' and 'delly'. We will use the output from the alignment step as input into these programs. In the end you will get a VCF (Variant Call Format) file with genotype information for every variant across all the samples.

![fc04](fc04.png)

---

**1\.** First, create a new directory for calling variants:

    cd ~/variant_example
    mkdir 03-freebayes
    cd 03-freebayes

Now, let's link in the relevant files from our alignments, along with their indices:

    ln -s ../02-Alignment/*.sorted.bam .
    ln -s ../02-Alignment/*.sorted.bam.bai .

---

**2\.** Now we will use software called 'freebayes' to find SNPs and short indels. Load the module and take a look at the help text:

    module load freebayes
    freebayes -h

Freebayes has many options, but we are going to run with the defaults. You can set the ploidy as an option, but the default is 2 (i.e. diploid). Also, even with our reduced data set, freebayes will take about 6 hours to run. So, we will run it on the cluster. Download the Slurm script for freebayes:

    wget https://raw.githubusercontent.com/ucdavis-bioinformatics-training/2018-August-Variant-Analysis-Workshop/master/wednesday/fb.slurm

Change the permissions:

    chmod a+x fb.slurm

Take a look at the file:

    cat fb.slurm

The way that we are running freebayes uses, as input, a text file containing a list of BAMs to analyze (the "-L" option). You will need to create this text file before you can run the script:

    ls *.sorted.bam > bamlist.txt

Check the file and make sure it looks right:

    cat bamlist.txt

There should be five filenames, one per line.

---

**3\.** You will also notice that the slurm script needs a region. The region option allows you to run freebayes in parallel across multiple regions. This is very useful because freebayes takes a long time to run and splitting up the regions (and running on a cluster) will make it much faster. Generally, you could just split based on chromosome, but here we will use a finer split within one chromosome. In order to split the region, we need to know the length of the fasta file. The easiest way to find the length of a single sequence fasta file (like chr18.fa) is to use the "tail", "tr", and "wc" commands. The "tr" command is used the change (translate) one character into another. In this case we will take everything but the header line of the chr18.fa file, delete the newline characters, and count the remaining characters. First, take a look at the beginning of just the sequence part of chr18.fa:

    tail -n +2 ../ref/chr18.fa | head

Now, delete the newlines using the "-d" option to "tr":

    tail -n +2 ../ref/chr18.fa | head | tr -d '\n'

And then count the characters for the entire file (by removing "head" and using the "-c" option for "wc"):

    tail -n +2 ../ref/chr18.fa | tr -d '\n' | wc -c

You should get **82527541**.

Now, run the script 9 times using sbatch and specifying regions of 10Mb (except the last region):

    sbatch fb.slurm bamlist.txt chr18:1-10000000
    sbatch fb.slurm bamlist.txt chr18:10000001-20000000
    sbatch fb.slurm bamlist.txt chr18:20000001-30000000
    sbatch fb.slurm bamlist.txt chr18:30000001-40000000
    sbatch fb.slurm bamlist.txt chr18:40000001-50000000
    sbatch fb.slurm bamlist.txt chr18:50000001-60000000
    sbatch fb.slurm bamlist.txt chr18:60000001-70000000
    sbatch fb.slurm bamlist.txt chr18:70000001-80000000
    sbatch fb.slurm bamlist.txt chr18:80000001-82527541

This will take about an hour to run.

---

**4\.** When it is done, you need to merge all the vcf files into one file. First, get just the header lines for the final file from one of the files:

    grep ^# freebayes.chr18.chr18:1-10000000.vcf > freebayes.chr18.all.vcf

This command looks for lines that begin with the "#" character (called "comments"). The "^" character is the symbol for "beginning of line". The output is then redirected into a new file. Finally, append the variant calls from each of the vcf files, without the comment lines:

    cat freebayes.chr18.chr18:1-10000000.vcf freebayes.chr18.*001*.vcf | grep -v ^# >> freebayes.chr18.all.vcf

---

**5\.** Now, let's run delly. We are going to use delly to find large deletions in our data. Load the module and take a look at the help pages:

    module load delly
    delly --help
    delly call --help

Now, run delly giving it a reference and all of our bam files:

    nohup delly call -o delly.chr18.bcf -g ../ref/chr18.fa *.sorted.bam &

This should take about 1.5 hours to run. We need to then convert the bcf file to a vcf so we can take a look at it:

    module load bcftools
    bcftools convert -o delly.chr18.vcf delly.chr18.bcf

---

**6\.** Take a look at the output:

    less delly.chr18.vcf

We want to just get the variants that "PASS", not the "LowQual" ones. So we will use a program called 'awk' to do that. 'awk' is a simple language designed for text processing in Unix. The command below looks at the 7th column ($7) on a line, and if the value of that column is "PASS", it prints out the line.

	grep "^#" delly.chr18.vcf > delly.chr18.filtered.vcf
    cat delly.chr18.vcf | awk '{ if($7=="PASS") print}' >> delly.chr18.filtered.vcf

Take a look at the filtered file. It should only contain "PASS" variants:

    less delly.chr18.filtered.vcf

The deletion from the paper is in this file. See if you can find it in the file. Also, look at the [VCF specification](https://samtools.github.io/hts-specs/VCFv4.2.pdf) to get more details of the different fields.
