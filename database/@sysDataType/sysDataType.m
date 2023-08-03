classdef sysDataType
    %% sysDataType
    % Cette classe permet d'avoir l'ensamble de tous les information liées
    % à chaque réalisation experimental.
    %
    %   -> Type décrit le type de mesure realisé, ce qui peut être
    %   'tension', 'flux' ou 'both'; Si le type a été configuré comme
    %   'tension', donc le flux de chaleur en entrée sera estimée par
    %   rapport à les valeurs des résistances choffantes. Si il a été
    %   configuré comme flux, il va être utilisé directement comme entrée
    %   du modèle, sans comparaison avec la tension. Si il est marqué comme
    %   'both', il va utilisé le flux mesuré, mais des comparaison des
    %   données seront possibles (les valeurs des tensions seront
    %   enregistrée dans 'UserData'.

    %% Proprietées --------------------------------------------------------
    properties
        name = 'Empty';         % [-] Nom de l'analyse ;
        geometry = 'None';      % [-] Type of the geometry ;
        size = 0;               % [m] Lateral size of the thermocouple ;
        type = 'None';          % [-] Type de mesure realisé en entrée ;
        R = 0;                  % [Ohm] Résistance choffante ;
        R_ = 0;                 % [Ohm] Résistance des cables ;
        resSize = 0;            % [m²] Taille de la résistance ;
        Vq = 0;                 % [uV/Wm²] Coefficient de transductance ;
        lambda = 0;             % [W/mK] Conductivité thermique ;
        rho = 0;                % [kg/m³] Masse volumique ;
        cp = 0;                 % [J/kgK] Capacité thermique massique ;
        a = 0;                  % [m^2/s] Diffusivité thermique ;
        ell = 0;                % [m] Epaisseur de la plaque ;
        Ytr_arr = 0;            % [uV/K] Coeff. du thermocouple (arr.) ;
        Ytr_avant = 0;          % [uV/K] Coeff. du thermocouple (avan.) ;
    end
    % ---------------------------------------------------------------------

    %% Méthodes publiques -------------------------------------------------
    methods

        % Contructeur de la classe
        function obj = sysDataType(name)
            if nargin == 1
                obj.name = name;
            end
        end

        % Initialise la valeur de la résistance choffante
        function obj = set.R(obj, R)
            if (R <= 0)
                error("La valeur de la résistance doit être " + ...
                    "positive et non nulle.");
            end
            obj.R = R;
        end

        % Initialise la valeur de la résistance des cables
        function obj = set.R_(obj, R_)
            if (R_ <= 0)
                error("La valeur de la résistance doit être " + ...
                    "positive et non nulle.");
            end
            obj.R_ = R_;
        end

        % Initialise la valeur de la surface de la résistance
        function obj = set.resSize(obj, resSize)
            if (resSize <= 0)
                error("La valeur de la surface doit être " + ...
                    "positive et non nulle.");
            end
            obj.resSize = resSize;
        end

        % Initialise la valeur de la conductivité thermique
        function obj = set.lambda(obj, lambda)
            if (lambda <= 0)
                error("La valeur de la conductivité thermique doit " + ...
                    "être positive et non nulle.");
            end
            obj.lambda = lambda;
            obj = obj.setDiffusivity;
        end

        % Initialise la valeur de la surface de la masse volumique
        function obj = set.rho(obj, rho)
            if (rho <= 0)
                error("La valeur de la masse volumique doit être " + ...
                    "positive et non nulle.");
            end
            obj.rho = rho;
            obj = obj.setDiffusivity;
        end

        % Initialise la capacité thermique
        function obj = set.cp(obj, cp)
            if (cp <= 0)
                error("La valeur du cp doit être positive et non " + ...
                    "nulle.");
            end
            obj.cp = cp;
            obj = obj.setDiffusivity;
        end

        % Initialise l'paisseur du thermocouple
        function obj = set.ell(obj, ell)
            if (ell <= 0)
                error("La valeur de l'paisseur doit être positive.");
            end
            obj.ell = ell;
        end

        % Convertion des données en tension par flux de chaleur
        phi = toFlux(obj, v)

        % Configure la sortie du thermocouple de la face avant
        y = setOutputAvant(obj, in)

        % Configure la sortie du thermocouple de la face arrière
        y = setOutputArr(obj, in)

        % Prendre la surface perpendiculaire du thermocouple
        S = takeArea(obj)

        % Prendre la surface perpendiculaire de la résistance
        S = takeResArea(obj)

    end
    % ---------------------------------------------------------------------

    %% Méthodes privées ---------------------------------------------------
    methods (Hidden=true)

        % Configure la diffusivité
        function obj = setDiffusivity(obj)
            % Function de configuration de la diffusivité.
            obj.a = obj.lambda/(obj.cp*obj.rho);
        end
        
    end
    % ---------------------------------------------------------------------
end