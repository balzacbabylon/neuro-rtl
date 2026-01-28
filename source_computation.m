function source_computation(eeg_file, imaging_kernel_file, cortex_file)
    
    % Load EEG data file
    %eeg_file = "C:\Users\natha\Documents\eeg_data\brainstorm_db\TutorialIntroduction\data\Subject02\S01_AEF_20131218_01_600Hz\data_deviant_average_260127_1730.mat";
    eeg_data = load(eeg_file);

    % Load ImagingKernel
    %imaging_kernel_file = "C:\Users\natha\Documents\eeg_data\brainstorm_db\TutorialIntroduction\data\Subject02/S01_AEF_20131218_01_600Hz/results_sLORETA_MEG_KERNEL_260127_1732.mat";
    R = load(imaging_kernel_file);
    K = R.ImagingKernel;
    good_channels = R.GoodChannel;
    
    % Exclude wrong channels from eeg_data 
    n_samples = size(eeg_data.F, 2);
    samples_arr = 1: n_samples;
    plot(samples_arr, eeg_data.F);
    ylim([-10e-3 10e-3]);

    eeg_data_good = eeg_data.F(good_channels, :);
    plot(samples_arr, -eeg_data_good);

    % Apply whitener to data if it exists
    Y = eeg_data_good;
    if isfield(R, 'Whitener')
        Yw = R.Whitener * Y;
        J  = R.ImagingKernel * Yw; % That's the line we want to FPGA accelerate
    end

    % Load cortex volume
    % cortex_file = "C:\Users\natha\Documents\eeg_data\brainstorm_db\TutorialIntroduction\anat\Subject02\tess_cortex_pial_low.mat";
    S = load(cortex_file);
    if ~size(S.Vertices,1) == size(J, 1) % Sanity check
        warning("Dimensions of cortex model vertices and dimensions of source space mismatch");
    end

    % Plot max activity on surface
    col_means = mean(eeg_data_good, 1);
    [max_value, m_index] = max(col_means);

    t_idx = m_index; 
    Jv = J(:, t_idx);
    figure
    p = patch( ...
        'Vertices', S.Vertices, ...
        'Faces', S.Faces, ...
        'FaceVertexCData', Jv, ...
        'FaceColor', 'interp', ...
        'EdgeColor', 'none');
    
    axis equal off
    view([90 0]) % lateral view
    camlight headlight
    lighting gouraud
    colormap(jet)
    colorbar
end
