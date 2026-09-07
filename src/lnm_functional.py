#!/usr/bin/env python3

import argparse
from pathlib import Path

import nibabel as nib
import numpy as np
import pandas as pd
from nilearn.glm.second_level import SecondLevelModel
from nilearn.maskers import NiftiMasker


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Compute a functional disconnectivity map for one lesion."
    )
    parser.add_argument(
        "project_path",
        type=Path,
        help="Project directory containing the data directory.",
    )
    parser.add_argument(
        "lesion_name",
        help="Lesion filename without the .nii.gz extension.",
    )
    return parser.parse_args()


def require_file(path: Path) -> Path:
    if not path.is_file():
        raise FileNotFoundError(f"Required input file not found: {path}")
    return path


def main() -> None:
    args = parse_args()
    data_dir = args.project_path.resolve() / "data"

    gm_mask = nib.load(require_file(data_dir / "gm_mask_2mm.nii.gz"))
    gm_vol = gm_mask.get_fdata()

    lesion_path = require_file(data_dir / "lesion" / f"{args.lesion_name}.nii.gz")
    lesion_mask = nib.load(lesion_path)
    lesion_vol = lesion_mask.get_fdata()
    if lesion_vol.shape != gm_vol.shape:
        raise ValueError(
            f"Lesion and grey-matter masks have different shapes: "
            f"{lesion_vol.shape} != {gm_vol.shape}"
        )

    lesion_cut = nib.Nifti1Image(lesion_vol * gm_vol, lesion_mask.affine)
    if not np.any(lesion_cut.get_fdata()):
        raise ValueError(f"Lesion does not overlap the grey-matter mask: {lesion_path}")

    lesion_masker = NiftiMasker(mask_img=lesion_cut, standardize="zscore_sample")
    gm_masker = NiftiMasker(mask_img=gm_mask, standardize="zscore_sample")

    participants_path = require_file(data_dir / "participants.tsv")
    normative_population = pd.read_csv(participants_path, sep="\t")
    if "ID" not in normative_population:
        raise ValueError(f"Missing ID column in {participants_path}")
    if normative_population.empty:
        raise ValueError(f"No participants found in {participants_path}")

    seed_to_voxel_correlations_group = []
    for subject_id in normative_population["ID"].astype(str):
        resting_path = require_file(
            data_dir / "func" / subject_id / f"{subject_id}_preprocessed.nii.gz"
        )
        resting_img = nib.load(resting_path)
        ts_lesion = lesion_masker.fit_transform(resting_img).mean(axis=1).reshape(-1, 1)
        ts_gm = gm_masker.fit_transform(resting_img)
        seed_to_voxel_correlations = np.dot(ts_gm.T, ts_lesion) / ts_lesion.shape[0]
        fisher_z = np.arctanh(seed_to_voxel_correlations)
        seed_to_voxel_correlations_group.append(gm_masker.inverse_transform(fisher_z.T))

    design_matrix = pd.DataFrame(
        {"intercept": np.ones(len(seed_to_voxel_correlations_group))}
    )
    second_level_model = SecondLevelModel().fit(
        seed_to_voxel_correlations_group,
        design_matrix=design_matrix,
    )
    z_map = second_level_model.compute_contrast(
        second_level_contrast="intercept",
        output_type="z_score",
    )

    output_dir = data_dir / "functional_disconnectivity"
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / f"{args.lesion_name}_Fdisconnectivity.nii.gz"
    z_map.to_filename(output_path)
    print(f"Functional disconnectivity map written to {output_path}")


if __name__ == "__main__":
    main()
