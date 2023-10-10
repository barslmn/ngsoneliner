#!/bin/sh
# Oneliner :noexport:
# Copyright 2023 Barış Salman

# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the “Software”), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# AUTHOR="Barış Salman"
# EMAIL="barslmn@gmail.com"


# [[file:ngsoneliners.org::*Oneliner][Oneliner:1]]
set -eu

VERSION="v1.0.0"


BASEDIR=$(dirname "$(realpath "$0")")

THREADS=16
ASSEMBLY="GRCh38"
REFERENCE="$HOME/reference/GRCh38/Homo_sapiens_assembly38.fasta"
TARGET="$HOME/reference/GRCh38/hg38.refGene.exon.bed"
AMPLICON="NO"

R1="$HOME/sample/U0a_CGATGT_L001_R1_005.fastq.gz"
R2="$HOME/sample/U0a_CGATGT_L001_R2_005.fastq.gz"
SAMPLE="U0a"

OUTPUT_DIR="results.$$"

OUTPUT="$OUTPUT_DIR/$SAMPLE"
columns="[%SAMPLE]\t%CHROM\t%POS\t%REF\t%ALT\t%ID\t%FILTER[\t%GT\t%VAF\t%AD\t%DP]\t%Consequence\t%IMPACT\t%SYMBOL\t%Feature\t%EXON\t%INTRON\t%HGVSc\t%HGVSp\t%cDNA_position\t%CDS_position\t%Protein_position\t%Amino_acids\t%Codons\t%Existing_variation\t%MANE_SELECT\t%MANE_PLUS_CLINICAL\t%GENE_PHENO\t%SIFT\t%PolyPhen\t%DOMAINS\t%AF\t%gnomADe_AF\t%gnomADg_AF\t%MAX_AF\t%MAX_AF_POPS\t%CLIN_SIG\t%PHENO\t%PUBMED\t%CANONICAL\n"
header=$(echo "$columns" | sed "s/%//g;s/\[//g;s/\]//g")

mkdir -p "$OUTPUT_DIR"

cp "$0" "$OUTPUT_DIR"


monitor_resources() {
    while ps $$ >/dev/null; do
        du -b $OUTPUT_DIR/* | sed "s#^#$(date +%Y/%m/%d/%H:%M:%S) #" >>"$OUTPUT_DIR/file_sizes.$$.log"
        ps --ppid $$ --forest --no-heading -o %cpu,%mem,cmd 2>/dev/null |
            cut -d " " -f 1-6 |
            sed "s#^#$(date +%Y/%m/%d/%H:%M:%S) #" |
            grep -v "CMD\|pv\|ps" |
            awk '{print $4"_"$5"\t"$1"\t"$2"\t"$3}' >>"$OUTPUT_DIR/resources.$$.log"
        sleep 5
    done
}
monitor_resources &

fastp --in1 "$R1" --in2 "$R2" --stdout --html $OUTPUT.fastp.html --json $OUTPUT.fastp.json 2>$OUTPUT.$$.fastp.log |
    pv -cN fastp -s "$(gzip -l "$R1" "$R2" | awk '{print $2}' | tail -n1)" |
    bwa mem -p -t "$THREADS" -R "@RG\tID:name_placeholder\tSM:name_placeholder\tPL:illumina\tLB:lib1\tPU:foo" "$REFERENCE" - 2>"$OUTPUT.$$.bwa.log" |
    pv -cN bwa |
    samtools collate -@ "$THREADS" -O - |
    samtools fixmate -@ "$THREADS" -m - - |
    samtools sort -@ "$THREADS" - 2>"$OUTPUT.$$.samtools.log" |
    pv -cN samtools_sort |
    ([ "$AMPLICON" = "NO" ] && samtools markdup -@ "$THREADS" - - || cat) |
    pv -cN samtools_markdup |
    samtools view -C -T "$REFERENCE" - |
    tee "$OUTPUT.cram" |
    bcftools mpileup --threads "$THREADS" -Ou -A -T "$TARGET" -d 10000 -L 10000 -a "FORMAT/AD,FORMAT/DP" -f "$REFERENCE" - 2>>"$OUTPUT.$$.bcftools.log" |
    pv -cN bcftools_mpileup |
    bcftools call --threads "$THREADS" -Ou --ploidy "$ASSEMBLY" -mv |
    pv -cN bcftools_call |
    bcftools view -i 'FORMAT/DP>5&&QUAL>5' |
    bcftools norm --threads "$THREADS" -Ou -m-any --check-ref w -f "$REFERENCE" 2>>"$OUTPUT.$$.bcftools.log" |
    bcftools +fill-tags -Ou -- -t all 2>>"$OUTPUT.$$.bcftools.log" |
    bcftools +setGT -Ou -- -t q -n c:'0/1' -i 'VAF>=.1' 2>>"$OUTPUT.$$.bcftools.log" |
    bcftools +setGT -Ov -- -t q -n c:'1/1' -i 'VAF>=.75' 2>>"$OUTPUT.$$.bcftools.log" |
    /home/bar/ensembl-vep/vep --everything --force_overwrite --vcf --pick --format vcf \
        --fork $THREADS \
        --stats_file "$OUTPUT"_summary.html \
        --warning_file "$OUTPUT"_warnings.txt \
        --output_file STDOUT --compress bgzip --fork "$THREADS" --cache 2>"$OUTPUT.$$.vep.log" |
    pv -cN vep |
    bcftools +split-vep -c SYMBOL,gnomADg_AF:Float,IMPACT,Existing_variation 2>>"$OUTPUT.$$.bcftools.log" |
    bcftools filter --threads "$THREADS" -Ou -m+ -s 'onTarget' -M "$TARGET" |
    bcftools filter --threads "$THREADS" -Ou -m+ -s 'lowQual' -g3 -G10 -e 'FORMAT/DP<=15 || QUAL<=20' |
    bcftools filter --threads "$THREADS" -Ou -m+ -s 'highFreq' -e 'gnomADg_AF>0.001' |
    bcftools filter --threads "$THREADS" -Ou -m+ -s 'lowIMPACT' -i 'IMPACT~"HIGH" || IMPACT~"MODERATE"' |
    bcftools filter --threads "$THREADS" -Ou -m+ -s 'HOMrare' -e 'GT="1/1" && (gnomADg_AF <= 0.001 || (Existing_variation="." && gnomADg_AF="." && ID="."))' |
    bcftools filter --threads "$THREADS" -Ob -m+ -s 'HETnovel' -e 'GT="0/1" && Existing_variation="." && gnomADg_AF="." && ID="."' |
    tee "$OUTPUT.bcf" |
    bcftools +split-vep -f "$columns" -d -i 'CANONICAL~"YES"' 2>>"$OUTPUT.$$.bcftools.log" |
    awk -v header="$header" 'BEGIN {print  header} 1' |
    gzip -c >"$OUTPUT.tsv.gz"

{
    printf 'oneliner: "%s"\n' "$VERSION";
    printf 'fastp: "%s"\n' "$(fastp 2>&1 | grep version | cut -d " " -f 2)"
    printf 'bwa: "%s"\n' "$(bwa 2>&1 | grep Version | cut -d: -f2)"
    printf 'samtools: "%s"\n' "$(samtools version | sed 1q | cut -d " " -f 2)"
    printf 'bcftools: "%s"\n' "$(bcftools version | sed 1q | cut -d " " -f 2)"
    printf 'ensembl-vep: "%s"\n' "$(~/ensembl-vep/vep | grep ensembl-vep | cut -d : -f 2)"
    printf 'bedtools: "%s"\n' "$(bedtools --version | cut -d " " -f2)"
    (
        echo "annotation_sources:"
        ~/ensembl-vep/vep --show_cache_info | sed 's/\s/: "/;s/$/"/;s/^/    /'
    )
} >oneliner_mqc_versions.yaml

samtools index -@ $THREADS "$OUTPUT.cram"
samtools stats --reference "$REFERENCE" "$OUTPUT.cram" >"$OUTPUT.cram.stats"
samtools idxstats "$OUTPUT.cram" >"$OUTPUT.cram.idxstats"
samtools flagstat "$OUTPUT.cram" >"$OUTPUT.cram.flagstat"
bcftools stats "$OUTPUT.bcf" >"$OUTPUT.bcf.stats"
"$BASEDIR"/plot_resource_usage.R "$OUTPUT_DIR"
multiqc -f -s -o "$OUTPUT_DIR" "$OUTPUT_DIR"
# Oneliner:1 ends here
