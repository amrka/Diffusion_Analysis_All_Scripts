#!/bin/bash

# Thu Sep 20 11:55:51 CEST 2018


#This script to move All the maps (regsitered to study template and to Waxholm) from workingdirectory of the following modules:
# 1 -> Diffusion 20 
# 2 -> Kurtosis
# 3 -> CHARMED_r2
# 4 -> NODDI
# 5 -> Kurtosis_Explore_DTI

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

# Study_Based_Template/Kurtosis_Explore_DTI:
# Kurtosis_AD  Kurtosis_AWF  Kurtosis_MD  Kurtosis_RD  Kurtosis_TORT
# Kurtosis_AK  Kurtosis_FA   Kurtosis_MK  Kurtosis_RK  Kurtosis_KA

# Waxholm_Template/CHARMED:
# CHARMED_AD  CHARMED_FA  CHARMED_FR  CHARMED_IAD  CHARMED_MD  CHARMED_RD

# Waxholm_Template/Diffusion_20:
# Diffusion_20_AD  Diffusion_20_FA  Diffusion_20_MD  Diffusion_20_RD

# Waxholm_Template/Kurtosis:
# Kurtosis_AD  Kurtosis_AK  Kurtosis_AWF  Kurtosis_FA  Kurtosis_MD  Kurtosis_MK  Kurtosis_RD  Kurtosis_RK  Kurtosis_TORT

# Waxholm_Template/NODDI:
# NODDI_FICVF  NODDI_ODI


#I did not register results of Kurtosis from ExploredDTI to Waxholm for 2 Reasons:
# 1 -> I already did the kurosis with dipy and I am much satisfied with the output than ExploredDTI
# 2 -> The registration with Waxholm was suboptimal
# #------------------------------------------------------------------------------------------------------------
###########################################################################################################################
#############################################						#######################################################
#############################################  Study-Based Template #######################################################
#############################################						#######################################################
###########################################################################################################################

#2 -> Study-Based Template
cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_ExploreDTI_workingdir/Multishell_ExploreDTI_workflow
for folder in _subject_id_*;do

		cd $folder
		id=`echo $folder | sed s/'_subject_id_'/''/`

		imcp FA_To_Study_Template/transform_Warped.nii.gz  \
		/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/FA_${id}

		imcp antsApply_MD_Study/DKI_ExploreDTI_MD  \
		/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_MD/MD_${id}

		imcp antsApply_AD_Study/DKI_ExploreDTI_AD  \
		/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_AD/AD_${id}

		imcp antsApply_RD_Study/DKI_ExploreDTI_RD  \
		/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_RD/RD_${id}

		imcp antsApply_AK_Study/DKI_ExploreDTI_AK  \
		/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_AK/AK_${id}

		imcp antsApply_MK_Study/DKI_ExploreDTI_MK  \
		/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_MK/MK_${id}

		imcp antsApply_RK_Study/DKI_ExploreDTI_RK  \
		/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_RK/RK_${id}


		imcp antsApply_KA_Study/DKI_ExploreDTI_KA  \
		/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_KA/KA_${id}


		imcp antsApply_AWF_Study/DKI_ExploreDTI_AWF  \
		/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_AWF/AWF_${id}

		imcp antsApply_TORT_Study/DKI_ExploreDTI_TORT  \
		/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_TORT/TORT_${id}



		cd ..

done

#change names to contain gp number 

python3 /home/amr/SCRIPTS/change_files_to_contain_gp_name.py \
/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA  3 6

cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA
fslmerge -t All_Kurtosis_E_DTI_FA_Study *

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<

python3 /home/amr/SCRIPTS/change_files_to_contain_gp_name.py \
/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_MD  3 6

cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_MD
fslmerge -t All_Kurtosis_E_DTI_MD_Study *

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<

python3 /home/amr/SCRIPTS/change_files_to_contain_gp_name.py \
/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_AD  3 6

cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_AD
fslmerge -t All_Kurtosis_E_DTI_AD_Study *

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<

python3 /home/amr/SCRIPTS/change_files_to_contain_gp_name.py \
/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_RD  3 6

cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_RD
fslmerge -t All_Kurtosis_E_DTI_RD_Study *

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<

python3 /home/amr/SCRIPTS/change_files_to_contain_gp_name.py \
/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_AK  3 6

cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_AK
fslmerge -t All_Kurtosis_E_DTI_AK_Study *

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<

python3 /home/amr/SCRIPTS/change_files_to_contain_gp_name.py \
/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_MK  3 6

cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_MK
fslmerge -t All_Kurtosis_E_DTI_MK_Study *

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<

python3 /home/amr/SCRIPTS/change_files_to_contain_gp_name.py \
/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_RK  3 6

cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_RK
fslmerge -t All_Kurtosis_E_DTI_RK_Study *

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<

python3 /home/amr/SCRIPTS/change_files_to_contain_gp_name.py \
/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_KA  3 6

cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_KA
fslmerge -t All_Kurtosis_E_DTI_KA_Study *

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<

python3 /home/amr/SCRIPTS/change_files_to_contain_gp_name.py \
/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_AWF  4 7

cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_AWF
fslmerge -t All_Kurtosis_E_DTI_AWF_Study *

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<

python3 /home/amr/SCRIPTS/change_files_to_contain_gp_name.py \
/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_TORT  5 8

cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_TORT
fslmerge -t All_Kurtosis_E_DTI_TORT_Study *

#--------------------------------------------------------------------------------------------------------------------------	

###########################################################################################################################
#############################################						#######################################################
#############################################          TBSS         #######################################################
#############################################						#######################################################
###########################################################################################################################

# # #Now, TBSS
cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA


fslmaths All_Kurtosis_E_DTI_FA_Study -max 0 -Tmin -bin mean_FA_mask -odt char;
fslmaths All_Kurtosis_E_DTI_FA_Study -mas mean_FA_mask All_Kurtosis_E_DTI_FA_Study;
fslmaths All_Kurtosis_E_DTI_FA_Study -Tmean mean_FA;
tbss_skeleton -i mean_FA -o mean_FA_skeleton;

skeleton_threshold=0.2;

fslmaths mean_FA_skeleton -thr $skeleton_threshold -bin mean_FA_skeleton_mask;

fslmaths mean_FA_mask -mul -1 -add 1 -add mean_FA_skeleton_mask mean_FA_skeleton_mask_dst;

distancemap -i mean_FA_skeleton_mask_dst -o mean_FA_skeleton_mask_dst;

tbss_skeleton -i mean_FA -p $skeleton_threshold mean_FA_skeleton_mask_dst \
${FSLDIR}/data/standard/LowerCingulum_1mm All_Kurtosis_E_DTI_FA_Study All_Kurtosis_E_DTI_FA_Study_skeletonised


# # #--------------------------------------------------------------------------------------------------------------------------------------------
# -> MD
cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_MD
skeleton_threshold=0.2;

imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA_mask .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA_skeleton_mask_dst .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/All_Kurtosis_E_DTI_FA_Study .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA_skeleton_mask .

fslmaths All_Kurtosis_E_DTI_MD_Study -mas mean_FA_mask All_Kurtosis_E_DTI_MD_Study
tbss_skeleton -i mean_FA -p $skeleton_threshold mean_FA_skeleton_mask_dst \
${FSLDIR}/data/standard/LowerCingulum_1mm All_Kurtosis_E_DTI_FA_Study All_MD_skeletonised -a All_Kurtosis_E_DTI_MD_Study


# # #--------------------------------------------------------------------------------------------------------------------------------------------
# -> AD
cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_AD
skeleton_threshold=0.2;

imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA_mask .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA_skeleton_mask_dst .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/All_Kurtosis_E_DTI_FA_Study .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA_skeleton_mask .

fslmaths All_Kurtosis_E_DTI_AD_Study -mas mean_FA_mask All_Kurtosis_E_DTI_AD_Study
tbss_skeleton -i mean_FA -p $skeleton_threshold mean_FA_skeleton_mask_dst \
${FSLDIR}/data/standard/LowerCingulum_1mm All_Kurtosis_E_DTI_FA_Study All_AD_skeletonised -a All_Kurtosis_E_DTI_AD_Study

# # #--------------------------------------------------------------------------------------------------------------------------------------------
# -> RD
cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_RD
skeleton_threshold=0.2;

imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA_mask .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA_skeleton_mask_dst .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/All_Kurtosis_E_DTI_FA_Study .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA_skeleton_mask .

fslmaths All_Kurtosis_E_DTI_RD_Study -mas mean_FA_mask All_Kurtosis_E_DTI_RD_Study
tbss_skeleton -i mean_FA -p $skeleton_threshold mean_FA_skeleton_mask_dst \
${FSLDIR}/data/standard/LowerCingulum_1mm All_Kurtosis_E_DTI_FA_Study All_RD_skeletonised -a All_Kurtosis_E_DTI_RD_Study



# # #--------------------------------------------------------------------------------------------------------------------------------------------
# -> AK
cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_AK
skeleton_threshold=0.2;

imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA_mask .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA_skeleton_mask_dst .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/All_Kurtosis_E_DTI_FA_Study .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA_skeleton_mask .

fslmaths All_Kurtosis_E_DTI_AK_Study -mas mean_FA_mask All_Kurtosis_E_DTI_AK_Study
tbss_skeleton -i mean_FA -p $skeleton_threshold mean_FA_skeleton_mask_dst \
${FSLDIR}/data/standard/LowerCingulum_1mm All_Kurtosis_E_DTI_FA_Study All_AK_skeletonised -a All_Kurtosis_E_DTI_AK_Study

# # #--------------------------------------------------------------------------------------------------------------------------------------------
# -> MK
cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_MK
skeleton_threshold=0.2;

imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA_mask .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA_skeleton_mask_dst .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/All_Kurtosis_E_DTI_FA_Study .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA_skeleton_mask .

fslmaths All_Kurtosis_E_DTI_MK_Study -mas mean_FA_mask All_Kurtosis_E_DTI_MK_Study
tbss_skeleton -i mean_FA -p $skeleton_threshold mean_FA_skeleton_mask_dst \
${FSLDIR}/data/standard/LowerCingulum_1mm All_Kurtosis_E_DTI_FA_Study All_MK_skeletonised -a All_Kurtosis_E_DTI_MK_Study


# # #--------------------------------------------------------------------------------------------------------------------------------------------
# -> RK
cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_RK
skeleton_threshold=0.2;

imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA_mask .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA_skeleton_mask_dst .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/All_Kurtosis_E_DTI_FA_Study .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA_skeleton_mask .

fslmaths All_Kurtosis_E_DTI_RK_Study -mas mean_FA_mask All_Kurtosis_E_DTI_RK_Study
tbss_skeleton -i mean_FA -p $skeleton_threshold mean_FA_skeleton_mask_dst \
${FSLDIR}/data/standard/LowerCingulum_1mm All_Kurtosis_E_DTI_FA_Study All_RK_skeletonised -a All_Kurtosis_E_DTI_RK_Study

# # #--------------------------------------------------------------------------------------------------------------------------------------------
# -> KA
cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_KA
skeleton_threshold=0.2;

imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA_mask .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA_skeleton_mask_dst .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/All_Kurtosis_E_DTI_FA_Study .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA_skeleton_mask .

fslmaths All_Kurtosis_E_DTI_KA_Study -mas mean_FA_mask All_Kurtosis_E_DTI_KA_Study
tbss_skeleton -i mean_FA -p $skeleton_threshold mean_FA_skeleton_mask_dst \
${FSLDIR}/data/standard/LowerCingulum_1mm All_Kurtosis_E_DTI_FA_Study All_KA_skeletonised -a All_Kurtosis_E_DTI_KA_Study


# # #--------------------------------------------------------------------------------------------------------------------------------------------
# -> AWF
cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_AWF
skeleton_threshold=0.2;

imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA_mask .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA_skeleton_mask_dst .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/All_Kurtosis_E_DTI_FA_Study .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA_skeleton_mask .

fslmaths All_Kurtosis_E_DTI_AWF_Study -mas mean_FA_mask All_Kurtosis_E_DTI_AWF_Study
tbss_skeleton -i mean_FA -p $skeleton_threshold mean_FA_skeleton_mask_dst \
${FSLDIR}/data/standard/LowerCingulum_1mm All_Kurtosis_E_DTI_FA_Study All_AWF_skeletonised -a All_Kurtosis_E_DTI_AWF_Study


# # #--------------------------------------------------------------------------------------------------------------------------------------------
# -> TORT
cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_TORT
skeleton_threshold=0.2;

imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA_mask .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA_skeleton_mask_dst .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/All_Kurtosis_E_DTI_FA_Study .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/Kurtosis_Explore_DTI/Kurtosis_E_DTI_FA/mean_FA_skeleton_mask .

fslmaths All_Kurtosis_E_DTI_TORT_Study -mas mean_FA_mask All_Kurtosis_E_DTI_TORT_Study
tbss_skeleton -i mean_FA -p $skeleton_threshold mean_FA_skeleton_mask_dst \
${FSLDIR}/data/standard/LowerCingulum_1mm All_Kurtosis_E_DTI_FA_Study All_TORT_skeletonised -a All_Kurtosis_E_DTI_TORT_Study













