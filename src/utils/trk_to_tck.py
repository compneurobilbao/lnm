#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
A simple script to convert a .trk tractography file to a .tck file using Nibabel.

This script handles the necessary coordinate system transformations to ensure
compatibility with MRtrix3.
"""

import argparse
import os
import nibabel as nib

def main():
    """
    Main function to parse arguments and perform the conversion.
    """
    parser = argparse.ArgumentParser(
        description="Convert a .trk tractography file to a .tck file.",
        formatter_class=argparse.RawTextHelpFormatter
    )

    parser.add_argument(
        'input_trk',
        help='The input tractography file in .trk format.'
    )
    parser.add_argument(
        'output_tck',
        help='The name of the output file in .tck format.'
    )

    args = parser.parse_args()

    # --- File path validation ---
    if not os.path.exists(args.input_trk):
        parser.error(f"Input file not found: {args.input_trk}")

    if not args.input_trk.endswith('.trk'):
        print("Warning: Input file does not have a .trk extension.")

    if not args.output_tck.endswith('.tck'):
        print("Warning: Output file does not have a .tck extension.")

    # --- Conversion Logic ---
    try:
        print(f"Loading streamlines from: {args.input_trk}...")

        # Nibabel's load function reads the .trk file.
        # By default, it applies the affine transformation stored in the .trk header,
        # moving the streamlines into world space (RASmm), which is ideal.
        trk_file = nib.streamlines.load(args.input_trk, lazy_load=False)
        tractogram = trk_file.tractogram

        print(f"Found {len(tractogram.streamlines)} streamlines.")
        print(f"Saving streamlines to: {args.output_tck}...")

        # Save the tractogram directly into the .tck format.
        # Nibabel handles the header creation for the .tck file.
        nib.streamlines.save(tractogram, args.output_tck)

        print("\nConversion complete! 🎉")
        print("Don't forget to verify the alignment in a viewer like mrview.")

    except Exception as e:
        print(f"\nAn error occurred during conversion: {e}")

if __name__ == '__main__':
    main()