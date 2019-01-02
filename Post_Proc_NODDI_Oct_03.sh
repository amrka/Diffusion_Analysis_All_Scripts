#!/bin/bash

# Thu Sep 20 11:55:51 CEST 2018


#This script to move all the maps (regsitered to study template and to Waxholm) from workingdirectory of the following modules:
# 1 -> Diffusion 20 
# 2 -> Kurtosis
# 3 -> CHARMED_r2
# 4 -> NODDI

######################################################################################################

# Icreated this tree manually, to serve as the local directory to transfer the maps and merge them for TBSS purposes later

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
cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_NODDI_workingdir/Multishell_NODDI_workflow
for folder in _subject_id_*;do

		cd $folder
		id=`echo $folder | sed s/'_subject_id_'/''/`

		imcp ODI_To_WAX_Template/transform_Warped.nii.gz  \
		/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/NODDI/NODDI_ODI/ODI_${id}

		imcp antsApply_FICVF_WAX/FICVF_{subject_id}  \
		/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/NODDI/NODDI_FICVF/FICVF_${id}


		cd ..

done


#change names to contain gp number 


python3 /home/amr/SCRIPTS/change_files_to_contain_gp_name.py \
/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/NODDI/NODDI_ODI  4 7

cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/NODDI/NODDI_ODI
fslmerge -t All_NODDI_ODI_WAX *
#->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

python3 /home/amr/SCRIPTS/change_files_to_contain_gp_name.py \
/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/NODDI/NODDI_FICVF  6 9 

cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/NODDI/NODDI_FICVF
fslmerge -t All_NODDI_FICVF_WAX *


###########################################################################################################################
#############################################						#######################################################
#############################################          TBSS         #######################################################
#############################################						#######################################################
###########################################################################################################################
#We copy CHARMED, becasue there is no FA here to use and we used the same data after eddy_correct
#But run Post_Proc_CHARMED_Oct_04.sh first and do not be stupid
# # #Now, TBSS
#ODI
cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/NODDI/NODDI_ODI
skeleton_threshold=0.2;

imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/CHARMED/CHARMED_FA/mean_FA_mask .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/CHARMED/CHARMED_FA/mean_FA .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/CHARMED/CHARMED_FA/mean_FA_skeleton_mask_dst .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/CHARMED/CHARMED_FA/All_CHARMED_FA_WAX .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/CHARMED/CHARMED_FA/mean_FA_skeleton_mask .

fslmaths All_NODDI_ODI_WAX -mas mean_FA_mask All_NODDI_ODI_WAX
tbss_skeleton -i mean_FA -p $skeleton_threshold mean_FA_skeleton_mask_dst \
${FSLDIR}/data/standard/LowerCingulum_1mm All_CHARMED_FA_WAX All_ODI_skeletonised -a All_NODDI_ODI_WAX


# # #--------------------------------------------------------------------------------------------------------------------------------------------
# -> FICVF

cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/NODDI/NODDI_FICVF
skeleton_threshold=0.2;

imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/CHARMED/CHARMED_FA/mean_FA_mask .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/CHARMED/CHARMED_FA/mean_FA .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/CHARMED/CHARMED_FA/mean_FA_skeleton_mask_dst .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/CHARMED/CHARMED_FA/All_CHARMED_FA_WAX .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Waxholm_Template/CHARMED/CHARMED_FA/mean_FA_skeleton_mask .

fslmaths All_NODDI_FICVF_WAX -mas mean_FA_mask All_NODDI_FICVF_WAX
tbss_skeleton -i mean_FA -p $skeleton_threshold mean_FA_skeleton_mask_dst \
${FSLDIR}/data/standard/LowerCingulum_1mm All_CHARMED_FA_WAX All_FICVF_skeletonised -a All_NODDI_FICVF_WAX



# #------------------------------------------------------------------------------------------------------------
###########################################################################################################################
#############################################						#######################################################
#############################################  Study-Based Template #######################################################
#############################################						#######################################################
###########################################################################################################################
#2 -> Study-Based Template
cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_NODDI_workingdir/Multishell_NODDI_workflow
for folder in _subject_id_*;do

		cd $folder
		id=`echo $folder | sed s/'_subject_id_'/''/`

		imcp ODI_To_ODI_Study_Template/transform_Warped.nii.gz  \
		/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/NODDI/NODDI_ODI/ODI_${id}

		imcp antsApply_FICVF_Study/_FICVF_{subject_id}  \
		/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/NODDI/NODDI_FICVF/FICVF_${id}


		cd ..

done

#change names to contain gp number 

python3 /home/amr/SCRIPTS/change_files_to_contain_gp_name.py \
/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/NODDI/NODDI_ODI  4 7

cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/NODDI/NODDI_ODI
fslmerge -t All_NODDI_ODI_Study *
#->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

python3 /home/amr/SCRIPTS/change_files_to_contain_gp_name.py \
/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/NODDI/NODDI_FICVF  6 9 

cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/NODDI/NODDI_FICVF
fslmerge -t All_NODDI_FICVF_Study *



#--end comment here------------------------------------------------------------------------------------------------------------------------	

###########################################################################################################################
#############################################						#######################################################
#############################################          TBSS         #######################################################
#############################################						#######################################################
###########################################################################################################################

# # #Now, TBSS
cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/NODDI/NODDI_ODI
skeleton_threshold=0.2;

imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/CHARMED/CHARMED_FA/mean_FA_mask .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/CHARMED/CHARMED_FA/mean_FA .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/CHARMED/CHARMED_FA/mean_FA_skeleton_mask_dst .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/CHARMED/CHARMED_FA/All_CHARMED_FA_Study .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/CHARMED/CHARMED_FA/mean_FA_skeleton_mask .

fslmaths All_NODDI_ODI_Study -mas mean_FA_mask All_NODDI_ODI_Study
tbss_skeleton -i mean_FA -p $skeleton_threshold mean_FA_skeleton_mask_dst \
${FSLDIR}/data/standard/LowerCingulum_1mm All_CHARMED_FA_Study All_ODI_skeletonised -a All_NODDI_ODI_Study


# # #--------------------------------------------------------------------------------------------------------------------------------------------
# -> FICVF

cd /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/NODDI/NODDI_FICVF
skeleton_threshold=0.2;

imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/CHARMED/CHARMED_FA/mean_FA_mask .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/CHARMED/CHARMED_FA/mean_FA .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/CHARMED/CHARMED_FA/mean_FA_skeleton_mask_dst .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/CHARMED/CHARMED_FA/All_CHARMED_FA_Study .
imcp /media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Study_Based_Template/CHARMED/CHARMED_FA/mean_FA_skeleton_mask .

fslmaths All_NODDI_FICVF_Study -mas mean_FA_mask All_NODDI_FICVF_Study
tbss_skeleton -i mean_FA -p $skeleton_threshold mean_FA_skeleton_mask_dst \
${FSLDIR}/data/standard/LowerCingulum_1mm All_CHARMED_FA_Study All_FICVF_skeletonised -a All_NODDI_FICVF_Study

# # #--------------------------------------------------------------------------------------------------------------------------------------------
















