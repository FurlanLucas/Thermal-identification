function [bodeOut, Fs_taylor] = model_2d_taylor(dataIn, h, taylorOrder, ...
    seriesOrder, varargin)
    %% model_2d_taylor
    %
    %   Analyse en 1D de la function transfert F(s) = phi(s)/theta(s)
    %   théorique, avec une aproximation polynomial de Taylor. Il utilise 
    %   les données qui sont disponibles dans dataIn, dedans le champs
    %   sysData.
    %
    %   Appels:
    %
    %       [bodeOut, Fs_taylor] = model_1d_taylor(dataIn, h) : prendre le
    %       diagramme de bode avec le modèle 1d de la transfert de chaleur 
    %       en utilisant la valeur du coefficient de transfert termique h 
    %       et une approximation de taylor d'ordre 10 ave les 6 premiers termes
    %       de la série.
    %       
    %       [bodeOut, Fs_taylor] = model_1d_taylor(dataIn, h, taylorOrder) : 
    %       prendre le diagramme de bode avec et de la fonction de transfert le 
    %       modèle 1d de la transfert de chaleur en utilisant la valeur du 
    %       coefficient de transfert termique h et une approximation de taylor 
    %       d'ordre taylorOrder. L'ordre de la expantion en série est fixé à 6.
    %
    %       [bodeOut, Fs_taylor] = model_1d_taylor(dataIn, h, taylorOrder,
    %       seriesOrder) : prendre le diagramme de bode et la fonction de 
    %       transfert avec le modèle 1d de la transfert de chaleur en utilisant 
    %       la valeur du coefficient de transfert termique h et une 
    %       approximation de taylor d'ordre taylorOrder. L'ordre de la expantion 
    %       en série est donnée par seriesOrder.
    %
    %       [bodeOut, Fs_taylor] = model_1d_taylor(__, optons) : prendre des 
    %       entrées optionnelles.
    %
    %   Entrées :
    % 
    %   - dataIn : variable thermalData avec le système qui va être simulée. Les
    %   information des coefficients thermiques du material et les autres
    %   carachteristiques comme la masse volumique sont estoquées dans le
    %   champs sysData dedans dataIn. Il peut aussi être utilisé comme une
    %   structure si il y a des champs necessaires dedans ;
    %   - h : Valeur du coefficient de transfert thermique (pertes). Il est
    %   donnée comme un vecteur h = [hx2, hr2] ;
    %   - taylorOrder : ordre de l'approximation de taylor ;
    %   - seriesOrder : numéro des termes dans la série en r.
    %
    %   Sorties :
    %   
    %   - bodeOut : structure avec le résultat de l'analyse qui contien les
    %   champs bodeOut.w avec les fréquences choisit, bodeOut.mag avec la
    %   magnitude et bodeOut.phase avec les données de phase. Les variables
    %   bodeOut.mag et bodeOut.phase sont des celulles 1x2 avec des valeurs
    %   pour la face arrière {1} et avant {2}.
    %   - Fs_taylor : function de transfert (variable tf) avec
    %   l'approximation de taylor. Il est une celulle seriesOrderx2 avec des 
    %   résultats pour la face arrière {i,1} et avant {i,2}.
    %
    %   Entrées optionnelles :
    %   
    %   - wmin : fréquence minimale pour l'analyse en rad/s ;
    %   - wmax : fréquence maximale pour l'analyse en rad/s ;
    %   - wpoints : numéro de points en fréquence a être analysés.
    %   
    % See also thermalData, sysDataType, model_2d.

    %% Entrées et constantes

    wmin = 1e-3;              % [rad/s] Fréquence minimale pour le bode ;
    wmax = 1e2;               % [rad/s] Fréquence maximale pour le bode ;
    wpoints = 1000;           % [rad/s] Nombre des fréquences ;  

    %% Données optionales et autres paramètres

    % Test les argument optionelles
    for i=1:2:length(varargin)        
        switch varargin{i}
            % Fréquence minimale pour le diagramme de bode
            case 'wmin'
                wmin = varargin{i+1};

            % Fréquence maximale pour le diagramme de bode
            case 'wmax'      
                wmax = varargin{i+1};

            % Nombre des points pour le diagrame
            case 'wpoints'     
                wpoints = varargin{i+1};

            % Erreur
            otherwise
                error("Option << " + varargin{i} + "non disponible.");
        end
    end

    % Il verifie le type d'entrée
    if isa(dataIn, 'thermalData')
        lambda = dataIn.sysData.lambda; % [W/mK] Conductivité thermique ;
        a = dataIn.sysData.a;           % [m^2/s] Diffusivité thermique ;
        ell = dataIn.sysData.ell;       % [m] Epaisseur plaque ;
        Rmax = dataIn.sysData.Size;     % [m] Taille du thermocouple (r) ;
        R0 = dataIn.sysData.ResSize;    % [m] Taille de la resistance (r) ;
    elseif isa(dataIn, 'struct')
        lambda = dataIn.lambda; % [W/mK] Conductivité thermique ;
        a = dataIn.a;           % [m^2/s] Diffusivité thermique ;
        ell = dataIn.ell;       % [m] Epaisseur plaque ;
        Rmax = dataIn.Size;     % [m] Taille du thermocouple (r) ;
        R0 = dataIn.ResSize;    % [m] Taille de la resistance (r) ;
    else
        error("Entrée << dataIn >> non valide.");
    end

    % Prendre l'ordre pour taylor
    if ~exist('taylorOrder', 'var')
        taylorOrder = 10;
    end

    % Prendre l'ordre pour la série
    if ~exist('seriesOrder', 'var')
        seriesOrder = 6;
    end

    %% Autres variables de l'analyses
    w = logspace(log10(wmin), log10(wmax), wpoints); % Vecteur des fréq.

    % Conductivité thermique
    lambda_x = lambda;
    lambda_r = lambda;

    % Diffusivité thermique (x)
    a_x = a;

    % Position a être analysé en r
    r = 0;

    % Coefficient de transfert thermique
    hx2 = h(1); % Convection naturelle en x2
    hr2 = h(2); % Convection naturelle en r2

    % Approximation pour e^(x) = P(xi)/Q(xi)
    n = taylorOrder:-1:0;
    P = poly((1/2).^n ./ factorial(n)); % Aproximation e^(x) = P(xi)/Q(xi)
    Q = poly((-1/2).^n ./ factorial(n)); % Aproximation e^(x) = P(xi)/Q(xi)

    % Sorties (initialization)
    Fs_taylor_ev = {zeros(size(w)), zeros(size(w))};  % Vecteur avec des solutions
    Fs_taylor = cell(seriesOrder+1, 2); % Fonction de transfert

    %% Solutions de l'équation transcendente

    % Prendre les solutions pour alpha_n (dans la direction y)
    load("J_roots.mat", 'J0', 'J1');
    
    f = @(alpha_n) hr2*besselj(0,alpha_n*Rmax) - ...
        lambda_r*besselj(1,alpha_n*Rmax).*alpha_n;
    
    alpha = zeros(seriesOrder+1, 1);
    
    alpha(1) = bissec(f, 0, J0(1)/Rmax);
    for i = 1:seriesOrder
       alpha(i+1) = bissec(f, J1(i)/Rmax, J0(i+1)/Rmax);
    end

    Malpha = (besselj(0, alpha*Rmax) .^ 2).*((Rmax * alpha).^2 + ...
        (Rmax * hr2 / lambda_r)^2)./(2*(alpha.^2));

    %% Approximation de taylor pour le modèle arrirère (avec des pertes)

    % Polynômes de la fonction (ils ne sont pas des termes du quadripôle)    
    A_ = poly([lambda_x/(2*ell), hx2/2]); % Polinôme en xi
    B_ = poly([-lambda_x/(2*ell), hx2/2]); % Polinôme en xi

    for n = 0:seriesOrder % Serie en r
        R = besselj(0, r*alpha(n+1));

        % Aproximation de la fonction de transfert F(xi) = N(xi)/D(xi)
        N = P * Q; % Numérateur
        D = (P*P*A_) + (Q*Q*B_); % Dénominateur
    
        % Passe à la variable de Laplace s = (a/e^2)xi
        N = N.odd.comp([ell^2/a_x (alpha(n+1)*ell)^2]);
        D = D.odd.comp([ell^2/a_x (alpha(n+1)*ell)^2]);    
    
        % Unicité de F(s) (d0 = 1)
        N.coef = N.coef/D.coef(end); 
        D.coef = D.coef/D.coef(end);

        % Diagramme de bode
        Fs_eval = N.evaluate(w*1j)./D.evaluate(w*1j);

        % Calcule le facteur de correction de la serie int(Y)*int(Z)
        int_R = (R0/alpha(n+1)) * besselj(1, alpha(n+1)*R0);

        % Some les fonctions (serie en y et en z)
        Fs_taylor_ev{1} = Fs_taylor_ev{1} + Fs_eval * (R/Malpha(n+1))*int_R;
        
        % Fonction de transfert
        Fs_taylor{n+1, 1} = tf(N.coef,D.coef) * (R/Malpha(n+1))*int_R;
    end

    %% Approximation de taylor pour le modèle avant (avec des pertes)
    
    % Polynômes de la fonction (ils ne sont pas des termes du quadripôle)
    A_ = poly([lambda_x/ell, hx2]); % Polinôme en xi
    B_ = poly([lambda_x/ell, -hx2]); % Polinôme en xi
    C_ = poly([(lambda_x/ell)^2, hx2*lambda_x/ell 0]); % Polinôme en xi
    D_ = poly([-(lambda_x/ell)^2, hx2*lambda_x/ell 0]); % Polinôme en xi

    for n = 0:seriesOrder % Serie en r
        R = besselj(0, r*alpha(n+1));

        % Aproximation de la fonction de transfert F(xi) = N(xi)/D(xi)
        N = (P*P*A_) + (Q*Q*B_); % Numérateur
        D = (P*P*C_) + (Q*Q*D_); % Dénominateur
    
        % Passe à la variable de Laplace s = (a/e^2)xi
        N = N.even.comp([ell^2/a_x (alpha(n+1)*ell)^2]);
        D = D.even.comp([ell^2/a_x (alpha(n+1)*ell)^2]);    
    
        % Unicité de F(s) (d0 = 1)
        N.coef = N.coef/D.coef(end); 
        D.coef = D.coef/D.coef(end);

        % Diagramme de bode
        Fs_eval = N.evaluate(w*1j)./D.evaluate(w*1j);

        % Calcule le facteur de correction de la serie int(Y)*int(Z)
        int_R = (R0/alpha(n+1)) * besselj(1, alpha(n+1)*R0);

        % Some les fonctions (serie en y et en z)
        Fs_taylor_ev{2} = Fs_taylor_ev{2} + Fs_eval * (R/Malpha(n+1))*int_R;
        
        % Fonction de transfert
        Fs_taylor{n+1, 2} = tf(N.coef,D.coef) * (R/Malpha(n+1))*int_R;
    end

    %% Résultats
    bodeOut.w = w;
    bodeOut.mag{1} = abs(Fs_taylor_ev{1});
    bodeOut.mag{2} = abs(Fs_taylor_ev{2});
    bodeOut.phase{1} = angle(Fs_taylor_ev{1});
    bodeOut.phase{2} = angle(Fs_taylor_ev{2});       

end
