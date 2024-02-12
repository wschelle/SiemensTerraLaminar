# run like so:
# qsub -l 'walltime=12:00:00,mem=200gb' 03_anat.sh


#! /bin/bash

module load ANTs

## Who is this?
sub='sub-P001b'
rdir='/home/control/wousch/project/pilot/7T/'
sdir=$rdir$sub'/'

adir=$sdir'derivatives/pipe/anat/'
afile=$adir$sub'_T1w_MPRAGEised_biascorrected.nii.gz'
mfile=$adir$sub'_T1w_MPRAGEised_brainmask.nii.gz'
afile_hr=$adir$sub'_T1w_MPRAGEised_biascorrected_hr.nii.gz'
mfile_hr=$adir$sub'_T1w_MPRAGEised_brainmask_hr.nii.gz'
afile0=$adir'AN4T1-0.5iso.nii.gz'
sfile0=$adir'segt1-class.nii.gz'
sfile=$adir'segt1-class_highres.nii.gz'

newpixdim=0.5x0.5x0.5

##Upsample baby
ultrahighdim=0.2x0.2x0.2
if ( [ ! -f $sfile ] ); then
ResampleImage 3 $sfile0 $sfile $ultrahighdim 0 1 2
fi

## Run LAYNII
## easily takes an hour
if ( [ ! -f $adir'segt1-class_highres_layers_equivol.nii.gz' ] ); then
cd /home/control/wousch/Progz/LayNii_v2.2.1_Linux64/
./LN2_LAYERS -rim $sfile -nr_layers 20 -equivol
fi


lay_eqvol=$adir'layers_equivol-0.5mm.nii.gz'
if ( [ ! -f $lay_eqvol ] ); then
ResampleImage 3 $adir'segt1-class_highres_layers_equivol.nii.gz' $lay_eqvol $newpixdim 0 1 4
fi
lay_eqdis=$adir'layers_equidist-0.5mm.nii.gz'
if ( [ ! -f $lay_eqdis ] ); then
ResampleImage 3 $adir'segt1-class_highres_layers_equidist.nii.gz' $lay_eqdis $newpixdim 0 1 4
fi
met_eqvol=$adir'metric_equivol-0.5mm.nii.gz'
if ( [ ! -f $met_eqvol ] ); then
ResampleImage 3 $adir'segt1-class_highres_metric_equivol.nii.gz' $met_eqvol $newpixdim 0 3'l' 6
fi
met_eqdis=$adir'metric_equidist-0.5mm.nii.gz'
if ( [ ! -f $met_eqdis ] ); then
ResampleImage 3 $adir'segt1-class_highres_metric_equidist.nii.gz' $met_eqdis $newpixdim 0 1 6
fi
gm_eqvol=$adir'midGM_equivol-0.5mm.nii.gz'
if ( [ ! -f $gm_eqvol ] ); then
ResampleImage 3 $adir'segt1-class_highres_midGM_equivol.nii.gz' $gm_eqvol $newpixdim 0 1 6
fi
gm_eqdis=$adir'midGM_equidist-0.5mm.nii.gz'
if ( [ ! -f $gm_eqdis ] ); then
ResampleImage 3 $adir'segt1-class_highres_midGM_equidist.nii.gz' $gm_eqdis $newpixdim 0 1 6
fi


