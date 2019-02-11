#!/bin/bash
#Creates directory for TBSS of Diffusion_20, Kurtosis, CHARMED, NODDI

#Do not put spaces after ,
cd /media/amr/Amr_4TB/Work/October_Acquistion
mkdir Diffusion_TBSS_Stat

cd Diffusion_TBSS_Stat
mkdir Study_Based_Template Waxholm_Template

#You can do it in only one line, this better for reading
cd Study_Based_Template
mkdir -p CHARMED/{CHARMED_FR,CHARMED_FA,CHARMED_MD,CHARMED_RD,CHARMED_AD,CHARMED_IAD}
mkdir -p Diffusion_20/{Diffusion_20_FA,Diffusion_20_MD,Diffusion_20_RD,Diffusion_20_AD} 
mkdir -p Kurtosis/{Kurtosis_FA,Kurtosis_MD,Kurtosis_RD,Kurtosis_AD,Kurtosis_MK,Kurtosis_AK,Kurtosis_RK,Kurtosis_AWF,Kurtosis_TORT} 
mkdir -p NODDI/{NODDI_ODI,NODDI_FICVF}
mkdir -p Kurtosis_Explore_DTI/{Kurtosis_FA,Kurtosis_MD,Kurtosis_RD,Kurtosis_AD,Kurtosis_MK,Kurtosis_AK,Kurtosis_RK,Kurtosis_AWF,Kurtosis_TORT}



cd ..
cd Waxholm_Template
mkdir -p CHARMED/{CHARMED_FR,CHARMED_FA,CHARMED_MD,CHARMED_RD,CHARMED_AD,CHARMED_IAD}
mkdir -p Diffusion_20/{Diffusion_20_FA,Diffusion_20_MD,Diffusion_20_RD,Diffusion_20_AD} 
mkdir -p Kurtosis/{Kurtosis_FA,Kurtosis_MD,Kurtosis_RD,Kurtosis_AD,Kurtosis_MK,Kurtosis_AK,Kurtosis_RK,Kurtosis_AWF,Kurtosis_TORT} 
mkdir -p NODDI/{NODDI_ODI,NODDI_FICVF}
