function [y, timeOut] = finitediff2d(dataIn, timeIn, phiIn, h, Mx, Mr, N)
    %% finitediff2D
    %
    % Function that implements the finite difference method in a 2D
    % analysis of the heat equation with a axisymetric system. It is used
    % the implicit method.
    %
    % Calls
    %
    %   [y, timeOut] = finitediff2d(dataIn, timeIn, phiIn, h, Mx, Mr, N):
    %   calls the function for the data in dataIn. The time vector that
    %   will be used and the heat flux applied to the front face (x = 0) is
    %   giving in timeIn and phiIn, respectively. The heat transfert
    %   coefficient is giving by h. Mx, Mr and N are the number of elements
    %   in x, r directions and in time, respectively.
    %
    % Inputs
    %
    %   dataIn: sysData variable with all the information for the
    %   system that will be simulated. It is possible also use a structure 
    %   with the same fields as a sysDataType;
    %
    %   h: vector of heat transfer coefficients in W/(m²K). The first one
    %   is the value for the rear face hx2 and the second one is to the
    %   external surface in r direction hr2;
    %
    %   Mx: Number of elements in x direction. Have to be an integer;
    %
    %   Mr: Number of elements in r direction. Have to be an integer;
    %
    %   N: Number of elements in time. Have to be an integer.
    %
    % Outputs
    %
    %   y: 2x1 cell array with the temperature variation outout of the 
    %   system. The first {1} position corresponds to the rear face and the 
    %   second one to front face.
    %
    %   timeOut: time vector with each simulation instant.
    %
    % See also sysDataType, model_2d, model_2d_pade and model_2d_taylor.

    %% Inputs

    ell = dataIn.ell; % [m] Thermocouple length
    a = dataIn.a;   % [m^2/s] Thermal diffusivity
    lambda_x = dataIn.lambda; % [W/mK] Thermal conductivity in x direction
    lambda_r = dataIn.lambda; % [W/mK] Thermal conductivity in r direction
    Rmax = dataIn.Size; % [m] Termocouple size
    r0 = dataIn.ResSize; % [m] Resistance size

    % Finite differences
    dt = timeIn(end)/(N-1);
    dx = ell/(Mx-1);
    dr = Rmax/(Mr-1);

    r = (0:Mr-1)*dr; % Radius vector (position in r direction)
    timeOut = (0:N-1)*dt; % New time vector
    phi = interp1(timeIn, phiIn, timeOut).* (r' <= r0); % New heat flux vector

    % Heat transfer coefficient
    if length(h) == 1
        hr = h; hx = h;
    else
        hr = h(1); hx = h(2);
    end

    %% Matrices A and B

    fprintf("\t\tCreating matrices.\n");

    % Initialize
    A = zeros(Mx*Mr);
    B = zeros(Mx*Mr);

    for i = 1:Mr
        for j=1:Mx
            pos = i + Mr*(j-1);
            
            R1 = a*dt/(dr^2);
            R2 = a*dt/(2*r(i)*dr);
            R3 = a*dt/(dx^2);
            
            % Within the mash ................................ 1
            if (i > 1) && (i < Mr) && (j > 1) && (j < Mx)
                B(pos, pos-1) = R2 - R1;
                B(pos, pos) = 2 + 2*R1 + 2*R3;
                B(pos, pos+1) = -R1 - R2;
                B(pos, pos-Mr) = -R3;
                B(pos, pos+Mr) = -R3;
                A(pos, pos-1) = R1 - R2;
                A(pos, pos) = 2 - 2*R1 - 2*R3;
                A(pos, pos+1) = R1 + R2;
                A(pos, pos-Mr) = R3;
                A(pos, pos+Mr) = R3;
    
            % Inferior boundary in x (within in r) ........... 2
            elseif (j == 1) && (i ~= 1) && (i ~= Mr)
                B(pos, pos-1) = R2 - R1;
                B(pos, pos) = 2 + 2*R1 + 2*R3;
                B(pos, pos+1) = -R1 - R2;
                B(pos, pos+Mr) = -2*R3;
                A(pos, pos-1) = R1 - R2;
                A(pos, pos) = 2 - 2*R1 - 2*R3;
                A(pos, pos+1) = R1 + R2;
                A(pos, pos+Mr) = 2*R3;
    
            % Superior boundary in x (within in r) ......... 3
            elseif (j == Mx) && (i ~= 1) && (i ~= Mr)
                B(pos, pos-1) = R2 - R1;
                B(pos, pos) = 2 + 2*R1 + 2*R3 + R3*(2*dx*hx/lambda_x);
                B(pos, pos+1) = -R1 - R2;
                B(pos, pos-Mr) = -2*R3;
                A(pos, pos-1) = R1 - R2;
                A(pos, pos) = 2 - 2*R1 - 2*R3 - R3*(2*dx*hx/lambda_x);
                A(pos, pos+1) = R1 + R2;
                A(pos, pos-Mr) = 2*R3;
    
            % Inferior boundary in r (within in x) ....... 4
            elseif (i == 1) && (j ~= 1) && (j ~= Mx)
                B(pos, pos) = 2 + 2*R1 + 2*R3;
                B(pos, pos+1) = -2*R1;
                B(pos, pos-Mr) = -R3;
                B(pos, pos+Mr) = -R3;
                A(pos, pos) = 2 - 2*R1 - 2*R3;
                A(pos, pos+1) = 2*R1;
                A(pos, pos-Mr) = R3;
                A(pos, pos+Mr) = R3;
    
            % Superior boundary in r (within in x) ....... 5
            elseif (i == Mr) && (j ~= 1) && (j ~= Mx)
                B(pos, pos-1) = - 2*R1;
                B(pos, pos) = 2 + 2*R1 + 2*R3 + (R1+R2)*(2*dr*hr/lambda_r);
                B(pos, pos-Mr) = -R3;
                B(pos, pos+Mr) = -R3;
                A(pos, pos-1) = 2*R1;
                A(pos, pos) = 2 - 2*R1 - 2*R3 - (R1+R2)*(2*dr*hr/lambda_r);
                A(pos, pos-Mr) = R3;
                A(pos, pos+Mr) = R3;
    
            % Inferior boundary in r and x .............. 6
            elseif (i == 1) && (j == 1)
                B(pos, pos) = 2 + 2*R1 + 2*R3;
                B(pos, pos+1) = -2*R1;
                B(pos, pos+Mr) = -2*R3;
                A(pos, pos) = 2 - 2*R1 - 2*R3;
                A(pos, pos+1) = 2*R1;
                A(pos, pos+Mr) = 2*R3;
              
            % Inferior boundary in x ans supeior in r . 7
            elseif (j == 1) && (i == Mr)
                B(pos, pos-1) = -2*R1;
                B(pos, pos) = 2 + 2*R1 + 2*R3 + (R1+R2)*(2*dr*hr/lambda_r);
                B(pos, pos+Mr) = -2*R3;
                A(pos, pos-1) = 2*R1;
                A(pos, pos) = 2 - 2*R1 - 2*R3 - (R1+R2)*(2*dr*hr/lambda_r);
                A(pos, pos+Mr) = 2*R3;
    
            % Inferior boundary in r and superior in x .8
            elseif (i == 1) && (j == Mx)
                B(pos, pos) = 2 + 2*R1 + 2*R3 + R3*(2*dx*hx/lambda_x);
                B(pos, pos+1) = -2*R1;
                B(pos, pos-Mr) = -2*R3;
                A(pos, pos) = 2 - 2*R1 - 2*R3 - R3*(2*dx*hx/lambda_x);
                A(pos, pos+1) = 2*R1;
                A(pos, pos-Mr) = 2*R3;
    
            % Superior boundary in r and x
            elseif (i == Mr) && (j == Mx)
                B(pos, pos-1) = -2*R1;
                B(pos, pos) = 2 + 2*R1 + 2*R3 + (R1+R2)*(2*dr*hr/lambda_r)...
                    + R3*(2*dx*hx/lambda_x);
                B(pos, pos-Mr) = -2*R3;
                A(pos, pos-1) = 2*R1;
                A(pos, pos) = 2 - 2*R1 - 2*R3 - (R1+R2)*(2*dr*hr/lambda_r)...
                    - R3*(2*dx*hx/lambda_x);
                A(pos, pos-Mr) = 2*R3;
            else
                error("There is a non-specified element.");
            end    
            
        end
    end

    %% Time loop

    % Display current status
    fprintf("\t\tAnalysis at 00%%.\n");

    % initialize variables
    T = zeros(Mx*Mr, 1);
    y_back = zeros(1,N);
    y_front = zeros(1,N);

    count = 0;
    for n = 2:N
        c = zeros(Mx*Mr, 1);

        for i = 1:Mr
            for j=1:Mx
                pos = i + Mr*(j-1);
                R3 = a*dt/(dx^2);

                % Inferior boundary in x (within in r) ........... 2
                if (j == 1) && (i ~= 1) && (i ~= Mr)
                    c(pos) = R3*2*dx*( (phi(i, n) + phi(i, n-1) )...
                                          )/lambda_x;

                % Inferior boundary in r and x .............. 6
                elseif (i == 1) && (j == 1)
                    c(pos) = R3*2*dx*( (phi(i, n) + phi(i, n-1) )...
                                          )/lambda_x;
                  
                % Inferior boundary in x ans supeior in r . 7
                elseif (j == 1) && (i == Mr)
                    c(pos) = R3*2*dx*( (phi(i, n) + phi(i, n-1) )...
                                          )/lambda_x;
                end
            end
        end

        % Display the current status
        p = floor(100*n/N);
        if p > count
            fprintf("\b\b\b\b\b");
            fprintf("%2d%%.\n", p);
            count = count + 1;
        end

        % Take the results
        T = B\(A*T + c);
        y_back(n) = T(Mr*Mx-Mr+1);
        y_front(n) = T(1);

    end % end for

    %% Output
    y = {y_back, y_front};
    fprintf(repmat('\b', 1, 41));

end % end function
