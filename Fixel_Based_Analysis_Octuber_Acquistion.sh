#!/bin/bash
#Fri Aug 20 19:45:22 CEST 2018
#This script is written to perfrom the Fixel-Based analysis on multishll diffusion data acquired in octuber 2017
#Using Mrtrix3

#Ihave 33 subs arranged as follow:
#229  233  236  243  252  261  264  273  282  288  364
# 230  234  237  244  253  262  271  274  286  362  365
# 232  235  242  245  255  263  272  281  287  363  366
#You have to copy these files from the original Data folder to manipulate them away from other data
# ├── 3D.nii
# ├── Anat_Bet_365.nii
# ├── Anat.nii
# ├── Diff_20_365_bet.nii
# ├── Diff_20_365.nii
# ├── Diff_45_365_bet.nii
# ├── Diff_45_365.nii
# ├── Diff_Mask_365.nii
# ├── Mask_365.nii
# ├── rs_fMRI_365.nii
# └── rs_Mask_365.nii

cd /media/amr/Amr_4TB/Work/October_Acquistion/Data
bvec='/media/amr/HDD/Work/October_Acquistion/bvec_multishell'
bval='/media/amr/HDD/Work/October_Acquistion/bval_multishell'
scheme='/media/amr/HDD/Work/October_Acquistion/FBA_Multishell_Scheme.txt'
#First you have to conatenate 20 and 45 shells together
#Output the multishell uncompressed to operate faster

#0 -> Create an operation directory

mkdir /media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir

#------------------------------
#1 -> concatenate 
#make a seperate folder fro each sub and for each step to mimic nipype sweet style
#Do not need it already done (the concatenation not the folder thing)
# for folder in *;do
# 	cd $folder
# 	echo $folder

# 	mkdir /media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}
# 	# imrm  Diff_Multishell_${folder} #just in case I run it multiple time
# 	# Diff_20=`remove_ext Diff_20_${folder}_bet.nii`
# 	# Diff_45=`remove_ext Diff_45_${folder}_bet.nii`
# 	# fslmerge -t Diff_Multishell_${folder} ${Diff_20} ${Diff_45}
# 	# fslchfiletype  NIFTI Diff_Multishell_${folder}
# 	cd ..
# done
# echo '-----------------------------------------------------------------------------------------------------'
 
#---------------------------
#2 -> denoise

# foreach * : dwidenoise IN/dwi.mif IN/dwi_denoised.mif

for folder in *;do
	cd $folder
	echo $folder
	
	mkdir /media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/denoise

	dwidenoise \
	Diff_Multishell_${folder}.nii \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/denoise/Diff_Multishell_${folder}_denoised.nii \
	-nthreads  100  

	cd ..
done
echo '-----------------------------------------------------------------------------------------------------'

#-------------------------
#3 -> Eddy current correction using FSL new function Eddy

pwd
# for folder in *;do
# 	cd $folder
# 	echo $folder

# 	mkdir /media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/eddy

# 	eddy_cuda7.5 \
# 	--ff=10.0 \
# 	--acqp=/media/amr/HDD/Work/October_Acquistion/acqparams.txt \
# 	--bvals=/media/amr/HDD/Work/October_Acquistion/bval_multishell \
# 	--bvecs=/media/amr/HDD/Work/October_Acquistion/bvec_multishell \
# 	--imain=/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/denoise/Diff_Multishell_${folder}_denoised.nii \
# 	--index=/media/amr/HDD/Work/October_Acquistion/index_multishell \
# 	--mask=Diff_Mask_${folder}.nii \
# 	--data_is_shelled --niter=5 --nvoxhp=1000 \
# 	--out=/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/eddy/Diff_Multishell_${folder}_denoised_eddy.nii

# 	cd ..

# done
# echo '-----------------------------------------------------------------------------------------------------'

# new one did not work very well, I am going for old
pwd
for folder in *;do
	cd $folder
	echo $folder

	mkdir /media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/eddy

	eddy_correct \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/denoise/Diff_Multishell_${folder}_denoised.nii \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/eddy/Diff_Multishell_${folder}_denoised_eddy.nii 0

	cd ..

done
echo '-----------------------------------------------------------------------------------------------------'


#------------------------
#4 -> estimate tissue response functions

for folder in *;do
	cd $folder
	echo $folder

	mkdir /media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/response_est

	dwi2response \
	dhollander \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/eddy/Diff_Multishell_${folder}_denoised_eddy.nii \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/response_est/wm_response_${folder}.txt \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/response_est/gm_response_${folder}.txt \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/response_est/csf_response_${folder}.txt \
	-fslgrad $bvec $bval \
	 -nthreads 8

	cd ..

done
echo '-----------------------------------------------------------------------------------------------------'

#----------------------
#5 -> average the response across tissues from all subs

average_response /media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/*/response_est/wm_response_*.txt \
/media/amr/Amr_4TB/Work/October_Acquistion/group_average_response_wm.txt

average_response /media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/*/response_est/gm_response_*.txt \
/media/amr/Amr_4TB/Work/October_Acquistion/group_average_response_gm.txt

average_response /media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/*/response_est/csf_response_*.txt \
/media/amr/Amr_4TB/Work/October_Acquistion/group_average_response_csf.txt
echo '-----------------------------------------------------------------------------------------------------'

#--------------------
#6 -> Upsample the DWI images

for folder in *;do
	cd $folder #Honestly, I do not need to enter, just using number. I am doing this just out of habit
	echo $folder

	mkdir /media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/upsampling

	mrresize \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/eddy/Diff_Multishell_${folder}_denoised_eddy.nii.gz \
	-vox 2 \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/upsampling/Diff_Multishell_${folder}_denoised_eddy_upsampled.nii \
	 -nthreads 20
	cd ..
#1 is very small. each sub will jump to 1.7 GB
done
echo '-----------------------------------------------------------------------------------------------------'

#---------------------
#7 -> compute upsampled brain mask images

for folder in *;do
	cd $folder
	echo $folder

	#save in the same directory as the upsampled images

	dwi2mask \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/upsampling/Diff_Multishell_${folder}_denoised_eddy_upsampled.nii \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/upsampling/Diff_Multishell_${folder}_denoised_eddy_upsampled_mask.nii \
	 -nthreads  100  -fslgrad $bvec $bval

	cd ..

done
echo '-----------------------------------------------------------------------------------------------------'

#--------------------
#8 -> estimate fODF

for folder in *;do
	cd $folder
	echo $folder

	mkdir /media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/fODF

	dwi2fod \
	msmt_csd \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/upsampling/Diff_Multishell_${folder}_denoised_eddy_upsampled.nii \
	/media/amr/Amr_4TB/Work/October_Acquistion/group_average_response_wm.txt \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/fODF/wm_fod_${folder}.nii \
	/media/amr/Amr_4TB/Work/October_Acquistion/group_average_response_gm.txt \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/fODF/gm_fod_${folder}.nii \
	/media/amr/Amr_4TB/Work/October_Acquistion/group_average_response_csf.txt \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/fODF/csf_fod_${folder}.nii \
	-mask /media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/upsampling/Diff_Multishell_${folder}_denoised_eddy_upsampled_mask.nii \
	-fslgrad $bvec $bval \
	-nthreads 100 \
	 

	mrconvert \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/fODF/wm_fod_${folder}.nii \
	- -coord 3 0 | \
	mrcat /media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/fODF/csf_fod_${folder}.nii \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/fODF/gm_fod_${folder}.nii \
	- /media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/fODF/tissueRGB.mif -axis 3

	cd ..

done

echo '-----------------------------------------------------------------------------------------------------'
# #If you want here to run tractography and the RGB image, you have to run fod with each subs response, not
# #the average like here
#-----------------------------------------------------------------------------------------------------------------
#8* -> run global (not streamline like tckgen) on each subject seperately
for folder in *;do
	cd $folder
	echo $folder

	mkdir /media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/Global_Tracktography

	tckglobal \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/eddy/Diff_Multishell_${folder}_denoised_eddy.nii.gz \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/response_est/wm_response_${folder}.txt \
	-riso /media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/response_est/csf_response_${folder}.txt \
	-riso /media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/response_est/gm_response_${folder}.txt \
	-mask Diff_Mask_${folder}.nii \
	-niter 1e9 \
	-fod /media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/Global_Tracktography/fod_${folder}.mif \
	-fiso /media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/Global_Tracktography/fiso_${folder}.mif \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/Global_Tracktography/Tracks_${folder}.tck \
	-grad $scheme \
	-nthreads 100

	cd ..

done

echo '-----------------------------------------------------------------------------------------------------'
#------------------
#9 -> joint bias field correction and intensity normalization

for folder in *;do
	cd $folder
	echo $folder

	mkdir /media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/mtnormalize

	mtnormalise \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/fODF/wm_fod_${folder}.nii \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/mtnormalize/wm_fod_${folder}_norm.nii \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/fODF/gm_fod_${folder}.nii \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/mtnormalize/gm_fod_${folder}_norm.nii \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/fODF/csf_fod_${folder}.nii \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/mtnormalize/csf_fod_${folder}_norm.nii \
	-mask /media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/upsampling/Diff_Multishell_${folder}_denoised_eddy_upsampled_mask.nii \
	-nthreads 100 

	cd ..

done
echo '-----------------------------------------------------------------------------------------------------'

#--------------------
#10 -> Create a study-based FOD template 

mkdir -p /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fod_input
mkdir    /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/mask_input

#-------------------
#11 -> Create symbolic link for fods and correpsonding masks

for folder in *;do
	cd $folder
	echo $folder

	ln -sr /media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/mtnormalize/wm_fod_${folder}_norm.nii \
	/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fod_input/PRE_${folder}.nii
	ln -sr  /media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/upsampling/Diff_Multishell_${folder}_denoised_eddy_upsampled_mask.nii \
	/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/mask_input/PRE_${folder}_mask.nii

	cd ..

done	
echo '-----------------------------------------------------------------------------------------------------'

#-----------------
#12 -> Building the template

population_template \
/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fod_input \
-mask_dir /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/mask_input \
/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/wmfod_template.nii \
-voxel_size 2
echo '-----------------------------------------------------------------------------------------------------'

#-------------------
#13 -> Register all images to FOD template

for folder in *;do
	cd $folder
	echo $folder

	mkdir /media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/subs2template

	mrregister \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/mtnormalize/wm_fod_${folder}_norm.nii \
	-mask1 /media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/upsampling/Diff_Multishell_${folder}_denoised_eddy_upsampled_mask.nii \
	/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/wmfod_template.nii \
	-nl_warp /media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/subs2template/sub_${folder}_2_template_warp.nii \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/subs2template/template_2_sub_${folder}_warp.nii \
	  -type rigid_nonlinear #Why i did not use the original affine_nonlinear, subject 366 only works with rigid_nonlinear and I wanted to unify the command


	cd ..


done
echo '-----------------------------------------------------------------------------------------------------'

#----------------------------------------------------------------------------------------------
#14 -> Compute template mask, transfrom subjects masks to template space 
#we put these masks in the same directory with the subjects' warps

for folder in *;do
	cd $folder
	echo $folder

	mrtransform \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/upsampling/Diff_Multishell_${folder}_denoised_eddy_upsampled_mask.nii \
	-warp /media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/subs2template/sub_${folder}_2_template_warp.nii \
	-interp nearest -datatype bit  \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/subs2template/sub_${folder}_2_template_mask.nii

	cd ..

done
echo '-----------------------------------------------------------------------------------------------------'

#----------------------------------------------------------------------------------------------
#15 -> compute the intersection

mrmath \
/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/*/subs2template/sub_*_2_template_mask.nii \
min \
/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/wmfod_template_mask.nii \
-datatype bit 
echo '-----------------------------------------------------------------------------------------------------'

#----------------------------------------------------------------------------------------------
#16 -> Compute a white matter template analysis fixel mask

fod2fixel \
-mask /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/wmfod_template_mask.nii \
-fmls_peak_value 0.06 \
/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/wmfod_template.nii \
/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fixel_mask 
echo '-----------------------------------------------------------------------------------------------------'

#----------------------------------------------------------------------------------------------
#17 -> transform subjects' FOD to template space
#We keep them in the same folder with the transformations and masks

for folder in *;do
	cd $folder
	echo $folder

	mrtransform \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/mtnormalize/wm_fod_${folder}_norm.nii \
	-warp /media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/subs2template/sub_${folder}_2_template_warp.nii \
	-noreorientation  \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/subs2template/sub_${folder}_2_template_fod_NOT_REORIENTED.nii

	cd ..

done
echo '-----------------------------------------------------------------------------------------------------'

#----------------------------------------------------------------------------------------------
#18 -> Segment fod images to estimate fixels and their AFD (FD)
#the output for fod2fixel is already a directory rather than a file
#So, no need to create a new folder

for folder in *;do
	cd $folder
	echo $folder

	fod2fixel \
	-mask /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/wmfod_template_mask.nii \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/subs2template/sub_${folder}_2_template_fod_NOT_REORIENTED.nii \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/fixel_in_template_NOT_REORIENTED \
	-afd fd.mif 

	cd ..

done
echo '-----------------------------------------------------------------------------------------------------'

#----------------------------------------------------------------------------------------------
#19 -> Reorient fixels
#the output for fod2fixel is already a directory rather than a file
#So, no need to create a new folder

for folder in *;do
	cd $folder
	echo $folder

	fixelreorient \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/fixel_in_template_NOT_REORIENTED \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/subs2template/sub_${folder}_2_template_warp.nii \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/fixel_in_template_REORIENTED 

	cd ..

done
echo '-----------------------------------------------------------------------------------------------------'

#----------------------------------------------------------------------------------------------
#20 -> Assign subject fixels to template fixels

for folder in *;do
	cd $folder
	echo $folder

	fixelcorrespondence  \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/fixel_in_template_REORIENTED/fd.mif \
	/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fixel_mask \
	/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fd PRE_${folder}.mif 

	cd ..


done
echo '-----------------------------------------------------------------------------------------------------'

#----------------------------------------------------------------------------------------------
#21 -> Compute the fibre cross-section(FC) metric

for folder in *;do
	cd $folder
	echo $folder

	warp2metric \
	/media/amr/Amr_4TB/Work/October_Acquistion/FBA_Workingdir/${folder}/subs2template/sub_${folder}_2_template_warp.nii \
	-fc \
	/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fixel_mask \
	/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fc IN_${folder}.mif 

	cd ..

done
echo '-----------------------------------------------------------------------------------------------------'

#----------------------------------------------------------------------------------------------
#22 -> calculate the log(FC)

mkdir /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/log_fc

cp /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fc/index.mif \
/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fc/directions.mif \
/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/log_fc 

cd /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fc/

for IN in IN_*;do
	echo $IN
	IN=`echo ${IN} | sed s/'.mif'/''/`
	echo $IN
	mrcalc ${IN}.mif -log  /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/log_fc/${IN}_log.mif 

done 

cd /media/amr/Amr_4TB/Work/October_Acquistion/Data
pwd
echo '-----------------------------------------------------------------------------------------------------'

#----------------------------------------------------------------------------------------------
#23 -> calculate combined measure of FD and FC (FDC)


mkdir /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fdc

cp /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fc/index.mif \
/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fc/directions.mif \
/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fdc 


for folder in *;do
	cd $folder 
	echo $folder

	mrcalc \
	/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fd/PRE_${folder}.mif \
	/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fc/IN_${folder}.mif \
	-mult /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fdc/IN_${folder}.mif 

	cd ..

done
echo '-----------------------------------------------------------------------------------------------------'

#----------------------------------------------------------------------------------------------
#23 -> perform whole brain fiber tractography on the FOD template

cd /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA

tckgen -angle 22.5 -maxlen 250 -minlen 10 -power 1.0 wmfod_template.nii \
-seed_image wmfod_template_mask.nii \
-mask wmfod_template_mask.nii \
-select 2000000 -cutoff 0.06 tracks_2_million.tck 
 
echo '-----------------------------------------------------------------------------------------------------'

#----------------------------------------------------------------------------------------------
#24 -> Reduce biases in tractogram densities

cd /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA

tcksift \
tracks_2_million.tck \
wmfod_template.nii \
tracks_200_thousand_sift.tck \
-term_number 200000 

echo '-----------------------------------------------------------------------------------------------------'

#----------------------------------------------------------------------------------------------
#25 -> fixel stats on fd
#I made a new directory under /media/amr/Amr_4TB/Work/October_Acquistion/ and I called it Stats
#I changed the names of the files to include the group name using my python script
#ls  ls ?_PRE_???.mif  > fd_files.txt
#i made the desing matrix and contrast using fsl Glm using only one contrast A > B
#Now run fixel analysis of fd metric

design='/media/amr/Amr_4TB/Work/October_Acquistion/Design_FBA_16_A_13_B.mat'
contrast='/media/amr/Amr_4TB/Work/October_Acquistion/Contrast_FBA_16_A_>_13_B.con'

cd /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fd
python3 /home/amr/SCRIPTS/change_files_to_contain_gp_name.py /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fd 4 7
ls  ?_PRE_???.mif  > fd_files.txt

fixelcfestats \
/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fd \
/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fd/fd_files.txt \
$design \
$contrast \
/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/tracks_200_thousand_sift.tck \
stats_fd_200_thousand -neg -nperms 10000


#----------------------------------------------------------------------------------------------
#26 -> fixel stats on log_fc
#I changed the names of the files to include the group name using my python script
#ls  ls ?_PRE_???.mif  > fd_files.txt
#i made the desing matrix and contrast using fsl Glm using only one contrast A > B
#Now run fixel analysis of fd metric

design='/media/amr/Amr_4TB/Work/October_Acquistion/Design_FBA_16_A_13_B.mat'
contrast='/media/amr/Amr_4TB/Work/October_Acquistion/Contrast_FBA_16_A_>_13_B.con'

cd /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/log_fc
python3 /home/amr/SCRIPTS/change_files_to_contain_gp_name.py /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/log_fc 3 6
ls  ?_IN_???_log.mif  > log_fc_files.txt

fixelcfestats \
/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/log_fc \
/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/log_fc/log_fc_files.txt \
$design \
$contrast \
/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/tracks_200_thousand_sift.tck \
stats_log_fc_200_thousand -neg -nperms 10000


#----------------------------------------------------------------------------------------------
#27 -> fixel stats on fdc
#I changed the names of the files to include the group name using my python script
#ls  ls ?_PRE_???.mif  > fd_files.txt
#i made the desing matrix and contrast using fsl Glm using only one contrast A > B
#Now run fixel analysis of fd metric


design='/media/amr/Amr_4TB/Work/October_Acquistion/Design_FBA_16_A_13_B.mat'
contrast='/media/amr/Amr_4TB/Work/October_Acquistion/Contrast_FBA_16_A_>_13_B.con'

cd /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fdc
python3 /home/amr/SCRIPTS/change_files_to_contain_gp_name.py /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fdc 3 6
ls  ?_IN_???.mif  > fdc_files.txt

fixelcfestats \
/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fdc \
/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fdc/fdc_files.txt \
$design \
$contrast \
/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/tracks_200_thousand_sift.tck \
stats_fdc_200_thousand -neg -nperms 10000






#xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
#xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx20 millionxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
#xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx











#||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
####################################################################################################
#Now we try with 20 million tracts
#----------------------------------------------------------------------------------------------
#23 -> perform whole brain fiber tractography on the FOD template

cd /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA

tckgen -angle 22.5 -maxlen 250 -minlen 10 -power 1.0 wmfod_template.nii \
-seed_image wmfod_template_mask.nii \
-mask wmfod_template_mask.nii \
-select 20000000 -cutoff 0.06 tracks_20_million.tck 
 
echo '-----------------------------------------------------------------------------------------------------'

#----------------------------------------------------------------------------------------------
#24 -> Reduce biases in tractogram densities

cd /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA

tcksift \
tracks_20_million.tck \
wmfod_template.nii \
tracks_2_million_sift.tck \
-term_number 2000000 

echo '-----------------------------------------------------------------------------------------------------'

#----------------------------------------------------------------------------------------------
#25 -> fixel stats on fd

#I changed the names of the files to include the group name using my python script
#ls  ls ?_PRE_???.mif  > fd_files.txt
#i made the desing matrix and contrast using fsl Glm using only one contrast A > B
#Now run fixel analysis of fd metric

design='/media/amr/Amr_4TB/Work/October_Acquistion/Design_FBA_16_A_13_B.mat'
contrast='/media/amr/Amr_4TB/Work/October_Acquistion/Contrast_FBA_16_A_>_13_B.con'

cd /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fd
#python3 /home/amr/SCRIPTS/change_files_to_contain_gp_name.py /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fd 4 7
#ls  ?_PRE_???.mif  > fd_files.txt #>>>>No need for the moment since I ran it with 2m tracks


fixelcfestats \
/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fd \
/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fd/fd_files.txt \
$design \
$contrast \
/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/tracks_2_million_sift.tck \
stats_fd_2_million -neg  -nthreads 8 -nperms 10000


#----------------------------------------------------------------------------------------------
#26 -> fixel stats on log_fc
#I changed the names of the files to include the group name using my python script
#ls  ls ?_PRE_???.mif  > fd_files.txt
#i made the desing matrix and contrast using fsl Glm using only one contrast A > B
#Now run fixel analysis of fd metric

design='/media/amr/Amr_4TB/Work/October_Acquistion/Design_FBA_16_A_13_B.mat'
contrast='/media/amr/Amr_4TB/Work/October_Acquistion/Contrast_FBA_16_A_>_13_B.con'

cd /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/log_fc
#python3 /home/amr/SCRIPTS/change_files_to_contain_gp_name.py /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/log_fc 3 6
#ls  ?_IN_???_log.mif  > log_fc_files.txt #>>>>No need for the moment since I ran it with 2m tracks


fixelcfestats \
/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/log_fc \
/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/log_fc/log_fc_files.txt \
$design \
$contrast \
/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/tracks_2_million_sift.tck \
stats_log_fc_2_million -neg -nperms 10000


#----------------------------------------------------------------------------------------------
#27 -> fixel stats on fdc
#I changed the names of the files to include the group name using my python script
#ls  ls ?_PRE_???.mif  > fd_files.txt
#i made the desing matrix and contrast using fsl Glm using only one contrast A > B
#Now run fixel analysis of fd metric


design='/media/amr/Amr_4TB/Work/October_Acquistion/Design_FBA_16_A_13_B.mat'
contrast='/media/amr/Amr_4TB/Work/October_Acquistion/Contrast_FBA_16_A_>_13_B.con'

cd /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fdc
#python3 /home/amr/SCRIPTS/change_files_to_contain_gp_name.py /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fdc 3 6
#ls  ?_IN_???.mif  > fdc_files.txt #>>>>No need for the moment since I ran it with 2m tracks


fixelcfestats \
/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fdc \
/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fdc/fdc_files.txt \
$design \
$contrast \
/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/tracks_2_million_sift.tck \
stats_fdc_2_million -neg -nperms 10000




#----------------------------------------------------------------------------------------------
#28 -> Facilitate results visualization
cd /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA

#reduce the number of tracks to faciltate the rendering
#I will skip this step necause I already have my 200000 track, I ebded up doing it anyway

tckedit \
tracks_2_million_sift.tck \
-num 200000 \
tracks_200k_sift.tck


#----------------------------------------------------------------------------------------------
#29 -> Map fixel values to streamline points, save them in a “track scalar file”

cd /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fd/stats_fd_200_thousand

fixel2tsf \
fwe_pvalue.mif \
/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/tracks_200_thousand_sift.tck \
fd_fwe_pvalue.tsf


cd /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/log_fc/stats_log_fc_200_thousand

fixel2tsf \
fwe_pvalue.mif \
/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/tracks_200_thousand_sift.tck \
log_fc_fwe_pvalue.tsf



cd /media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/fdc/stats_fdc_200_thousand

fixel2tsf \
fwe_pvalue.mif \
/media/amr/Amr_4TB/Work/October_Acquistion/template_FBA/tracks_200_thousand_sift.tck \
fdc_fwe_pvalue.tsf


#----------------------------------------------------------------------------------------------


#Do not forget tractography









