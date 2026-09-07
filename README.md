# LNM

Understanding how brain lesions from a stroke affect a patient's behavior is critical for optimizing their care. Traditionally, clinicians link the location of a lesion to a specific functional problem. A major advance in this area is Lesion Network Mapping (LNM), a technique based on the idea that symptoms arise not just from the lesion itself, but from the disruption of entire brain networks.

This tool computes the functional and structural dysconnectivity maps for a given lesion mask and normative dataset.

<p align="center">
    <img src="docs/lnm_logo.png" alt="Description" width="200"/>
</p>

## CITE
Antonio Jimenez-Marin, Silke Boulanger, Iñigo Tellaetxe-Elorriaga, Iñaki Escudero, Ivan Gil De Sousa, Marimar Freijo, Pedro I Tejada, Asier Erramuzpe, Jesus M. Cortes. COGNET-STROKE: A NOVEL BRAIN DYSCONNECTIVITY TOOL FOR PREDICTION OF COGNITIVE DEFICITS AFTER STROKE. MedRxiv. 2025. https://doi.org/10.1101/2023.08.04.551953

## Background

Beyond the characteristics of a brain lesion, such as its etiology, size or location, LNM has shown that similar symptoms after a brain lesion reflects similar dysconnectivity patterns, thereby linking symptoms to brain networks.

## Description

Here we provide the code for computing LNM maps based on functional data (resting-state fMRI) and structural data (diffusion MRI).

- **Functional dysconnectivity maps**: the maps are based on the correlation between the average time-serie inside the lesioned area and the rest of the voxels of the brain (Seed Based Connectivity - SBC). Once the maps are computed in all the normative subjects, a *one-sample t-test* is performed to generate a unique dysconnectivity map per lesion.

- **Structural dysconnectivity maps**: the maps are based on the fibers passing through the lesion mask in a *whole brain structural connectome*. The structural connectome is computed using a *deterministc tractography* with the [FACT algorithm](https://doi.org/10.1016/S1053-8119(18)31543-X). After that, the map is binarized. Once we have a binary mask in all normative subjects, we sum that dysconnectivity masks.

- **Tract disconnection values**: the values are based on the number of fibers passing through the lesion mask in a the canonical tracts defined by [Yeh et al. (2022)](https://doi.org/10.1038/s41467-022-32595-4). The tracts can be downloaded from the [fiber data hub](https://github.com/data-others/atlas/releases/download/hcp1065/hcp1065_avg_tracts_trk.zip). Then should be transformed to `.tck` format using the code in `src/utils/`.

## Running with Docker

Docker is the only host prerequisite; a Dev Container is not required. The
project image is based on
[`compneurobilbaolab/compneuro-dwiproc:1.0.0`](https://hub.docker.com/r/compneurobilbaolab/compneuro-dwiproc),
which supplies MRtrix3, ANTs, FSL, and the scientific Python stack. The local
Dockerfile adds Nilearn, the only dependency needed by `lnm_functional.py`
that is missing from the upstream image.

Build the small derived image once:

```bash
docker build -t lnm:latest .
```

The helper mounts this repository at `/work`, runs as the current user, and
writes results back to `data/`:

```bash
# Functional disconnectivity map for data/lesion/sub-001.nii.gz
./src/run_lnm.sh functional sub-001

# Structural disconnectivity map for the same lesion
./src/run_lnm.sh structural sub-001

# Disconnection values for every lesion listed in data/lesion_list.txt
./src/run_lnm.sh tracts

# Optional tract conversion utility (paths are relative to this repository)
./src/run_lnm.sh trk-to-tck data/tract.trk data/tract.tck
```

`src/run_lnm.sh` builds `lnm:latest` automatically when it does not exist. Set
`LNM_IMAGE` to select another compatible, already-built image.
