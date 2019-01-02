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
from nipype.interfaces.matlab import MatlabCommand
MatlabCommand.set_default_paths('/media/amr/HDD/Sofwares/spm12/')
MatlabCommand.set_default_matlab_cmd("matlab -nodesktop -nosplash")


#-----------------------------------------------------------------------------------------------------
# In[2]:

experiment_dir = '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat' 

map_list=  [    'CHARMED_AD' ,'CHARMED_FA'  ,'CHARMED_FR' , 'CHARMED_IAD', 'CHARMED_MD',  'CHARMED_RD',


                'Diffusion_20_AD' , 'Diffusion_20_FA',  'Diffusion_20_MD' , 'Diffusion_20_RD',

                'Kurtosis_AD' , 'Kurtosis_AWF' , 'Kurtosis_MD' , 'Kurtosis_RD' , 'Kurtosis_TORT',
                'Kurtosis_AK' , 'Kurtosis_FA' ,  'Kurtosis_MK' , 'Kurtosis_RK',


                'NODDI_FICVF' , 'NODDI_ODI'
]


# map_list = ['229', '230', '365', '274']

output_dir  = 'DTI_TBSS_Wax'
working_dir = 'DTI_TBSS_workingdir_Wax_Template'

DTI_TBSS_Wax = Workflow (name = 'DTI_TBSS_Wax')
DTI_TBSS_Wax.base_dir = opj(experiment_dir, working_dir)

#-----------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------
# In[3]:




# Infosource - a function free node to iterate over the list of subject names
infosource = Node(IdentityInterface(fields=['map_id']),
                  name="infosource")
infosource.iterables = [('map_id', map_list)]

#-----------------------------------------------------------------------------------------------------
# In[4]:

templates = {


             'all_skeleton'             : 'Waxholm_Template/*/{map_id}/All_*_skeletonised.nii.gz',
             'skeleton_mask'            : 'Waxholm_Template/*/{map_id}/mean_FA_skeleton_mask.nii.gz',

             'all_image'                : 'Waxholm_Template/*/{map_id}/All_{map_id}_WAX.nii.gz',
             'image_mask'               : 'Waxholm_Template/*/{map_id}/mean_FA_mask.nii.gz',

 }


selectfiles = Node(SelectFiles(templates,
                               base_directory=experiment_dir),
                   name="selectfiles")
#-----------------------------------------------------------------------------------------------------
# In[5]:

datasink = Node(DataSink(), name = 'datasink')
datasink.inputs.container = output_dir
datasink.inputs.base_directory = experiment_dir

substitutions = [('_map_id_', ' ')]

datasink.inputs.substitutions = substitutions

#-----------------------------------------------------------------------------------------------------
#Design with two contrasts only

design = '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Design_TBSS.mat'
contrast = '/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_TBSS_Stat/Design_TBSS.con'

#-----------------------------------------------------------------------------------------------------
#randomise on the skeletonised data
randomise_tbss = Node(fsl.Randomise(), name = 'randomise_tbss')
randomise_tbss.inputs.design_mat = design
randomise_tbss.inputs.tcon = contrast
randomise_tbss.inputs.num_perm = 10000
randomise_tbss.inputs.tfce2D = True
randomise_tbss.inputs.vox_p_values = True
randomise_tbss.inputs.base_name = 'TBSS_'


#-----------------------------------------------------------------------------------------------------
#smoothing the images
def nilearn_smoothing(image):
    import nilearn 
    from nilearn.image import smooth_img

    import numpy as np
    import os

    kernel = [4.3,4.3,16]



    smoothed_img = smooth_img(image, kernel)
    smoothed_img.to_filename('smoothed_all.nii.gz')

    smoothed_output = os.path.abspath('smoothed_all.nii.gz')
    return  smoothed_output



nilearn_smoothing = Node(name = 'nilearn_smoothing',
                  interface = Function(input_names = ['image'],
                               output_names = ['smoothed_output'],
                  function = nilearn_smoothing))


#-----------------------------------------------------------------------------------------------------
#randomise on the smoothed all images
randomise_VBA = Node(fsl.Randomise(), name = 'randomise_vba')
randomise_VBA.inputs.design_mat = design
randomise_VBA.inputs.tcon = contrast
randomise_VBA.inputs.num_perm = 10000
randomise_VBA.inputs.tfce = True
randomise_VBA.inputs.vox_p_values = True
randomise_VBA.inputs.base_name = 'VBA_'


#-----------------------------------------------------------------------------------------------------
DTI_TBSS_Wax.connect ([

      (infosource, selectfiles,[('map_id','map_id')]),

      (selectfiles, randomise_tbss, [('all_skeleton','in_file')]),
      (selectfiles, randomise_tbss, [('skeleton_mask','mask')]),

      (selectfiles, nilearn_smoothing, [('all_image','image')]),

      (nilearn_smoothing, randomise_VBA, [('smoothed_output','in_file')]),
      (selectfiles, randomise_VBA, [('image_mask','mask')])




  ])


DTI_TBSS_Wax.write_graph(graph2use='flat')
DTI_TBSS_Wax.run('MultiProc', plugin_args={'n_procs': 8})
# DTI_workflow.run(plugin='SLURM')
