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

# subject_list = ['229', '230', '365', '274']
                
# subject_list = ['232']


output_dir  = 'Diffusion_Multishell_NODDI_output'
working_dir = 'Diffusion_Multishell_NODDI_workingdir'

Multishell_NODDI_workflow = Workflow (name = 'Multishell_NODDI_workflow')
Multishell_NODDI_workflow.base_dir = opj(experiment_dir, working_dir)

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
protocol = '/media/amr/HDD/Work/October_Acquistion/MDT_multishell_protocol.prtcl'
Wax_FA_Template = '/media/amr/HDD/Work/standard/FMRIB58_FA_2mm.nii.gz'
ODI_Study_Template = '/media/amr/HDD/Work/October_Acquistion/ODI_Template_Cluster.nii.gz'

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

decompress = Node(fsl.ChangeDataType(), name = 'decompress')
decompress.inputs.output_datatype = 'float'
decompress.inputs.output_type = 'NIFTI'


#-----------------------------------------------------------------------------------------------------

def NODDI(brain_nii, brain_mask_nii):
		import os
		import nipype.interfaces.matlab as Matlab
		matlab = Matlab.MatlabCommand()
		
		bval = '/media/amr/HDD/Work/October_Acquistion/bval_multishell'
		bvec = '/media/amr/HDD/Work/October_Acquistion/bvec_multishell'
		brain_mat_name = 'NODDI_brain.mat'
		prefix = 'NODDI'


		# below is where you add paths that matlab might require, this is equivalent to addpath()
		matlab.inputs.paths = ['/home/amr/SCRIPTS/']
		matlab.inputs.single_comp_thread = False
		import os
		matlab.inputs.script = """
		

		bval = '/media/amr/HDD/Work/October_Acquistion/bval_multishell'
		bvec = '/media/amr/HDD/Work/October_Acquistion/bvec_multishell'
		brain_mat_name = 'NODDI_brain.mat'
		prefix = 'NODDI'
		


		CreateROI('%s', '%s', brain_mat_name);

		protocol = FSL2Protocol('%s', '%s');

		noddi = MakeModel('WatsonSHStickTortIsoV_B0');


		batch_fitting_single(brain_mat_name, protocol, noddi, 'FittedParams.mat');

		SaveParamsAsNIfTI('FittedParams.mat', brain_mat_name, '%s', prefix)

		"""%(brain_nii, brain_mask_nii, bval, bvec, brain_mask_nii )

		res = matlab.run()

		odi = os.path.abspath('NODDI_odi.nii')
		ficvf = os.path.abspath('NODDI_ficvf.nii')

		return odi, ficvf



NODDI = Node(name = 'NODDI',
                  interface = Function(input_names = ['brain_nii', 'brain_mask_nii'],
                  					   output_names = ['odi', 'ficvf'],
                  function = NODDI))

#-----------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------
# In[9]: Transform maps to waxholm Template
#I am going also to use the transformations from Kurtosis pipeline
#Update, it did not work, Now, I am going to register directly to Waxholm and study based ODI template
#>>>>>>>>>>>>>>>>>>>>>>>>>ODI

ODI_to_WAX_Temp = Node(ants.Registration(), name = 'ODI_To_WAX_Template')
ODI_to_WAX_Temp.inputs.args='--float'
ODI_to_WAX_Temp.inputs.collapse_output_transforms=True
ODI_to_WAX_Temp.inputs.initial_moving_transform_com=True
ODI_to_WAX_Temp.inputs.fixed_image= Wax_FA_Template
ODI_to_WAX_Temp.inputs.num_threads=4
ODI_to_WAX_Temp.inputs.output_inverse_warped_image=True
ODI_to_WAX_Temp.inputs.output_warped_image=True
ODI_to_WAX_Temp.inputs.sigma_units=['vox']*3
ODI_to_WAX_Temp.inputs.transforms= ['Rigid', 'Affine', 'SyN']
# ODI_to_WAX_Temp.inputs.terminal_output='file' #returns an error
ODI_to_WAX_Temp.inputs.winsorize_lower_quantile=0.005
ODI_to_WAX_Temp.inputs.winsorize_upper_quantile=0.995
ODI_to_WAX_Temp.inputs.convergence_threshold=[1e-6]
ODI_to_WAX_Temp.inputs.convergence_window_size=[10]
ODI_to_WAX_Temp.inputs.metric=['MI', 'MI', 'CC']
ODI_to_WAX_Temp.inputs.metric_weight=[1.0]*3
ODI_to_WAX_Temp.inputs.number_of_iterations=[[1000, 500, 250, 100],
                                                 [1000, 500, 250, 100],
                                                 [100, 70, 50, 20]]
ODI_to_WAX_Temp.inputs.radius_or_number_of_bins=[32, 32, 4]
ODI_to_WAX_Temp.inputs.sampling_percentage=[0.25, 0.25, 1]
ODI_to_WAX_Temp.inputs.sampling_strategy=['Regular',
                                              'Regular',
                                              'None']
ODI_to_WAX_Temp.inputs.shrink_factors=[[8, 4, 2, 1]]*3
ODI_to_WAX_Temp.inputs.smoothing_sigmas=[[3, 2, 1, 0]]*3
ODI_to_WAX_Temp.inputs.transform_parameters=[(0.1,),
                                                 (0.1,),
                                                 (0.1, 3.0, 0.0)]
ODI_to_WAX_Temp.inputs.use_histogram_matching=True
ODI_to_WAX_Temp.inputs.write_composite_transform=True
ODI_to_WAX_Temp.inputs.verbose=True
ODI_to_WAX_Temp.inputs.output_warped_image=True
ODI_to_WAX_Temp.inputs.float=True


#>>>>>>>>>>>>>>>>>>>>>>>>>FICVF
antsApply_FICVF_WAX = Node(ants.ApplyTransforms(), name = 'antsApply_FICVF_WAX')
antsApply_FICVF_WAX.inputs.dimension = 3
antsApply_FICVF_WAX.inputs.input_image_type = 3
antsApply_FICVF_WAX.inputs.num_threads = 4
antsApply_FICVF_WAX.inputs.float = True
antsApply_FICVF_WAX.inputs.output_image = 'FICVF_{subject_id}.nii'
antsApply_FICVF_WAX.inputs.reference_image = Wax_FA_Template


#---------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------

# In[10]: Transform maps to Study-based Template

#>>>>>>>>>>>>>>>>>>>>>>>>>>>FA
ODI_to_Study_Temp = Node(ants.Registration(), name = 'ODI_To_ODI_Study_Template')
ODI_to_Study_Temp.inputs.args='--float'
ODI_to_Study_Temp.inputs.collapse_output_transforms=True
ODI_to_Study_Temp.inputs.initial_moving_transform_com=True
ODI_to_Study_Temp.inputs.fixed_image= ODI_Study_Template
ODI_to_Study_Temp.inputs.num_threads=1
ODI_to_Study_Temp.inputs.output_inverse_warped_image=True
ODI_to_Study_Temp.inputs.output_warped_image=True
ODI_to_Study_Temp.inputs.sigma_units=['vox']*3
ODI_to_Study_Temp.inputs.transforms= ['Rigid', 'Affine', 'SyN']
# ODI_to_Study_Temp.inputs.terminal_output='file' #returns an error
ODI_to_Study_Temp.inputs.winsorize_lower_quantile=0.005
ODI_to_Study_Temp.inputs.winsorize_upper_quantile=0.995
ODI_to_Study_Temp.inputs.convergence_threshold=[1e-6]
ODI_to_Study_Temp.inputs.convergence_window_size=[10]
ODI_to_Study_Temp.inputs.metric=['MI', 'MI', 'CC']
ODI_to_Study_Temp.inputs.metric_weight=[1.0]*3
ODI_to_Study_Temp.inputs.number_of_iterations=[[1000, 500, 250, 100],
                                                 [1000, 500, 250, 100],
                                                 [100, 70, 50, 20]]
ODI_to_Study_Temp.inputs.radius_or_number_of_bins=[32, 32, 4]
ODI_to_Study_Temp.inputs.sampling_percentage=[0.25, 0.25, 1]
ODI_to_Study_Temp.inputs.sampling_strategy=['Regular',
                                              'Regular',
                                              'None']
ODI_to_Study_Temp.inputs.shrink_factors=[[8, 4, 2, 1]]*3
ODI_to_Study_Temp.inputs.smoothing_sigmas=[[3, 2, 1, 0]]*3
ODI_to_Study_Temp.inputs.transform_parameters=[(0.1,),
                                                 (0.1,),
                                                 (0.1, 3.0, 0.0)]
ODI_to_Study_Temp.inputs.use_histogram_matching=True
ODI_to_Study_Temp.inputs.write_composite_transform=True
ODI_to_Study_Temp.inputs.verbose=True
ODI_to_Study_Temp.inputs.output_warped_image=True
ODI_to_Study_Temp.inputs.float=True


#>>>>>>>>>>>>>>>>>>>>>>>>>>>_FICVF
antsApply_FICVF_Study = Node(ants.ApplyTransforms(), name = 'antsApply_FICVF_Study')
antsApply_FICVF_Study.inputs.dimension = 3
antsApply_FICVF_Study.inputs.input_image_type = 3
antsApply_FICVF_Study.inputs.num_threads = 1
antsApply_FICVF_Study.inputs.float = True
antsApply_FICVF_Study.inputs.output_image = '_FICVF_{subject_id}.nii'
antsApply_FICVF_Study.inputs.reference_image = ODI_Study_Template


#------------------------------------------------------------------------------------------------


Multishell_NODDI_workflow.connect ([

      (infosource, selectfiles,[('subject_id','subject_id')]),

      # (selectfiles, eddy, [('Mask','in_mask')]),
      # (selectfiles, eddy, [('DWI','in_file')]),

      (selectfiles, decompress, [('DWI_eddy_corrected','in_file')]),

      (decompress, NODDI, [('out_file','brain_nii')]),
	    (selectfiles, NODDI, [('Mask','brain_mask_nii')]),

#-----------------------------------------------------------------------------------------------

      (NODDI, ODI_to_WAX_Temp, [('odi','moving_image')]),
	  
      (NODDI, antsApply_FICVF_WAX, [('ficvf','input_image')]),
      (ODI_to_WAX_Temp, antsApply_FICVF_WAX, [('composite_transform','transforms')]),

#-----------------------------------------------------------------------------------------------
      # (NODDI, ODI_to_Study_Temp, [('odi','moving_image')]),
      
      # (NODDI, antsApply_FICVF_Study, [('ficvf','input_image')]),
      # (ODI_to_Study_Temp, antsApply_FICVF_Study, [('composite_transform','transforms')]),


  ])


Multishell_NODDI_workflow.write_graph(graph2use='flat')
Multishell_NODDI_workflow.run('MultiProc', plugin_args={'n_procs': 8})











