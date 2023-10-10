# fastqc bedtools tabix

# [[file:ngsoneliners.org::*fastqc bedtools tabix][fastqc bedtools tabix:1]]
apt update -y
apt install -y fastqc tabix bedtools
# fastqc bedtools tabix:1 ends here

# ggplot2
# Debian packages lots of R packages so we don't have to compile it.


# [[file:ngsoneliners.org::*ggplot2][ggplot2:1]]
apt update -y
apt install -y r-cran-ggplot2
# ggplot2:1 ends here

# multiqc and igv-reports
# Debian also packages multiqc but it is version 1.4 which doesn't have software version or custom image module we are using.
# In order to get the latest version of multiqc we need to spin up a virtual environment.
# IGV-reports is also a python package we can use the same environment while installing.


# [[file:ngsoneliners.org::*multiqc and igv-reports][multiqc and igv-reports:1]]
apt update -y
apt install -y python3-virtualenv
virtualenv -p python3 venv
source venv/bin/activate
pip install -U multiqc igv-reports
# multiqc and igv-reports:1 ends here

# fastp

# [[file:ngsoneliners.org::*fastp][fastp:1]]
apt update -y
apt install -y wget
wget http://opengene.org/fastp/fastp -O /usr/bin/fastp
chmod a+x /usr/bin/fastp
# fastp:1 ends here

# BWA

# [[file:ngsoneliners.org::*BWA][BWA:1]]
apt update -y
apt install -y git gcc zlib1g-dev make
git clone https://github.com/lh3/bwa
cd bwa
make
cp ./bwa /usr/local/bin/
cd ..
rm -rf bwa
# BWA:1 ends here

# samtools

# [[file:ngsoneliners.org::*samtools][samtools:1]]
apt update -y
apt install -y \
  git gcc zlib1g-dev autoconf make \
  liblzma-dev libbz2-dev libcurl4-openssl-dev
git clone --recurse-submodules https://github.com/samtools/htslib.git
git clone https://github.com/samtools/samtools

cd samtools
autoheader
autoconf -Wno-syntax
./configure --without-curses
make
make install
cd ..
rm -rf samtools
rm -rf htslib
# samtools:1 ends here

# bcftools

# [[file:ngsoneliners.org::*bcftools][bcftools:1]]
apt update -y
apt install -y \
  git gcc zlib1g-dev autoconf make \
  liblzma-dev libbz2-dev libperl-dev \
  libgsl-dev libcurl4-openssl-dev
git clone --recurse-submodules https://github.com/samtools/htslib.git
git clone https://github.com/samtools/bcftools

cd bcftools
autoheader && autoconf && ./configure --enable-libgsl --enable-perl-filters
make
make install
cd ..
rm -rf bcftools
rm -rf htslib
# bcftools:1 ends here

# ensembl-vep
# Installing the vep cache takes time...


# [[file:ngsoneliners.org::*ensembl-vep][ensembl-vep:1]]
apt install -y \
    zlib1g-dev libbz2-dev liblzma-dev gcc \
    libmodule-build-perl libjson-perl libdbi-perl \
    libset-intervaltree-perl build-essential make \
    automake git unzip autoconf libdbd-mysql-perl \

git clone https://github.com/Ensembl/ensembl-vep.git
cd ensembl-vep
perl INSTALL.pl -a acf -s homo_sapiens -y GRCh38
# ensembl-vep:1 ends here
