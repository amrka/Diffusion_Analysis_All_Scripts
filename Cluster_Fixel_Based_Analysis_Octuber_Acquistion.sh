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

cd /home/in/aeed/Work/October_Acquistion/Data
bvec='/home/in/aeed/Work/October_Acquistion/bvec_multishell'
bval='/home/in/aeed/Work/October_Acquistion/bval_multishell'
scheme='/home/in/aeed/Work/October_Acquistion/FBA_Multishell_Scheme.txt'
#First you have to conatenate 20 and 45 shells together
#Output the multishell uncompressed to operate faster

#0 -> Create an operation directory

mkdir /home/in/aeed/Work/October_Acquistion/FBA_Workingdir

#------------------------------
#1 -> concatenate 
#make a seperate folder fro each sub and for each step to mimic nipype sweet style
#Do not need it already done (the concatenation not the folder thing)
for folder in *;do
	cd $folder
	echo $folder

	mkdir /home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}
	# imrm  Diff_Multishell_${folder} #just in case I run it multiple time
	# Diff_20=`remove_ext Diff_20_${folder}_bet.nii`
	# Diff_45=`remove_ext Diff_45_${folder}_bet.nii`
	# fslmerge -t Diff_Multishell_${folder} ${Diff_20} ${Diff_45}
	# fslchfiletype  NIFTI Diff_Multishell_${folder}
	cd ..
done
echo '-----------------------------------------------------------------------------------------------------'

#---------------------------
#2 -> denoise

# foreach * : dwidenoise IN/dwi.mif IN/dwi_denoised.mif

# for folder in *;do
# 	cd $folder
# 	echo $folder
	
# 	mkdir /home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/denoise

# 	dwidenoise \
# 	Diff_Multishell_${folder}.nii \
# 	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/denoise/Diff_Multishell_${folder}_denoised.nii \
# 	-nthreads  100  -force

# 	cd ..
# done
# echo '-----------------------------------------------------------------------------------------------------'

#-------------------------
#3 -> Eddy current correction using FSL new function Eddy

# pwd
# for folder in *;do
# 	cd $folder
# 	echo $folder

# 	mkdir /home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/eddy

# 	eddy_cuda7.5 \
# 	--ff=10.0 \
# 	--acqp=/media/amr/HDD/Work/October_Acquistion/acqparams.txt \
# 	--bvals=/media/amr/HDD/Work/October_Acquistion/bval_multishell \
# 	--bvecs=/media/amr/HDD/Work/October_Acquistion/bvec_multishell \
# 	--imain=/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/denoise/Diff_Multishell_${folder}_denoised.nii \
# 	--index=/media/amr/HDD/Work/October_Acquistion/index_multishell \
# 	--mask=Diff_Mask_${folder}.nii \
# 	--data_is_shelled --niter=5 --nvoxhp=1000 \
# 	--out=/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/eddy/Diff_Multishell_${folder}_denoised_eddy.nii

# 	cd ..

# done
# echo '-----------------------------------------------------------------------------------------------------'

# new one did not work very well, I am going for old
pwd
# for folder in *;do
# 	cd $folder
# 	echo $folder

# 	mkdir /home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/eddy

# 	eddy_correct \
# 	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/denoise/Diff_Multishell_${folder}_denoised.nii \
# 	eddy_corrected 0

# 	cd ..

# done
# echo '-----------------------------------------------------------------------------------------------------'


#------------------------
#4 -> estimate tissue response functions

# for folder in *;do
# 	cd $folder
# 	echo $folder

# 	mkdir /home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/response_est

# 	dwi2response \
# 	dhollander \
# 	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/eddy/Diff_Multishell_${folder}_denoised_eddy.nii.gz \
# 	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/response_est/wm_response_${folder}.txt \
# 	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/response_est/gm_response_${folder}.txt \
# 	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/response_est/csf_response_${folder}.txt \
# 	-fslgrad $bvec $bval \
# 	-force -nthreads 8

# 	cd ..

# done
# echo '-----------------------------------------------------------------------------------------------------'

#----------------------
#5 -> average the response across tissues from all subs

# average_response /home/in/aeed/Work/October_Acquistion/FBA_Workingdir/*/response_est/wm_response_*.txt \
# /home/in/aeed/Work/October_Acquistion/group_average_response_wm.txt

# average_response /home/in/aeed/Work/October_Acquistion/FBA_Workingdir/*/response_est/gm_response_*.txt \
# /home/in/aeed/Work/October_Acquistion/group_average_response_gm.txt

# average_response /home/in/aeed/Work/October_Acquistion/FBA_Workingdir/*/response_est/csf_response_*.txt \
# /home/in/aeed/Work/October_Acquistion/group_average_response_csf.txt
# echo '-----------------------------------------------------------------------------------------------------'

#--------------------
#6 -> Upsample the DWI images

# for folder in *;do
# 	cd $folder #Honestly, I do not need to enter, just using number. I am doing this just out of habit
# 	echo $folder

# 	mkdir /home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/upsampling

# 	mrresize \
# 	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/eddy/Diff_Multishell_${folder}_denoised_eddy.nii.gz \
# 	-vox 2 \
# 	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/upsampling/Diff_Multishell_${folder}_denoised_eddy_upsampled.nii \
# 	-force -nthreads 20
# 	cd ..
# #1 is very small. each sub will jump to 1.7 GB
# done
# echo '-----------------------------------------------------------------------------------------------------'

#---------------------
#7 -> compute upsampled brain mask images

# for folder in *;do
# 	cd $folder
# 	echo $folder

# 	#save in the same directory as the upsampled images

# 	dwi2mask \
# 	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/upsampling/Diff_Multishell_${folder}_denoised_eddy_upsampled.nii \
# 	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/upsampling/Diff_Multishell_${folder}_denoised_eddy_upsampled_mask.nii \
# 	-force -nthreads  100  -fslgrad $bvec $bval

# 	cd ..

# done
# echo '-----------------------------------------------------------------------------------------------------'

#--------------------
#8 -> estimate fODF

for folder in *;do
	cd $folder
	echo $folder

	mkdir /home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/fODF

	# dwi2fod \
	# msmt_csd \
	# /home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/upsampling/Diff_Multishell_${folder}_denoised_eddy_upsampled.nii \
	# /home/in/aeed/Work/October_Acquistion/group_average_response_wm.txt \
	# /home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/fODF/wm_fod_${folder}.nii \
	# /home/in/aeed/Work/October_Acquistion/group_average_response_gm.txt \
	# /home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/fODF/gm_fod_${folder}.nii \
	# /home/in/aeed/Work/October_Acquistion/group_average_response_csf.txt \
	# /home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/fODF/csf_fod_${folder}.nii \
	# -mask /home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/upsampling/Diff_Multishell_${folder}_denoised_eddy_upsampled_mask.nii \
	# -fslgrad $bvec $bval \
	# -nthreads 100 \
	# -force 

#Create the 3-tissue segmentation image
	mrconvert \
	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/fODF/wm_fod_${folder}.nii \
	- -coord 3 0 | \
	mrcat /home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/fODF/csf_fod_${folder}.nii \
	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/fODF/gm_fod_${folder}.nii \
	- /home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/fODF/tissueRGB.nii \
	-axis 3

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

	mkdir /home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/Global_Tracktography

	tckglobal \
	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/eddy/Diff_Multishell_${folder}_denoised_eddy.nii.gz \
	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/response_est/wm_response_${folder}.txt \
	-riso /home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/response_est/csf_response_${folder}.txt \
	-riso /home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/response_est/gm_response_${folder}.txt \
	-mask Diff_Mask_${folder}.nii \
	-niter 1e9 \
	-fod /home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/Global_Tracktography/fod_${folder}.mif \
	-fiso /home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/Global_Tracktography/fiso_${folder}.mif \
	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/Global_Tracktography/Tracks_${folder}.tck \
	-grad $scheme \
	-nthreads 100

	cd ..

done

echo '----------------------------------------------Tractography-------------------------------------------------------'
#------------------
#9 -> joint bias field correction and intensity normalization

for folder in *;do
	cd $folder
	echo $folder

	mkdir /home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/mtnormalize

	mtnormalise \
	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/fODF/wm_fod_${folder}.nii \
	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/mtnormalize/wm_fod_${folder}_norm.nii \
	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/fODF/gm_fod_${folder}.nii \
	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/mtnormalize/gm_fod_${folder}_norm.nii \
	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/fODF/csf_fod_${folder}.nii \
	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/mtnormalize/csf_fod_${folder}_norm.nii \
	-mask /home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/upsampling/Diff_Multishell_${folder}_denoised_eddy_upsampled_mask.nii \
	-nthreads 100 -force

	cd ..

done
echo '---------------------------------------------mtnormalize--------------------------------------------------------'

#--------------------
#10 -> Create a study-based FOD template 

mkdir -p /home/in/aeed/Work/October_Acquistion/template_FBA/fod_input
mkdir    /home/in/aeed/Work/October_Acquistion/template_FBA/mask_input

#-------------------
#11 -> Create symbolic link for fods and correpsonding masks

for folder in *;do
	cd $folder
	echo $folder

	ln -sr /home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/mtnormalize/wm_fod_${folder}_norm.nii \
	/home/in/aeed/Work/October_Acquistion/template_FBA/fod_input/PRE_${folder}.nii
	ln -sr  /home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/upsampling/Diff_Multishell_${folder}_denoised_eddy_upsampled_mask.nii \
	/home/in/aeed/Work/October_Acquistion/template_FBA/mask_input/PRE_${folder}_mask.nii

	cd ..

done	
echo '-----------------------------------------------------------------------------------------------------'

#-----------------
#12 -> Building the template

population_template \
/home/in/aeed/Work/October_Acquistion/template_FBA/fod_input \
-mask_dir /home/in/aeed/Work/October_Acquistion/template_FBA/mask_input \
/home/in/aeed/Work/October_Acquistion/template_FBA/wmfod_template.nii \
-voxel_size 2
echo '-----------------------------------------------------------------------------------------------------'

#-------------------
#13 -> Register all images to FOD template

for folder in *;do
	cd $folder
	echo $folder

	mkdir /home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/subs2template

	mrregister \
	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/mtnormalize/wm_fod_${folder}_norm.nii \
	-mask1 /home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/upsampling/Diff_Multishell_${folder}_denoised_eddy_upsampled_mask.nii \
	/home/in/aeed/Work/October_Acquistion/template_FBA/wmfod_template.nii \
	-nl_warp /home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/subs2template/sub_${folder}_2_template_warp.nii \
	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/subs2template/template_2_sub_${folder}_warp.nii \
	-force

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
	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/upsampling/Diff_Multishell_${folder}_denoised_eddy_upsampled_mask.nii \
	-warp /home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/subs2template/sub_${folder}_2_template_warp.nii \
	-interp nearest -datatype bit -force \
	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/subs2template/sub_${folder}_2_template_mask.nii

	cd ..

done
echo '-----------------------------------------------------------------------------------------------------'

#----------------------------------------------------------------------------------------------
#15 -> compute the intersection

mrmath \
/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/*/subs2template/sub_*_2_template_mask.nii \
min \
/home/in/aeed/Work/October_Acquistion/template_FBA/wmfod_template_mask.nii \
-datatype bit -force
echo '-----------------------------------------------------------------------------------------------------'

#----------------------------------------------------------------------------------------------
#16 -> Compute a white matter template analysis fixel mask

fod2fixel \
-mask /home/in/aeed/Work/October_Acquistion/template_FBA/wmfod_template_mask.nii \
-fmls_peak_value 0.06 \
/home/in/aeed/Work/October_Acquistion/template_FBA/wmfod_template.nii \
/home/in/aeed/Work/October_Acquistion/template_FBA/fixel_mask -force
echo '-----------------------------------------------------------------------------------------------------'

#----------------------------------------------------------------------------------------------
#17 -> transform subjects' FOD to template space
#We keep them in the same folder with the transformations and masks

for folder in *;do
	cd $folder
	echo $folder

	mrtransform \
	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/mtnormalize/wm_fod_${folder}_norm.nii \
	-warp /home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/subs2template/sub_${folder}_2_template_warp.nii \
	-noreorientation -force \
	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/subs2template/sub_${folder}_2_template_fod_NOT_REORIENTED.nii

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
	-mask /home/in/aeed/Work/October_Acquistion/template_FBA/wmfod_template_mask.nii \
	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/subs2template/sub_${folder}_2_template_fod_NOT_REORIENTED.nii \
	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/fixel_in_template_NOT_REORIENTED \
	-afd fd.mif -force

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
	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/fixel_in_template_NOT_REORIENTED \
	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/subs2template/sub_${folder}_2_template_warp.nii \
	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/fixel_in_template_REORIENTED -force

	cd ..

done
echo '-----------------------------------------------------------------------------------------------------'

#----------------------------------------------------------------------------------------------
#20 -> Assign subject fixels to template fixels

for folder in *;do
	cd $folder
	echo $folder

	fixelcorrespondence  \
	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/fixel_in_template_REORIENTED/fd.mif \
	/home/in/aeed/Work/October_Acquistion/template_FBA/fixel_mask \
	/home/in/aeed/Work/October_Acquistion/template_FBA/fd PRE_${folder}.mif -force

	cd ..


done
echo '-----------------------------------------------------------------------------------------------------'

#----------------------------------------------------------------------------------------------
#21 -> Compute the fibre cross-section(FC) metric

for folder in *;do
	cd $folder
	echo $folder

	warp2metric \
	/home/in/aeed/Work/October_Acquistion/FBA_Workingdir/${folder}/subs2template/sub_${folder}_2_template_warp.nii \
	-fc \
	/home/in/aeed/Work/October_Acquistion/template_FBA/fixel_mask \
	/home/in/aeed/Work/October_Acquistion/template_FBA/fc IN_${folder}.mif -force

	cd ..

done
echo '-----------------------------------------------------------------------------------------------------'

#----------------------------------------------------------------------------------------------
#22 -> calculate the log(FC)

mkdir /home/in/aeed/Work/October_Acquistion/template_FBA/log_fc

cp /home/in/aeed/Work/October_Acquistion/template_FBA/fc/index.mif \
/home/in/aeed/Work/October_Acquistion/template_FBA/fc/directions.mif \
/home/in/aeed/Work/October_Acquistion/template_FBA/log_fc 

cd /home/in/aeed/Work/October_Acquistion/template_FBA/fc/

for IN in IN_*;do
	echo $IN
	IN=`echo ${IN} | sed s/'.mif'/''/`
	echo $IN
	mrcalc ${IN}.mif -log  /home/in/aeed/Work/October_Acquistion/template_FBA/log_fc/${IN}_log.mif -force

done 

cd /home/in/aeed/Work/October_Acquistion/Data
pwd
echo '-----------------------------------------------------------------------------------------------------'

#----------------------------------------------------------------------------------------------
#23 -> calculate combined measure of FD and FC (FDC)


mkdir /home/in/aeed/Work/October_Acquistion/template_FBA/fdc

cp /home/in/aeed/Work/October_Acquistion/template_FBA/fc/index.mif \
/home/in/aeed/Work/October_Acquistion/template_FBA/fc/directions.mif \
/home/in/aeed/Work/October_Acquistion/template_FBA/fdc 


for folder in *;do
	cd $folder 
	echo $folder

	mrcalc \
	/home/in/aeed/Work/October_Acquistion/template_FBA/fd/PRE_${folder}.mif \
	/home/in/aeed/Work/October_Acquistion/template_FBA/fc/IN_${folder}.mif \
	-mult /home/in/aeed/Work/October_Acquistion/template_FBA/fdc/IN_${folder}.mif -force

	cd ..

done
echo '-----------------------------------------------------------------------------------------------------'

#----------------------------------------------------------------------------------------------
#23 -> perform whole brain fiber tractography on the FOD template

cd /home/in/aeed/Work/October_Acquistion/template_FBA

tckgen -angle 22.5 -maxlen 250 -minlen 10 -power 1.0 wmfod_template.nii \
-seed_image wmfod_template_mask.nii \
-mask wmfod_template_mask.nii \
-select 2000000 -cutoff 0.06 tracks_2_million.tck -force
 
echo '-----------------------------------------------------------------------------------------------------'

#----------------------------------------------------------------------------------------------
#24 -> Reduce biases in tractogram densities

cd /home/in/aeed/Work/October_Acquistion/template_FBA

tcksift \
tracks_2_million.tck \
wmfod_template.nii \
tracks_200_thousand_sift.tck \
-term_number 200000 -force

echo '-----------------------------------------------------------------------------------------------------'

#----------------------------------------------------------------------------------------------
#25 -> fixel stats on fd
#I made a new directory under /home/in/aeed/Work/October_Acquistion/ and I called it Stats
#under which I created three folders corresponding to the three parameters I am trying to compare
#inside each one I copied the the files from respective folder under template directory
#I changed the names of the files to include the group name using my python script
#ls  ls ?_PRE_???.mif  > fd_files.txt
#i made the desing matrix and contrast using fsl Glm using only one contrast A > B
#Now run fixel analysis of fd metric

design='/home/in/aeed/Work/October_Acquistion/Design_FBA_16_A_13_B.mat'
contrast='/home/in/aeed/Work/October_Acquistion/Contrast_FBA_16_A_>_13_B.con'

cd /home/in/aeed/Work/October_Acquistion/template_FBA/fd
python3 /home/in/aeed/change_files_to_contain_gp_name.py /home/in/aeed/Work/October_Acquistion/template_FBA/fd 4 7
ls  ?_PRE_???.mif  > fd_files.txt

fixelcfestats \
/home/in/aeed/Work/October_Acquistion/template_FBA/fd \
/home/in/aeed/Work/October_Acquistion/template_FBA/fd/fd_files.txt \
$design \
$contrast \
/home/in/aeed/Work/October_Acquistion/template_FBA/tracks_200_thousand_sift.tck \
stats_fd_200_thousand -neg -force


#----------------------------------------------------------------------------------------------
#26 -> fixel stats on log_fc
#I changed the names of the files to include the group name using my python script
#ls  ls ?_PRE_???.mif  > fd_files.txt
#i made the desing matrix and contrast using fsl Glm using only one contrast A > B
#Now run fixel analysis of fd metric

design='/home/in/aeed/Work/October_Acquistion/Design_FBA_16_A_13_B.mat'
contrast='/home/in/aeed/Work/October_Acquistion/Contrast_FBA_16_A_>_13_B.con'

cd /home/in/aeed/Work/October_Acquistion/template_FBA/log_fc
python3 /home/in/aeed/change_files_to_contain_gp_name.py /home/in/aeed/Work/October_Acquistion/template_FBA/log_fc 3 6
ls  ?_IN_???_log.mif  > log_fc_files.txt

fixelcfestats \
/home/in/aeed/Work/October_Acquistion/template_FBA/log_fc \
/home/in/aeed/Work/October_Acquistion/template_FBA/log_fc/log_fc_files.txt \
$design \
$contrast \
/home/in/aeed/Work/October_Acquistion/template_FBA/tracks_200_thousand_sift.tck \
stats_log_fc_200_thousand -neg -force


#----------------------------------------------------------------------------------------------
#27 -> fixel stats on fdc
#I changed the names of the files to include the group name using my python script
#ls  ls ?_PRE_???.mif  > fd_files.txt
#i made the desing matrix and contrast using fsl Glm using only one contrast A > B
#Now run fixel analysis of fd metric


design='/home/in/aeed/Work/October_Acquistion/Design_FBA_16_A_13_B.mat'
contrast='/home/in/aeed/Work/October_Acquistion/Contrast_FBA_16_A_>_13_B.con'

cd /home/in/aeed/Work/October_Acquistion/template_FBA/fdc
python3 /home/in/aeed/change_files_to_contain_gp_name.py /home/in/aeed/Work/October_Acquistion/template_FBA/fdc 3 6
ls  ?_IN_???.mif  > fdc_files.txt

fixelcfestats \
/home/in/aeed/Work/October_Acquistion/template_FBA/fdc \
/home/in/aeed/Work/October_Acquistion/template_FBA/fdc/fdc_files.txt \
$design \
$contrast \
/home/in/aeed/Work/October_Acquistion/template_FBA/tracks_200_thousand_sift.tck \
stats_fdc_200_thousand -neg -force






#xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
#xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx20 millionxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
#xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx











#||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
####################################################################################################
#Now we try with 20 million tracts
#----------------------------------------------------------------------------------------------
#23 -> perform whole brain fiber tractography on the FOD template

cd /home/in/aeed/Work/October_Acquistion/template_FBA

tckgen -angle 22.5 -maxlen 250 -minlen 10 -power 1.0 wmfod_template.nii \
-seed_image wmfod_template_mask.nii \
-mask wmfod_template_mask.nii \
-select 20000000 -cutoff 0.06 tracks_20_million.tck -force
 
echo '-----------------------------------------------------------------------------------------------------'

#----------------------------------------------------------------------------------------------
#24 -> Reduce biases in tractogram densities

cd /home/in/aeed/Work/October_Acquistion/template_FBA

tcksift \
tracks_20_million.tck \
wmfod_template.nii \
tracks_2_million_sift.tck \
-term_number 2000000 -force

echo '-----------------------------------------------------------------------------------------------------'

#----------------------------------------------------------------------------------------------
#25 -> fixel stats on fd
#I made a new directory under /home/in/aeed/Work/October_Acquistion/ and I called it Stats
#under which I created three fodlers corresponding to the three parameters I am trying to compare
#inside each one I copied the the files from respective folder under template directory
#I changed the names of the files to include the group name using my python script
#ls  ls ?_PRE_???.mif  > fd_files.txt
#i made the desing matrix and contrast using fsl Glm using only one contrast A > B
#Now run fixel analysis of fd metric

design='/home/in/aeed/Work/October_Acquistion/Design_FBA_16_A_13_B.mat'
contrast='/home/in/aeed/Work/October_Acquistion/Contrast_FBA_16_A_>_13_B.con'

cd /home/in/aeed/Work/October_Acquistion/template_FBA/fd
python3 /home/in/aeed/change_files_to_contain_gp_name.py /home/in/aeed/Work/October_Acquistion/template_FBA/fd 4 7
ls  ?_PRE_???.mif  > fd_files.txt

fixelcfestats \
/home/in/aeed/Work/October_Acquistion/template_FBA/fd \
/home/in/aeed/Work/October_Acquistion/template_FBA/fd/fd_files.txt \
$design \
$contrast \
/home/in/aeed/Work/October_Acquistion/template_FBA/tracks_2_million_sift.tck \
stats_fd_2_million -neg -force -nthreads 8


#----------------------------------------------------------------------------------------------
#26 -> fixel stats on log_fc
#I changed the names of the files to include the group name using my python script
#ls  ls ?_PRE_???.mif  > fd_files.txt
#i made the desing matrix and contrast using fsl Glm using only one contrast A > B
#Now run fixel analysis of fd metric

design='/home/in/aeed/Work/October_Acquistion/Design_FBA_16_A_13_B.mat'
contrast='/home/in/aeed/Work/October_Acquistion/Contrast_FBA_16_A_>_13_B.con'

cd /home/in/aeed/Work/October_Acquistion/template_FBA/log_fc
python3 /home/in/aeed/change_files_to_contain_gp_name.py /home/in/aeed/Work/October_Acquistion/template_FBA/log_fc 3 6
ls  ?_IN_???_log.mif  > log_fc_files.txt

fixelcfestats \
/home/in/aeed/Work/October_Acquistion/template_FBA/log_fc \
/home/in/aeed/Work/October_Acquistion/template_FBA/log_fc/log_fc_files.txt \
$design \
$contrast \
/home/in/aeed/Work/October_Acquistion/template_FBA/tracks_2_million_sift.tck \
stats_log_fc_2_million -neg -force


#----------------------------------------------------------------------------------------------
#27 -> fixel stats on fdc
#I changed the names of the files to include the group name using my python script
#ls  ls ?_PRE_???.mif  > fd_files.txt
#i made the desing matrix and contrast using fsl Glm using only one contrast A > B
#Now run fixel analysis of fd metric


design='/home/in/aeed/Work/October_Acquistion/Design_FBA_16_A_13_B.mat'
contrast='/home/in/aeed/Work/October_Acquistion/Contrast_FBA_16_A_>_13_B.con'

cd /home/in/aeed/Work/October_Acquistion/template_FBA/fdc
python3 /home/in/aeed/change_files_to_contain_gp_name.py /home/in/aeed/Work/October_Acquistion/template_FBA/fdc 3 6
ls  ?_IN_???.mif  > fdc_files.txt

fixelcfestats \
/home/in/aeed/Work/October_Acquistion/template_FBA/fdc \
/home/in/aeed/Work/October_Acquistion/template_FBA/fdc/fdc_files.txt \
$design \
$contrast \
/home/in/aeed/Work/October_Acquistion/template_FBA/tracks_2_million_sift.tck \
stats_fdc_2_million -neg -force




#----------------------------------------------------------------------------------------------
#28 -> Facilitate results visualization
cd /home/in/aeed/Work/October_Acquistion/template_FBA

#reduce the number of tracks to faciltate the rendering
#I will skip this step necause I already have my 200000 track, I ebded up doing it anyway

tckedit \
tracks_2_million_sift.tck \
-num 200000 \
tracks_200k_sift.tck


#----------------------------------------------------------------------------------------------
#29 -> Map fixel values to streamline points, save them in a “track scalar file”

cd /home/in/aeed/Work/October_Acquistion/template_FBA/fd/stats_fd_200_thousand

fixel2tsf \
fwe_pvalue.mif \
/home/in/aeed/Work/October_Acquistion/template_FBA/tracks_200_thousand_sift.tck \
fd_fwe_pvalue.tsf


cd /home/in/aeed/Work/October_Acquistion/template_FBA/log_fc/stats_log_fc_200_thousand

fixel2tsf \
fwe_pvalue.mif \
/home/in/aeed/Work/October_Acquistion/template_FBA/tracks_200_thousand_sift.tck \
log_fc_fwe_pvalue.tsf



cd /home/in/aeed/Work/October_Acquistion/template_FBA/fdc/stats_fdc_200_thousand

fixel2tsf \
fwe_pvalue.mif \
/home/in/aeed/Work/October_Acquistion/template_FBA/tracks_200_thousand_sift.tck \
fdc_fwe_pvalue.tsf


#----------------------------------------------------------------------------------------------


#Do not forget tractography









