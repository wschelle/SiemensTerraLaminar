#! /bin/bash

# run like so:
# qsub -l 'nodes=1:ppn=4,walltime=24:00:00,mem=100gb' 04_func.sh

module load ANTs
module load afni

## Who is this?
sub='sub-P001b'
rdir='/home/control/wousch/project/pilot/7T/'
sdir=$rdir$sub'/'

## What did (s)he do?
declare -a fnr=("task-wmg_run-1_bold")
declare -a tu=("dir-AP_run-1_fieldmap")

fdir=$sdir'derivatives/pipe/func/'
adir=$sdir'derivatives/pipe/anat/'
fmdir=$sdir'derivatives/pipe/fmap/'

## where are the functional files?
ffile0=()
ffile=()
nses=${#fnr[@]}
for (( i=0; i<nses; i++ ));
do
ffile0[i]=$fdir$sub'_'${fnr[$i]}'_POCS_NORDIC.nii.gz'
ffile[i]=$fdir$sub'_'${fnr[$i]}'_POCS_NORDIC_DEO.nii.gz'
done

## Prepping the topup
tufile0=$fmdir$sub'_'$tu'_POCS_NORDIC.nii.gz'
tufile=$fmdir$sub'_'$tu'_POCS_NORDIC_DEO.nii.gz'

if ( [ ! -f $tufile ] ); then
cp $tufile0 $tufile
3drefit -deoblique $tufile
fi

tufile2=$fmdir$sub'_'$tu'_POCS_NORDIC_DEO_MC.nii.gz'
if ( [ ! -f $tufile2 ] ); then
3dvolreg -prefix $tufile2 \
-base 0 \
-edging 5 \
$tufile
fi

tufile3=$fmdir$sub'_'$tu'_POCS_NORDIC_DEO_MCAVG.nii.gz'
if ( [ ! -f $tufile3 ] ); then
3dTstat -mean \
-prefix $tufile3 \
$tufile2
fi


## Alright! Lets motion correction the shit outta these data
for (( i=0; i<nses; i++ ));
do
if ( [ ! -f ${ffile[$i]} ] ); then
cp ${ffile0[$i]} ${ffile[$i]}
3drefit -deoblique ${ffile[$i]}
fi
done


declare -a refscan=("137")
ffile2=()
AWARP=()

for (( i=0; i<nses; i++ ));
do
ffile2[i]=$fdir$sub'_'${fnr[$i]}'_POCS_NORDIC_DEO_MC.nii.gz'
AWARP[i]=$fdir$sub'_'${fnr[$i]}'_mp.1D'

if ( [ ! -f ${AWARP[$i]} ] ); then
3dvolreg -prefix ${ffile2[$i]} \
-1Dfile $fdir$sub'_'${fnr[$i]}'_mp' \
-maxdisp1D $fdir$sub'_'${fnr[$i]}'_mp_maxdisp' \
-1Dmatrix_save ${AWARP[$i]} \
-base ${refscan[$i]} \
-edging 5 \
${ffile[$i]}
fi

done


BWARP=()
for (( i=0; i<nses; i++ ));
do
BWARP[i]=$fdir$sub'_'${fnr[$i]}'_POCS_NORDIC_DEO_MCAVGW_pa_WARP.nii.gz'
done

if ( [ ! -f ${BWARP[0]} ] ); then

## Calculate mean timeseries
ffile3=()
for (( i=0; i<nses; i++ ));
do
ffile3[i]=$fdir$sub'_'${fnr[$i]}'_POCS_NORDIC_DEO_MCAVG.nii.gz'
if ( [ ! -f ${ffile3[$i]} ] ); then
3dTstat -mean \
-prefix ${ffile3[$i]} \
${ffile2[$i]} 
fi
done

## Align funcs with AP
tufile4=()
for (( i=0; i<nses; i++ ));
do
tufile4[i]=$fmdir$tu'_tu_2_fu'$(( $i+1 ))'.nii.gz'
if ( [ ! -f ${tufile4[$i]} ] ); then
antsRegistration --dimensionality 3 \
--output [$fmdir${fnr[$i]}$tu'-tu_2_fu'$(( $i+1 )),${tufile4[$i]}] \
--float \
--use-histogram-matching 1 \
--transform Rigid[0.1] \
--metric CC[${ffile3[$i]},$tufile3, 1, 3, Regular, 0.25 ] \
--convergence [ 1000x800x500,1e-6,10 ] \
--smoothing-sigmas 3x2x1vox \
--shrink-factors 4x2x1 \
--verbose
fi
done

## Calculating EPI phase acquisition distortion warp (or EPAD warp, because that's less letters)
ffile4=()
for (( i=0; i<nses; i++ ));
do
ffile4[i]=$fdir$sub'_'${fnr[$i]}'_POCS_NORDIC_DEO_MCAVGW.nii.gz'
if ( [ ! -f ${ffile4[$i]} ] ); then
3dQwarp -base ${ffile3[$i]} \
-source ${tufile4[$i]} \
-prefix ${ffile4[$i]} \
-plusminus \
-pmNAMES ap pa
fi
done

ffile4=()
ffile5=()
for (( i=0; i<nses; i++ ));
do
ffile4[i]=$fdir$sub'_'${fnr[$i]}'_POCS_NORDIC_DEO_MCAVGW_pa.nii.gz'
ffile5[i]=$fdir$sub'_'${fnr[$i]}'_POCS_NORDIC_DEO_MCAVGWR.nii.gz'
done
if ( [ ! -f ${ffile5[0]} ] ); then
cp ${ffile4[0]} ${ffile5[0]}
fi

#CWARP=()
#for (( i=1; i<nses; i++ ));
#do
#CWARP[i]=$fdir$sub'_'${fnr[$i]}'_2f1.1D'
#if ( [ ! -f ${ffile5[$i]} ] ); then
#3dAllineate -base ${ffile5[0]} \
#-source ${ffile4[$i]} \
#-prefix ${ffile5[$i]} \
#-1Dmatrix_save ${CWARP[$i]} \
#-nmi \
#-master BASE \
#-warp shift_rotate
#fi
#done

fi

## Apply transformations to original dataset (like Rihanna ft. Drake - "warp warp warp")
ffile6=()
for (( i=0; i<nses; i++ ));
do
ffile6[i]=$fdir$sub'_'${fnr[$i]}'_prep.nii.gz'
if (( i == 0 )); then
3dNwarpApply -nwarp "${BWARP[$i]} ${AWARP[$i]}" \
-source ${ffile[$i]} \
-master ${ffile5[0]} \
-prefix ${ffile6[$i]}

else
3dNwarpApply -nwarp "${CWARP[$i]} ${BWARP[$i]} ${AWARP[$i]}" \
-source ${ffile[$i]} \
-master ${ffile5[0]} \
-prefix ${ffile6[$i]}
fi
done

## Calculate mean timeseries
ffile7=()
for (( i=0; i<nses; i++ ));
do
ffile7[i]=$fdir$sub'_'${fnr[$i]}'_bold_prepavg.nii.gz'
if ( [ ! -f ${ffile7[$i]} ] ); then
3dTstat -mean \
-prefix ${ffile7[$i]} \
${ffile6[$i]} 
fi
done

for (( i=0; i<nses; i++ ));
do
cp ${ffile6[$i]} $fdir$sub'_'${fnr[$i]}'_prep_copy.nii.gz'
rm ${ffile6[$i]}

3dAutomask -apply_prefix ${ffile6[$i]} \
-dilate 11 \
$fdir$sub'_'${fnr[$i]}'_prep_copy.nii.gz'

if ( [ -f ${ffile6[$i]} ] ); then
rm $fdir$sub'_'${fnr[$i]}'_prep_copy.nii.gz'
fi
done

## Cleaning up all the in-between steps
rm -f ${ffile[@]}
rm -f ${ffile2[@]}
rm -f ${ffile3[@]}
rm -f ${ffile4[@]}
for (( i=0; i<nses; i++ ));
do
rm -f $fdir$sub'_'${fnr[$i]}'_POCS_NORDIC_DEO_MCAVGW_ap.nii.gz'
rm -f $fdir$sub'_'${fnr[$i]}'_POCS_NORDIC_DEO_MCAVGW_ap_WARP.nii.gz'
done





