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
# import nipype.interfaces.spm as spm
import nipype.interfaces.utility as utility
from nipype.interfaces.utility import IdentityInterface, Function
from os.path import join as opj
from nipype.interfaces.io import SelectFiles, DataSink
from nipype.pipeline.engine import Workflow, Node, MapNode

import numpy as np
import matplotlib.pyplot as plt


#-----------------------------------------------------------------------------------------------------
# In[2]:

experiment_dir = '/home/in/aeed/TBSS' 


map_list=  [    'CHARMED_AD' ,'CHARMED_FA'  ,'CHARMED_FR' , 'CHARMED_IAD', 'CHARMED_MD',  'CHARMED_RD',


                 'Diffusion_20_AD' , 'Diffusion_20_FA',  'Diffusion_20_MD' , 'Diffusion_20_RD',

                 'Kurtosis_AD' , 'Kurtosis_AWF' , 'Kurtosis_MD' , 'Kurtosis_RD' , 'Kurtosis_TORT',
                 'Kurtosis_AK' , 'Kurtosis_FA'  , 'Kurtosis_MK' , 'Kurtosis_RK' ,

                 'Kurtosis_E_DTI_AD'  ,  'Kurtosis_E_DTI_FA' , 'Kurtosis_E_DTI_MK' , 'Kurtosis_E_DTI_TORT',
                 'Kurtosis_E_DTI_AK'  ,  'Kurtosis_E_DTI_KA' , 'Kurtosis_E_DTI_RD' ,
                 'Kurtosis_E_DTI_AWF' ,  'Kurtosis_E_DTI_MD' , 'Kurtosis_E_DTI_RK' ,


                 'NODDI_FICVF' , 'NODDI_ODI'
 ]


# map_list = ['229', '230', '365', '274']

output_dir  = 'DTI_TBSS_Study'
working_dir = 'DTI_TBSS_workingdir_Study_Based_Template'

DTI_TBSS_Study = Workflow (name = 'DTI_TBSS_Study')
DTI_TBSS_Study.base_dir = opj(experiment_dir, working_dir)

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


             'all_skeleton'             : 'Study_Based_Template/*/{map_id}/All_*_skeletonised.nii.gz',
             'skeleton_mask'            : 'Study_Based_Template/*/{map_id}/mean_FA_skeleton_mask.nii.gz',

             'all_image'                : 'Study_Based_Template/*/{map_id}/All_{map_id}_Study.nii.gz',
#             'image_mask'               : 'Study_Based_Template/*/{map_id}/mean_FA_mask.nii.gz',
	     'mean_FA'               : 'Study_Based_Template/*/{map_id}/mean_FA.nii.gz',

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

design = '/home/in/aeed/TBSS/Design_TBSS.mat'
contrast = '/home/in/aeed/TBSS/Design_TBSS.con'

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
    kernel = [4,4,8]

    #kernel = [4.3,4.3,16]
    



    smoothed_img = smooth_img(image, kernel)
    smoothed_img.to_filename('smoothed_all.nii.gz')

    smoothed_output = os.path.abspath('smoothed_all.nii.gz')
    return  smoothed_output



nilearn_smoothing = Node(name = 'nilearn_smoothing',
                  interface = Function(input_names = ['image'],
                               output_names = ['smoothed_output'],
                  function = nilearn_smoothing))


#-----------------------------------------------------------------------------------------------------
#mask only FA values > 0.2 to gurantee it is WM
thresh_FA = Node(fsl.Threshold(), name = 'thresh_FA')
thresh_FA.inputs.thresh = 0.2	


#-----------------------------------------------------------------------------------------------------
#binarize this mask
binarize_FA = Node(fsl.UnaryMaths(), name = 'binarize_FA')
binarize_FA.inputs.operation = 'bin'
binarize_FA.inputs.output_datatype = 'char'


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
DTI_TBSS_Study.connect ([

      (infosource, selectfiles,[('map_id','map_id')]),

      (selectfiles, randomise_tbss, [('all_skeleton','in_file')]),
      (selectfiles, randomise_tbss, [('skeleton_mask','mask')]),

      (selectfiles, nilearn_smoothing, [('all_image','image')]),

      (nilearn_smoothing, randomise_VBA, [('smoothed_output','in_file')]),
     
     (selectfiles, thresh_FA, [('mean_FA','in_file')]),
     (thresh_FA, binarize_FA, [('out_file','in_file')]), 
     (binarize_FA, randomise_VBA, [('out_file','mask')])




  ])


DTI_TBSS_Study.write_graph(graph2use='flat')
DTI_TBSS_Study.run(plugin='SLURM')
# DTI_workflow.run(plugin='SLURM')
