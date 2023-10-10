# downloading the reference genome

# [[file:ngsoneliners.org::*downloading the reference genome][downloading the reference genome:1]]
apt update -y
apt install -y wget

cd
mkdir -p reference/GRCh38
cd reference/GRCh38
wget https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.dict
wget https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta
wget https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta.64.alt
wget https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta.64.amb
wget https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta.64.ann
wget https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta.64.bwt
wget https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta.64.pac
wget https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta.64.sa
wget https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta.fai
cd
# downloading the reference genome:1 ends here

# downloading the sample data and target file

# [[file:ngsoneliners.org::*downloading the sample data and target file][downloading the sample data and target file:1]]
cd
mkdir -p sample
cd sample
wget https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data/NA12878/NIST_NA12878_HG001_HiSeq_300x/131219_D00360_005_BH814YADXX/Project_RM8398/Sample_U0a/U0a_CGATGT_L001_R1_005.fastq.gz
wget https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data/NA12878/NIST_NA12878_HG001_HiSeq_300x/131219_D00360_005_BH814YADXX/Project_RM8398/Sample_U0a/U0a_CGATGT_L001_R2_005.fastq.gz
cd "$HOME"/reference/GRCh38
wget https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/release/references/GRCh38/resources/hg38.refGene.exon.bed.gz
# downloading the sample data and target file:1 ends here

# Preprocess the target file
# We add some padding to the panel file


# [[file:ngsoneliners.org::*Preprocess the target file][Preprocess the target file:1]]
PADDING=100
wget https://hgdownload.cse.ucsc.edu/goldenpath/hg38/bigZips/hg38.chrom.sizes

bedtools slop -i hg38.refGene.exon.bed -g hg38.chrom.sizes -b $PADDING > hg38.refGene.exon_padding.bed
# Preprocess the target file:1 ends here
