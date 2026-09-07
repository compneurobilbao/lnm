#!/usr/bin/env bash
set -euo pipefail

readonly script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly project_dir="$(cd -- "$script_dir/.." && pwd)"
readonly image="${LNM_IMAGE:-lnm:latest}"

usage() {
    cat <<'EOF'
Usage:
  ./src/run_lnm.sh functional LESION_NAME
  ./src/run_lnm.sh structural LESION_NAME
  ./src/run_lnm.sh tracts
  ./src/run_lnm.sh trk-to-tck INPUT.trk OUTPUT.tck

LESION_NAME is the filename in data/lesion without the .nii.gz extension.
Set LNM_IMAGE to use a different locally available image tag.
EOF
}

if [[ $# -lt 1 ]]; then
    usage >&2
    exit 2
fi

if ! command -v docker >/dev/null 2>&1; then
    echo "Error: Docker is required but was not found." >&2
    exit 1
fi

if ! docker image inspect "$image" >/dev/null 2>&1; then
    if [[ "$image" != "lnm:latest" ]]; then
        echo "Error: Docker image '$image' is not available locally." >&2
        exit 1
    fi
    echo "Building $image from compneurobilbaolab/compneuro-dwiproc:1.0.0 ..."
    docker build --tag "$image" "$project_dir"
fi

container_command=()
case "$1" in
    functional | structural)
        if [[ $# -ne 2 ]]; then
            usage >&2
            exit 2
        fi
        if [[ "$1" == "functional" ]]; then
            container_command=(python3 /work/src/lnm_functional.py /work "$2")
        else
            container_command=(bash /work/src/lnm_structural.sh /work "$2")
        fi
        ;;
    tracts)
        if [[ $# -ne 1 ]]; then
            usage >&2
            exit 2
        fi
        container_command=(bash /work/src/lnm_tracts.sh /work)
        ;;
    trk-to-tck)
        if [[ $# -ne 3 ]]; then
            usage >&2
            exit 2
        fi
        container_command=(
            python3 /work/src/utils/trk_to_tck.py "/work/$2" "/work/$3"
        )
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        echo "Error: unknown function '$1'." >&2
        usage >&2
        exit 2
        ;;
esac

docker run --rm --init \
    --user "$(id -u):$(id -g)" \
    --env "USER=$(id -un)" \
    --env HOME=/tmp \
    --volume "$project_dir:/work" \
    --workdir /work \
    "$image" "${container_command[@]}"
