
#qsub -l 'walltime=00:30:00,mem=50gb' 06_anat.sh 

sub='sub-P001b'
export SUBJECTS_DIR='/home/control/wousch/project/pilot/7T/'$sub'/derivatives/fs'

if ( [ ! -f $SUBJECTS_DIR'/lh.HCPMMP1.annot' ] ); then
cp '/home/control/wousch/project/bids/group/lh.HCPMMP1.annot' $SUBJECTS_DIR'/lh.HCPMMP1.annot'
fi
if ( [ ! -f $SUBJECTS_DIR'/rh.HCPMMP1.annot' ] ); then
cp '/home/control/wousch/project/bids/group/rh.HCPMMP1.annot' $SUBJECTS_DIR'/rh.HCPMMP1.annot'
fi

rdir='/home/control/wousch/project/pilot/7T/'
sdir=$rdir$sub'/'
adir=$sdir'derivatives/pipe/anat/'

if ( [ ! -f $SUBJECTS_DIR'/'$sub'/label/lh.HCPMMP1.annot' ] ); then
mri_surf2surf --srcsubject fsaverage --sval-annot $SUBJECTS_DIR'/lh.HCPMMP1.annot' --trgsubject $sub --tval $SUBJECTS_DIR'/'$sub'/label/lh.HCPMMP1.annot' --hemi lh
fi
if ( [ ! -f $SUBJECTS_DIR'/'$sub'/label/rh.HCPMMP1.annot' ] ); then
mri_surf2surf --srcsubject fsaverage --sval-annot $SUBJECTS_DIR'/rh.HCPMMP1.annot' --trgsubject $sub --tval $SUBJECTS_DIR'/'$sub'/label/rh.HCPMMP1.annot' --hemi rh
fi

if ( [ ! -f $SUBJECTS_DIR'/'$sub'/mri/lh.HCPMMP1.nii.gz' ] ); then
mri_label2vol --subject $sub --annot $SUBJECTS_DIR'/'$sub'/label/lh.HCPMMP1.annot' --o $SUBJECTS_DIR'/'$sub'/mri/lh.HCPMMP1.nii.gz' --regheader $SUBJECTS_DIR'/'$sub'/mri/brainmask.mgz' --hemi lh --temp $adir'/'$sub'_T1w_MPRAGEised_biascorrected.nii.gz' --proj frac -0.2 1.2 0.01 --new-aseg2vol
fi
if ( [ ! -f $SUBJECTS_DIR'/'$sub'/mri/rh.HCPMMP1.nii.gz' ] ); then
mri_label2vol --subject $sub --annot $SUBJECTS_DIR'/'$sub'/label/rh.HCPMMP1.annot' --o $SUBJECTS_DIR'/'$sub'/mri/rh.HCPMMP1.nii.gz' --regheader $SUBJECTS_DIR'/'$sub'/mri/brainmask.mgz' --hemi rh --temp $adir'/'$sub'_T1w_MPRAGEised_biascorrected.nii.gz' --proj frac -0.2 1.2 0.01 --new-aseg2vol
fi

if ( [ ! -f $adir'HCPMMP1.nii.gz' ] ); then
mri_concat --i $SUBJECTS_DIR'/'$sub'/mri/lh.HCPMMP1.nii.gz' --i $SUBJECTS_DIR'/'$sub'/mri/rh.HCPMMP1.nii.gz' --o $SUBJECTS_DIR'/'$sub'/mri/HCPMMP1.nii.gz' --combine
mv -f $SUBJECTS_DIR'/'$sub'/mri/HCPMMP1.nii.gz' $adir'HCPMMP1.nii.gz'
fi

##Fill gaps in varea. Like a dentist.
roi2=$adir'fill_HCPMMP1.nii.gz'
layfile=$adir'segt1-class.nii.gz'
if ( [ ! -f $roi2 ] ); then
module load anaconda3
source activate py311
cd /home/control/wousch/
python3 -c'from Python.python_scripts.wauwterpreproc import fillgaps; fillgaps('"'"$adir"'"',"'"HCPMMP1.nii.gz"'",boxsize=5,helperfile='"'"$layfile"'"')'
#python3 -c'from Python.python_scripts.wauwterpreproc import fillgaps; fillgaps('"'"$adir"'"',"'"fill_HCPMMP1.nii.gz"'",fillthres=13)'
fi

if ( [ ! -f $adir'RF_HCPMMP1.nii.gz' ] ); then
module load afni

3dresample -master $adir'AN4T1-0.5iso.nii.gz' \
-prefix $adir'RF_HCPMMP1.nii.gz' \
-rmode NN \
-input $adir'fill_HCPMMP1.nii.gz'
fi

