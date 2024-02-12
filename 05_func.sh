#! /bin/bash

# run like so:
# qsub -l 'nodes=1:ppn=4,walltime=24:00:00,mem=100gb' 05_func.sh

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
nses=${#fnr[@]}
for (( i=0; i<nses; i++ ));
do
ffile[i]=$fdir$sub'_'${fnr[$i]}'_bold_prep.nii.gz'
ffile0[i]=$fdir$sub'_'${fnr[$i]}'_bold_POCS.nii.gz'
done

t1file_hr=$adir$sub'_T1w_MPRAGEised_biascorrected_hr.nii.gz'
t1mask_hr=$adir$sub'_T1w_MPRAGEised_brainmask_hr.nii.gz'
#t1file2=$adir$sub'_T1w_BM.nii.gz'
#if ( [ ! -f $t1file2 ] ); then
#fslmaths $t1file_hr -mul $t1mask_hr $t1file2
#fi

## Calculate mean timeseries
ffile2=()
for (( i=0; i<nses; i++ ));
do
ffile2[i]=$fdir$sub'_'${fnr[$i]}'_bold_prepavg.nii.gz'
if ( [ ! -f ${ffile2[$i]} ] ); then
3dTstat -mean \
-prefix ${ffile2[$i]} \
${ffile[$i]} 
fi
done

#oblique your data back to original space
ffile3=()
for (( i=0; i<nses; i++ ));
do
ffile3[i]=$fdir$sub'_'${fnr[$i]}'_bold_prepavg_ori.nii.gz'
if ( [ ! -f ${ffile3[$i]} ] ); then
module load anaconda3
source activate py311
cd /home/control/wousch/
python3 -c'from Python.python_scripts.wauwternifti import readnii,savenii,copy_nifti_orientation; copy_nifti_orientation("'"${ffile0[$i]}"'","'"${ffile2[$i]}"'","'"${ffile3[$i]}"'")'
fi
done


## Lets register stuff to T1w
ffile4=$fdir$sub'_'${fnr[0]}'_2T1.nii.gz'
if ( [ ! -f $ffile4 ] ); then
antsRegistration --dimensionality 3 \
--output [$fdir$sub'_'${fnr[0]}'_2T1_',$ffile4] \
--float \
--transform Rigid[0.05] \
--metric MI[$t1file_hr,${ffile3[0]}, 1, 32, Regular, 0.25 ] \
--convergence [ 800x500x400,1e-6,8 ] \
--smoothing-sigmas 4x2x1vox \
--shrink-factors 3x2x1 \
--transform SyN[0.1,1,0] \
--metric CC[$t1file_hr,${ffile3[0]}, 1, 3 ] \
--convergence [ 300x200,1e-4,6 ] \
--smoothing-sigmas 1x0vox \
--shrink-factors 2x1 \
--verbose
fi
mv $fdir$sub'_'${fnr[0]}'_2T1_0GenericAffine.mat' $fdir$sub'_'${fnr[0]}'_2T1.mat'

#--transform Affine[0.1] \
#--metric MI[$t1file_hr,${ffile3[0]}, 1, 32, Regular, 0.25 ] \
#--convergence [ 500x200,1e-5,8 ] \
#--smoothing-sigmas 2x1vox \
#--shrink-factors 2x1 \
#--transform SyN[0.1,2,0] \
#--metric CC[$t1file_hr,${ffile2[0]}, 1, 3 ] \
#--convergence [ 500x200,1e-4,6 ] \
#--smoothing-sigmas 2x0vox \
#--shrink-factors 3x1 \

#ffile4=${fdirz[0]}${fnr[0]}'-2T1.nii.gz'
#if ( [ ! -f $ffile4 ] ); then
#antsRegistration --dimensionality 3 \
#--output [${fdirz[0]}${fnr[0]}'-2T1-',$ffile4] \
#--float \
#--use-histogram-matching 0 \
#--winsorize-image-intensities [0.001,0.99] \
#--transform Rigid[0.1] \
#--metric MI[$t1file_hr, $ffile3, 1, 32, Regular, 0.5 ] \
#--convergence [ 800x400,1e-6,10 ] \
#--smoothing-sigmas 2x0vox \
#--shrink-factors 2x1 \
#--transform Affine[0.1] \
#--metric MI[$t1file_hr, $ffile3, 1, 32, Regular, 0.5 ] \
#--convergence [ 800x400,1e-6,10 ] \
#--smoothing-sigmas 2x1vox \
#--shrink-factors 2x1 \
#--verbose
#fi

## If the previous lines didn't work, try the next few. Takes forever.


#if ( [ ! -f $t2file_hr_T1 ] ); then
#antsRegistration --dimensionality 3 \
#--output [$t2dirz$t2'-T1-',$t2file_hr_T1] \
#--float \
#--use-histogram-matching 0 \
#--transform Rigid[0.1] \
#--metric CC[$t1file_hr, $t2file_hr, 1, 3, Regular, 0.25 ] \
#--convergence [ 800x400,1e-6,10 ] \
#--smoothing-sigmas 2x1vox \
#--shrink-factors 2x1 \
#--verbose
#fi


