#! /bin/bash

# run like so:
# qsub -l 'walltime=02:00:00,mem=200gb' 08_func.sh
# sbatch --mem=200G --time=02:00:00 08_func.sh

ulimit -v unlimited

## Who is this?
sub='sub-001'

pdir='/project/3017081.01/'
homedir=$pdir'required/'
rdir=$pdir'bids7T/'
sdir=$rdir$sub'/'
fdir=$sdir'derivatives/pipe/func/'

suffix0='prep_ls'
TR=2.98
cutoff=0.01

module load anaconda3
source activate py311
cd $homedir
export PYTHONPATH="$PYTHONPATH:$homedir"

python3 $sdir'derivatives/scripts/highpassfilter.py' $fdir $suffix0 $TR $cutoff

conda deactivate




