#!/bin/bash

project_path=$1
echo "BIDS,Tract,Disc" > ${project_path}/data/lnm_tracts.csv

mkdir -p ${project_path}/data/tck_exclusion_temp_folder
for subject in $(cat ${project_path}/data/lesion_list.txt)
do
    for tract in $(cat ${project_path}/data/yeh_tracts/labels.txt)
    do
        n_orig_stream=$(tckstats -output count ${project_path}/data/yeh_tracts/${tract}.tck)
        tckedit ${project_path}/data/yeh_tracts/${tract}.tck -exclude \
            ${project_path}/data/lesion/${subject}.nii.gz -force ${project_path}/data/tck_exclusion_temp_folder/${tract}_${subject}.tck
        n_after_exclude_lesion=$(tckstats -output count ${project_path}/data/tck_exclusion_temp_folder/${tract}_${subject}.tck)
        exclusion_ratio=$(echo "scale=3 ; $n_after_exclude_lesion / $n_orig_stream" | bc)
        echo "$subject,$tract,$exclusion_ratio" >> ${project_path}/data/lnm_tracts.csv
    done
done
