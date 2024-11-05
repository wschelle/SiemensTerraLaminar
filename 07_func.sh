#! /bin/bash

# run like so:
# qsub -l 'walltime=04:00:00,mem=100gb' 07_func.sh
# sbatch --mem=100G --time=04:00:00 07_func.sh

## Who is this?
sub='sub-001'

pdir='/project/3017081.01/'
homedir=$pdir'required/'
rdir=$pdir'bids7T/'
sdir=$rdir$sub'/'

## What did (s)he do?
declare -a fnr=("task-wmg_run-1_bold" "task-wmg_run-2_bold" "task-wmg_run-3_bold" "task-loc_run-1_bold")

fdir=$sdir'derivatives/pipe/func/'
adir=$sdir'derivatives/pipe/anat/'
ndir=$sdir'derivatives/nii/'

## where are the functional files?
ffile=()
ffile2=()
nses=${#fnr[@]}
for (( i=0; i<nses; i++ ));
do
ffile[i]=$fdir$sub'_'${fnr[$i]}'_prep.nii.gz'
ffile2[i]=$fdir$sub'_'${fnr[$i]}'_prep_ls.nii.gz'
done

layfile=$ndir$sub'_lay-equidist.nii.gz'
parcfile=$ndir$sub'_HCPMMP1.nii.gz'

module load anaconda3
source activate py311
cd $homedir
export PYTHONPATH="$PYTHONPATH:$homedir"

#foo () {
#local run=$1
#python3 -c'from Python.python_scripts.wauwterlaysmo import layersmooth_seq; layersmooth_seq('"'"$run"'"',"'"$layfile"'",layedge=1,nlay=3,kernelsize=7,fwhm=1.25,parcfile="'"$parcfile"'")'
#}
#for run in $fnr; do foo "$run" & done

for (( i=0; i<nses; i++ ));
do
if ( [ ! -f ${ffile2[$i]} ] ); then
python3 -c'from Python.python_scripts.wauwterlaysmo import layersmooth_seq; layersmooth_seq('"'"${ffile[$i]}"'"',"'"$layfile"'",layedge=1,nlay=3,kernelsize=7,fwhm=1.25,parcfile="'"$parcfile"'")'
fi
done

conda deactivate


