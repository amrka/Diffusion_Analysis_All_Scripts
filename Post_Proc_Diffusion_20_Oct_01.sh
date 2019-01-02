#!/bin/bash

# Thu Sep 20 11:55:51 CEST 2018


#This script to move All the maps (regsitered to study template and to Waxholm) from workingdirectory of the following modules:
# 1 -> Diffusion 20 
# 2 -> Kurtosis
# 3 -> CHARMED_r2
# 4 -> NODDI

######################################################################################################

# Icreated this tree manuAlly, to serve as the local directory to transfer the maps and merge them for TBSS purposes later

# Please, do notice there is two parent folders; one for maps registered to Waxholm and 
# the other one for maps registered to study-based template

# amr@amr-Aspire-V5-591G:/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat$ ls */* 

# Study_Based_Results/Study_Based_Template:
# CHARMED  Diffusion_20  Kurtosis  NODDI

# Study_Based_Template/CHARMED:
# CHARMED_AD  CHARMED_FA  CHARMED_FR  CHARMED_IAD  CHARMED_MD  CHARMED_RD

# Study_Based_Template/Diffusion_20:
# Diffusion_20_AD  Diffusion_20_FA  Diffusion_20_MD  Diffusion_20_RD

# Study_Based_Template/Kurtosis:
# Kurtosis_AD  Kurtosis_AK  Kurtosis_AWF  Kurtosis_FA  Kurtosis_MD  Kurtosis_MK  Kurtosis_RD  Kurtosis_RK  Kurtosis_TORT

# Study_Based_Template/NODDI:
# NODDI_FICVF  NODDI_ODI

# Waxholm_Template/CHARMED:
# CHARMED_AD  CHARMED_FA  CHARMED_FR  CHARMED_IAD  CHARMED_MD  CHARMED_RD

# Waxholm_Template/Diffusion_20:
# Diffusion_20_AD  Diffusion_20_FA  Diffusion_20_MD  Diffusion_20_RD

# Waxholm_Template/Kurtosis:
# Kurtosis_AD  Kurtosis_AK  Kurtosis_AWF  Kurtosis_FA  Kurtosis_MD  Kurtosis_MK  Kurtosis_RD  Kurtosis_RK  Kurtosis_TORT

# Waxholm_Template/NODDI:
# NODDI_FICVF  NODDI_ODI

###########################################################################################################################
#############################################						#######################################################
#############################################       Waxholm         #######################################################
#############################################						#######################################################
###########################################################################################################################

###start comment here######################################################################################################
#Diffusion_20_Dir

#1 -> Waxholm Template
cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_20_workingdir/DTI_workflow
for folder in _subject_id_*;do

		cd $folder
		id=`echo $folder | sed s/'_subject_id_'/''/`

		imcp FA_To_WAX_Template/transform_Warped.nii.gz  \
		/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/Diffusion_20/Diffusion_20_FA/FA_${id}

		imcp antsApplyMD_WAX/MD_{subject_id}  \
		/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/Diffusion_20/Diffusion_20_MD/MD_${id}

		imcp antsApplyAD_WAX/AD_{subject_id}  \
		/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/Diffusion_20/Diffusion_20_AD/AD_${id}

		imcp antsApplyRD_WAX/RD_{subject_id}  \
		/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/Diffusion_20/Diffusion_20_RD/RD_${id}


		cd ..

done


#change names to contain gp number 


python3 /home/amr/SCRIPTS/change_files_to_contain_gp_name.py \
/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/Diffusion_20/Diffusion_20_FA  3 6

cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/Diffusion_20/Diffusion_20_FA
fslmerge -t All_Diffusion_20_FA_WAX *
#->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

python3 /home/amr/SCRIPTS/change_files_to_contain_gp_name.py \
/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/Diffusion_20/Diffusion_20_MD  3 6

cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/Diffusion_20/Diffusion_20_MD
fslmerge -t All_Diffusion_20_MD_WAX *
#->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

python3 /home/amr/SCRIPTS/change_files_to_contain_gp_name.py \
/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/Diffusion_20/Diffusion_20_AD  3 6

cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/Diffusion_20/Diffusion_20_AD
fslmerge -t All_Diffusion_20_AD_WAX *
#->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

python3 /home/amr/SCRIPTS/change_files_to_contain_gp_name.py \
/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/Diffusion_20/Diffusion_20_RD  3 6

cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/Diffusion_20/Diffusion_20_RD
fslmerge -t All_Diffusion_20_RD_WAX *

###########################################################################################################################
#############################################						#######################################################
#############################################          TBSS         #######################################################
#############################################						#######################################################
###########################################################################################################################

# # #Now, TBSS
cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/Diffusion_20/Diffusion_20_FA


fslmaths All_Diffusion_20_FA_WAX -max 0 -Tmin -bin mean_FA_mask -odt char;
fslmaths All_Diffusion_20_FA_WAX -mas mean_FA_mask All_Diffusion_20_FA_WAX;
fslmaths All_Diffusion_20_FA_WAX -Tmean mean_FA;
tbss_skeleton -i mean_FA -o mean_FA_skeleton;

skeleton_threshold=0.2;

fslmaths mean_FA_skeleton -thr $skeleton_threshold -bin mean_FA_skeleton_mask;

fslmaths mean_FA_mask -mul -1 -add 1 -add mean_FA_skeleton_mask mean_FA_skeleton_mask_dst;

distancemap -i mean_FA_skeleton_mask_dst -o mean_FA_skeleton_mask_dst;

tbss_skeleton -i mean_FA -p $skeleton_threshold mean_FA_skeleton_mask_dst \
${FSLDIR}/data/standard/LowerCingulum_1mm All_Diffusion_20_FA_WAX All_Diffusion_20_FA_WAX_skeletonised


# # #--------------------------------------------------------------------------------------------------------------------------------------------
# -> MD
cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/Diffusion_20/Diffusion_20_MD
skeleton_threshold=0.2;

imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/Diffusion_20/Diffusion_20_FA/mean_FA_mask .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/Diffusion_20/Diffusion_20_FA/mean_FA .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/Diffusion_20/Diffusion_20_FA/mean_FA_skeleton_mask_dst .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/Diffusion_20/Diffusion_20_FA/All_Diffusion_20_FA_WAX .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/Diffusion_20/Diffusion_20_FA/mean_FA_skeleton_mask .

fslmaths All_Diffusion_20_MD_WAX -mas mean_FA_mask All_Diffusion_20_MD_WAX
tbss_skeleton -i mean_FA -p $skeleton_threshold mean_FA_skeleton_mask_dst \
${FSLDIR}/data/standard/LowerCingulum_1mm All_Diffusion_20_FA_WAX All_MD_skeletonised -a All_Diffusion_20_MD_WAX


# # #--------------------------------------------------------------------------------------------------------------------------------------------
# -> AD
cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/Diffusion_20/Diffusion_20_AD
skeleton_threshold=0.2;

imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/Diffusion_20/Diffusion_20_FA/mean_FA_mask .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/Diffusion_20/Diffusion_20_FA/mean_FA .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/Diffusion_20/Diffusion_20_FA/mean_FA_skeleton_mask_dst .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/Diffusion_20/Diffusion_20_FA/All_Diffusion_20_FA_WAX .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/Diffusion_20/Diffusion_20_FA/mean_FA_skeleton_mask .

fslmaths All_Diffusion_20_AD_WAX -mas mean_FA_mask All_Diffusion_20_AD_WAX
tbss_skeleton -i mean_FA -p $skeleton_threshold mean_FA_skeleton_mask_dst \
${FSLDIR}/data/standard/LowerCingulum_1mm All_Diffusion_20_FA_WAX All_AD_skeletonised -a All_Diffusion_20_AD_WAX

# # #--------------------------------------------------------------------------------------------------------------------------------------------
# -> RD
cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/Diffusion_20/Diffusion_20_RD
skeleton_threshold=0.2;

imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/Diffusion_20/Diffusion_20_FA/mean_FA_mask .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/Diffusion_20/Diffusion_20_FA/mean_FA .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/Diffusion_20/Diffusion_20_FA/mean_FA_skeleton_mask_dst .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/Diffusion_20/Diffusion_20_FA/All_Diffusion_20_FA_WAX .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/Diffusion_20/Diffusion_20_FA/mean_FA_skeleton_mask .

fslmaths All_Diffusion_20_RD_WAX -mas mean_FA_mask All_Diffusion_20_RD_WAX
tbss_skeleton -i mean_FA -p $skeleton_threshold mean_FA_skeleton_mask_dst \
${FSLDIR}/data/standard/LowerCingulum_1mm All_Diffusion_20_FA_WAX All_RD_skeletonised -a All_Diffusion_20_RD_WAX






# #------------------------------------------------------------------------------------------------------------
###########################################################################################################################
#############################################						#######################################################
#############################################  Study-Based Template #######################################################
#############################################						#######################################################
###########################################################################################################################
#2 -> Study-Based Template
cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_20_workingdir/DTI_workflow
for folder in _subject_id_*;do

		cd $folder
		id=`echo $folder | sed s/'_subject_id_'/''/`

		imcp FA_To_Study_Template/transform_Warped.nii.gz  \
		/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Diffusion_20/Diffusion_20_FA/FA_${id}

		imcp antsApplyMD_Study/MD_{subject_id}  \
		/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Diffusion_20/Diffusion_20_MD/MD_${id}

		imcp antsApplyAD_Study/AD_{subject_id}  \
		/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Diffusion_20/Diffusion_20_AD/AD_${id}

		imcp antsApplyRD_Study/RD_{subject_id}  \
		/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Diffusion_20/Diffusion_20_RD/RD_${id}


		cd ..

done

#change names to contain gp number 

python3 /home/amr/SCRIPTS/change_files_to_contain_gp_name.py \
/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Diffusion_20/Diffusion_20_FA  3 6

cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Diffusion_20/Diffusion_20_FA
fslmerge -t All_Diffusion_20_FA_Study *
#->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

python3 /home/amr/SCRIPTS/change_files_to_contain_gp_name.py \
/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Diffusion_20/Diffusion_20_MD  3 6

cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Diffusion_20/Diffusion_20_MD
fslmerge -t All_Diffusion_20_MD_Study *

#->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

python3 /home/amr/SCRIPTS/change_files_to_contain_gp_name.py \
/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Diffusion_20/Diffusion_20_AD  3 6

cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Diffusion_20/Diffusion_20_AD
fslmerge -t All_Diffusion_20_AD_Study *

#->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

python3 /home/amr/SCRIPTS/change_files_to_contain_gp_name.py \
/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Diffusion_20/Diffusion_20_RD  3 6

cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Diffusion_20/Diffusion_20_RD
fslmerge -t All_Diffusion_20_RD_Study *
#--end comment here------------------------------------------------------------------------------------------------------------------------	

###########################################################################################################################
#############################################						#######################################################
#############################################          TBSS         #######################################################
#############################################						#######################################################
###########################################################################################################################

# # #Now, TBSS
cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Diffusion_20/Diffusion_20_FA


fslmaths All_Diffusion_20_FA_Study -max 0 -Tmin -bin mean_FA_mask -odt char;
fslmaths All_Diffusion_20_FA_Study -mas mean_FA_mask All_Diffusion_20_FA_Study;
fslmaths All_Diffusion_20_FA_Study -Tmean mean_FA;
tbss_skeleton -i mean_FA -o mean_FA_skeleton;

skeleton_threshold=0.2;

fslmaths mean_FA_skeleton -thr $skeleton_threshold -bin mean_FA_skeleton_mask;

fslmaths mean_FA_mask -mul -1 -add 1 -add mean_FA_skeleton_mask mean_FA_skeleton_mask_dst;

distancemap -i mean_FA_skeleton_mask_dst -o mean_FA_skeleton_mask_dst;

tbss_skeleton -i mean_FA -p $skeleton_threshold mean_FA_skeleton_mask_dst \
${FSLDIR}/data/standard/LowerCingulum_1mm All_Diffusion_20_FA_Study All_Diffusion_20_FA_Study_skeletonised


# # #--------------------------------------------------------------------------------------------------------------------------------------------
# -> MD
cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Diffusion_20/Diffusion_20_MD
skeleton_threshold=0.2;

imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Diffusion_20/Diffusion_20_FA/mean_FA_mask .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Diffusion_20/Diffusion_20_FA/mean_FA .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Diffusion_20/Diffusion_20_FA/mean_FA_skeleton_mask_dst .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Diffusion_20/Diffusion_20_FA/All_Diffusion_20_FA_Study .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Diffusion_20/Diffusion_20_FA/mean_FA_skeleton_mask .

fslmaths All_Diffusion_20_MD_Study -mas mean_FA_mask All_Diffusion_20_MD_Study
tbss_skeleton -i mean_FA -p $skeleton_threshold mean_FA_skeleton_mask_dst \
${FSLDIR}/data/standard/LowerCingulum_1mm All_Diffusion_20_FA_Study All_MD_skeletonised -a All_Diffusion_20_MD_Study


# # #--------------------------------------------------------------------------------------------------------------------------------------------
# -> AD
cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Diffusion_20/Diffusion_20_AD
skeleton_threshold=0.2;

imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Diffusion_20/Diffusion_20_FA/mean_FA_mask .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Diffusion_20/Diffusion_20_FA/mean_FA .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Diffusion_20/Diffusion_20_FA/mean_FA_skeleton_mask_dst .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Diffusion_20/Diffusion_20_FA/All_Diffusion_20_FA_Study .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Diffusion_20/Diffusion_20_FA/mean_FA_skeleton_mask .

fslmaths All_Diffusion_20_AD_Study -mas mean_FA_mask All_Diffusion_20_AD_Study
tbss_skeleton -i mean_FA -p $skeleton_threshold mean_FA_skeleton_mask_dst \
${FSLDIR}/data/standard/LowerCingulum_1mm All_Diffusion_20_FA_Study All_AD_skeletonised -a All_Diffusion_20_AD_Study

# # #--------------------------------------------------------------------------------------------------------------------------------------------
# -> RD
cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Diffusion_20/Diffusion_20_RD
skeleton_threshold=0.2;

imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Diffusion_20/Diffusion_20_FA/mean_FA_mask .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Diffusion_20/Diffusion_20_FA/mean_FA .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Diffusion_20/Diffusion_20_FA/mean_FA_skeleton_mask_dst .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Diffusion_20/Diffusion_20_FA/All_Diffusion_20_FA_Study .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Diffusion_20/Diffusion_20_FA/mean_FA_skeleton_mask .

fslmaths All_Diffusion_20_RD_Study -mas mean_FA_mask All_Diffusion_20_RD_Study
tbss_skeleton -i mean_FA -p $skeleton_threshold mean_FA_skeleton_mask_dst \
${FSLDIR}/data/standard/LowerCingulum_1mm All_Diffusion_20_FA_Study All_RD_skeletonised -a All_Diffusion_20_RD_Study
















