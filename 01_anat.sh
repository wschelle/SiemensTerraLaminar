#!/bin/bash

#run like so:
#qsub -l 'nodes=1:ppn=4,walltime=12:00:00,mem=32gb' runfs.sh

sub='sub-P001'
export SUBJECTS_DIR='/home/control/wousch/project/pilot/7T/'$sub'/derivatives/fs/'
recon-all -all -s $sub -i '/home/control/wousch/project/pilot/7T/'$sub'/anat/presurf_MPRAGEise/presurf_UNI/'$sub'_T1w_MPRAGEised_biascorrected.nii' -highres -parallel -openmp 4
