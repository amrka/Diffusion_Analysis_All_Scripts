from nipype import config
cfg = dict(execution={'remove_unnecessary_outputs': False})
config.update_config(cfg)

import numpy as np
import matplotlib.pyplot as plt
import nipype.interfaces.fsl as fsl
import nipype.interfaces.afni as afni
import nipype.interfaces.ants as ants
import nipype.interfaces.spm as spm
import nipype.interfaces.utility as utility
from nipype.interfaces.utility import IdentityInterface, Function
from os.path import join as opj
from nipype.interfaces.io import SelectFiles, DataSink
from nipype.pipeline.engine import Workflow, Node, MapNode

from nipype.interfaces.matlab import MatlabCommand





#-----------------------------------------------------------------------------------------------------
# In[-1]:

experiment_dir = '/media/amr/Amr_4TB/Work/October_Acquistion/' 

subject_list = ['229', '230', '232', '233', 
                '234', '235', '237', '242', 
                '243', '244', '245', '252', 
                '253', '255', '261', '262', 
                '263', '264', '273', '274', 
                '281', '282', '286', '287', 
                '362', '363', '364', '365', 
                '366']

# subject_list = ['229', '230', '365', '274']
                
# subject_list = ['255']


output_dir  = 'Diffusion_Multishell_ExploreDTI_output'
working_dir = 'Diffusion_Multishell_ExploreDTI_workingdir'
workflow = 'Multishell_ExploreDTI_workflow'

Multishell_ExploreDTI_workflow = Workflow (name = workflow)
Multishell_ExploreDTI_workflow.base_dir = opj(experiment_dir, working_dir)

#-----------------------------------------------------------------------------------------------------
# In[3]:


# Infosource - a function free node to iterate over the list of subject names
infosource = Node(IdentityInterface(fields=['subject_id']),
                  name="infosource")
infosource.iterables = [('subject_id', subject_list)]

#-----------------------------------------------------------------------------------------------------
# In[4]:

#To avoid running eddy again, I will pass eddy_corrected from Kurtosis pipeline that was previously processed remotely
#on trueno
templates = {

'DWI_eddy_corrected'  : '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_Kurtosis_workingdir/Multishell_workflow_Kurtosis/_subject_id_{subject_id}/eddy/Diff_Multishell_{subject_id}_edc.nii.gz',

}

selectfiles = Node(SelectFiles(templates,
                   base_directory=experiment_dir),
                   name="selectfiles")
#-----------------------------------------------------------------------------------------------------
# In[5]:

# datasink = Node(DataSink(base_directory=experiment_dir,
#                          container=output_dir),
#                 name="datasink")
datasink = Node(DataSink(), name = 'datasink')
datasink.inputs.container = output_dir
datasink.inputs.base_directory = experiment_dir

substitutions = [('_subject_id_', '')]

datasink.inputs.substitutions = substitutions



#-----------------------------------------------------------------------------------------------------
# In[6]:
Bmatrix = '/media/amr/Amr_4TB/Work/October_Acquistion/Bmatrix_ExploreDTI.txt'
Wax_FA_Template = '/media/amr/HDD/Work/standard/FMRIB58_FA_2mm.nii.gz'
Study_Template = '/media/amr/HDD/Work/October_Acquistion/FA_Template_Cluster.nii.gz'
#The AND and NOT added together to facilitate the transformations
CC_mask_AND_Study = '/media/amr/Amr_4TB/Work/October_Acquistion/Standard_Diffusion/CC_FA_Study_Template.nii'
CC_mask_NOT_Study = '/media/amr/Amr_4TB/Work/October_Acquistion/Standard_Diffusion/CC_Exclusion_FA_Study_Template_mask.nii'

#-----------------------------------------------------------------------------------------------------
# In[7]:
#We need to change from .nii.gz to nii
decompress = Node(fsl.ChangeDataType(), name = 'decompress')
decompress.inputs.output_datatype = 'float'
decompress.inputs.output_type = 'NIFTI'

#-----------------------------------------------------------------------------------------------------
# In[8]:
def ExploreDTI_sort(eddy_file):
    import nipype.interfaces.matlab as Matlab
    import os
    import re
    from shutil import copy

    matlab = Matlab.MatlabCommand()
    
    # below is where you add paths that matlab might require, this is equivalent to addpath()
    matlab.inputs.paths = ['/home/amr/SCRIPTS/']
    matlab.inputs.single_comp_thread = False
    Bmatrix = '/media/amr/Amr_4TB/Work/October_Acquistion/Bmatrix_ExploreDTI.txt'
    experiment_dir = '/media/amr/Amr_4TB/Work/October_Acquistion' 
    working_dir = 'Diffusion_Multishell_ExploreDTI_workingdir'
    workflow = 'Multishell_ExploreDTI_workflow'
    cwd = os.getcwd()
    subj_no = re.findall('\d+',cwd)[-1]
    


    copy(Bmatrix, '%s/%s/%s/_subject_id_%s/decompress/Diff_Multishell_%s_edc_chdt.txt'
    	%(experiment_dir,working_dir,workflow,subj_no, subj_no))

    matlab.inputs.script = """


    eddy_file = '{0}'
    

    
    name_wo_ext = eddy_file(145:end-4)
   

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Sort eddy_corrected nii%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % You need the absolute path for things to work 
    
    E_DTI_sort_DWIs_wrt_b_val_ex(eddy_file,['{1}' '/' '' name_wo_ext '_sorted.nii'],...
    ['{1}' '/' '' name_wo_ext '_sorted.nii'])
    
    """.format(eddy_file, cwd) #Ihave no idea why '' solved the problem of writing to different dir, but it did
    
    res = matlab.run()
    
    sorted_nii = os.path.abspath('Diff_Multishell_{0}_edc_chdt_sorted.nii'.format(subj_no))
    sorted_txt = os.path.abspath('Diff_Multishell_{0}_edc_chdt_sorted.txt'.format(subj_no))

    return sorted_nii, sorted_txt #You always need return


ExploreDTI_sort = Node(name = 'ExploreDTI_sort',
                  interface = Function(input_names = ['eddy_file'],
                  					   output_names = ['sorted_nii', 'sorted_txt'],
                  function = ExploreDTI_sort))

#-----------------------------------------------------------------------------------------------------
# In[9]:
def ExploreDTI_mat(sorted_nii, sorted_txt):
    import nipype.interfaces.matlab as Matlab
    import os
    from shutil import copy
    import re
    matlab = Matlab.MatlabCommand()
    
    # below is where you add paths that matlab might require, this is equivalent to addpath()
    matlab.inputs.paths = ['/home/amr/SCRIPTS/']
    matlab.inputs.single_comp_thread = False


    cwd = os.getcwd()
    subj_no = re.findall('\d+',cwd)[-1]



    matlab.inputs.script = """
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%convert to kurtosis.mat%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Mask_par.tune_NDWI = 0.7;  % recommened by Leemans
    Mask_par.tune_DWI = 0.7;
    Mask_par.mfs = 5
    
    f_DWI = '{0}'
    f_BM  = '{1}'
    basename = f_DWI(1:end-4)
    f_mat = [basename '.mat']
    
    E_DTI_quick_and_dirty_DKI_convert_from_nii_txt_to_mat(f_DWI, f_BM, f_mat, Mask_par, 6, 2, 1)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Now flip R-L%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    flipped_mat = ['{2}/Diff_Multishell_{3}_sorted_flipped.mat']
    
    E_DTI_Flip_left_right_mat(f_mat,flipped_mat)

    """.format(sorted_nii, sorted_txt, cwd, subj_no) #Ihave no idea why '' solved the problem of writing to different dir, but it did
    
    res = matlab.run()
    
    flipped_mat = os.path.abspath('Diff_Multishell_{0}_sorted_flipped.mat'.format(subj_no))

    return flipped_mat #You always need return


ExploreDTI_mat = Node(name = 'ExploreDTI_mat',
                  interface = Function(input_names = ['sorted_nii', 'sorted_txt'],
                  					   output_names = ['flipped_mat'],
                  function = ExploreDTI_mat))


#-----------------------------------------------------------------------------------------------------
# In[8]

def ExploreDTI_kurtosis(flipped_mat):
    import nipype.interfaces.matlab as Matlab
    import os
    from shutil import copy
    import re
    matlab = Matlab.MatlabCommand()
    
    # below is where you add paths that matlab might require, this is equivalent to addpath()
    matlab.inputs.paths = ['/home/amr/SCRIPTS/']
    matlab.inputs.single_comp_thread = False


    cwd = os.getcwd()
    subj_no = re.findall('\d+',cwd)[-1]



    matlab.inputs.script = """
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Get Kurtosis params%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    addpath('/media/amr/HDD/Softwares/ExploreDTI')
    MainExploreDTI;
    vars = E_DTI_Complete_List_var;
    %  FA -> 1
    %  MD -> 2
    %  L1 aka AD ->3
    %  RD -> 6
    %
    % 'Mean kurtosis (''_MK.nii'')' -> 46
    % 'Axial kurtosis (''_AK.nii'')' -> 47 
    % 'Radial kurtosis (''_RK.nii'')' -> 48
    % 'Kurtosis anisotropy (''_KA.nii'')' -> 49
    %  AWF -> 53
    %  TORT -> 54
    
    E_DTI_Convert_mat_2_nii('{0}', '{1}', vars([1:3,6,46:49,53,54]))

    """.format(flipped_mat, cwd) #Ihave no idea why '' solved the problem of writing to different dir, but it did
    
    res = matlab.run()
    
    ak   = os.path.abspath('Diff_Multishell_{0}_sorted_flipped_AK.nii'.format(subj_no))
    awf  = os.path.abspath('Diff_Multishell_{0}_sorted_flipped_AWF.nii'.format(subj_no))
    fa   = os.path.abspath('Diff_Multishell_{0}_sorted_flipped_FA.nii'.format(subj_no))
    ka   = os.path.abspath('Diff_Multishell_{0}_sorted_flipped_KA.nii'.format(subj_no))
    ad 	 = os.path.abspath('Diff_Multishell_{0}_sorted_flipped_L1.nii'.format(subj_no))
    md   = os.path.abspath('Diff_Multishell_{0}_sorted_flipped_MD.nii'.format(subj_no))
    mk   = os.path.abspath('Diff_Multishell_{0}_sorted_flipped_MK.nii'.format(subj_no))
    rd   = os.path.abspath('Diff_Multishell_{0}_sorted_flipped_RD.nii'.format(subj_no))
    rk   = os.path.abspath('Diff_Multishell_{0}_sorted_flipped_RK.nii'.format(subj_no))
    tort = os.path.abspath('Diff_Multishell_{0}_sorted_flipped_TORT.nii'.format(subj_no))



    return ak,awf,fa,ka,ad,md,mk,rd,rk,tort #You always need return


ExploreDTI_kurtosis = Node(name = 'ExploreDTI_kurtosis',
                  interface = Function(input_names = ['flipped_mat'],
                  					   output_names = ['ak','awf','fa','ka','ad','md','mk','rd','rk','tort'],
                  function = ExploreDTI_kurtosis))

#-----------------------------------------------------------------------------------------------------
# In[10]


def ExploreDTI_tractography(flipped_mat):
    import nipype.interfaces.matlab as Matlab
    import os
    from shutil import copy
    import re
    matlab = Matlab.MatlabCommand()
    
    # below is where you add paths that matlab might require, this is equivalent to addpath()
    matlab.inputs.paths = ['/home/amr/SCRIPTS/']
    matlab.inputs.single_comp_thread = False


    cwd = os.getcwd()
    subj_no = re.findall('\d+',cwd)[-1]



    matlab.inputs.script = """

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Tractography%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

params.SeedPointRes = [2 2 2]
params.LinearGeoTrackRange = [0 1]
params.SphericalGeoTrackRange = [0 1]
params.InterpolationMethod = 1
params.PlanarGeoTrackRange = [0 1]
params.SeedFAThresh = 0.2
params.AngleThresh = 30
params.MDTrackRange = [0 Inf]
params.FiberLengthRange = [5 500]
params.ran_sam = 0
params.StepSize = 1
params.FAThresh = 0.2
params.SeedFAThreshold = 0.2
params.FATrackRange = [0.2 1]

tracts_thick = ['{0}/Diff_Multishell_{1}_Tracts_Thick.mat']

tracts_thin = ['{0}/Diff_Multishell_{1}_Tracts_Thin.mat']

%on the other hand, this will return only the major bundles
E_DTI_WholeBrainTracking('{2}', tracts_thick, params)

% params.FiberLengthRange = [50 500]
% this will written only the major  tracts
% WholeBrainTrackingDTI_fast('{2}', tracts_thin, params)


  """.format(cwd, subj_no, flipped_mat) #Ihave no idea why '' solved the problem of writing to different dir, but it did
    
    res = matlab.run()

    tracts = os.path.abspath('Diff_Multishell_{0}_Tracts_Thick.mat'.format(subj_no))
    return  tracts #You always need return


ExploreDTI_tractography = Node(name = 'ExploreDTI_tractography',
                  interface = Function(input_names = ['flipped_mat'],
                  					   output_names = ['tracts'],
                  function = ExploreDTI_tractography))


#-----------------------------------------------------------------------------------------------------
# In[] Apply transformations to kurtosis images
#register FA to Wax

FA_to_Study_Temp = Node(ants.Registration(), name = 'FA_To_Study_Template')
FA_to_Study_Temp.inputs.args='--float'
FA_to_Study_Temp.inputs.collapse_output_transforms=True
FA_to_Study_Temp.inputs.initial_moving_transform_com=True
FA_to_Study_Temp.inputs.fixed_image= Study_Template
FA_to_Study_Temp.inputs.num_threads=4
FA_to_Study_Temp.inputs.output_inverse_warped_image=True
FA_to_Study_Temp.inputs.output_warped_image=True
FA_to_Study_Temp.inputs.sigma_units=['vox']*3
FA_to_Study_Temp.inputs.transforms= ['Rigid', 'Affine', 'SyN']
# FA_to_Study_Temp.inputs.terminal_output='file' #returns an error
FA_to_Study_Temp.inputs.winsorize_lower_quantile=0.005
FA_to_Study_Temp.inputs.winsorize_upper_quantile=0.995
FA_to_Study_Temp.inputs.convergence_threshold=[1e-6]
FA_to_Study_Temp.inputs.convergence_window_size=[10]
FA_to_Study_Temp.inputs.metric=['MI', 'MI', 'CC']
FA_to_Study_Temp.inputs.metric_weight=[1.0]*3
FA_to_Study_Temp.inputs.number_of_iterations=[[1000, 500, 250, 100],
                                                 [1000, 500, 250, 100],
                                                 [100, 70, 50, 20]]
FA_to_Study_Temp.inputs.radius_or_number_of_bins=[32, 32, 4]
FA_to_Study_Temp.inputs.sampling_percentage=[0.25, 0.25, 1]
FA_to_Study_Temp.inputs.sampling_strategy=['Regular',
                                              'Regular',
                                              'None']
FA_to_Study_Temp.inputs.shrink_factors=[[8, 4, 2, 1]]*3
FA_to_Study_Temp.inputs.smoothing_sigmas=[[3, 2, 1, 0]]*3
FA_to_Study_Temp.inputs.transform_parameters=[(0.1,),
                                                 (0.1,),
                                                 (0.1, 3.0, 0.0)]
FA_to_Study_Temp.inputs.use_histogram_matching=True
FA_to_Study_Temp.inputs.write_composite_transform=True
FA_to_Study_Temp.inputs.verbose=True
FA_to_Study_Temp.inputs.output_warped_image=True
FA_to_Study_Temp.inputs.float=True

#>>>>>>>>>>>>>>>>>>>>>>>>>>>AK
antsApply_AK_Study = Node(ants.ApplyTransforms(), name = 'antsApply_AK_Study')
antsApply_AK_Study.inputs.dimension = 3
antsApply_AK_Study.inputs.input_image_type = 3
antsApply_AK_Study.inputs.num_threads = 1
antsApply_AK_Study.inputs.float = True
antsApply_AK_Study.inputs.output_image = 'DKI_ExploreDTI_AK.nii'
antsApply_AK_Study.inputs.reference_image = Study_Template


#>>>>>>>>>>>>>>>>>>>>>>>>>AWF
antsApply_AWF_Study = antsApply_AK_Study.clone(name = 'antsApply_AWF_Study')
antsApply_AWF_Study.inputs.output_image = 'DKI_ExploreDTI_AWF.nii'

#>>>>>>>>>>>>>>>>>>>>>>>>>KA
antsApply_KA_Study = antsApply_AK_Study.clone(name = 'antsApply_KA_Study')
antsApply_KA_Study.inputs.output_image = 'DKI_ExploreDTI_KA.nii'

#>>>>>>>>>>>>>>>>>>>>>>>>>AD
antsApply_AD_Study = antsApply_AK_Study.clone(name = 'antsApply_AD_Study')
antsApply_AD_Study.inputs.output_image = 'DKI_ExploreDTI_AD.nii'

#>>>>>>>>>>>>>>>>>>>>>>>>>MD
antsApply_MD_Study = antsApply_AK_Study.clone(name = 'antsApply_MD_Study')
antsApply_MD_Study.inputs.output_image = 'DKI_ExploreDTI_MD.nii'

#>>>>>>>>>>>>>>>>>>>>>>>>>MK
antsApply_MK_Study = antsApply_AK_Study.clone(name = 'antsApply_MK_Study')
antsApply_MK_Study.inputs.output_image = 'DKI_ExploreDTI_MK.nii'

#>>>>>>>>>>>>>>>>>>>>>>>>>RD
antsApply_RD_Study = antsApply_AK_Study.clone(name = 'antsApply_RD_Study')
antsApply_RD_Study.inputs.output_image = 'DKI_ExploreDTI_RD.nii'

#>>>>>>>>>>>>>>>>>>>>>>>>>RK
antsApply_RK_Study = antsApply_AK_Study.clone(name = 'antsApply_RK_Study')
antsApply_RK_Study.inputs.output_image = 'DKI_ExploreDTI_RK.nii'

#>>>>>>>>>>>>>>>>>>>>>>>>>TORT
antsApply_TORT_Study = antsApply_AK_Study.clone(name = 'antsApply_TORT_Study')
antsApply_TORT_Study.inputs.output_image = 'DKI_ExploreDTI_TORT.nii'




#-----------------------------------------------------------------------------------------------------
# In[] move the masks (AND & NOT from Waxholm space to subject space)


#>>>>>>>>>>>>>>>>>>>>>>>>>>>AND
transform_cc_AND_mask = Node(ants.ApplyTransforms(), name = 'transform_cc_AND_mask')
transform_cc_AND_mask.inputs.dimension = 3
transform_cc_AND_mask.inputs.input_image_type = 3
transform_cc_AND_mask.inputs.input_image = CC_mask_AND_Study
transform_cc_AND_mask.inputs.num_threads = 1
transform_cc_AND_mask.inputs.float = True
transform_cc_AND_mask.inputs.output_image = 'CC_AND_mask.nii'
transform_cc_AND_mask.inputs.interpolation = 'NearestNeighbor'


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>NOT
transform_cc_NOT_mask = transform_cc_AND_mask.clone(name = 'transform_cc_NOT_mask')
transform_cc_NOT_mask.inputs.input_image = CC_mask_NOT_Study
transform_cc_NOT_mask.inputs.output_image = 'CC_NOT_mask.nii'

#-----------------------------------------------------------------------------------------------------
# In[12] to use ExploreDTI_calculate_tracts_from_masks, you need to have a folder of masks
#Itried with a list of masks in matlab, it did not work
#the other good option was to make the 2 masks as 4D merged togther, transform,  reorient and then split
#the only proble with rather a resonable option is that, it won't give me a folder as an output
#I can pass to matlab, hence the only left option is to create a function to copy the two masks(AND&NOT)
#and return me the folder as an output

def copy_masks_to_same_folder(AND_mask, NOT_mask):
    import os
    from shutil import copy2
    import re

    import nipype.interfaces.fsl as fsl


    cwd_masks = os.getcwd()
    subj_no = re.findall('\d+',cwd_masks)[-1]


    copy2(AND_mask, cwd_masks)
    copy2(NOT_mask, cwd_masks)

    return cwd_masks

copy_masks_to_same_folder = Node(name = 'copy_masks_to_same_folder',
				interface = Function(input_names = ['AND_mask', 'NOT_mask'],
									 output_names = ['cwd_masks'],
									 function = copy_masks_to_same_folder))


#-----------------------------------------------------------------------------------------------------
# In[12] calculate tracts from folder of masks

def ExploreDTI_calculate_tracts_from_masks(cwd_masks, tracts, mat):
    import nipype.interfaces.matlab as Matlab
    import os
    from shutil import copy
    import re
    matlab = Matlab.MatlabCommand()
    
    # below is where you add paths that matlab might require, this is equivalent to addpath()
    matlab.inputs.paths = ['/home/amr/SCRIPTS/']
    matlab.inputs.single_comp_thread = False
    cwd = os.getcwd()
    subj_no = re.findall('\d+',cwd)[-1]



    matlab.inputs.script = """


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%calculate tracts from masks%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


E_DTI_Analyse_tracts_ff...
    ('{0}', '{1}', '{2}', '{3}/CC_Tracts_{4}.mat')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Extract Tract Info%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

E_DTI_Convert_Tract_mats_2_xls('{3}', '{3}/Tracts_Desc_Stats_{4}.csv')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Extract Tract Info Other Modalities%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Native space, do not forget
% put all images you wish to extract tract info from 
% matlab from inside python does not accept curly braces aka cells, i tried many combinations without much luck

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Diff_20
fa_diff_20 =  '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_20_workingdir/DTI_workflow/_subject_id_{4}/fit_tensor/dtifit__FA.nii.gz'
E_DTI_Export_Tract_Volume_Info(fa_diff_20 ,'{3}/CC_Tracts_{4}.mat','{2}','{3}')
fa_diff_20 = load('{3}/CC_Tracts_{4}_dtifit__FA.nii_Vol_Info.mat');
dlmwrite('{3}/Tracts_Others_Stats_{4}.csv', ['FA_Diff_20_{4},' num2str(fa_diff_20.mean_TV)], 'delimiter','','-append');



md_diff_20 =  '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_20_workingdir/DTI_workflow/_subject_id_{4}/fit_tensor/dtifit__MD.nii.gz'
E_DTI_Export_Tract_Volume_Info(md_diff_20 ,'{3}/CC_Tracts_{4}.mat','{2}','{3}')
md_diff_20 = load('{3}/CC_Tracts_{4}_dtifit__MD.nii_Vol_Info.mat');
dlmwrite('{3}/Tracts_Others_Stats_{4}.csv', ['MD_Diff_20_{4},' num2str(md_diff_20.mean_TV)], 'delimiter','','-append');


ad_diff_20 =  '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_20_workingdir/DTI_workflow/_subject_id_{4}/fit_tensor/dtifit__L1.nii.gz'
E_DTI_Export_Tract_Volume_Info(ad_diff_20 ,'{3}/CC_Tracts_{4}.mat','{2}','{3}')
ad_diff_20 = load('{3}/CC_Tracts_{4}_dtifit__L1.nii_Vol_Info.mat');
dlmwrite('{3}/Tracts_Others_Stats_{4}.csv', ['AD_Diff_20_{4},' num2str(ad_diff_20.mean_TV)], 'delimiter','','-append');


rd_diff_20 =  '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_20_workingdir/DTI_workflow/_subject_id_{4}/RD/dtifit__L2_maths_maths.nii.gz'
E_DTI_Export_Tract_Volume_Info(rd_diff_20 ,'{3}/CC_Tracts_{4}.mat','{2}','{3}')
rd_diff_20 = load('{3}/CC_Tracts_{4}_dtifit__L2_maths_maths.nii_Vol_Info.mat');
dlmwrite('{3}/Tracts_Others_Stats_{4}.csv', ['RD_Diff_20_{4},' num2str(rd_diff_20.mean_TV)], 'delimiter','','-append');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%CHARMED
FA_CHARMED = '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_CHARMED_workingdir/Multishell_CHARMED_workflow/_subject_id_{4}/CHARMED_r2/CHARMED_r2/Tensor.FA.nii.gz'
E_DTI_Export_Tract_Volume_Info(FA_CHARMED ,'{3}/CC_Tracts_{4}.mat','{2}','{3}')
FA_CHARMED = load('{3}/CC_Tracts_{4}_Tensor.FA.nii_Vol_Info.mat');
dlmwrite('{3}/Tracts_Others_Stats_{4}.csv', ['FA_CHARMED_{4},' num2str(FA_CHARMED.mean_TV)], 'delimiter','','-append');

MD_CHARMED = '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_CHARMED_workingdir/Multishell_CHARMED_workflow/_subject_id_{4}/CHARMED_r2/CHARMED_r2/Tensor.MD.nii.gz'
E_DTI_Export_Tract_Volume_Info(MD_CHARMED ,'{3}/CC_Tracts_{4}.mat','{2}','{3}')
MD_CHARMED = load('{3}/CC_Tracts_{4}_Tensor.MD.nii_Vol_Info.mat');
dlmwrite('{3}/Tracts_Others_Stats_{4}.csv', ['MD_CHARMED_{4},' num2str(MD_CHARMED.mean_TV)], 'delimiter','','-append');

AD_CHARMED = '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_CHARMED_workingdir/Multishell_CHARMED_workflow/_subject_id_{4}/CHARMED_r2/CHARMED_r2/Tensor.AD.nii.gz'
E_DTI_Export_Tract_Volume_Info(AD_CHARMED ,'{3}/CC_Tracts_{4}.mat','{2}','{3}')
AD_CHARMED = load('{3}/CC_Tracts_{4}_Tensor.AD.nii_Vol_Info.mat');
dlmwrite('{3}/Tracts_Others_Stats_{4}.csv', ['AD_CHARMED_{4},' num2str(AD_CHARMED.mean_TV)], 'delimiter','','-append');

RD_CHARMED = '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_CHARMED_workingdir/Multishell_CHARMED_workflow/_subject_id_{4}/CHARMED_r2/CHARMED_r2/Tensor.RD.nii.gz'
E_DTI_Export_Tract_Volume_Info(RD_CHARMED ,'{3}/CC_Tracts_{4}.mat','{2}','{3}')
RD_CHARMED = load('{3}/CC_Tracts_{4}_Tensor.RD.nii_Vol_Info.mat');
dlmwrite('{3}/Tracts_Others_Stats_{4}.csv', ['RD_CHARMED_{4},' num2str(RD_CHARMED.mean_TV)], 'delimiter','','-append');

FR_CHARMED = '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_CHARMED_workingdir/Multishell_CHARMED_workflow/_subject_id_{4}/CHARMED_r2/CHARMED_r2/FR.nii.gz'
E_DTI_Export_Tract_Volume_Info(FR_CHARMED ,'{3}/CC_Tracts_{4}.mat','{2}','{3}')
FR_CHARMED = load('{3}/CC_Tracts_{4}_FR.nii_Vol_Info.mat');
dlmwrite('{3}/Tracts_Others_Stats_{4}.csv', ['FR_CHARMED_{4},' num2str(FR_CHARMED.mean_TV)], 'delimiter','','-append');


IAD_CHARMED = '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_CHARMED_workingdir/Multishell_CHARMED_workflow/_subject_id_{4}/CHARMED_r2/CHARMED_r2/CHARMEDRestricted0.d.nii.gz'
E_DTI_Export_Tract_Volume_Info(IAD_CHARMED ,'{3}/CC_Tracts_{4}.mat','{2}','{3}')
IAD_CHARMED = load('{3}/CC_Tracts_{4}_CHARMEDRestricted0.d.nii_Vol_Info.mat');
dlmwrite('{3}/Tracts_Others_Stats_{4}.csv', ['IAD_CHARMED_{4},' num2str(IAD_CHARMED.mean_TV)], 'delimiter','','-append');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%NODDI


ODI_NODDI = '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_NODDI_workingdir/Multishell_NODDI_workflow/_subject_id_{4}/NODDI/NODDI_odi.nii'
E_DTI_Export_Tract_Volume_Info(ODI_NODDI ,'{3}/CC_Tracts_{4}.mat','{2}','{3}')
ODI_NODDI = load('{3}/CC_Tracts_{4}_NODDI_odi_Vol_Info.mat');
dlmwrite('{3}/Tracts_Others_Stats_{4}.csv', ['ODI_NODDI_{4},' num2str(ODI_NODDI.mean_TV)], 'delimiter','','-append');


FICVF_NODDI = '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_NODDI_workingdir/Multishell_NODDI_workflow/_subject_id_{4}/NODDI/NODDI_ficvf.nii'
E_DTI_Export_Tract_Volume_Info(FICVF_NODDI ,'{3}/CC_Tracts_{4}.mat','{2}','{3}')
FICVF_NODDI = load('{3}/CC_Tracts_{4}_NODDI_ficvf_Vol_Info.mat');
dlmwrite('{3}/Tracts_Others_Stats_{4}.csv', ['FICVF_NODDI_{4},' num2str(FICVF_NODDI.mean_TV)], 'delimiter','','-append');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Kurtosis_dipy
FA_Kurtosis_dipy = '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_Kurtosis_workingdir/Multishell_workflow_Kurtosis/_subject_id_{4}/Kurtosis/DKI_FA.nii'
E_DTI_Export_Tract_Volume_Info(FA_Kurtosis_dipy ,'{3}/CC_Tracts_{4}.mat','{2}','{3}')
FA_Kurtosis_dipy = load('{3}/CC_Tracts_{4}_DKI_FA_Vol_Info.mat');
dlmwrite('{3}/Tracts_Others_Stats_{4}.csv', ['FA_Kurtosis_dipy_{4},' num2str(FA_Kurtosis_dipy.mean_TV)], 'delimiter','','-append');

MD_Kurtosis_dipy = '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_Kurtosis_workingdir/Multishell_workflow_Kurtosis/_subject_id_{4}/Kurtosis/DKI_MD.nii'
E_DTI_Export_Tract_Volume_Info(MD_Kurtosis_dipy ,'{3}/CC_Tracts_{4}.mat','{2}','{3}')
MD_Kurtosis_dipy = load('{3}/CC_Tracts_{4}_DKI_MD_Vol_Info.mat');
dlmwrite('{3}/Tracts_Others_Stats_{4}.csv', ['MD_Kurtosis_dipy_{4},' num2str(MD_Kurtosis_dipy.mean_TV)], 'delimiter','','-append');

AD_Kurtosis_dipy = '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_Kurtosis_workingdir/Multishell_workflow_Kurtosis/_subject_id_{4}/Kurtosis/DKI_AD.nii'
E_DTI_Export_Tract_Volume_Info(AD_Kurtosis_dipy ,'{3}/CC_Tracts_{4}.mat','{2}','{3}')
AD_Kurtosis_dipy = load('{3}/CC_Tracts_{4}_DKI_AD_Vol_Info.mat');
dlmwrite('{3}/Tracts_Others_Stats_{4}.csv', ['AD_Kurtosis_dipy_{4},' num2str(AD_Kurtosis_dipy.mean_TV)], 'delimiter','','-append');

RD_Kurtosis_dipy = '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_Kurtosis_workingdir/Multishell_workflow_Kurtosis/_subject_id_{4}/Kurtosis/DKI_RD.nii'
E_DTI_Export_Tract_Volume_Info(RD_Kurtosis_dipy ,'{3}/CC_Tracts_{4}.mat','{2}','{3}')
RD_Kurtosis_dipy = load('{3}/CC_Tracts_{4}_DKI_RD_Vol_Info.mat');
dlmwrite('{3}/Tracts_Others_Stats_{4}.csv', ['RD_Kurtosis_dipy_{4},' num2str(RD_Kurtosis_dipy.mean_TV)], 'delimiter','','-append');

AK_Kurtosis_dipy = '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_Kurtosis_workingdir/Multishell_workflow_Kurtosis/_subject_id_{4}/Kurtosis/DKI_AK.nii'
E_DTI_Export_Tract_Volume_Info(AK_Kurtosis_dipy ,'{3}/CC_Tracts_{4}.mat','{2}','{3}')
AK_Kurtosis_dipy = load('{3}/CC_Tracts_{4}_DKI_AK_Vol_Info.mat');
dlmwrite('{3}/Tracts_Others_Stats_{4}.csv', ['AK_Kurtosis_dipy_{4},' num2str(AK_Kurtosis_dipy.mean_TV)], 'delimiter','','-append');

AWF_Kurtosis_dipy = '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_Kurtosis_workingdir/Multishell_workflow_Kurtosis/_subject_id_{4}/Kurtosis/DKI_AWF.nii'
E_DTI_Export_Tract_Volume_Info(AWF_Kurtosis_dipy ,'{3}/CC_Tracts_{4}.mat','{2}','{3}')
AWF_Kurtosis_dipy = load('{3}/CC_Tracts_{4}_DKI_AWF_Vol_Info.mat');
dlmwrite('{3}/Tracts_Others_Stats_{4}.csv', ['AWF_Kurtosis_dipy_{4},' num2str(AWF_Kurtosis_dipy.mean_TV)], 'delimiter','','-append');


MK_Kurtosis_dipy = '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_Kurtosis_workingdir/Multishell_workflow_Kurtosis/_subject_id_{4}/Kurtosis/DKI_MK.nii'
E_DTI_Export_Tract_Volume_Info(MK_Kurtosis_dipy ,'{3}/CC_Tracts_{4}.mat','{2}','{3}')
MK_Kurtosis_dipy = load('{3}/CC_Tracts_{4}_DKI_MK_Vol_Info.mat');
dlmwrite('{3}/Tracts_Others_Stats_{4}.csv', ['MK_Kurtosis_dipy_{4},' num2str(MK_Kurtosis_dipy.mean_TV)], 'delimiter','','-append');


RK_Kurtosis_dipy = '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_Kurtosis_workingdir/Multishell_workflow_Kurtosis/_subject_id_{4}/Kurtosis/DKI_RK.nii'
E_DTI_Export_Tract_Volume_Info(RK_Kurtosis_dipy ,'{3}/CC_Tracts_{4}.mat','{2}','{3}')
RK_Kurtosis_dipy = load('{3}/CC_Tracts_{4}_DKI_RK_Vol_Info.mat');
dlmwrite('{3}/Tracts_Others_Stats_{4}.csv', ['RK_Kurtosis_dipy_{4},' num2str(RK_Kurtosis_dipy.mean_TV)], 'delimiter','','-append');

TORT_Kurtosis_dipy = '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_Kurtosis_workingdir/Multishell_workflow_Kurtosis/_subject_id_{4}/Kurtosis/DKI_TORT.nii'
E_DTI_Export_Tract_Volume_Info(TORT_Kurtosis_dipy ,'{3}/CC_Tracts_{4}.mat','{2}','{3}')
TORT_Kurtosis_dipy = load('{3}/CC_Tracts_{4}_DKI_TORT_Vol_Info.mat');
dlmwrite('{3}/Tracts_Others_Stats_{4}.csv', ['TORT_Kurtosis_dipy_{4},' num2str(TORT_Kurtosis_dipy.mean_TV)], 'delimiter','','-append');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Kurtosis_ExploreDTI

FA_Kurtosis_E_DTI = '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_ExploreDTI_workingdir/Multishell_ExploreDTI_workflow/_subject_id_{4}/ExploreDTI_kurtosis/Diff_Multishell_{4}_sorted_flipped_FA.nii'
E_DTI_Export_Tract_Volume_Info(FA_Kurtosis_E_DTI ,'{3}/CC_Tracts_{4}.mat','{2}','{3}')
FA_Kurtosis_E_DTI = load('{3}/CC_Tracts_{4}_Diff_Multishell_{4}_sorted_flipped_FA_Vol_Info.mat');
dlmwrite('{3}/Tracts_Others_Stats_{4}.csv', ['FA_Kurtosis_E_DTI_{4},' num2str(FA_Kurtosis_E_DTI.mean_TV)], 'delimiter','','-append');


MD_Kurtosis_E_DTI = '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_ExploreDTI_workingdir/Multishell_ExploreDTI_workflow/_subject_id_{4}/ExploreDTI_kurtosis/Diff_Multishell_{4}_sorted_flipped_MD.nii'
E_DTI_Export_Tract_Volume_Info(MD_Kurtosis_E_DTI ,'{3}/CC_Tracts_{4}.mat','{2}','{3}')
MD_Kurtosis_E_DTI = load('{3}/CC_Tracts_{4}_Diff_Multishell_{4}_sorted_flipped_MD_Vol_Info.mat');
dlmwrite('{3}/Tracts_Others_Stats_{4}.csv', ['MD_Kurtosis_E_DTI_{4},' num2str(MD_Kurtosis_E_DTI.mean_TV)], 'delimiter','','-append');

AD_Kurtosis_E_DTI = '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_ExploreDTI_workingdir/Multishell_ExploreDTI_workflow/_subject_id_{4}/ExploreDTI_kurtosis/Diff_Multishell_{4}_sorted_flipped_L1.nii'
E_DTI_Export_Tract_Volume_Info(AD_Kurtosis_E_DTI ,'{3}/CC_Tracts_{4}.mat','{2}','{3}')
AD_Kurtosis_E_DTI = load('{3}/CC_Tracts_{4}_Diff_Multishell_{4}_sorted_flipped_L1_Vol_Info.mat');
dlmwrite('{3}/Tracts_Others_Stats_{4}.csv', ['AD_Kurtosis_E_DTI_{4},' num2str(AD_Kurtosis_E_DTI.mean_TV)], 'delimiter','','-append');


RD_Kurtosis_E_DTI = '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_ExploreDTI_workingdir/Multishell_ExploreDTI_workflow/_subject_id_{4}/ExploreDTI_kurtosis/Diff_Multishell_{4}_sorted_flipped_RD.nii'
E_DTI_Export_Tract_Volume_Info(RD_Kurtosis_E_DTI ,'{3}/CC_Tracts_{4}.mat','{2}','{3}')
RD_Kurtosis_E_DTI = load('{3}/CC_Tracts_{4}_Diff_Multishell_{4}_sorted_flipped_RD_Vol_Info.mat');
dlmwrite('{3}/Tracts_Others_Stats_{4}.csv', ['RD_Kurtosis_E_DTI_{4},' num2str(RD_Kurtosis_E_DTI.mean_TV)], 'delimiter','','-append');


AK_Kurtosis_E_DTI = '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_ExploreDTI_workingdir/Multishell_ExploreDTI_workflow/_subject_id_{4}/ExploreDTI_kurtosis/Diff_Multishell_{4}_sorted_flipped_AK.nii'
E_DTI_Export_Tract_Volume_Info(AK_Kurtosis_E_DTI ,'{3}/CC_Tracts_{4}.mat','{2}','{3}')
AK_Kurtosis_E_DTI = load('{3}/CC_Tracts_{4}_Diff_Multishell_{4}_sorted_flipped_AK_Vol_Info.mat');
dlmwrite('{3}/Tracts_Others_Stats_{4}.csv', ['AK_Kurtosis_E_DTI_{4},' num2str(AK_Kurtosis_E_DTI.mean_TV)], 'delimiter','','-append');


AWF_Kurtosis_E_DTI = '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_ExploreDTI_workingdir/Multishell_ExploreDTI_workflow/_subject_id_{4}/ExploreDTI_kurtosis/Diff_Multishell_{4}_sorted_flipped_AWF.nii'
E_DTI_Export_Tract_Volume_Info(AWF_Kurtosis_E_DTI ,'{3}/CC_Tracts_{4}.mat','{2}','{3}')
AWF_Kurtosis_E_DTI = load('{3}/CC_Tracts_{4}_Diff_Multishell_{4}_sorted_flipped_AWF_Vol_Info.mat');
dlmwrite('{3}/Tracts_Others_Stats_{4}.csv', ['AWF_Kurtosis_E_DTI_{4},' num2str(AWF_Kurtosis_E_DTI.mean_TV)], 'delimiter','','-append');


KA_Kurtosis_E_DTI = '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_ExploreDTI_workingdir/Multishell_ExploreDTI_workflow/_subject_id_{4}/ExploreDTI_kurtosis/Diff_Multishell_{4}_sorted_flipped_KA.nii'
E_DTI_Export_Tract_Volume_Info(KA_Kurtosis_E_DTI ,'{3}/CC_Tracts_{4}.mat','{2}','{3}')
KA_Kurtosis_E_DTI = load('{3}/CC_Tracts_{4}_Diff_Multishell_{4}_sorted_flipped_KA_Vol_Info.mat');
dlmwrite('{3}/Tracts_Others_Stats_{4}.csv', ['KA_Kurtosis_E_DTI_{4},' num2str(KA_Kurtosis_E_DTI.mean_TV)], 'delimiter','','-append');


MK_Kurtosis_E_DTI = '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_ExploreDTI_workingdir/Multishell_ExploreDTI_workflow/_subject_id_{4}/ExploreDTI_kurtosis/Diff_Multishell_{4}_sorted_flipped_MK.nii'
E_DTI_Export_Tract_Volume_Info(MK_Kurtosis_E_DTI ,'{3}/CC_Tracts_{4}.mat','{2}','{3}')
MK_Kurtosis_E_DTI = load('{3}/CC_Tracts_{4}_Diff_Multishell_{4}_sorted_flipped_MK_Vol_Info.mat');
dlmwrite('{3}/Tracts_Others_Stats_{4}.csv', ['MK_Kurtosis_E_DTI_{4},' num2str(MK_Kurtosis_E_DTI.mean_TV)], 'delimiter','','-append');


RK_Kurtosis_E_DTI = '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_ExploreDTI_workingdir/Multishell_ExploreDTI_workflow/_subject_id_{4}/ExploreDTI_kurtosis/Diff_Multishell_{4}_sorted_flipped_RK.nii'
E_DTI_Export_Tract_Volume_Info(RK_Kurtosis_E_DTI ,'{3}/CC_Tracts_{4}.mat','{2}','{3}')
RK_Kurtosis_E_DTI = load('{3}/CC_Tracts_{4}_Diff_Multishell_{4}_sorted_flipped_RK_Vol_Info.mat');
dlmwrite('{3}/Tracts_Others_Stats_{4}.csv', ['RK_Kurtosis_E_DTI_{4},' num2str(RK_Kurtosis_E_DTI.mean_TV)], 'delimiter','','-append');


TORT_Kurtosis_E_DTI = '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_ExploreDTI_workingdir/Multishell_ExploreDTI_workflow/_subject_id_{4}/ExploreDTI_kurtosis/Diff_Multishell_{4}_sorted_flipped_TORT.nii'
E_DTI_Export_Tract_Volume_Info(TORT_Kurtosis_E_DTI ,'{3}/CC_Tracts_{4}.mat','{2}','{3}')
TORT_Kurtosis_E_DTI = load('{3}/CC_Tracts_{4}_Diff_Multishell_{4}_sorted_flipped_TORT_Vol_Info.mat');
dlmwrite('{3}/Tracts_Others_Stats_{4}.csv', ['TORT_Kurtosis_E_DTI_{4},' num2str(TORT_Kurtosis_E_DTI.mean_TV)], 'delimiter','','-append');





  """.format(cwd_masks, tracts, mat, cwd, subj_no) #Ihave no idea why '' solved the problem of writing to different dir, but it did
    
    res = matlab.run()

    cc_tracts = os.path.abspath('CC_Tracts_{0}.mat'.format(subj_no))



    return  cc_tracts #You always need return






ExploreDTI_calculate_tracts_from_masks = Node(name = 'ExploreDTI_calculate_tracts_from_masks',
                  interface = Function(input_names = ['cwd_masks', 'tracts', 'mat'],
                  					   output_names = ['cc_tracts'],
                  function = ExploreDTI_calculate_tracts_from_masks))



#-----------------------------------------------------------------------------------------------------
# In[x]





Multishell_ExploreDTI_workflow.connect ([

      (infosource, selectfiles,[('subject_id','subject_id')]),
      (selectfiles, decompress, [('DWI_eddy_corrected','in_file')]),

	  (decompress, ExploreDTI_sort, [('out_file','eddy_file')]),

	  (ExploreDTI_sort, ExploreDTI_mat, [('sorted_nii','sorted_nii'),('sorted_txt','sorted_txt')]),

	  (ExploreDTI_mat, ExploreDTI_kurtosis, [('flipped_mat','flipped_mat')]),

	  (ExploreDTI_mat, ExploreDTI_tractography, [('flipped_mat','flipped_mat')]),

      (ExploreDTI_kurtosis, FA_to_Study_Temp, [('fa','moving_image')]),



      (FA_to_Study_Temp, antsApply_AK_Study, [('composite_transform','transforms')]),
      (ExploreDTI_kurtosis, antsApply_AK_Study, [('ak','input_image')]),

      (FA_to_Study_Temp, antsApply_AWF_Study, [('composite_transform','transforms')]),
      (ExploreDTI_kurtosis, antsApply_AWF_Study, [('awf','input_image')]),

      (FA_to_Study_Temp, antsApply_KA_Study, [('composite_transform','transforms')]),
      (ExploreDTI_kurtosis, antsApply_KA_Study, [('ka','input_image')]),

      (FA_to_Study_Temp, antsApply_AD_Study, [('composite_transform','transforms')]),
      (ExploreDTI_kurtosis, antsApply_AD_Study, [('ad','input_image')]),

      (FA_to_Study_Temp, antsApply_MD_Study, [('composite_transform','transforms')]),
      (ExploreDTI_kurtosis, antsApply_MD_Study, [('md','input_image')]),

      (FA_to_Study_Temp, antsApply_MK_Study, [('composite_transform','transforms')]),
      (ExploreDTI_kurtosis, antsApply_MK_Study, [('mk','input_image')]),

      (FA_to_Study_Temp, antsApply_RD_Study, [('composite_transform','transforms')]),
      (ExploreDTI_kurtosis, antsApply_RD_Study, [('rd','input_image')]),

      (FA_to_Study_Temp, antsApply_RK_Study, [('composite_transform','transforms')]),
      (ExploreDTI_kurtosis, antsApply_RK_Study, [('rk','input_image')]),

      (FA_to_Study_Temp, antsApply_TORT_Study, [('composite_transform','transforms')]),
      (ExploreDTI_kurtosis, antsApply_TORT_Study, [('tort','input_image')]),

	  

      (FA_to_Study_Temp, transform_cc_AND_mask, [('inverse_composite_transform','transforms')]),
	  (ExploreDTI_kurtosis, transform_cc_AND_mask, [('fa','reference_image')]),

	  (FA_to_Study_Temp, transform_cc_NOT_mask, [('inverse_composite_transform','transforms')]),
	  (ExploreDTI_kurtosis, transform_cc_NOT_mask, [('fa','reference_image')]),


	  (transform_cc_AND_mask, copy_masks_to_same_folder, [('output_image','AND_mask')]),
	  (transform_cc_NOT_mask, copy_masks_to_same_folder, [('output_image','NOT_mask')]),


	  (copy_masks_to_same_folder, ExploreDTI_calculate_tracts_from_masks, [('cwd_masks','cwd_masks')]),
	  (ExploreDTI_tractography, ExploreDTI_calculate_tracts_from_masks, [('tracts','tracts')]),
	  (ExploreDTI_mat, ExploreDTI_calculate_tracts_from_masks, [('flipped_mat','mat')]),


  ])


Multishell_ExploreDTI_workflow.write_graph(graph2use='flat')
Multishell_ExploreDTI_workflow.run('MultiProc', plugin_args={'n_procs': 8})

















