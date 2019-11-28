%% CrossMember class
%
% This class defines a member of a continuous beam for the Cross Process.
% Euler-Bernoulli flexural behavior is assumed (Navier beam theory).
%
% See definition of <crosssolver.html *CrossSolver*> class.
%
%% Author
% Luiz Fernando Martha
%
%% History
% @version 1.00
%
% Initial version: August 2019
%%%
% Initially prepared for the course CIV 2801 - Fundamentos de Computação
% Gráfica, 2019, second term, Department of Civil Engineering, PUC-Rio.
%
%% Class definition
classdef CrossMember < handle
    %%
    % <https://www.mathworks.com/help/matlab/ref/handle-class.html
    % See documentation on *handle* super-class>.
    
    %% Public attributes
    properties (SetAccess = public, GetAccess = public)
        EI = 0;            % flexural stiffness
        len = 0;           % member length
        q = 0;             % vertical distributed load (top-down positive)
        ml = 0;            % left end moment
        mr = 0;            % right end moment
        k = 0;             % rotational stiffness coefficient
    end
    
    %% Constructor method
    methods
        %------------------------------------------------------------------
        function memb = CrossMember(EI,len,q)
            if (nargin > 0)
                memb.EI = EI;
                memb.len = len;
                memb.q = q;
                memb.ml = 0;
                memb.mr = 0;
                memb.k = 0;
            end
        end
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        % Cleans data structure of a CrossMember object.
        function memb = clean(memb)
            memb.EI = 0;
            memb.len = 0;
            memb.q = 0;
            memb.ml = 0;
            memb.mr = 0;
            memb.k = 0;
        end
    end
end