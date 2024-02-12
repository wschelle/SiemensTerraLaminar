#! /bin/bash

# run like so:
# qsub -l 'walltime=02:00:00,mem=32gb' 07_func.sh

module load ANTs
module load afni

## Who is this?
sub='sub-P001b'
rdir='/home/control/wousch/project/pilot/7T/'
sdir=$rdir$sub'/'

## What did (s)he do?
declare -a fnr=("task-wmg_run-1")

fdir=$sdir'derivatives/pipe/func/'
adir=$sdir'derivatives/pipe/anat/'

## where are the functional files?
ffile=()
ffile0=()
ffile1=()
nses=${#fnr[@]}
for (( i=0; i<nses; i++ ));
do
ffile[i]=$fdir$sub'_'${fnr[$i]}'_bold_prep.nii.gz'
ffile0[i]=$fdir$sub'_'${fnr[$i]}'_bold_POCS.nii.gz'
ffile1[i]=$fdir$sub'_'${fnr[$i]}'_bold_prepavg_ori.nii.gz'
done
ffile2=$fdir$sub'_'${fnr[0]}'_2T1.BU.nii.gz'

T1lay=()
T1lay[0]=$adir'layers_equivol-0.5mm.nii.gz'
T1lay[1]=$adir'layers_equidist-0.5mm.nii.gz'
T1lay[2]=$adir'metric_equivol-0.5mm.nii.gz'
T1lay[3]=$adir'metric_equidist-0.5mm.nii.gz'
T1lay[4]=$adir'midGM_equivol-0.5mm.nii.gz'
T1lay[5]=$adir'midGM_equidist-0.5mm.nii.gz'
T1lay[6]=$adir'RF_HCPMMP1.nii.gz'

funclay=()
funclay[0]=$sdir'derivatives/nii/'$sub'_lay-equivol.nii.gz'
funclay[1]=$sdir'derivatives/nii/'$sub'_lay-equidist.nii.gz'
funclay[2]=$sdir'derivatives/nii/'$sub'_metric-equivol.nii.gz'
funclay[3]=$sdir'derivatives/nii/'$sub'_metric-equidist.nii.gz'
funclay[4]=$sdir'derivatives/nii/'$sub'_gm-equivol.nii.gz'
funclay[5]=$sdir'derivatives/nii/'$sub'_gm-equidist.nii.gz'
funclay[6]=$sdir'derivatives/nii/'$sub'_HCPMMP1.nii.gz'

##Push layers to func space
for (( i=0; i<7; i++ ));
do
if ( [ ! -f ${funclay[$i]} ] ); then
antsApplyTransforms -d 3 \
-r ${ffile1[0]} \
-t [$fdir$sub'_'${fnr[0]}'_2T1.BU.mat', 1] \
-i ${T1lay[$i]} \
-o ${funclay[$i]} \
-n NearestNeighbor \
-v 1 \
--float
fi
done


