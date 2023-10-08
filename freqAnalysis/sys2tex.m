function sys2tex(expData, analysis)
    %% systemDataTable
    %
    %   Creates tables for latex repport with system information.
    %
    %   See also sysDataType.

    %% Inputs

    dirOut = analysis.texDir;

    %% System data

    fileHandle = fopen(dirOut + "\freqAnalysis_sysData.tex", "w");

    % Table
    fprintf(fileHandle, "\\begin{table}" + ...
        "[H]\n\\centering\n\\begin{tabular}{cccc}\n\t\\hline\n\t" + ...
        "Variable\t&\tName\t&\tValue\t&\tUnit\t\\\\\n" + ...
        "\t\\hline\n" + ...
        "\t$\\lambda$\t&\tThermal conductivity\t&\t%.3d\t&\tW/mK\t\\\\\n" + ...
        "\t$\\rho$\t&\tDensity\t&\t%.3d\t&\tkg/m$^3$\t\\\\\n" + ...
        "\t$c_p$\t&\tSpecific heat\t&\t%.3d\t&\tJ/kgK\t\\\\\n" + ...
        "\t$\\ell$\t&\tThermocouple depth\t&\t%.0d\t&\tmm\t\\\\\n" + ...
	    "\t\\hline\n\\end{tabular}\n\\caption{Coefficients table" + ...
        " for one-dimentional analysis.}\n\\label{tab:coef_1d_tab}" + ...
	    "\n\\end{table}", expData.sysData.lambda, expData.sysData.rho, ...
        expData.sysData.cp, expData.sysData.ell*1e3);

    % Ending
    fclose(fileHandle);

end

