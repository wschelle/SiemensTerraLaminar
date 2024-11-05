#!/bin/bash

#run like so:
#qsub -l 'nodes=1:ppn=4,walltime=12:00:00,mem=32gb' 01_anat.sh
#sbatch -N 1 -c 4 --ntasks-per-node=1 --mem=32G --time=12:00:00 01_anat.sh

sub='sub-001' # subject number here. Assuming BIDS structure
rdir='/project/3017081.01/' # Root of the project folder
bidsdir=$rdir'bids7T/' # BIDS folder
subdir=$bidsdir$sub'/'
derdir=$subdir'derivatives/'
pipedir=$derdir'pipe/' # processed data are saved in .../derivatives/pipe/

export SUBJECTS_DIR=$derdir'fs'

recon-all -all -s $sub -i $pipedir'/anat/'$sub'_T1w-UNI_MPRAGEised_biascorrected.nii.gz' -highres -parallel -openmp 4

if ( [ ! -f $pipedir'anat/fs-ribbon.lh.nii.gz' ] ); then
mri_label2vol --subject $sub --hemi lh \
--label $SUBJECTS_DIR'/'$sub'/label/lh.cortex.label' \
--o $pipedir'anat/fs-ribbon.lh.nii.gz' \
--regheader $SUBJECTS_DIR'/'$sub'/mri/brainmask.mgz' \
--temp $pipedir'anat/'$sub'_T1w-UNI_MPRAGEised_biascorrected.nii.gz' \
--proj frac 0 1 0.1 \
--new-aseg2vol \
--fill-ribbon
fi

if ( [ ! -f $pipedir'anat/fs-ribbon.rh.nii.gz' ] ); then
mri_label2vol --subject $sub --hemi rh \
--label $SUBJECTS_DIR'/'$sub'/label/rh.cortex.label' \
--o $pipedir'anat/fs-ribbon.rh.nii.gz' \
--regheader $SUBJECTS_DIR'/'$sub'/mri/brainmask.mgz' \
--temp $pipedir'anat/'$sub'_T1w-UNI_MPRAGEised_biascorrected.nii.gz' \
--proj frac 0 1 0.1 \
--new-aseg2vol \
--fill-ribbon
fi

if ( [ ! -f $pipedir'anat/fs-ribbon.nii.gz' -a -f $pipedir'anat/fs-ribbon.lh.nii.gz' ] ); then
mri_concat --i $pipedir'anat/fs-ribbon.lh.nii.gz' --i $pipedir'anat/fs-ribbon.rh.nii.gz' --o $pipedir'anat/fs-ribbon.nii.gz' --combine

rm -f $pipedir'anat/fs-ribbon.lh.nii.gz'
rm -f $pipedir'anat/fs-ribbon.rh.nii.gz'
fi

