#! /bin/bash

# run like so:
# qsub -l 'walltime=12:00:00,mem=120gb' 08_func.sh

## Who is this?
sub='sub-P001b'
rdir='/home/control/wousch/project/pilot/7T/'
sdir=$rdir$sub'/'

## What did (s)he do?
declare -a fnr=("task-wmg_run-1")

fdir=$sdir'derivatives/pipe/func/'
adir=$sdir'derivatives/pipe/anat/'
ndir=$sdir'derivatives/nii/'

## where are the functional files?
ffile=()
nses=${#fnr[@]}
for (( i=0; i<nses; i++ ));
do
ffile[i]=$fdir$sub'_'${fnr[$i]}'_bold_prep.nii.gz'
done

layfile=$ndir$sub'_lay-equidist.nii.gz'
parcfile=$ndir$sub'_HCPMMP1.nii.gz'

module load anaconda3
source activate py311
cd /home/control/wousch/
export PYTHONPATH="$PYTHONPATH:/home/control/wousch/"

ffile2=()
for (( i=0; i<nses; i++ ));
do
ffile2[i]=$fdir$sub'_'${fnr[$i]}'_bold_prep_ls.nii.gz'
if ( [ ! -f ${ffile2[$i]} ] ); then
python3 -c'from Python.python_scripts.wauwterpreproc import laysmo; laysmo('"'"${ffile[$i]}"'"',"'"$layfile"'",layedge=1,nlay=3,kernelsize=9,fwhm=2.5,parcfile="'"$parcfile"'")'
fi
done


