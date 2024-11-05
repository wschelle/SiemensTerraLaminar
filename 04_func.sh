#! /bin/bash

# run like so:
# qsub -l 'nodes=1:ppn=4,walltime=48:00:00,mem=120gb' 04_func.sh
# sbatch -n 16 --mem=120G --time=48:00:00 04_func.sh

module load ANTs
module load afni
module load fsl
module load anaconda3

ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=16  # controls multi-threading
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS

## Who is this?
sub='sub-001'
pdir='/project/3017081.01/'
hdir=$pdir'required/'
rdir=$pdir'bids7T/'
sdir=$rdir$sub'/'

## What did (s)he do?
declare -a fnr=("task-wmg_run-1_bold" "task-wmg_run-2_bold" "task-wmg_run-3_bold" "task-loc_run-1_bold")
declare -a tu=("task-wmg_acq-PA_run-1_bold" "task-wmg_acq-PA_run-2_bold" "task-wmg_acq-PA_run-3_bold" "task-loc_acq-PA_run-1_bold")
declare -a refscan=("135" "135" "135" "77")

fdir=$sdir'derivatives/pipe/func/'
adir=$sdir'derivatives/pipe/anat/'
fmdir=$sdir'derivatives/pipe/fmap/'

## where are the functional files?
ffile=()
tufile=()
nses=${#fnr[@]}
for (( i=0; i<nses; i++ ));
do
ffile[i]=$fdir$sub'_'${fnr[$i]}'_POCS_NORDIC.nii.gz'
tufile[i]=$fmdir$sub'_'${tu[$i]}'_POCS_NORDIC.nii.gz'
done

## Prepping the topup
tufile2=()
tufile3=()
tufileref=()
for (( i=0; i<nses; i++ ));
do

tufile2[i]=$fmdir$sub'_'${tu[$i]}'_POCS_NORDIC_MC.nii.gz'
tufile3[i]=$fmdir$sub'_'${tu[$i]}'_POCS_NORDIC_MCAVG.nii.gz'
tufileref[i]=$fmdir$sub'_'${tu[$i]}'_POCS_NORDIC_n0.nii.gz'

if ( [ ! -f ${tufile3[$i]} ] ); then

source activate py311
cd $hdir
export PYTHONPATH="$PYTHONPATH:$hdir"
if ( [ ! -f ${tufileref[$i]} ] ); then
python 'Python/python_scripts/nii_extract_timepoint.py' ${tufile[$i]} 0
fi
conda deactivate

antsMotionCorr  -d 3 \
-o [ $fmdir$sub'_'${tu[$i]}'_POCS_NORDIC_MC', ${tufile2[$i]},${tufile3[$i]}] \
-m MI[${tufileref[$i]}, ${tufile[$i]}, 1 , 32 , Regular, 0.25  ] \
-t Affine[ 0.01 ] -u 1 -e 1 -s 1x0 -f 2x1 -i 20x5 -n 3 -w 0 -v 1
fi

done

rm -f ${tufile2[@]}
rm -f ${tufileref[@]}

## Alright! Lets motion correction the shit outta these data

ffile2=()
ffile3=()
ffileref=()
AWARP=()

for (( i=0; i<nses; i++ ));
do
ffile2[i]=$fdir$sub'_'${fnr[$i]}'_POCS_NORDIC_MC.nii.gz'
ffile3[i]=$fdir$sub'_'${fnr[$i]}'_POCS_NORDIC_MCAVG.nii.gz'
ffileref[i]=$fdir$sub'_'${fnr[$i]}'_POCS_NORDIC_n'${refscan[$i]}'.nii.gz'
AWARP[i]=$fdir$sub'_'${fnr[$i]}'_POCS_NORDIC_MCMOCOparams.csv'

if ( [ ! -f ${ffile3[$i]} ] ); then

source activate py311
cd $hdir
if ( [ ! -f ${ffileref[$i]} ] ); then
python 'Python/python_scripts/nii_extract_timepoint.py' ${ffile[$i]} ${refscan[$i]}
fi
conda deactivate


antsMotionCorr  -d 3 \
-o [ $fdir$sub'_'${fnr[$i]}'_POCS_NORDIC_MC', ${ffile2[$i]},${ffile3[$i]}] \
-m MI[${ffileref[$i]}, ${ffile[$i]}, 1 , 32 , Regular, 0.25  ] \
-t Affine[ 0.01 ] -u 1 -e 1 -s 1x0 -f 2x1 -i 20x5 -n 3 -w 0 -v 1
fi
done

rm -f ${ffile2[@]}
rm -f ${ffileref[@]}


ffile4=()
BWARP=()
for (( i=0; i<nses; i++ ));
do
ffile4[i]=$fmdir$sub'_'${tu[$i]}'_2F.nii.gz'
BWARP[i]=$fmdir$sub'_'${tu[$i]}'_2F_1InverseWarp.nii.gz'

if ( [ ! -f ${ffile4[$i]} ] ); then
antsRegistration --dimensionality 3 \
--output [$fmdir$sub'_'${tu[$i]}'_2F_',${ffile4[$i]}] \
--float \
--transform Rigid[0.05] \
--metric MI[${ffile3[$i]},${tufile3[$i]}, 1, 32, Regular, 0.25 ] \
--convergence [ 800x500x500,1e-6,8 ] \
--smoothing-sigmas 4x2x1vox \
--shrink-factors 3x2x1 \
--transform SyN[0.1,2,0] \
--metric CC[${ffile3[$i]},${tufile3[$i]}, 1, 5 ] \
--convergence [ 1000x1000x1000,1e-5,5 ] \
--smoothing-sigmas 2x1x0vox \
--shrink-factors 4x3x2 \
--verbose
fi
done

BWARPB=()
for (( i=0; i<nses; i++ ));
do
BWARPB[i]=$fdir$sub'_'${fnr[$i]}'_2TU_1Warp_MidWay.nii.gz'
if ( [ ! -f ${BWARPB[$i]} ] ); then
fslmaths ${BWARP[$i]} -div 2.0 ${BWARPB[$i]}
fi
done

ffile5=()
for (( i=0; i<nses; i++ ));
do
ffile5[i]=$fdir$sub'_'${fnr[$i]}'_POCS_NORDIC_MCAVG_SDC.nii.gz'

if ( [ ! -f ${ffile5[$i]} ] ); then
antsApplyTransforms -d 3 \
-r ${ffile3[$i]} \
-t ${BWARPB[$i]} \
-i ${ffile3[$i]} \
-o ${ffile5[$i]} \
-n LanczosWindowedSinc \
-v 1 \
--float
fi
done


## Coregister to Fx to F1
ffile6=()
CWARP=()
CAFFI=()
for (( i=1; i<nses; i++ ));
do
ffile6[i]=$fdir$sub'_'${fnr[$i]}'_2F1.nii.gz'
CWARP[i]=$fdir$sub'_'${fnr[$i]}'_2F1_1Warp.nii.gz'
CAFFI[i]=$fdir$sub'_'${fnr[$i]}'_2F1_0GenericAffine.mat'
if ( [ ! -f ${ffile6[$i]} ] ); then
antsRegistration --dimensionality 3 \
--output [$fdir$sub'_'${fnr[$i]}'_2F1_',${ffile6[$i]}] \
--float \
--transform Rigid[0.05] \
--metric MI[${ffile5[0]},${ffile5[$i]}, 1, 32, Regular, 0.25 ] \
--convergence [ 1000x1000x500,1e-6,8 ] \
--smoothing-sigmas 4x2x1vox \
--shrink-factors 3x2x1 \
--transform Affine[0.025] \
--metric MI[${ffile5[0]},${ffile5[$i]}, 1, 32, Regular, 0.25 ] \
--convergence [ 1000x1000,1e-6,8 ] \
--smoothing-sigmas 1x0vox \
--shrink-factors 2x1 \
--transform SyN[0.1,2,0] \
--metric CC[${ffile5[0]},${ffile5[$i]}, 1, 4 ] \
--convergence [ 1000x1000,1e-5,5 ] \
--smoothing-sigmas 1x0vox \
--shrink-factors 3x2 \
--verbose
fi
done


if ( [ ! -d $fdir'tmp/' ] ); then
mkdir $fdir'tmp/'
fi

source activate py311
cd $hdir
for (( i=0; i<nses; i++ ));
do

if ( [ ! -f $fdir'tmp/'$sub'_'${fnr[$i]}'_POCS_NORDIC_MCMOCOparams_0000.mat' ] ); then
python 'Python/python_scripts/motionparamfromaffine.py' ${AWARP[$i]} ${ffile5[$i]}
fi

done
conda deactivate

for (( i=0; i<nses; i++ ));
do
if ( [ ! -f $fdir'tmp/'$sub'_'${fnr[$i]}'_POCS_NORDIC_f0000.nii.gz' ] ); then
fslsplit ${ffile[$i]} $fdir'tmp/'$sub'_'${fnr[$i]}'_POCS_NORDIC_f' -t
fi
done


ffile7=()
for (( i=0; i<nses; i++ ));
do
ffile7[i]=$fdir'tmp/'$sub'_'${fnr[$i]}'_prep_'

splitf=($(ls $fdir'tmp/'$sub'_'${fnr[$i]}'_POCS_NORDIC_f'*'.nii.gz'))
nf=${#splitf[@]}
AWARPsplit=($(ls $fdir'tmp/'$sub'_'${fnr[$i]}'_POCS_NORDIC_MCMOCOparams_'*'.mat'))

if ( [ ! -f ${ffile7[$i]} ] ); then
if (( i == 0 )); then
for (( j=0; j<nf; j++ ));
do
antsApplyTransforms -d 3 \
-r ${ffile5[$i]} \
-t ${BWARPB[$i]} \
-t ${AWARPsplit[$j]} \
-i ${splitf[$j]} \
-o ${ffile7[$i]}$(printf "%04d" $j)'.nii.gz' \
-n LanczosWindowedSinc \
-v 1 \
--float
done

else
for (( j=0; j<nf; j++ ));
do
antsApplyTransforms -d 3 \
-r ${ffile6[$i]} \
-t ${CWARP[$i]} \
-t ${CAFFI[$i]} \
-t ${BWARPB[$i]} \
-t ${AWARPsplit[$j]} \
-i ${splitf[$j]} \
-o ${ffile7[$i]}$(printf "%04d" $j)'.nii.gz' \
-n LanczosWindowedSinc \
-v 1 \
--float
done
fi

fi
done

ffile8=()
for (( i=0; i<nses; i++ ));
do
ffile8[i]=$fdir$sub'_'${fnr[$i]}'_prep.nii.gz'
prep=($(ls $fdir'tmp/'$sub'_'${fnr[$i]}'_prep_0'*'.nii.gz'))

if ( [ ! -f ${ffile8[$i]} ] ); then
fslmerge -tr ${ffile8[$i]} ${prep[@]} 2.98
fi
done

for (( i=0; i<nses; i++ ));
do
cp ${ffile8[$i]} $fdir$sub'_'${fnr[$i]}'_prep_copy.nii.gz'
rm ${ffile8[$i]}

3dAutomask -apply_prefix ${ffile8[$i]} \
-dilate 11 \
$fdir$sub'_'${fnr[$i]}'_prep_copy.nii.gz'

if ( [ -f ${ffile8[$i]} ] ); then
rm $fdir$sub'_'${fnr[$i]}'_prep_copy.nii.gz'
fi
done

## Calculate mean timeseries
ffile9=()
for (( i=0; i<nses; i++ ));
do
ffile9[i]=$fdir$sub'_'${fnr[$i]}'_prepavg.nii.gz'
if ( [ ! -f ${ffile9[$i]} ] ); then
3dTstat -mean \
-prefix ${ffile9[$i]} \
${ffile8[$i]} 
fi
done

if ( [ -f ${ffile9[0]} ] ); then
rm -f -r $fdir'tmp/'
fi

