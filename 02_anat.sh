#!/bin/bash

# run like so:
# qsub -l 'walltime=48:00:00,mem=128gb' 02_anat.sh
# sbatch --mem=128G --time=48:00:00 02_anat.sh

module load ANTs
module load anaconda3
module load afni

## Who is this?
sub='sub-001'

pdir='/project/3017081.01/'
rdir=$pdir'bids7T/'
sdir=$rdir$sub'/'
hdir=$rdir'required/'
export PYTHONPATH="$PYTHONPATH:$hdir"

adir=$sdir'derivatives/pipe/anat/'
afile=$adir$sub'_T1w-UNI_MPRAGEised_biascorrected.nii.gz'
mfile=$adir$sub'_T1w-UNI_MPRAGEised_brainmask.nii.gz'
afile_hr=$adir$sub'_T1w-UNI_MPRAGEised_biascorrected_hr.nii.gz'
mfile_hr=$adir$sub'_T1w-UNI_MPRAGEised_brainmask_hr.nii.gz'

newpixdim=0.5x0.5x0.5


if ( [ ! -f $afile_hr ] ); then
ResampleImage 3 $afile $afile_hr $newpixdim 0 3'l' 6
fi

if ( [ ! -f $mfile_hr ] ); then
ResampleImage 3 $mfile $mfile_hr $newpixdim 0 0 6
fi

## Make a segmentation file first! Ya Lazy bum.

## Run segmentation (takes forever. grab six million coffees in the meantime)
an4dir=$adir'AN4/'
if ( [ ! -d $an4dir ] ); then
cd $adir
antsAtroposN4.sh -d 3 \
-a $afile_hr \
-x $mfile_hr \
-c 12 \
-g 1 \
-o AN4

mv $adir'AN4Segmentation'* $an4dir
cp $an4dir'AN4Segmentation0N4.nii.gz' $adir'AN4T1-0.5iso.nii.gz'
fi

## Make a segmentation file for laynii
if ( [ ! -f $adir'segt1.nii' ] ); then

source activate py311
cd $hdir
python3 -c'from Python.python_scripts.wauwterpreproc import atropos_seg; atropos_seg('"'"$an4dir"'"',gmin=4,gmax=7)'
mv $an4dir'segt1.nii' $adir'segt1.nii'
fi

## Make a class segmentation file for laynii
if ( [ ! -f $adir'segt1-class.nii' ] ); then
c1=$adir$sub'_T1w-UNI_MPRAGEised_class1.nii.gz'
c2=$adir$sub'_T1w-UNI_MPRAGEised_class2.nii.gz'
c3=$adir$sub'_T1w-UNI_MPRAGEised_class3.nii.gz'
out=$adir'segt1-class.nii.gz'

source activate py311
cd $hdir
python3 -c'from Python.python_scripts.wauwterpreproc import MP2Rclass_seg; MP2Rclass_seg('"'"$c1"'"','"'"$c2"'"','"'"$c3"'"','"'"$out"'"')'
fi

## Make a freesurfer segmentation file for laynii
fs=$adir'fs-ribbon.nii.gz'
fsr=$adir'fs-ribbon-r.nii.gz'

if ( [ ! -f $fsr ] ); then
3dresample -master $afile -prefix $fsr -input $fs
fi

if ( [ ! -f $adir'segt1-fs.nii' ] ); then
out=$adir'segt1-fs.nii.gz'

source activate py311
cd $hdir
python3 -c'from Python.python_scripts.wauwterpreproc import fsribbon_seg; fsribbon_seg('"'"$fsr"'"','"'"$afile"'"','"'"$out"'"')'
fi

echo 'INTERACTION REQUIRED!'
echo 'check the segt1.nii'

## open /anat/T1/AN4T1-0.5iso.nii.gz and overlay anat/T1/segt1.nii (set scale to 1(min) to 3(max))
## check if it covers grey matter nicely.
## if not: change gmin and gmax values in previous lines.
## lower gmin will push border towards CSF and higher gmax will push border towards white matter (and vice versa vice versa)
## if you're happy with the results, proceed to the next step.


