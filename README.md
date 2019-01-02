# Diffusion_Analysis_All_Scripts
<font color=red>These are the scripts I used to analyze dti dat acquired in oct_2017</font>

After converting raw 2dseq to nifti, I rotated the images and augmented them to look right upon visulization.

I also made sure the R/L orientation is correct by applying the same pipeline to a subject with Agarose on the RH.

I extracted the B0 from the images and used ITKSnap to remove the skull manually.

I concatenated the two shells together to use them for applying models like CSD, NODDI, CHARMED_r2 and Kurtosis.

The B=1000 shell was used for fitting diffusion tensor.

The multishell data was used for all the other models.

I did not used Nipype for CSD (Fixel Based Analysis) because Mrtrix3 is not complete in the library, I used the same folder arrangements though.

I also included the scripts I used on the cluser, they are the scripts preceded with Cluster_.

I finally came to the conclusion that using a study-based template is the best and I also used Waxholm template as it is the only FM hih resolution mapt out there.

For the stasticis, i used four approaches:
1-TBSS on images registered to Study-Based template.
2-TBSS on images registered to Waxholm template.

3-VBA on images registered to Study-Based template.
4-VBA on images registered to Waxholm template.

I used nipype to do all stats.
