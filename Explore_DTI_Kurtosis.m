%%%%%%%%%%%%%%%%%%%%%%%%%%%%%copy bmatrix%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% you just have to copy the Bmatrix text and rename it instead of doing
%it everytome I do a subject

% 
% copyfile('/media/amr/Amr_4TB/Work/October_Acquistion/Diff_Multishell_ExploreDTI.bval'...
%     ,['/media/amr/Amr_4TB/Explore_DTI/matlab_script/' name_wo_ext '.bval'])
% 
% 
% copyfile('/media/amr/Amr_4TB/Work/October_Acquistion/Diff_Multishell_ExploreDTI.bvec'...
%     ,['/media/amr/Amr_4TB/Explore_DTI/matlab_script/' name_wo_ext '.bvec'])



eddy_file = dir('Diff_Multishell_*_edc.nii')

eddy_path = fileparts(which(eddy_file.name))

name_wo_ext = eddy_file.name(1:end-4)

copyfile('/media/amr/Amr_4TB/Work/October_Acquistion/Bmatrix_ExploreDTI.txt'...
    ,['/media/amr/Amr_4TB/Explore_DTI/matlab_script/' name_wo_ext '.txt'])
%%%%%%%%%%%%%%%%%%%%%%Sort eddy_corrected nii%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%You need the absolute path for things to work 

E_DTI_sort_DWIs_wrt_b_val_ex([eddy_path '/' eddy_file.name] ,'_sorted.nii',...
    [eddy_path '/' name_wo_ext '_sorted.nii'])


%%%%%%%%%%%%%%%%%%%%%%convert to kurtosis.mat%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Mask_par.tune_NDWI = 0.7; %recommened by Leemans
Mask_par.tune_DWI = 0.7;
Mask_par.mfs = 5

f_DWI = [eddy_path '/' name_wo_ext '_sorted.nii']
f_BM  = [eddy_path '/' name_wo_ext '_sorted.txt']
f_mat = [eddy_path '/' name_wo_ext '_sorted.mat']

E_DTI_quick_and_dirty_DKI_convert_from_nii_txt_to_mat(f_DWI, f_BM, f_mat, Mask_par, 6, 2, 1)

%%%%%%%%%%%%%%%%%%%%%Now flip R-L%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fliped_mat = [eddy_path '/' name_wo_ext '_sorted_flipped.mat']

E_DTI_Flip_left_right_mat(f_mat,fliped_mat)

%%%%%%%%%%%%%%%%%%%%%%%%Get Kurtosis params%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
vars = E_DTI_Complete_List_var;
%FA -> 1
%MD -> 2
%'Mean kurtosis (''_MK.nii'')' -> 46
%'Axial kurtosis (''_AK.nii'')' -> 47 
%'Radial kurtosis (''_RK.nii'')' -> 48
%'Kurtosis anisotropy (''_KA.nii'')' -> 49
%AWF -> 53
%TORT -> 54
%be aware that this is only to try to different estimation to DKI
%to test this against Dipy
%after you are done with this, we can start doing extraction of tract info

E_DTI_Convert_mat_2_nii(fliped_mat, eddy_path, vars([1,2,46:49,53,54]))

%%%%%%%%%%%%%%%%%%%%%%%%%Tractography%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

tracts_thick = [eddy_path '/' name_wo_ext '_sorted_flipped_Tracts_Thick.mat']

tracts_thin = [eddy_path '/' name_wo_ext '_sorted_flipped_Tracts_Thin.mat']


%this will written a lot of tracts
WholeBrainTrackingDTI_fast(fliped_mat, tracts_thick, params)

%on the other hand, this will return only the major bundles
E_DTI_WholeBrainTracking(fliped_mat, tracts_thin, params)

%%%%%%%%%%%%%%%%%calculate tracts from masks%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
E_DTI_Analyse_tracts_ff...
    ('/media/amr/Amr_4TB/Explore_DTI/matlab_script/ROI',...
    '/media/amr/Amr_4TB/Explore_DTI/matlab_script/Diff_Multishell_243_edc_sorted_flipped_Tracts_Thin.mat',...
    '/media/amr/Amr_4TB/Explore_DTI/matlab_script/Diff_Multishell_243_edc_sorted_flipped.mat',...
    '/media/amr/Amr_4TB/Explore_DTI/matlab_script/ROI/Diff_Multishell_243_edc_sorted_flipped_Tracts_Thin_cmd.mat')%,...
%     '/media/amr/Amr_4TB/Explore_DTI/matlab_script/ROI')

%%%%%%%%%%%%%%%%%%remove horizontal tract%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% This part is really fuckin fantastic, but it will take a lot of code 
%also remember I have to do this for around 10 images
%it is easier to craft quite, not 100%, accurate mask
%the perfect solution was to use this code and then use the indices to create a new tract file and use this one
%but i could not fugre out how to convert a mat to a tract file and the code is encrypted unforunately

track_file = load('/media/amr/Amr_4TB/Work/October_Acquistion/Diffusion_Multishell_ExploreDTI_workingdir/Multishell_ExploreDTI_workflow/_subject_id_243/ExploreDTI_calculate_tracts_from_masks/CC_Tracts_243.mat');
tracts = track_file.Tracts;
FE = track_file.TractFE;
si = size(tracts);




%count the fibers that run transversely
count = 0;
i = 1;
ii = 1;
good_fibers=[];
figure(2);

for i=1:(si(2))

    
%     if (FE{i}(end,2) > FE{i}(end,3)) || (FE{i}(end,1) > FE{i}(end,3))
    
    
    %I divide by 2 just to make sure the fiber is not running vertically
    %I was using the starting point (aka 1), but it also removes the tracts
    %that go 
    if (FE{i}((ceil(length(FE{i}) / 2)),2) > FE{i}((ceil(length(FE{i}) / 2)),3))...
            &&...
            (FE{i}((ceil(length(FE{i}) / 2)),1) > FE{i}((ceil(length(FE{i}) / 2)),3))
        
        plot3(tracts{1,i}(:,1), tracts{1,i}(:,2), tracts{1,i}(:,3));
        
        hold on
        count = count + 1;
        good_fibers(ii) = i;
        ii = ii + 1;
        i = i + 1;
    else
        continue
    end
end

count;
hold off


md = track_file.TractMD(good_fibers);
% md = tr.TractVol
md_size = size(md);


for i=(1:md_size(2))   % this was the mistake. I tried to make it i=md_size(2) like a newbie
value_ = sum(md{i}) ;

value_size = size(md{i});

value_sizes(i) = value_size(1);
md_values(i) = value_;
i = i +1 ;
end

all_md = sum(md_values) / sum(value_sizes)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Get tract descriptive stats as csv%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


E_DTI_Convert_Tract_mats_2_xls('/media/amr/Amr_4TB/Explore_DTI/matlab_script/ROI',...
 '/media/amr/Amr_4TB/Explore_DTI/matlab_script/ROI/Desc.csv')








%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55
E_DTI_Export_Tract_Volume_Info('/media/amr/Amr_4TB/Explore_DTI/matlab_script/Diff_Multishell_243_edc_sorted_flipped_FA.nii',...
'/media/amr/Amr_4TB/Explore_DTI/matlab_script/CC_Tracts.mat',...
'/media/amr/Amr_4TB/Explore_DTI/matlab_script/Diff_Multishell_243_edc_sorted_flipped.mat',... 
'/media/amr/Amr_4TB/Explore_DTI/matlab_script/')









