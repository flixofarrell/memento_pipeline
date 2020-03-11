#MEMENETO PIPELINE 
#INPUT: SFF SINGLE-END

##run with: bash meta_pipe3.0_SS.sh GLXK8YI01.sff GLXK8YI01.txt  0

#bash pipelines/meta_pipe3.0_SS.sh GLXK8YI01.sff GLXK8YI01.txt CCGTCAATTCMTTTRAGT  CTGCTGCCTCCCCGTAGG 0

mkdir run_x
mkdir run_x/fastqs
mkdir run_x/qiime_artifacts
mkdir run_x/visuals
mkdir run_x/pi_in
mkdir run_x/logs

fastqdir=~/Desktop/run_x/fastqs
qiimedir=~/Desktop/run_x/qiime_artifacts
visdir=~/Desktop/run_x/visuals
pi_in=~/Desktop/run_x/pi_in
pi_out=~/Desktop/run_x/pi_out
log_dir=~/Desktop/run_x/logs 
tools_dir=~/Desktop/tools	

module load python/3.7.4 

##input options in command line 
#sff_file $1 GNKV64B01.sff
#barcode $2  GNKV64B01.txt
#f_primer $3 CCGTCAATTCMTTTRAGT
#r_primer $4 CTGCTGCCTCCCCGTAGG
#trunc_len $5 0
#load qiim $6

#convert sff and ensure all nucleotides are uppercase (will do QC in qiime)
python $tools_dir/sff_to_fastq.py $1 run_x 
python $tools_dir/convert_to_upper.py run_x.fastq
#zip so qiime can read
echo zipping the fastq_file
gzip run_x.fastq_upper.fastq
mv *.fastq $fastqdir
#load qiime2
module load qiime
source activate qiime2-2019.10
#import multiplexed 
echo importing fastqs into qiime...
qiime tools import \
--type MultiplexedSingleEndBarcodeInSequence \
--input-path run_x.fastq_upper.fastq.gz \
--output-path $qiimedir/multiplexed-seqs.qza
mv *.gz $fastqdir
#demultiplex the fastq using the barcode (specific)
echo demultiplexing data ...
qiime cutadapt demux-single \
--i-seqs $qiimedir/multiplexed-seqs.qza \
--m-barcodes-file $2 \
--m-barcodes-column Molecular\ Barcode \
--p-error-rate 0 \
--o-per-sample-sequences $qiimedir/demultiplexed-seqs.qza \
--o-untrimmed-sequences $qiimedir/untrimmed_demultiplexed-seqs.qza \
--verbose
##demultiplex seqs and check quality
echo summarizing demultiplexing ...
qiime demux summarize \
--i-data $qiimedir/demultiplexed-seqs.qza \
--o-visualization $visdir/demultiplexed-seqs.qzv \
##view qza file (as qzv file) - will open qiime2 tab in browser
#qiime tools view run_x/visuals/data_x.qzv 
echo cutting adapters  
qiime cutadapt trim-single \
--i-demultiplexed-sequences $qiimedir/demultiplexed-seqs.qza \
--p-front $3 \
--p-adapter $4 \
--o-trimmed-sequences $qiimedir/trimmed-seqs.qza \
--verbose 
#denoise the artefact 
echo denoising artefact ...
qiime dada2 denoise-single \
--i-demultiplexed-seqs $qiimedir/trimmed-seqs.qza \
--p-trunc-len $5 \
--p-n-threads 0 \
--o-representative-sequences $qiimedir/rep-seqs.qza \
--o-table $qiimedir/table_data_x.qza \
--o-denoising-stats $log_dir/denoising-stats.qza
#create tailored classifier
echo creating OTU classifier
echo importing greengenes sequences... 
#import ref otus 
qiime tools import \
  --type 'FeatureData[Sequence]' \
  --input-path $tools_dir/gg_13_8_otus/rep_set/99_otus.fasta \
  --output-path $qiimedir/99_otus.qza
#import ref sequences 
echo importing greengenes taxonmy... 
qiime tools import \
  --type 'FeatureData[Taxonomy]' \
  --input-format HeaderlessTSVTaxonomyFormat \
  --input-path $tools_dir/gg_13_8_otus/taxonomy/99_otu_taxonomy.txt \
  --output-path $qiimedir/ref-taxonomy.qza
#extracting ref reads from greengenes in the same way reads are extracted from this particular data set 
#takes into account truncation length, adapters etc - creates reference sequence artifact
echo extracting reads to train...this will take time 
qiime feature-classifier extract-reads \
  --i-sequences $qiimedir/99_otus.qza \
  --p-f-primer $3 \
  --p-r-primer $4 \
  --p-trunc-len $5 \
  --p-min-length 100 \
  --p-max-length 400 \
  --o-reads $qiimedir/ref-seqs.qza
echo training classifier...
#train the classifier on the refseqs that was just extracted 
qiime feature-classifier fit-classifier-naive-bayes \
 --i-reference-reads $qiimedir/ref-seqs.qza \
 --i-reference-taxonomy $qiimedir/ref-taxonomy.qza \
 --o-classifier $qiimedir/classifier.qza
echo classifying denoise output ...
#run the classifier on the representative sequences made from dada2
qiime feature-classifier classify-sklearn \
--i-classifier $qiimedir/classifier.qza \
--p-n-jobs 6 \
--i-reads $qiimedir/rep-seqs.qza  \
--o-classification $qiimedir/taxonomy.qza
#export the classification tree 
echo exporting OTU classification artefact
qiime tools export \
--input-path  $qiimedir/taxonomy.qza \
--output-path $pi_in 
#export fasta file of seqs
echo exporting rep-seqs artefact
qiime tools export \
--input-path $qiimedir/rep-seqs.qza \
--output-path $pi_in
#export .biom
echo exporting biom table 
qiime tools export \
--input-path $qiimedir/table_data_x.qza \
--output-path $pi_in
echo qiime finished
#reverse compliment the fasta file
echo rc the fasta 
python tools/rc_saftey_net.py $pi_in/dna-sequences.fasta
#move to pi_in dir
mv rc_dna-sequences.fasta $pi_in
sed -i -e "1d" $pi_in/rc_dna-sequences.fasta 
echo picrust2 ready 
module load picrust
source activate picrust2
##run picrust2
echo running picrust2
picrust2_pipeline.py \
-s $pi_in/rc_dna-sequences.fasta \
-i $pi_in/feature-table.biom \
--per_sequence_contrib \
--stratified \
-o $pi_out \
-p 4
#add name to ECs
echo adding descriptiosn to ECs and pathways
add_descriptions.py -i $pi_out/EC_metagenome_out/pred_metagenome_unstrat.tsv.gz -m EC \
                    -o $pi_out/EC_metagenome_out/pred_metagenome_unstrat_descrip.tsv.gz
#add name to pathways
add_descriptions.py -i $pi_out/pathways_out/path_abun_unstrat.tsv.gz -m METACYC \
                    -o $pi_out/pathways_out/path_abun_unstrat_descrip.tsv.gz

#Ariane's stats scripts 
python $tools_dir/ecscore.py	
python $tools_dir/Wilcoxon_test_EC.py	
python $tools_dir/pathwayscore.py	
python $tools_dir/Wilcoxon_test_pathway.py	
