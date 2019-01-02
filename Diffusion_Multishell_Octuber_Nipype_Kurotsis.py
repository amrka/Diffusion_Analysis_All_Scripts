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

# subject_list = ['229', '230', '232', '233', 
#                 '234', '235', '237', '242', 
#                 '243', '244', '245', '252', 
#                 '253', '255', '261', '262', 
#                 '263', '264', '273', '274', 
#                 '281', '282', '286', '287', 
#                 '362', '363', '364', '365', 
#                 '366']

# subject_list = ['229', '230', '365', '274']
                
subject_list = ['230', '365']


output_dir  = 'Diffusion_Multishell_output'
working_dir = 'Diffusion_Multishell_workingdir'

Multishell_workflow = Workflow (name = 'Multishell_workflow')
Multishell_workflow.base_dir = opj(experiment_dir, working_dir)

#-----------------------------------------------------------------------------------------------------
# In[3]:


# Infosource - a function free node to iterate over the list of subject names
infosource = Node(IdentityInterface(fields=['subject_id']),
                  name="infosource")
infosource.iterables = [('subject_id', subject_list)]

#-----------------------------------------------------------------------------------------------------
# In[4]:

templates = {

             'DWI'  : 'Data/{subject_id}/Diff_Multishell_{subject_id}.nii',
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
Study_Template = '/media/amr/HDD/Work/October_Acquistion/FA_Template_Cluster.nii.gz'

#-----------------------------------------------------------------------------------------------------
# In[7]
#You need the output to be nifti, otherwise NODDI cannot read it
# eddy = Node (fsl.Eddy(), name = 'eddy')
# eddy.inputs.in_acqp  = acqparams
# eddy.inputs.in_bval  = bval
# eddy.inputs.in_bvec  = bvec
# eddy.inputs.in_index = index
# eddy.inputs.use_cuda = True
# eddy.inputs.is_shelled = True
# eddy.inputs.num_threads = 8
# eddy.inputs.niter = 2
# eddy.inputs.output_type = 'NIFTI' #This will be passed to NODDI and charmed


#I tried new Eddy function, it did not work very well, So, I am regressing to good old eddy_correct that perfroms only affine
#I compared new eddy vs mcflirt vs eddy_correct and the later really did perform much better

eddy = Node (fsl.EddyCorrect(), name = 'eddy')
eddy.inputs.ref_num = 0

#-----------------------------------------------------------------------------------------------------
# In[8]
def Kurtosis(dwi, mask):
		import numpy as np
		import dipy.reconst.dki as dki
		import dipy.reconst.dti as dti
		import dipy.reconst.dki_micro as dki_micro
		from dipy.data import fetch_cfin_multib
		from dipy.data import read_cfin_dwi
		from dipy.segment.mask import median_otsu
		from dipy.io.image import load_nifti, save_nifti
		from scipy.ndimage.filters import gaussian_filter
		import nibabel as nib
		from dipy.core.gradients import gradient_table
		from dipy.io import read_bvals_bvecs
		from sklearn import preprocessing
		import os


		bval = '/media/amr/HDD/Work/October_Acquistion/bval_multishell'
		bvec = '/media/amr/HDD/Work/October_Acquistion/bvec_multishell'
		protocol = '/media/amr/HDD/Work/October_Acquistion/MDT_multishell_protocol.prtcl'
		data, affine = load_nifti(dwi)
		mask, affine_mask = load_nifti(mask)
		protocol = np.loadtxt(protocol)
		fbval = bval
		fbvec = bvec

		bval, bvec = read_bvals_bvecs(fbval, fbvec)
		gnorm = protocol[:,3]
		Delta = protocol[:,4]
		delta = protocol[:,5]
		TE = protocol[:,6]
		TR = protocol[:,8]

		if np.dot(bvec[5, :], bvec[5, :]) == 1.0:
			gtab = gradient_table(bval, bvec, big_delta=Delta, small_delta=delta, b0_threshold=0,atol=1)

		else:
			bvec = preprocessing.normalize(bvec, norm ='l2')
			gtab = gradient_table(bval, bvec, big_delta=Delta, small_delta=delta, b0_threshold=0,atol=0.01)


		dkimodel = dki.DiffusionKurtosisModel(gtab)

		dkifit = dkimodel.fit(data, mask=mask)

		FA = dkifit.fa
		MD = dkifit.md
		AD = dkifit.ad
		RD = dkifit.rd

		MK = dkifit.mk(0, 3)
		AK = dkifit.ak(0, 3)
		RK = dkifit.rk(0, 3)


		save_nifti('DKI_FA.nii', FA, affine)
		save_nifti('DKI_MD.nii', MD, affine)
		save_nifti('DKI_AD.nii', AD, affine)
		save_nifti('DKI_RD.nii', RD, affine)

		save_nifti('DKI_MK.nii', MK, affine)
		save_nifti('DKI_AK.nii', AK, affine)
		save_nifti('DKI_RK.nii', RK, affine)

		DKI_FA = os.path.abspath('DKI_FA.nii')
		DKI_MD = os.path.abspath('DKI_MD.nii')
		DKI_AD = os.path.abspath('DKI_AD.nii')
		DKI_RD = os.path.abspath('DKI_RD.nii')

		DKI_MK = os.path.abspath('DKI_MK.nii')
		DKI_AK = os.path.abspath('DKI_AK.nii')
		DKI_RK = os.path.abspath('DKI_RK.nii')

		#AWF and TORT from microstructure model
		dki_micro_model = dki_micro.KurtosisMicrostructureModel(gtab)

		dki_micro_fit = dki_micro_model.fit(data, mask=mask)

		AWF = dki_micro_fit.awf                  #Axonal watrer Fraction
		TORT = dki_micro_fit.tortuosity          #Tortouisty

		save_nifti('DKI_AWF.nii', AWF, affine)
		save_nifti('DKI_TORT.nii', TORT, affine)

		DKI_AWF = os.path.abspath('DKI_AWF.nii')
		DKI_TORT = os.path.abspath('DKI_TORT.nii')

		return  DKI_FA, DKI_MD, DKI_AD, DKI_RD, DKI_MK, DKI_AK, DKI_RK, DKI_AWF, DKI_TORT



Kurtosis = Node(name = 'Kurtosis',
                  interface = Function(input_names = ['dwi','mask'],
                  					   output_names = ['DKI_FA', 'DKI_MD', 'DKI_AD', 'DKI_RD', 'DKI_MK', 'DKI_AK', 'DKI_RK', 'DKI_AWF', 'DKI_TORT'],
                  function = Kurtosis))


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

#>>>>>>>>>>>>>>>>>>>>>>>>>AK
antsApplyAK_WAX = antsApplyMD_WAX.clone(name = 'antsApplyAK_WAX')
antsApplyAK_WAX.inputs.output_image = 'AK_{subject_id}.nii'

#>>>>>>>>>>>>>>>>>>>>>>>>>MK
antsApplyMK_WAX = antsApplyMD_WAX.clone(name = 'antsApplyMK_WAX')
antsApplyMK_WAX.inputs.output_image = 'MK_{subject_id}.nii'

#>>>>>>>>>>>>>>>>>>>>>>>>>RK
antsApplyRK_WAX = antsApplyMD_WAX.clone(name = 'antsApplyRK_WAX')
antsApplyRK_WAX.inputs.output_image = 'RK_{subject_id}.nii'


#>>>>>>>>>>>>>>>>>>>>>>>>>AWF
antsApplyAWF_WAX = antsApplyMD_WAX.clone(name = 'antsApplyAWF_WAX')
antsApplyAWF_WAX.inputs.output_image = 'AWF_{subject_id}.nii'

#>>>>>>>>>>>>>>>>>>>>>>>>>TORT
antsApplyTORT_WAX = antsApplyMD_WAX.clone(name = 'antsApplyTORT_WAX')
antsApplyTORT_WAX.inputs.output_image = 'TORT_{subject_id}.nii'


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
FA_to_Study_Temp.inputs.num_threads=8
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

#>>>>>>>>>>>>>>>>>>>>>>>>>AK
antsApplyAK_Study = antsApplyMD_Study.clone(name = 'antsApplyAK_Study')
antsApplyAK_Study.inputs.output_image = 'AK_{subject_id}.nii'

#>>>>>>>>>>>>>>>>>>>>>>>>>MK
antsApplyMK_Study = antsApplyMD_Study.clone(name = 'antsApplyMK_Study')
antsApplyMK_Study.inputs.output_image = 'MK_{subject_id}.nii'

#>>>>>>>>>>>>>>>>>>>>>>>>>RK
antsApplyRK_Study = antsApplyMD_Study.clone(name = 'antsApplyRK_Study')
antsApplyRK_Study.inputs.output_image = 'RK_{subject_id}.nii'

#>>>>>>>>>>>>>>>>>>>>>>>>>AWF
antsApplyAWF_Study = antsApplyMD_Study.clone(name = 'antsApplyAWF_Study')
antsApplyAWF_Study.inputs.output_image = 'AWF_{subject_id}.nii'

#>>>>>>>>>>>>>>>>>>>>>>>>>TORT
antsApplyTORT_Study = antsApplyMD_Study.clone(name = 'antsApplyTORT_Study')
antsApplyTORT_Study.inputs.output_image = 'TORT_{subject_id}.nii'


#------------------------------------------------------------------------------------------------


Multishell_workflow.connect ([

      (infosource, selectfiles,[('subject_id','subject_id')]),

      (selectfiles, eddy, [('DWI','in_file')]),

      (selectfiles, Kurtosis, [('Mask','mask')]),
      (eddy, Kurtosis, [('eddy_corrected','dwi')]),

#-----------------------------------------------------------------------------------------------

      (Kurtosis, FA_to_WAX_Temp, [('DKI_FA','moving_image')]),

      (Kurtosis, antsApplyMD_WAX, [('DKI_MD','input_image')]),
      (FA_to_WAX_Temp, antsApplyMD_WAX, [('composite_transform','transforms')]),


      (Kurtosis, antsApplyAD_WAX, [('DKI_AD','input_image')]),
      (FA_to_WAX_Temp, antsApplyAD_WAX,[('composite_transform','transforms')]),


      (Kurtosis, antsApplyRD_WAX, [('DKI_RD','input_image')]),
      (FA_to_WAX_Temp, antsApplyRD_WAX,[('composite_transform','transforms')]),


      (Kurtosis, antsApplyAK_WAX, [('DKI_AK','input_image')]),
      (FA_to_WAX_Temp, antsApplyAK_WAX,[('composite_transform','transforms')]),


      (Kurtosis, antsApplyMK_WAX, [('DKI_MK','input_image')]),
      (FA_to_WAX_Temp, antsApplyMK_WAX,[('composite_transform','transforms')]),

      (Kurtosis, antsApplyRK_WAX, [('DKI_RK','input_image')]),
      (FA_to_WAX_Temp, antsApplyRK_WAX,[('composite_transform','transforms')]),



      (Kurtosis, antsApplyAWF_WAX, [('DKI_AWF','input_image')]),
      (FA_to_WAX_Temp, antsApplyAWF_WAX,[('composite_transform','transforms')]),


      (Kurtosis, antsApplyTORT_WAX, [('DKI_TORT','input_image')]),	
      (FA_to_WAX_Temp, antsApplyTORT_WAX,[('composite_transform','transforms')]),
#-----------------------------------------------------------------------------------------------
      (Kurtosis, FA_to_Study_Temp, [('DKI_FA','moving_image')]),

      (Kurtosis, antsApplyMD_Study, [('DKI_MD','input_image')]),
      (FA_to_Study_Temp, antsApplyMD_Study, [('composite_transform','transforms')]),


      (Kurtosis, antsApplyAD_Study, [('DKI_AD','input_image')]),
      (FA_to_Study_Temp, antsApplyAD_Study,[('composite_transform','transforms')]),


      (Kurtosis, antsApplyRD_Study, [('DKI_RD','input_image')]),
      (FA_to_Study_Temp, antsApplyRD_Study,[('composite_transform','transforms')]),

      (Kurtosis, antsApplyAK_Study, [('DKI_AK','input_image')]),
      (FA_to_Study_Temp, antsApplyAK_Study,[('composite_transform','transforms')]),

      (Kurtosis, antsApplyMK_Study, [('DKI_MK','input_image')]),
      (FA_to_Study_Temp, antsApplyMK_Study,[('composite_transform','transforms')]),

      (Kurtosis, antsApplyRK_Study, [('DKI_RK','input_image')]),
      (FA_to_Study_Temp, antsApplyRK_Study,[('composite_transform','transforms')]),


      (Kurtosis, antsApplyAWF_Study, [('DKI_AWF','input_image')]),
      (FA_to_Study_Temp, antsApplyAWF_Study,[('composite_transform','transforms')]),

      (Kurtosis, antsApplyTORT_Study, [('DKI_TORT','input_image')]),
      (FA_to_Study_Temp, antsApplyTORT_Study,[('composite_transform','transforms')]),


  ])


Multishell_workflow.write_graph(graph2use='flat')
Multishell_workflow.run('MultiProc', plugin_args={'n_procs': 8})

