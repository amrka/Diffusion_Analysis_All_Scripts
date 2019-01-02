#-----------------------------------------------------------------------------------------------------
# In[2]:
#This is an alternative script to process diffusion data
#The key concept here from Diffusion_20_Octuber_Nipype is to register B0 to anatomical image
#Then use the transformation from resting state preprocessing to transfer the images to anatomical images
#The registration with FA_template was horrible
#This script was done after restripping the skull to remove extra parts of the skull
#The overlap with the VBM template is quite good, yet not so satifactory
#So, here I am trying with the WAX FA template downsized to 2mm
from nipype import config
cfg = dict(execution={'remove_unnecessary_outputs': False})
config.update_config(cfg)


import nipype.interfaces.fsl as fsl
import nipype.interfaces.afni as afni
import nipype.interfaces.ants as ants
import nipype.interfaces.spm as spm
import nipype.interfaces.utility as utility
from nipype.interfaces.utility import IdentityInterface, Function
from os.path import join as opj
from nipype.interfaces.io import SelectFiles, DataSink
from nipype.pipeline.engine import Workflow, Node, MapNode

import numpy as np
import matplotlib.pyplot as plt



#-----------------------------------------------------------------------------------------------------
# In[2]:

experiment_dir = '/home/in/aeed/Work/October_Acquistion/' 

subject_list = ['229', '230', '232', '233', 
                '234', '235', '237', '242', 
                '243', '244', '245', '252', 
                '253', '255', '261', '262', 
                '263', '264', '273', '274', 
                '281', '282', '286', '287', 
                '362', '363', '364', '365', 
                '366']



output_dir  = 'Diffusion_20_outdir'
working_dir = 'Diffusion_20_workingdir'

DTI_workflow = Workflow (name = 'DTI_workflow')
DTI_workflow.base_dir = opj(experiment_dir, working_dir)

#-----------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------
# In[3]:


# Infosource - a function free node to iterate over the list of subject names
infosource = Node(IdentityInterface(fields=['subject_id']),
                  name="infosource")
infosource.iterables = [('subject_id', subject_list)]

#-----------------------------------------------------------------------------------------------------
# In[4]:

templates = {
             'DWI'       : 'Data/{subject_id}/Diff_20_{subject_id}_bet.nii',
             'Mask'      : 'Data/{subject_id}/Diff_Mask_{subject_id}.nii',
 }


selectfiles = Node(SelectFiles(templates,
                               base_directory=experiment_dir),
                   name="selectfiles")
#-----------------------------------------------------------------------------------------------------
# In[5]:

datasink = Node(DataSink(), name = 'datasink')
datasink.inputs.container = output_dir
datasink.inputs.base_directory = experiment_dir

substitutions = [('_subject_id_', '')]

datasink.inputs.substitutions = substitutions



#-----------------------------------------------------------------------------------------------------
# In[6]:
bval =  '/home/in/aeed/Work/October_Acquistion/bval_20'
bvec =  '/home/in/aeed/Work/October_Acquistion/bvec_20'
acqparams = '/home/in/aeed/Work/October_Acquistion/acqparams.txt'  
index =  '/home/in/aeed/Work/October_Acquistion/index_20.txt'

VBM_DTI_Template = '/home/in/aeed/Work/October_Acquistion/VBM_DTI.nii.gz'
Wax_FA_Template = '/home/in/aeed/Work/October_Acquistion/FMRIB58_FA_2mm.nii.gz'
Study_Template = '/home/in/aeed/Work/October_Acquistion/FA_Template_Cluster.nii.gz'
#-----------------------------------------------------------------------------------------------------
# In[7]:
#Eddy Current correction using the new function Eddy instead of Eddy_correct

eddy = Node (fsl.Eddy(), name = 'eddy')
eddy.inputs.in_acqp  = acqparams
eddy.inputs.in_bval  = bval
eddy.inputs.in_bvec  = bvec
eddy.inputs.in_index = index
eddy.inputs.niter = 10
#-----------------------------------------------------------------------------------------------------
# In[7]:
#Fit the tensor

fit_tensor = Node (fsl.DTIFit(), name = 'fit_tensor')
fit_tensor.inputs.bvals = '/home/in/aeed/Work/October_Acquistion/bval_20'
fit_tensor.inputs.bvecs = '/home/in/aeed/Work/October_Acquistion/bvec_20'
fit_tensor.inputs.save_tensor = True
# fit_tensor.inputs.wls = True #Fit the tensor with wighted least squares, try this one
#-----------------------------------------------------------------------------------------------------
# In[7]:
#Get the radial diffusivity by taking the first, the sum of L2 and L3

l2_l3_sum = Node(fsl.BinaryMaths(), name = 'l2_l3_sum')
l2_l3_sum.inputs.operation = 'add'

#-----------------------------------------------------------------------------------------------------
# In[7]:
#Now the average

RD = Node (fsl.BinaryMaths(), name = 'RD')
RD.inputs.operand_value = 2
RD.inputs.operation = 'div'

#-----------------------------------------------------------------------------------------------------
# Register to Study Waxholm template first, just to have both for purposes of comparison
#I am not comining both transformations, just I want to have them both to compare

#>>>>>>>>>>>>>>>>>>>>>>>>>>>FA

FA_to_WAX_Temp = Node(ants.Registration(), name = 'FA_To_WAX_Template')
FA_to_WAX_Temp.inputs.args='--float'
FA_to_WAX_Temp.inputs.collapse_output_transforms=True
FA_to_WAX_Temp.inputs.initial_moving_transform_com=True
FA_to_WAX_Temp.inputs.fixed_image= Wax_FA_Template
FA_to_WAX_Temp.inputs.num_threads=10
FA_to_WAX_Temp.inputs.output_inverse_warped_image=True
FA_to_WAX_Temp.inputs.output_warped_image=True
FA_to_WAX_Temp.inputs.sigma_units=['vox']*3
FA_to_WAX_Temp.inputs.transforms= ['Rigid', 'Affine', 'SyN']
# FA_to_WAX_Temp.inputs.terminal_output='file' #returns an error
FA_to_WAX_Temp.inputs.winsorize_lower_quantile=0.005
FA_to_WAX_Temp.inputs.winsorize_upper_quantile=0.995
FA_to_WAX_Temp.inputs.convergence_threshold=[1e-6]
FA_to_WAX_Temp.inputs.convergence_window_size=[10]
FA_to_WAX_Temp.inputs.metric=['MI', 'MI', 'CC']
FA_to_WAX_Temp.inputs.metric_weight=[1.0]*3
FA_to_WAX_Temp.inputs.number_of_iterations=[[1000, 500, 250, 100],
                                                 [1000, 500, 250, 100],
                                                 [100, 70, 50, 20]]
FA_to_WAX_Temp.inputs.radius_or_number_of_bins=[32, 32, 4]
FA_to_WAX_Temp.inputs.sampling_percentage=[0.25, 0.25, 1]
FA_to_WAX_Temp.inputs.sampling_strategy=['Regular',
                                              'Regular',
                                              'None']
FA_to_WAX_Temp.inputs.shrink_factors=[[8, 4, 2, 1]]*3
FA_to_WAX_Temp.inputs.smoothing_sigmas=[[3, 2, 1, 0]]*3
FA_to_WAX_Temp.inputs.transform_parameters=[(0.1,),
                                                 (0.1,),
                                                 (0.1, 3.0, 0.0)]
FA_to_WAX_Temp.inputs.use_histogram_matching=True
FA_to_WAX_Temp.inputs.write_composite_transform=True
FA_to_WAX_Temp.inputs.verbose=True
FA_to_WAX_Temp.inputs.output_warped_image=True
FA_to_WAX_Temp.inputs.float=True

#>>>>>>>>>>>>>>>>>>>>>>>>>>>MD

antsApplyMD_WAX = Node(ants.ApplyTransforms(), name = 'antsApplyMD_WAX')
antsApplyMD_WAX.inputs.dimension = 3
antsApplyMD_WAX.inputs.input_image_type = 3
antsApplyMD_WAX.inputs.num_threads = 1
antsApplyMD_WAX.inputs.float = True
antsApplyMD_WAX.inputs.output_image = 'MD_{subject_id}.nii'
antsApplyMD_WAX.inputs.reference_image = Wax_FA_Template

#>>>>>>>>>>>>>>>>>>>>>>>>>>>AD

antsApplyAD_WAX = antsApplyMD_WAX.clone(name = 'antsApplyAD_WAX')
antsApplyAD_WAX.inputs.output_image = 'AD_{subject_id}.nii'

#>>>>>>>>>>>>>>>>>>>>>>>>>>>RD

antsApplyRD_WAX = antsApplyMD_WAX.clone(name = 'antsApplyRD_WAX')
antsApplyRD_WAX.inputs.output_image = 'RD_{subject_id}.nii'


#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
# Register to Study template second, just to have both for purposes of comparison

#>>>>>>>>>>>>>>>>>>>>>>>>>>>FA
FA_to_Study_Temp = Node(ants.Registration(), name = 'FA_To_Study_Template')
FA_to_Study_Temp.inputs.args='--float'
FA_to_Study_Temp.inputs.collapse_output_transforms=True
FA_to_Study_Temp.inputs.initial_moving_transform_com=True
FA_to_Study_Temp.inputs.fixed_image= Study_Template
FA_to_Study_Temp.inputs.num_threads=10
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


#>>>>>>>>>>>>>>>>>>>>>>>>>>>MD
antsApplyMD_Study = Node(ants.ApplyTransforms(), name = 'antsApplyMD_Study')
antsApplyMD_Study.inputs.dimension = 3
antsApplyMD_Study.inputs.input_image_type = 3
antsApplyMD_Study.inputs.num_threads = 1
antsApplyMD_Study.inputs.float = True
antsApplyMD_Study.inputs.output_image = 'MD_{subject_id}.nii'
antsApplyMD_Study.inputs.reference_image = Study_Template


#>>>>>>>>>>>>>>>>>>>>>>>>>>>AD
antsApplyAD_Study = antsApplyMD_Study.clone(name = 'antsApplyAD_Study')
antsApplyAD_Study.inputs.output_image = 'AD_{subject_id}.nii'


#>>>>>>>>>>>>>>>>>>>>>>>>>>>RD
antsApplyRD_Study = antsApplyMD_Study.clone(name = 'antsApplyRD_Study')
antsApplyRD_Study.inputs.output_image = 'RD_{subject_id}.nii'


#-----------------------------------------------------------------------------------------------------
# In[7]:
DTI_workflow.connect ([

      (infosource, selectfiles,[('subject_id','subject_id')]),
      (selectfiles, eddy, [('DWI','in_file')]),
      (selectfiles, eddy, [('Mask','in_mask')]),


      (selectfiles, fit_tensor, [('Mask','mask')]),
      (eddy, fit_tensor, [('out_corrected','dwi')]),
      (fit_tensor, l2_l3_sum, [('L2','in_file')]),
      (fit_tensor, l2_l3_sum, [('L3','operand_file')]),
      (l2_l3_sum, RD, [('out_file','in_file')]),


#----------------------------------------------------------------------------------------------------
      (fit_tensor, FA_to_WAX_Temp, [('FA','moving_image')]),

      (fit_tensor, antsApplyMD_WAX, [('MD','input_image')]),
      (FA_to_WAX_Temp, antsApplyMD_WAX, [('composite_transform','transforms')]),


      (fit_tensor, antsApplyAD_WAX, [('L1','input_image')]),
      (FA_to_WAX_Temp, antsApplyAD_WAX,[('composite_transform','transforms')]),


      (RD, antsApplyRD_WAX, [('out_file','input_image')]),
      (FA_to_WAX_Temp, antsApplyRD_WAX,[('composite_transform','transforms')]),

#----------------------------------------------------------------------------------------------------
      (fit_tensor, FA_to_Study_Temp, [('FA','moving_image')]),

      (fit_tensor, antsApplyMD_Study, [('MD','input_image')]),
      (FA_to_Study_Temp, antsApplyMD_Study, [('composite_transform','transforms')]),


      (fit_tensor, antsApplyAD_Study, [('L1','input_image')]),
      (FA_to_Study_Temp, antsApplyAD_Study,[('composite_transform','transforms')]),


      (RD, antsApplyRD_Study, [('out_file','input_image')]),
      (FA_to_Study_Temp, antsApplyRD_Study,[('composite_transform','transforms')]),





  ])


DTI_workflow.write_graph(graph2use='flat')
DTI_workflow.run(plugin='SLURMGraph', plugin_args = {'dont_resubmit_completed_jobs':True})
