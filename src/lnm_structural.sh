#!/bin/bash

project_path=$1
lesion_name=$2

brain_template=${project_path}/data/MNI152_T1_2mm_brain.nii.gz
lesion_mask=${project_path}/data/lesion/${lesion_name}.nii.gz
normative_population=${project_path}/data/participants.tsv

nvox_lesion=$(mrdump $lesion_mask | awk '{ sum += $1 } END { print sum }') 
fibr_to_select=$(echo "${nvox_lesion} * 100" | bc -l)

echo "Number of streamlines to select: ${fibr_to_select}"

mrcalc -force $brain_template -neg $brain_template -add \
    ${project_path}/data/structural_disconnectivity/${lesion_name}_Sdisconnectivity.nii.gz

count=0
for sub in $(cat $normative_population | awk '{ print $1 }' | tail -n +2)
do
    antsApplyTransforms -d 3 -r ${project_path}/data/dwi/${sub}/anat_dwispace.nii.gz \
        -i $lesion_mask -e 0 \
        -t ${project_path}/data/dwi/${sub}/dwireg/standard2dwi1Warp.nii.gz \
        -t ${project_path}/data/dwi/${sub}/dwireg/standard2dwi0GenericAffine.mat \
        -o ${project_path}/data/dwi/${sub}/${lesion_name}_subSpace.nii.gz -n NearestNeighbor -v 1

    tckgen -seed_image  ${project_path}/data/dwi/${sub}/dwi_mask.nii.gz -angle 45  \
        -maxlength 200 -select $fibr_to_select -algorithm FACT -downsample 5 -force \
        ${project_path}/data/dwi/${sub}/dwi_directions.nii.gz \
        -include  ${project_path}/data/dwi/${sub}/${lesion_name}_subSpace.nii.gz \
        ${project_path}/data/dwi/${sub}/lesion_streamlines.tck
    tckmap -template  ${project_path}/data/dwi/${sub}/dwi_bzero.nii.gz -force \
        ${project_path}/data/dwi/${sub}/lesion_streamlines.tck \
        ${project_path}/data/dwi/${sub}/lesion_streamlines.nii.gz
    antsApplyTransforms -d 3 -r ${brain_template} \
        -i ${project_path}/data/dwi/${sub}/lesion_streamlines.nii.gz -e 0 \
        -t [ ${project_path}/data/dwi/${sub}/dwireg/standard2dwi0GenericAffine.mat, 1 ] \
        -t ${project_path}/data/dwi/${sub}/dwireg/standard2dwi1InverseWarp.nii.gz \
        -o ${project_path}/data/dwi/${sub}/lesion_map_MNI.nii.gz -v 1
    mrcalc -force ${project_path}/data/dwi/${sub}/lesion_map_MNI.nii.gz 0 -neq \
        ${project_path}/data/structural_disconnectivity/${lesion_name}_Sdisconnectivity.nii.gz -add \
        ${project_path}/data/structural_disconnectivity/${lesion_name}_Sdisconnectivity.nii.gz
    count=$((count+1))
done

mrcalc -force ${project_path}/data/structural_disconnectivity/${lesion_name}_Sdisconnectivity.nii.gz \
    $count -div ${project_path}/data/structural_disconnectivity/${lesion_name}_Sdisconnectivity.nii.gz