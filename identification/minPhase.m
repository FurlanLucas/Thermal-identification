function [phi t_out] = minPhase(dataIn, modelsBack, modelsFront, varargin)
    %% inversion
    %
    % Function to invert the model and validate it with reentry data. The
    % input will be tha last experiment available in dataIn, giving the
    % resid as a result.
    %
    % Calls
    %
    %   resid = validation(dataIn, models): validate the models in the
    %   structure models, using the data avaiable in dataIn. It will be
    %   used all the datasets except for the first one;
    %
    %   resid = validation(dataIn, models)(__, options): take the optional 
    %   arguments.
    %
    % Inputs
    %
    %   dataIn: thermalData variable with all the information for the
    %   system that will be simulated. The thermal coefficients are within
    %   the field sysData. It is not possible also use a structure in this
    %   case;
    %
    %   models: struct with the models to be validated. For instance, with
    %   the filds named: ARMAX, ARMAX, ARMAX and BJ.
    %
    % Outputs
    %
    %   resid: residue from the analysis.
    %
    % Aditional options
    %
    %   setExp: set the number of experiments to be used in the validation
    %   analysis. The result of validation(dataIn, models, setExp=[1,2]) is
    %   the same of validation(getexp(dataIn, [1,2]), models).
    %
    % See convergence, iddata, sysDataType, thermalData.

    %% Inputs
    figDir = 'outFig';          % Directory for output figures
    analysisName = dataIn.Name; % Analysis name 

    % Default values
    wmin = 1e-3;              % [rad/s] Minimum frequency
    wmax = 1e-1;               % [rad/s] Maximum frequency
    wpoints = 1000;           % [rad/s] Number of frequency points 

    % Verify the optional arguments
    for i=1:2:length(varargin)        
        switch varargin{i}
            % Minimum frequency
            case 'wmin'
                wmin = varargin{i+1};
            % Maximum frequency
            case 'wmax'      
                wmax = varargin{i+1};
            % Number of frequency points 
            case 'wpoints'     
                wpoints = varargin{i+1};
            % Error
            otherwise
                error("Option << " + varargin{i} + "is not available.");
        end
    end

    w = logspace(log10(wmin), log10(wmax), wpoints); % Frequency vector

    %% Direct system's model

    G = tf(modelsBack.ARMAX.B, modelsBack.ARMAX.A, modelsBack.ARMAX.Ts);
    G.TimeUnit = modelsBack.ARMAX.TimeUnit;
    fig = figure; pzplot(G);
    saveas(fig, figDir + "\" + analysisName + ...
        "\ARMAX_pzplot_before.eps", 'epsc');  
    
    % Take 'unstable' zeros
    out_zeros = zpk(modelsBack.ARMAX).Z{1};
    out_zeros = out_zeros(abs(out_zeros)>=1);
    
    % All pass filter
    Pt = zpk(out_zeros, 1./conj(out_zeros), 1/real(prod(-out_zeros)),...
        modelsBack.ARMAX.Ts);
    Pt.TimeUnit = modelsBack.ARMAX.TimeUnit;

    % Approximation by minimum phase
    Gm = minreal(G/Pt);
    fig = figure; pzplot(Gm);
    saveas(fig, figDir + "\" + analysisName + ...
        "\ARMAX_pzplot_after.eps", 'epsc');     

    % Direct simulation (comparison)
    [mag, phase] = bode(G, w);
    [y_ARMAX_dir, t_ARMAX_dir] = lsim(G, dataIn.phi{end}, ...
        dataIn.t{end});
    [magm, phasem] = bode(Gm, w);
    [y_ARMAX_dir_app, t_ARMAX_dir_app] = lsim(Gm, dataIn.phi{end}, ...
        dataIn.t{end});
    phasem2 = squeeze(phasem) + round((phase(1,1,1)-phasem(1,1,1))/360)*360;

    % Frequency comparison english
    fig = figure; subplot(2, 1, 1); hold on; 
    semilogx(w, mag2db(squeeze(mag)), 'b', LineWidth=2.1);
    semilogx(w, mag2db(squeeze(magm)), '--r' , LineWidth=2.1);
    ylabel("Magnitude (dB)", Interpreter='latex', FontSize=17);
    set(gca, 'XScale', 'log'); grid minor; hold off; 
    subplot(2, 1, 2); hold on;
    h1 = semilogx(w, squeeze(phase), 'b', Linewidth=1.7, ...
        DisplayName="Identified model");
    h2 = semilogx(w, phasem2, '--r' , LineWidth=1.7, ...
        DisplayName="Approximated model");
    hold off; set(gca, 'XScale', 'log'); grid minor;
    ylabel("Phase (deg)", Interpreter='latex', FontSize=17);
    xlabel("Frequency (rad/s)", Interpreter='latex', FontSize=17);
    legend(Location='southwest', Interpreter='latex', FontSize=17);
    saveas(fig, figDir + "\" + analysisName + ...
        "\ARMAX_freq_reentry_en.eps", 'epsc');    

    % Frequency comparison french
    xlabel("Fr\'{e}quence (rad/s)", Interpreter='latex', FontSize=17);
    set(h1, "DisplayName", "Mod\`{e}le optimis\'{e}");
    set(h2, "DisplayName", "Mod\`{e}le approxim\'{e}");
    subplot(2, 1, 1); 
    ylabel("Module (dB)", Interpreter='latex', FontSize=17);
    saveas(fig, figDir + "\" + analysisName + ...
        "\ARMAX_freq_reentry_fr.eps", 'epsc');

    % Time comparison
    fig = figure; hold on;
    plot(dataIn.t{end}/60e3, dataIn.y_back{end}, 'ok', Linewidth=1.2, ...
        HandleVisibility='off', MarkerSize=1, MarkerFaceColor='k'); 
    h(1) = plot(NaN, NaN, 'ok', Linewidth=1.2, DisplayName="Exp. data",...
        MarkerSize=7, MarkerFaceColor='k'); 
    h(2) = plot(t_ARMAX_dir/60e3, y_ARMAX_dir, 'b', LineWidth=1.7, ...
        DisplayName="Identified model"); 
    h(3) = plot(t_ARMAX_dir_app/60e3, y_ARMAX_dir_app, '--r', ...
        LineWidth=1.7, DisplayName="Approximated model"); 
    hold off; grid minor;
    xlabel("Time (min)", Interpreter='latex', FontSize=17);
    ylabel("Temperature ($^\circ$)", Interpreter='latex', FontSize=17);
    legend(h, Location='southeast', Interpreter='latex', FontSize=17);
    saveas(fig, figDir + "\" + analysisName + ...
        "\ARMAX_time_reentry_en.eps", 'epsc');

    % Time comparison french
    xlabel("Temps (min)", Interpreter='latex', FontSize=17);
    ylabel("Temp\'{e}rature ($^\circ$)", Interpreter='latex', FontSize=17);
    set(h(2), "DisplayName", "Mod\`{e}le identifi\'{e}");
    set(h(3), "DisplayName", "Mod\`{e}le approxim\'{e}");
    saveas(fig, figDir + "\" + analysisName + ...
        "\ARMAX_time_reentry_fr.eps", 'epsc');
    
    %% Inverse model (valid)
    Gm_inv = 1/Gm;

    % Inverse simulation (comparison for last valid data)
    dataIn.y_back{dataIn.Ne} = lowpass(dataIn.y_back{dataIn.Ne}, 1e-2);
    [phi_ARMAX_inv, t_ARMAX_inv] = lsim(Gm_inv, dataIn.y_back{dataIn.Ne}, ...
        dataIn.t{dataIn.Ne});
    phi_ARMAX_inv = medfilt1(lowpass(phi_ARMAX_inv(1:end-50), 1e-2), 5);
    t_ARMAX_inv = t_ARMAX_inv(1:end-50);

    % Time comparison for last valid data english
    fig = figure; hold on; clear h;
    h(1) = plot(t_ARMAX_inv/60e3, phi_ARMAX_inv, 'r', LineWidth=1.7, ...
        DisplayName="Approximated model"); 
    plot(dataIn.t{dataIn.Ne}/60e3, dataIn.phi{dataIn.Ne}, 'ok', ...
        Linewidth=.8, HandleVisibility='off', MarkerSize=1, ...
        MarkerFaceColor='k');
    h(2) = plot(NaN, NaN, 'ok', Linewidth=.8, DisplayName="Exp. data", ...
        MarkerSize=7, MarkerFaceColor='k');
    hold off; grid minor;
    xlabel("Time (min)", Interpreter='latex', FontSize=17);
    ylabel("Heat flux (W/m$^2$)", Interpreter='latex', FontSize=17);
    legend(h, Location='southeast', Interpreter='latex', FontSize=17);
    saveas(fig, figDir + "\" + analysisName + ...
        "\ARMAX_time_valid_inv_en.eps", 'epsc');

    % Time comparison for last valid data french
    xlabel("Temps (min)", Interpreter='latex', FontSize=17);
    ylabel("Flux de chaleur (W/m$^2$)", Interpreter='latex', FontSize=17);
    set(h(1), "DisplayName", "Mod\`{e}le approxim\'{e}");
    set(h(2), "DisplayName", "Donn\'{e}es exp\'{e}rimentales");
    saveas(fig, figDir + "\" + analysisName + ...
        "\ARMAX_time_valid_inv_fr.eps", 'epsc');

    %% Inverse model (reentry)

    % Input and output figure (english)
    fig = figure; subplot(2, 1, 1);
    plot(dataIn.t{end}/60e3, dataIn.phi{end}, 'r', LineWidth=1.7);
    ylabel({"Heat flux", "(W/m$^2$)"}, Interpreter='latex', ...
        FontSize=17);
    grid minor; subplot(2, 1, 2);
    plot(dataIn.t{end}/60e3, dataIn.y_back{end}, 'r', LineWidth=1.7);
    grid minor;
    xlabel("Time (min)", Interpreter='latex', FontSize=17);
    ylabel("Temperature ($^\circ$C)", Interpreter='latex', FontSize=17);
    saveas(fig, figDir + "\" + analysisName + ...
        "\ARMAX_reentry_inputOutput_en.eps", 'epsc');

    % Input and output figure french
    ylabel("Temp\'{e}rature ($^\circ$C)", Interpreter='latex', FontSize=17);
    xlabel("Temps (min)", Interpreter='latex', FontSize=17);
    subplot(2, 1, 1);
    ylabel({"Flux de chaleur", "(W/m$^2$)"}, Interpreter='latex', FontSize=17);
    saveas(fig, figDir + "\" + analysisName + ...
        "\ARMAX_reentry_inputOutput_fr.eps", 'epsc');
    
    % Inverse simulation (comparison for reentry data)
    dataIn.y_back{end} = lowpass(dataIn.y_back{end}, 1e-3);
    [phi_ARMAX_inv, t_ARMAX_inv] = lsim(Gm_inv, dataIn.y_back{end}, ...
        dataIn.t{end});

    % Time comparison for reentry data english
    fig = figure; hold on; clear h;
    h(1) = plot(t_ARMAX_inv(1:end-50)/60e3, phi_ARMAX_inv(1:end-50), ...
        'r', LineWidth=1.7, DisplayName="Approximated model"); 
    plot(dataIn.t{end}(1:end-50)/60e3, dataIn.phi{end}(1:end-50), ...
        'ok', Linewidth=.8, HandleVisibility='off', MarkerSize=1, ...
        MarkerFaceColor='k');
    h(2) = plot(NaN, NaN, 'ok', Linewidth=.8, DisplayName="Exp. data", ...
        MarkerSize=7, MarkerFaceColor='k');
    hold off; grid minor;
    xlabel("Time (min)", Interpreter='latex', FontSize=17);
    ylabel("Heat flux (W/m$^2$)", Interpreter='latex', FontSize=17);
    legend(h, Location='southeast', Interpreter='latex', FontSize=17);
    saveas(fig, figDir + "\" + analysisName + ...
        "\ARMAX_time_reentry_inv_en.eps", 'epsc');

    % Time comparison for reentry data french
    xlabel("Temps (min)", Interpreter='latex', FontSize=17);
    ylabel("Flux de chaleur (W/m$^2$)", Interpreter='latex', FontSize=17);
    set(h(1), "DisplayName", "Mod\`{e}le identifi\'{e}");
    set(h(2), "DisplayName", "Donn\'{e}es exp\'{e}rimentales");
    saveas(fig, figDir + "\" + analysisName + ...
        "\ARMAX_time_reentry_inv_fr.eps", 'epsc');

    %% Down sample and filtering

    phi_ARMAX_inv = downsample(phi_ARMAX_inv, 5);
    t_ARMAX_inv = downsample(t_ARMAX_inv, 5);

    phi_ARMAX_inv = medfilt1(lowpass(phi_ARMAX_inv(1:end-50), 1e-3),5);
    t_ARMAX_inv = t_ARMAX_inv(1:end-50);

    % Time comparison for reentry data english
    fig = figure; hold on; clear h;
    h(1) = plot(t_ARMAX_inv/60e3, phi_ARMAX_inv, 'r', LineWidth=1.7, ...
        DisplayName="Approximated model"); 
    plot(dataIn.t{end}/60e3, dataIn.phi{end}, 'ok', Linewidth=.8, ...
        HandleVisibility='off', MarkerSize=1, MarkerFaceColor='k');
    h(2) = plot(NaN, NaN, 'ok', Linewidth=.8, DisplayName="Exp. data", ...
        MarkerSize=7, MarkerFaceColor='k');
    hold off; grid minor;
    xlabel("Time (min)", Interpreter='latex', FontSize=17);
    ylabel("Heat flux (W/m$^2$)", Interpreter='latex', FontSize=17);
    legend(h, Location='southeast', Interpreter='latex', FontSize=17);
    saveas(fig, figDir + "\" + analysisName + ...
        "\ARMAX_time_reentry_invPlus_en.eps", 'epsc');

    % Time comparison for reentry data french
    xlabel("Temps (min)", Interpreter='latex', FontSize=17);
    ylabel("Flux de chaleur (W/m$^2$)", Interpreter='latex', FontSize=17);
    set(h(1), "DisplayName", "Mod\`{e}le identifi\'{e}");
    set(h(2), "DisplayName", "Donn\'{e}es exp\'{e}rimentales");
    saveas(fig, figDir + "\" + analysisName + ...
        "\ARMAX_time_reentry_invPlus_fr.eps", 'epsc');

    % Output
    phi = phi_ARMAX_inv;
    t_out = t_ARMAX_inv;

    %% Front temperature
    
    G = tf(modelsFront.ARMAX.B, modelsFront.ARMAX.A, modelsFront.ARMAX.Ts);
    G.TimeUnit = modelsFront.ARMAX.TimeUnit;

    % Take 'unstable' zeros
    out_zeros = zpk(modelsFront.ARMAX).Z{1};
    out_zeros = out_zeros(abs(out_zeros)>=1);
    
    % All pass filter
    Pt = zpk(out_zeros, 1./conj(out_zeros), 1/real(prod(-out_zeros)),...
        modelsFront.ARMAX.Ts);
    Pt.TimeUnit = modelsFront.ARMAX.TimeUnit;

    % Approximation by minimum phase
    GmFront = minreal(G/Pt);

    % Inverse simulation (comparison for reentry data)
    dataIn.y_front{end} = lowpass(dataIn.y_front{end}, 1e-3);
    [temp_ARMAX_inv, t_ARMAX_inv] = lsim(1/GmFront, dataIn.y_front{end}, ...
        dataIn.t{end});

    % Time comparison for reentry data english
    fig = figure; hold on; clear h;
    h(1) = plot(t_ARMAX_inv/60e3, temp_ARMAX_inv, 'r', LineWidth=1.7, ...
        DisplayName="Approximated model"); 
    plot(dataIn.t{end}/60e3, dataIn.phi{end}, 'ok', Linewidth=.8, ...
        HandleVisibility='off', MarkerSize=1, MarkerFaceColor='k');
    h(2) = plot(NaN, NaN, 'ok', Linewidth=.8, DisplayName="Exp. data", ...
        MarkerSize=7, MarkerFaceColor='k');
    hold off; grid minor;
    xlabel("Time (min)", Interpreter='latex', FontSize=17);
    ylabel("Heat flux (W/m$^2$)", Interpreter='latex', FontSize=17);
    legend(h, Location='southeast', Interpreter='latex', FontSize=17);
    saveas(fig, figDir + "\" + analysisName + ...
        "\ARMAX_time_reentry_temp_inv_en.eps", 'epsc');

    % Time comparison for reentry data french
    xlabel("Temps (min)", Interpreter='latex', FontSize=17);
    ylabel("Flux de chaleur (W/m$^2$)", Interpreter='latex', FontSize=17);
    set(h(1), "DisplayName", "Mod\`{e}le identifi\'{e}");
    set(h(2), "DisplayName", "Donn\'{e}es exp\'{e}rimentales");
    saveas(fig, figDir + "\" + analysisName + ...
        "\ARMAX_time_reentry_inv_temp_fr0.eps", 'epsc');


    % Inverse simulation (comparison for reentry data) Temperature
    [y_ARMAX_inv, t_ARMAX_inv] = lsim(minreal(GmFront/Gm), dataIn.y_back{end}, ...
        dataIn.t{end});

    % Time comparison for reentry data english
    fig = figure; hold on; clear h;
    h(1) = plot(t_ARMAX_inv/60e3, y_ARMAX_inv, 'r', LineWidth=1.7, ...
        DisplayName="Approximated model"); 
    plot(dataIn.t{end}/60e3, dataIn.y_front{end}, 'ok', Linewidth=.8, ...
        HandleVisibility='off', MarkerSize=1, MarkerFaceColor='k');
    h(2) = plot(NaN, NaN, 'ok', Linewidth=.8, DisplayName="Exp. data", ...
        MarkerSize=7, MarkerFaceColor='k');
    hold off; grid minor;
    xlabel("Time (min)", Interpreter='latex', FontSize=17);
    ylabel("Heat flux (W/m$^2$)", Interpreter='latex', FontSize=17);
    legend(h, Location='southeast', Interpreter='latex', FontSize=17);
    saveas(fig, figDir + "\" + analysisName + ...
        "\ARMAX_time_reentry_inv_en0.eps", 'epsc');

    % Time comparison for reentry data french
    xlabel("Temps (min)", Interpreter='latex', FontSize=17);
    ylabel("Flux de chaleur (W/m$^2$)", Interpreter='latex', FontSize=17);
    set(h(1), "DisplayName", "Mod\`{e}le identifi\'{e}");
    set(h(2), "DisplayName", "Donn\'{e}es exp\'{e}rimentales");
    saveas(fig, figDir + "\" + analysisName + ...
        "\ARMAX_time_reentry_inv_fr0.eps", 'epsc');

    %% Ending and output
    msg = 'Press enter to continue...';
    input(msg);
    fprintf(repmat('\b', 1, length(msg)+1));
    close all;

end