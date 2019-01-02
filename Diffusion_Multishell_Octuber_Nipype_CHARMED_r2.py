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
# In[2]:

experiment_dir = '/media/amr/Amr_4TB/Work/October_Acquistion/' 

subject_list = ['229', '230', '232', '233', 
                '234', '235', '237', '242', 
                '243', '244', '245', '252', 
                '253', '255', '261', '262', 
                '263', '264', '273', '274', 
                '281', '282', '286', '287', 
                '362', '363', '364', '365', 
                '366']

# subject_list = ['252']
                
# subject_list = ['230']


output_dir  = 'Diffusion_Multishell_CHARMED_output'
working_dir = 'Diffusion_Multishell_CHARMED_workingdir'

Multishell_CHARMED_workflow = Workflow (name = 'Multishell_CHARMED_workflow')
Multishell_CHARMED_workflow.base_dir = opj(experiment_dir, working_dir)

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

 'Mask' : 'Data/{subject_id}/Diff_Mask_{subject_id}.nii',
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
bval = '/media/amr/HDD/Work/October_Acquistion/bval_multishell'
bvec = '/media/amr/HDD/Work/October_Acquistion/bvec_multishell'
index = '/media/amr/HDD/Work/October_Acquistion/index_multishell'
acqparams = '/media/amr/HDD/Work/October_Acquistion/acqparams.txt' 
Wax_FA_Template = '/media/amr/HDD/Work/standard/FMRIB58_FA_2mm.nii.gz'
Study_Template = '/media/amr/HDD/Work/October_Acquistion/FA_Template_Cluster.nii.gz'

#-----------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------
# In[7]
#You need the output to be nifti, otherwise NODDI cannot read it
#Eddy was run already in kurtosis pipeline, so I will just pass it from there directly to decompress
# eddy = Node (fsl.Eddy(), name = 'eddy')
# eddy.inputs.in_acqp  = acqparams
# eddy.inputs.in_bval  = bval
# eddy.inputs.in_bvec  = bvec
# eddy.inputs.in_index = index
# eddy.inputs.use_cuda = True
# eddy.inputs.is_shelled = True
# eddy.inputs.num_threads = 8
# eddy.inputs.niter = 2


# eddy.inputs.output_type = 'NIFTI' #This will be passed to NODDI and charmed #creates an error, do not use this field

#-----------------------------------------------------------------------------------------------------
#mdt toolbox needs no decompression

# decompress = Node(fsl.ChangeDataType(), name = 'decompress')
# decompress.inputs.output_datatype = 'float'
# decompress.inputs.output_type = 'NIFTI'


#-----------------------------------------------------------------------------------------------------

def CHARMED(dwi, mask):
    import mdt 
    import os
    import nibabel as nib
    from mdt.configuration import SetGeneralOptimizer;

    protocol = '/media/amr/HDD/Work/October_Acquistion/MDT_multishell_protocol.prtcl'
    model = 'CHARMED_r2 (Cascade|fixed)'
    algorithm = 'Levenberg-Marquardt'
    patience = 100
    output_folder = os.getcwd()

    input_data = mdt.load_input_data(
    	    dwi,
    	    protocol,
    	    mask,
    	    noise_std=5,
    	    gradient_deviations=None,
    	    extra_protocol={})

    with mdt.config_context(SetGeneralOptimizer(algorithm, settings={'patience': patience})):
            mdt.fit_model(
            model,
            input_data,
            output_folder,
            recalculate=True,
            only_recalculate_last=True,
            double_precision=False,
            cl_device_ind=[0])

    os.chdir('CHARMED_r2')

    CHARMED_FA = os.path.abspath('Tensor.FA.nii.gz')
    CHARMED_MD = os.path.abspath('Tensor.MD.nii.gz')
    CHARMED_AD = os.path.abspath('Tensor.AD.nii.gz')
    CHARMED_RD = os.path.abspath('Tensor.RD.nii.gz')

    CHARMED_FR = os.path.abspath('FR.nii.gz')

    #I assumed that CHARMEDRestricted0.d to be the intra-axonal diffusvity
    CHARMED_IAD = os.path.abspath('CHARMEDRestricted0.d.nii.gz')

    return CHARMED_FA, CHARMED_MD, CHARMED_AD, CHARMED_RD, CHARMED_FR, CHARMED_IAD  



CHARMED = Node(name = 'CHARMED_r2',
                  interface = Function(input_names = ['dwi','mask'],
                  					   output_names = ['CHARMED_FA', 'CHARMED_MD', 'CHARMED_AD', 'CHARMED_RD', 'CHARMED_FR', 'CHARMED_IAD'],
                  function = CHARMED))


    
    
#-----------------------------------------------------------------------------------------------------
# In[9]: Transform maps to waxholm Template

#>>>>>>>>>>>>>>>>>>>>>>>>>FA
FA_to_WAX_Temp = Node(ants.Registration(), name = 'FA_To_WAX_Template')
FA_to_WAX_Temp.inputs.args='--float'
FA_to_WAX_Temp.inputs.collapse_output_transforms=True
FA_to_WAX_Temp.inputs.initial_moving_transform_com=True
FA_to_WAX_Temp.inputs.fixed_image= Wax_FA_Template
FA_to_WAX_Temp.inputs.num_threads=8
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


#>>>>>>>>>>>>>>>>>>>>>>>>>MD
antsApplyMD_WAX = Node(ants.ApplyTransforms(), name = 'antsApplyMD_WAX')
antsApplyMD_WAX.inputs.dimension = 3
antsApplyMD_WAX.inputs.input_image_type = 3
antsApplyMD_WAX.inputs.num_threads = 1
antsApplyMD_WAX.inputs.float = True
antsApplyMD_WAX.inputs.output_image = 'MD_{subject_id}.nii'
antsApplyMD_WAX.inputs.reference_image = Wax_FA_Template

#>>>>>>>>>>>>>>>>>>>>>>>>>AD
antsApplyAD_WAX = antsApplyMD_WAX.clone(name = 'antsApplyAD_WAX')
antsApplyAD_WAX.inputs.output_image = 'AD_{subject_id}.nii'


#>>>>>>>>>>>>>>>>>>>>>>>>>RD
antsApplyRD_WAX = antsApplyMD_WAX.clone(name = 'antsApplyRD_WAX')
antsApplyRD_WAX.inputs.output_image = 'RD_{subject_id}.nii'

#>>>>>>>>>>>>>>>>>>>>>>>>>FR
antsApplyFR_WAX = antsApplyMD_WAX.clone(name = 'antsApplyFR_WAX')
antsApplyFR_WAX.inputs.output_image = 'FR_{subject_id}.nii'

#>>>>>>>>>>>>>>>>>>>>>>>>>IAD
antsApplyIAD_WAX = antsApplyMD_WAX.clone(name = 'antsApplyIAD_WAX')
antsApplyIAD_WAX.inputs.output_image = 'IAD_{subject_id}.nii'

#---------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------

# In[10]: Transform maps to Study-based Template

#>>>>>>>>>>>>>>>>>>>>>>>>>FA
FA_to_Study_Temp = Node(ants.Registration(), name = 'FA_To_Study_Template')
FA_to_Study_Temp.inputs.args='--float'
FA_to_Study_Temp.inputs.collapse_output_transforms=True
FA_to_Study_Temp.inputs.initial_moving_transform_com=True
FA_to_Study_Temp.inputs.fixed_image= Study_Template
FA_to_Study_Temp.inputs.num_threads=2

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


#>>>>>>>>>>>>>>>>>>>>>>>>>MD
antsApplyMD_Study = Node(ants.ApplyTransforms(), name = 'antsApplyMD_Study')
antsApplyMD_Study.inputs.dimension = 3
antsApplyMD_Study.inputs.input_image_type = 3
antsApplyMD_Study.inputs.num_threads = 1
antsApplyMD_Study.inputs.float = True
antsApplyMD_Study.inputs.output_image = 'MD_{subject_id}.nii'
antsApplyMD_Study.inputs.reference_image = Study_Template

#>>>>>>>>>>>>>>>>>>>>>>>>>AD
antsApplyAD_Study = antsApplyMD_Study.clone(name = 'antsApplyAD_Study')
antsApplyAD_Study.inputs.output_image = 'AD_{subject_id}.nii'


#>>>>>>>>>>>>>>>>>>>>>>>>>RD
antsApplyRD_Study = antsApplyMD_Study.clone(name = 'antsApplyRD_Study')
antsApplyRD_Study.inputs.output_image = 'RD_{subject_id}.nii'

#>>>>>>>>>>>>>>>>>>>>>>>>>FR
antsApplyFR_Study = antsApplyMD_Study.clone(name = 'antsApplyFR_Study')
antsApplyFR_Study.inputs.output_image = 'FR_{subject_id}.nii'

#>>>>>>>>>>>>>>>>>>>>>>>>>IAD
antsApplyIAD_Study = antsApplyMD_Study.clone(name = 'antsApplyIAD_Study')
antsApplyIAD_Study.inputs.output_image = 'IAD_{subject_id}.nii'

#------------------------------------------------------------------------------------------------


Multishell_CHARMED_workflow.connect ([

      (infosource, selectfiles,[('subject_id','subject_id')]),

      # (selectfiles, eddy, [('Mask','in_mask')]),
      # (selectfiles, eddy, [('DWI','in_file')]),

      # (selectfiles, decompress, [('DWI_eddy_corrected','in_file')]),
      
      # (decompress, CHARMED, [('out_file','dwi')]),
      (selectfiles, CHARMED, [('DWI_eddy_corrected','dwi')]),
	    (selectfiles, CHARMED, [('Mask','mask')]),

#-----------------------------------------------------------------------------------------------

      (CHARMED, FA_to_WAX_Temp, [('CHARMED_FA','moving_image')]),

      (CHARMED, antsApplyMD_WAX, [('CHARMED_MD','input_image')]),
      (FA_to_WAX_Temp, antsApplyMD_WAX, [('composite_transform','transforms')]),


      (CHARMED, antsApplyAD_WAX, [('CHARMED_AD','input_image')]),
      (FA_to_WAX_Temp, antsApplyAD_WAX,[('composite_transform','transforms')]),


      (CHARMED, antsApplyRD_WAX, [('CHARMED_RD','input_image')]),
      (FA_to_WAX_Temp, antsApplyRD_WAX,[('composite_transform','transforms')]),

      (CHARMED, antsApplyFR_WAX, [('CHARMED_FR','input_image')]),
      (FA_to_WAX_Temp, antsApplyFR_WAX,[('composite_transform','transforms')]),


      (CHARMED, antsApplyIAD_WAX, [('CHARMED_IAD','input_image')]),
      (FA_to_WAX_Temp, antsApplyIAD_WAX,[('composite_transform','transforms')]),

#-----------------------------------------------------------------------------------------------

      (CHARMED, FA_to_Study_Temp, [('CHARMED_FA','moving_image')]),

      (CHARMED, antsApplyMD_Study, [('CHARMED_MD','input_image')]),
      (FA_to_Study_Temp, antsApplyMD_Study, [('composite_transform','transforms')]),


      (CHARMED, antsApplyAD_Study, [('CHARMED_AD','input_image')]),
      (FA_to_Study_Temp, antsApplyAD_Study,[('composite_transform','transforms')]),


      (CHARMED, antsApplyRD_Study, [('CHARMED_RD','input_image')]),
      (FA_to_Study_Temp, antsApplyRD_Study,[('composite_transform','transforms')]),

      (CHARMED, antsApplyFR_Study, [('CHARMED_FR','input_image')]),
      (FA_to_Study_Temp, antsApplyFR_Study,[('composite_transform','transforms')]),

      (CHARMED, antsApplyIAD_Study, [('CHARMED_IAD','input_image')]),
      (FA_to_Study_Temp, antsApplyIAD_Study,[('composite_transform','transforms')]),

#-----------------------------------------------------------------------------------------------

  ])


Multishell_CHARMED_workflow.write_graph(graph2use='flat')
Multishell_CHARMED_workflow.run('MultiProc', plugin_args={'n_procs': 8})











