import os
import sys
import numpy as np
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import nibabel as nib
from nilearn.maskers import NiftiMasker
from nilearn.glm.second_level import SecondLevelModel

project_path = sys.argv[1]
lesion_name = sys.argv[2]


gm_mask = nib.load(os.path.join(project_path, "data", "gm_mask_2mm.nii.gz"))
gm_vol = gm_mask.get_fdata()

lesion_mask = nib.load(
    os.path.join(project_path, "data", "lesion", lesion_name + ".nii.gz")
)
lesion_vol = lesion_mask.get_fdata()

lesion_cut = nib.Nifti1Image(lesion_vol * gm_vol, lesion_mask.affine)

lesion_masker = NiftiMasker(mask_img=lesion_cut, standardize="zscore_sample")
gm_masker = NiftiMasker(mask_img=gm_mask, standardize="zscore_sample")

normative_population = pd.read_csv(
    os.path.join(project_path, "data", "participants.tsv"), sep="\t"
)

seed_to_voxel_correlations_group = []
for sub in normative_population["ID"]:
    resting_img = nib.load(
        os.path.join(project_path, "data", "func", sub, sub + "_preprocessed.nii.gz")
    )
    ts_lesion = lesion_masker.fit_transform(resting_img).mean(axis=1).reshape(-1, 1)
    ts_gm = gm_masker.fit_transform(resting_img)
    seed_to_voxel_correlations = np.dot(ts_gm.T, ts_lesion) / ts_lesion.shape[0]
    seed_to_voxel_correlations_fisher_z = np.arctanh(seed_to_voxel_correlations)

    seed_to_voxel_correlations_group.append(
        gm_masker.inverse_transform(seed_to_voxel_correlations_fisher_z.T)
    )

second_level_model = SecondLevelModel()
design_matrix = pd.DataFrame(
    [1] * len(seed_to_voxel_correlations_group),
    columns=["intercept"],
)
second_level_model = second_level_model.fit(
    seed_to_voxel_correlations_group,
    design_matrix=design_matrix,
)

z_map = second_level_model.compute_contrast(
    second_level_contrast="intercept",
    output_type="z_score",
)

z_map.to_filename(
    os.path.join(project_path, "data", "functional_disconnectivity", lesion_name + "_Fdisconnectivity.nii.gz")
)
