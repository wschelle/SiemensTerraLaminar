#! /bin/bash

# run like so:
# qsub -l 'nodes=1:ppn=8,walltime=48:00:00,mem=50gb' 06_anat.sh
# sbatch -n 8 --mem=50G --time=48:00:00 06_anat.sh

module unload fsl
module load ANTs
module load anaconda3
module load fsl

ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=8  # controls multi-threading
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS

## Who is this?
sub='sub-001'

pdir='/project/3017081.01/'
homedir=$pdir'required/'
rdir=$pdir'bids7T/'
sdir=$rdir$sub'/'

## What did (s)he do?
adir1=$sdir'anat/'
adir2=$sdir'derivatives/pipe/anat/'

swifile=$adir1$sub'_SWI.nii.gz'
mipfile=$adir1$sub'_MIP.nii.gz'

swifile2=$adir2$sub'_SWI_vessel.nii.gz'
mipfile2=$adir2$sub'_MIP_vessel.nii.gz'

swi2=$adir2$sub'_swi2T1f.nii.gz'
t1file=$adir2$sub'_T1w-UNI_MPRAGEised_biascorrected.nii.gz'
t1file_hr=$adir2$sub'_T1w-UNI_MPRAGEised_biascorrected_hr.nii.gz'
func=$sdir'derivatives/pipe/func/'$sub'_task-wmg_run-1_bold_prepavg.nii.gz'
func2=$adir2$sub'_func2T1.nii.gz'

if ( [ ! -f $func2 ] ); then
antsRegistration --dimensionality 3 \
--output [$adir2$sub'_func2T1_',$func2] \
--float \
--transform Rigid[0.1] \
--metric MI[$t1file_hr,$func, 1, 32, Regular, 0.25 ] \
--convergence [ 800x500x500,1e-6,8 ] \
--smoothing-sigmas 4x2x1vox \
--shrink-factors 3x2x1 \
--transform SyN[0.1,1,0] \
--metric CC[$t1file_hr,$func, 1, 5 ] \
--convergence [ 1000x1000,1e-5,5 ] \
--smoothing-sigmas 1x0vox \
--shrink-factors 3x2 \
--verbose

fi


## Coregister to MIP to SWI
mip2=$adir2$sub'_MIP2SWI.nii.gz'
if ( [ ! -f $mip2 ] ); then
antsRegistration --dimensionality 3 \
--output [$adir2$sub'_MIP2SWI_',$mip2] \
--float \
--transform Rigid[0.05] \
--metric MI[$swifile,$mipfile, 1, 32, Regular, 0.25 ] \
--convergence [ 500x400,1e-6,8 ] \
--smoothing-sigmas 2x1vox \
--shrink-factors 2x1 \
--transform Affine[0.05] \
--metric MI[$swifile,$mipfile, 1, 32, Regular, 0.25 ] \
--convergence [ 200,1e-6,8 ] \
--smoothing-sigmas 1vox \
--shrink-factors 1 \
--verbose
fi

## Create vessel mask native space
source activate py311
cd $homedir
export PYTHONPATH="$PYTHONPATH:$homedir"
if ( [ ! -f $swifile2 ] ); then
python3 -c'from Python.python_scripts.wauwterpreproc import frangi_vessel; frangi_vessel("'"$swifile"'","'"$swifile2"'")'
fi

if ( [ ! -f $mipfile2 ] ); then
python3 -c'from Python.python_scripts.wauwterpreproc import frangi_vessel; frangi_vessel("'"$mip2"'","'"$mipfile2"'")'
fi

if ( [ ! -f $adir2'layers_equidist-0.5mm_deep.nii.gz' ] ); then
python3 'Python/python_scripts/3layfiles.py' $adir2'layers_equidist-0.5mm.nii.gz'
fi

conda deactivate

## Create brain mask and apply to vessel mask
swi1=$adir2$sub'_SWI_bet.nii.gz'
if ( [ ! -f $swi1 ] ); then
bet $swifile $swi1 -m -f 0.05
fi

swifile3=$adir2$sub'_SWI_vessel_bet.nii.gz'
mipfile3=$adir2$sub'_MIP_vessel_bet.nii.gz'
if ( [ ! -f $swifile3 ] ); then
fslmaths $swifile2 -mul $adir2$sub'_SWI_bet_mask.nii.gz' $swifile3
fi
if ( [ ! -f $mipfile3 ] ); then
fslmaths $mipfile2 -mul $adir2$sub'_SWI_bet_mask.nii.gz' $mipfile3
fi

## Coregister to T1 space

if ( [ ! -f $swi2 ] ); then
antsRegistration --dimensionality 3 \
--output [$adir2$sub'_swi2T1f_',$swi2] \
--float \
--transform Rigid[0.05] \
--metric MI[$func2,$swifile, 1, 32, Regular, 0.25 ] \
--convergence [ 800x500x500,1e-6,8 ] \
--smoothing-sigmas 4x2x1vox \
--shrink-factors 3x2x1 \
--transform Affine[0.05] \
--metric MI[$func2,$swifile, 1, 32, Regular, 0.25 ] \
--convergence [ 500x500,1e-6,8 ] \
--smoothing-sigmas 1x0vox \
--shrink-factors 2x1 \
--transform SyN[0.1,2,0] \
--metric CC[$func2,$swifile, 1, 4 ] \
--convergence [ 1000x1000,1e-5,5 ] \
--smoothing-sigmas 1x0vox \
--shrink-factors 3x2 \
--verbose

fi

## Apply affine transformation matrix
swifile4=$adir2$sub'_SWI_vessel_hr.nii.gz'
mipfile4=$adir2$sub'_MIP_vessel_hr.nii.gz'

if ( [ ! -f $swifile4 ] ); then
antsApplyTransforms -d 3 \
-r $t1file_hr \
-t $adir2$sub'_swi2T1f_1Warp.nii.gz' \
-t $adir2$sub'_swi2T1f_0GenericAffine.mat' \
-i $swifile3 \
-o $swifile4 \
-n LanczosWindowedSinc \
-v 1 \
--float
fi
if ( [ ! -f $mipfile4 ] ); then
antsApplyTransforms -d 3 \
-r $t1file_hr \
-t $adir2$sub'_swi2T1f_1Warp.nii.gz' \
-t $adir2$sub'_swi2T1f_0GenericAffine.mat' \
-i $mipfile3 \
-o $mipfile4 \
-n LanczosWindowedSinc \
-v 1 \
--float
fi

## Bring to functional space using affine
fdir=$sdir'derivatives/pipe/func/'
ffile1=$fdir$sub'_task-wmg_run-1_bold_prepavg.nii.gz'

swifile5=$sdir'derivatives/nii/'$sub'_SWI_vessel.nii.gz'
mipfile5=$sdir'derivatives/nii/'$sub'_MIP_vessel.nii.gz'

if ( [ ! -f $swifile5 ] ); then
antsApplyTransforms -d 3 \
-r $func \
-t [$adir2$sub'_func2T1_0GenericAffine.mat', 1] \
-t $adir2$sub'_func2T1_1InverseWarp.nii.gz' \
-i $swifile4 \
-o $swifile5 \
-n LanczosWindowedSinc \
-v 1 \
--float
fi
if ( [ ! -f $mipfile5 ] ); then
antsApplyTransforms -d 3 \
-r $func \
-t [$adir2$sub'_func2T1_0GenericAffine.mat', 1] \
-t $adir2$sub'_func2T1_1InverseWarp.nii.gz' \
-i $mipfile4 \
-o $mipfile5 \
-n LanczosWindowedSinc \
-v 1 \
--float
fi

if ( [ ! -f $sdir'derivatives/nii/'$sub'_AN4T1.nii.gz' ] ); then
antsApplyTransforms -d 3 \
-r $func \
-t [$adir2$sub'_func2T1_0GenericAffine.mat', 1] \
-t $adir2$sub'_func2T1_1InverseWarp.nii.gz' \
-i $t1file_hr \
-o $sdir'derivatives/nii/'$sub'_AN4T1.nii.gz' \
-n LanczosWindowedSinc \
-v 1 \
--float
fi

if ( [ ! -f $sdir'derivatives/nii/'$sub'_lay-equidist.nii.gz' ] ); then
antsApplyTransforms -d 3 \
-r $func \
-t [$adir2$sub'_func2T1_0GenericAffine.mat', 1] \
-t $adir2$sub'_func2T1_1InverseWarp.nii.gz' \
-i $adir2'layers_equidist-0.5mm.nii.gz' \
-o $sdir'derivatives/nii/'$sub'_lay-equidist.nii.gz' \
-n NearestNeighbor \
-v 1 \
--float
fi

if ( [ ! -f $sdir'derivatives/nii/'$sub'_metric-equidist.nii.gz' ] ); then
antsApplyTransforms -d 3 \
-r $func \
-t [$adir2$sub'_func2T1_0GenericAffine.mat', 1] \
-t $adir2$sub'_func2T1_1InverseWarp.nii.gz' \
-i $adir2'metric_equidist-0.5mm.nii.gz' \
-o $sdir'derivatives/nii/'$sub'_metric-equidist.nii.gz' \
-n NearestNeighbor \
-v 1 \
--float
fi

if ( [ ! -f $sdir'derivatives/nii/'$sub'_gm-equidist.nii.gz' ] ); then
antsApplyTransforms -d 3 \
-r $func \
-t [$adir2$sub'_func2T1_0GenericAffine.mat', 1] \
-t $adir2$sub'_func2T1_1InverseWarp.nii.gz' \
-i $adir2'midGM_equidist-0.5mm.nii.gz' \
-o $sdir'derivatives/nii/'$sub'_gm-equidist.nii.gz' \
-n NearestNeighbor \
-v 1 \
--float
fi

if ( [ ! -f $sdir'derivatives/nii/'$sub'_HCPMMP1.nii.gz' ] ); then
antsApplyTransforms -d 3 \
-r $func \
-t [$adir2$sub'_func2T1_0GenericAffine.mat', 1] \
-t $adir2$sub'_func2T1_1InverseWarp.nii.gz' \
-i $adir2'RF_HCPMMP1.nii.gz' \
-o $sdir'derivatives/nii/'$sub'_HCPMMP1.nii.gz' \
-n NearestNeighbor \
-v 1 \
--float
fi


if ( [ ! -f $sdir'derivatives/nii/'$sub'_lay-equidist-deep.nii.gz' ] ); then
antsApplyTransforms -d 3 \
-r $func \
-t [$adir2$sub'_func2T1_0GenericAffine.mat', 1] \
-t $adir2$sub'_func2T1_1InverseWarp.nii.gz' \
-i $adir2'layers_equidist-0.5mm_deep.nii.gz' \
-o $sdir'derivatives/nii/'$sub'_lay-equidist-deep.nii.gz' \
-n Linear \
-v 1 \
--float
fi

if ( [ ! -f $sdir'derivatives/nii/'$sub'_lay-equidist-mid.nii.gz' ] ); then
antsApplyTransforms -d 3 \
-r $func \
-t [$adir2$sub'_func2T1_0GenericAffine.mat', 1] \
-t $adir2$sub'_func2T1_1InverseWarp.nii.gz' \
-i $adir2'layers_equidist-0.5mm_mid.nii.gz' \
-o $sdir'derivatives/nii/'$sub'_lay-equidist-mid.nii.gz' \
-n Linear \
-v 1 \
--float
fi

if ( [ ! -f $sdir'derivatives/nii/'$sub'_lay-equidist-top.nii.gz' ] ); then
antsApplyTransforms -d 3 \
-r $func \
-t [$adir2$sub'_func2T1_0GenericAffine.mat', 1] \
-t $adir2$sub'_func2T1_1InverseWarp.nii.gz' \
-i $adir2'layers_equidist-0.5mm_top.nii.gz' \
-o $sdir'derivatives/nii/'$sub'_lay-equidist-top.nii.gz' \
-n Linear \
-v 1 \
--float
fi
