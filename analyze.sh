#!/bin/sh
#conda activate qiime2-2021.11
mkdir qzv
start=`date +%s`

echo -e "\e[36mImporting Data"
qiime tools import --type 'SampleData[SequencesWithQuality]' --input-path reads --input-format CasavaOneEightSingleLanePerSampleDirFmt --output-path reads.qza

echo -e "\e[36mSummarize"
qiime demux summarize --i-data reads.qza --o-visualization reads.qzv
echo -e "\e[37mMoving reads.qzv to the /qzv folder"
mv reads.qzv qzv/reads.qzv

echo -e "\e[91mPlease Check the summary : reads.qzv"
echo -e "\e[32mTrim left value ?"
read trimleft
echo -e "\e[32mTrunc len value ?"
read trunclen

echo -e "\e[36mDenoising with trim-left=$trimleft and trunc-len=$trunclen"
qiime dada2 denoise-single --p-trim-left $trimleft --p-trunc-len $trunclen --i-demultiplexed-seqs reads.qza --o-representative-sequences repseq.qza --o-table table.qza --o-denoising-stats stat.qza --p-n-threads 8

echo -e "\e[36mGenerating feature table"
qiime feature-table summarize --i-table table.qza --o-visualization table.qzv --m-sample-metadata-file metadata.tsv
qiime feature-table tabulate-seqs --i-data repseq.qza --o-visualization repseq.qzv
qiime metadata tabulate --m-input-file stat.qza --o-visualization stat.qzv
echo -e "\e[37mMoving table.qzv, repseq.qzv and stat.qzv to the /qzv folder"
mv table.qzv qzv/table.qzv
mv repseq.qzv qzv/repseq.qzv
mv stat.qzv qzv/stat.qzv

echo -e "\e[91mPlease Check the file table.qzv to determine the max squencing depth"
echo -e "\e[32mSequencing depth ?"
read seqdepth

echo -e "\e[36mClassification with GreenGenes Basic model"
qiime feature-classifier classify-sklearn --i-classifier gg-13-8-99-nb-classifier.qza --i-reads repseq.qza --o-classification taxonomy-GGBasic.qza

echo -e "\e[36mClassification with GreenGenes Plant surface"
qiime feature-classifier classify-sklearn --i-classifier gg138_v4_plant-surface_classifier.qza --i-reads repseq.qza --o-classification taxonomy-GGPlantSurface.qza

echo -e "\e[36mClassification with Silva Basic model"
qiime feature-classifier classify-sklearn --i-classifier silva-138-99-nb-classifier.qza --i-reads repseq.qza --o-classification taxonomy-SilvaBasic.qza

echo -e "\e[36mClassification with Silva Plant surface"
qiime feature-classifier classify-sklearn --i-classifier silva139_plant-surface_classifier.qza --i-reads repseq.qza --o-classification taxonomy-SilvaPlantSurface.qza

echo -e "\e[36mTaxonomy visualization (txt)"
qiime metadata tabulate --m-input-file taxonomy-GGBasic.qza --o-visualization taxonomy-GGBasic.qzv
qiime metadata tabulate --m-input-file taxonomy-GGPlantSurface.qza --o-visualization taxonomy-GGPlantSurface.qzv
qiime metadata tabulate --m-input-file taxonomy-SilvaBasic.qza --o-visualization taxonomy-SilvaBasic.qzv
qiime metadata tabulate --m-input-file taxonomy-SilvaPlantSurface.qza --o-visualization taxonomy-SilvaPlantSurface.qzv

echo -e "\e[37mMoving taxonomy-GGBasic.qzv, taxonomy-GGPlantSurface.qzv, taxonomy-SilvaBasic.qzv and taxonomy-SilvaPlantSurface.qzv to the /qzv folder"
mv taxonomy-Basic.qzv qzv/taxonomy-GGBasic.qzv
mv taxonomy-PlantSurface.qzv qzv/taxonomy-GGPlantSurface.qzv
mv taxonomy-Basic.qzv qzv/taxonomy-SilvaBasic.qzv
mv taxonomy-PlantSurface.qzv qzv/taxonomy-SilvaPlantSurface.qzv

echo -e "\e[36mTaxonomy visualization (barplot)"
qiime taxa barplot --i-table table.qza --i-taxonomy taxonomy-GGBasic.qza --m-metadata-file metadata.tsv --o-visualization taxa-bar-plots-GGBasic.qzv
qiime taxa barplot --i-table table.qza --i-taxonomy taxonomy-GGPlantSurface.qza --m-metadata-file metadata.tsv --o-visualization taxa-bar-plots-GGPlantSurface.qzv
qiime taxa barplot --i-table table.qza --i-taxonomy taxonomy-SilvaBasic.qza --m-metadata-file metadata.tsv --o-visualization taxa-bar-plots-SilvaBasic.qzv
qiime taxa barplot --i-table table.qza --i-taxonomy taxonomy-SilvaPlantSurface.qza --m-metadata-file metadata.tsv --o-visualization taxa-bar-plots-SilvaPlantSurface.qzv
echo -e "\e[37mMoving taxa-bar-plots-GGBasic.qzv, taxa-bar-plots-GGPlantSurface.qzv, taxa-bar-plots-SilvaBasic.qzv and taxa-bar-plots-SilvaPlantSurface.qzv to the /qzv folder"

mv taxa-bar-plots-GGBasic.qzv qzv/taxa-bar-plots-GGBasic.qzv
mv taxa-bar-plots-GGPlantSurface.qzv qzv/taxa-bar-plots-PlantSurface.qzv
mv taxa-bar-plots-SilvaBasic.qzv qzv/taxa-bar-plots-SilvaBasic.qzv
mv taxa-bar-plots-SilvaPlantSurface.qzv qzv/taxa-bar-plots-SilvaPlantSurface.qzv

echo -e "\e[36mPhylogenic tree"
qiime alignment mafft --i-sequences repseq.qza --o-alignment aligned-repseq.qza
qiime alignment mask --i-alignment aligned-repseq.qza --o-masked-alignment masked-aligned-repseq.qza
qiime phylogeny fasttree --i-alignment masked-aligned-repseq.qza --o-tree unrooted-tree.qza
qiime phylogeny midpoint-root --i-tree unrooted-tree.qza --o-rooted-tree rooted-tree.qza

echo -e "\e[36mAlpha rarefaction"
qiime diversity alpha-rarefaction --i-table table.qza --i-phylogeny rooted-tree.qza --p-max-depth $seqdepth --m-metadata-file metadata.tsv --o-visualization alpha-rarefaction.qzv
echo -e "\e[37mMoving alpha-rarefaction.qzv to the /qzv folder"
mv alpha-rarefaction.qzv qzv/alpha-rarefaction.qzv
echo -e "\e[91mMake sure the sequencing depth is large enough from : alpha-rarefaction.qzv "

echo -e "\e[36mDiversity setup"
qiime diversity core-metrics-phylogenetic --i-phylogeny rooted-tree.qza --i-table table.qza --p-sampling-depth $seqdepth --m-metadata-file metadata.tsv --output-dir results
echo -e "\e[37mMoving unweighted_unifrac_emperor.qzv, weighted_unifrac_emperor.qzv, jaccard_emperor.qzv and bray_curtis_emperor.qzv to the /qzv folder"
mv results/unweighted_unifrac_emperor.qzv qzv/unweighted_unifrac_emperor.qzv
mv results/weighted_unifrac_emperor.qzv qzv/weighted_unifrac_emperor.qzv
mv results/jaccard_emperor.qzv qzv/jaccard_emperor.qzv
mv results/bray_curtis_emperor.qzv qzv/bray_curtis_emperor.qzv

echo -e "\e[36mAlpha diversity faith pd"
qiime diversity alpha-group-significance --i-alpha-diversity results/faith_pd_vector.qza --m-metadata-file metadata.tsv --o-visualization results/faith-pd-group-significance.qzv
echo -e "\e[37mMoving faith-pd-group-significance.qzv to the /qzv folder"
mv results/faith-pd-group-significance.qzv qzv/faith-pd-group-significance.qzv

echo -e "\e[36mAlpha diversity eveness"
qiime diversity alpha-group-significance --i-alpha-diversity results/evenness_vector.qza --m-metadata-file metadata.tsv --o-visualization results/evenness-group-significance.qzv
echo -e "\e[37mMoving evenness-group-significance.qzv to the /qzv folder"
mv results/evenness-group-significance.qzv qzv/evenness-group-significance.qzv

echo -e "\e[36mAlpha diversity Shannon"
qiime diversity alpha-group-significance --i-alpha-diversity results/shannon_vector.qza --m-metadata-file metadata.tsv --o-visualization results/shannon_group-significance.qzv
echo -e "\e[37mMoving shannon_group-significance.qzv to the /qzv folder"
mv results/shannon_group-significance.qzv qzv/shannon_group-significance.qzv

echo -e "\e[36mGNEISS"
qiime gneiss correlation-clustering --i-table table.qza --o-clustering hierarchy.qza
qiime gneiss dendrogram-heatmap --i-table table.qza --i-tree hierarchy.qza --m-metadata-file metadata.tsv --m-metadata-column type --o-visualization heatmap.qzv
echo -e "\e[37mMoving heatmap.qzv to the /qzv folder"
mv heatmap.qzv qzv/heatmap.qzv

echo -e "\e[36mBeta TYPE unweighted"
qiime diversity beta-group-significance --i-distance-matrix results/unweighted_unifrac_distance_matrix.qza --m-metadata-file metadata.tsv --m-metadata-column type --o-visualization results/unweighted-unifrac-type-significance.qzv --p-pairwise
echo -e "\e[37mMoving unweighted-unifrac-type-significance.qzv to the /qzv folder"
mv results/unweighted-unifrac-type-significance.qzv qzv/unweighted-unifrac-type-significance.qzv

echo -e "\e[36mBeta TYPE weighted"
qiime diversity beta-group-significance --i-distance-matrix results/weighted_unifrac_distance_matrix.qza --m-metadata-file metadata.tsv --m-metadata-column type --o-visualization results/weighted-unifrac-type-significance.qzv --p-pairwise
echo -e "\e[37mMoving weighted-unifrac-type-significance.qzv to the /qzv folder"
mv results/weighted-unifrac-type-significance.qzv qzv/weighted-unifrac-type-significance.qzv

echo -e "\e[36mBeta VARIETY unweighted"
qiime diversity beta-group-significance --i-distance-matrix results/unweighted_unifrac_distance_matrix.qza --m-metadata-file metadata.tsv --m-metadata-column variety --o-visualization results/unweighted-unifrac-variety-significance.qzv --p-pairwise
echo -e "\e[37mMoving unweighted-unifrac-variety-significance.qzv to the /qzv folder"
mv results/unweighted-unifrac-variety-significance.qzv qzv/unweighted-unifrac-variety-significance.qzv

echo -e "\e[36mBeta VARIETY weighted"
qiime diversity beta-group-significance --i-distance-matrix results/weighted_unifrac_distance_matrix.qza --m-metadata-file metadata.tsv --m-metadata-column variety --o-visualization results/weighted-unifrac-variety-significance.qzv --p-pairwise
echo -e "\e[37mMoving weighted-unifrac-variety-significance.qzv to the /qzv folder"
mv results/weighted-unifrac-variety-significance.qzv qzv/weighted-unifrac-variety-significance.qzv

echo -e "\e[36mANCOM BIO"
qiime feature-table filter-samples --i-table table.qza --m-metadata-file metadata.tsv --p-where "type='BIO'" --o-filtered-table BIO-table.qza
qiime composition add-pseudocount --i-table BIO-table.qza --o-composition-table comp-BIO-table.qza
qiime composition ancom --i-table comp-BIO-table.qza --m-metadata-file metadata.tsv --m-metadata-column variety --o-visualization ancom-BIO.qzv
echo -e "\e[37mMoving ancom-BIO.qzv to the /qzv folder"
mv ancom-BIO.qzv qzv/ancom-BIO.qzv

echo -e "\e[36mANCOM COV"
qiime feature-table filter-samples --i-table table.qza --m-metadata-file metadata.tsv --p-where "type='COV'" --o-filtered-table COV-table.qza
qiime composition add-pseudocount --i-table COV-table.qza --o-composition-table comp-COV-table.qza
qiime composition ancom --i-table comp-COV-table.qza --m-metadata-file metadata.tsv --m-metadata-column variety --o-visualization ancom-COV.qzv
echo -e "\e[37mMoving ancom-COV.qzv to the /qzv folder"
mv ancom-COV.qzv qzv/ancom-COV.qzv

end=`date +%s`
echo DONE
runtime=$( echo "$end - $start" | bc -l )
hours=$((runtime / 3600));
minutes=$(( (runtime % 3600) / 60 ));
seconds=$(( (runtime % 3600) % 60 ));
echo "Runtime: $hours h:$minutes m:$seconds s"
