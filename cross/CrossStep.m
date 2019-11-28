%% CrossStep class
%
% This class defines a step of the Cross Process for continuous beam.
%
% See definition of <crosssolver.html *CrossSolver*> class.
%
%% Author
% Luiz Fernando Martha
%
%% History
% @version 1.00
%
% Initial version: October 2019
%%%
% Initially prepared for the course CIV 2801 - Fundamentos de Computação
% Gráfica, 2019, second term, Department of Civil Engineering, PUC-Rio.
%
%% Class definition
classdef CrossStep < handle
    %%
    % <https://www.mathworks.com/help/matlab/ref/handle-class.html
    % See documentation on *handle* super-class>.
    
    %% Public attributes
    properties (SetAccess = public, GetAccess = public)
        n = 0;     % index of an interior node that is balanced in a step
        bml = 0;   % balancing moment at left of node
        bmr = 0;   % balancing moment at right of node
        tml = 0;   % carry-over moment at left of node
        tmr = 0;   % carry-over moment at right of node
    end
    
    %% Constructor method
    methods
        %------------------------------------------------------------------
        function step = CrossStep(n,bml,bmr,tml,tmr)
            if (nargin > 0)
                step.n = n;
                step.bml = bml;
                step.bmr = bmr;
                step.tml = tml;
                step.tmr = tmr;
            end
        end
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        % Cleans data structure of a CrossStep object.
        function step = clean(step)
            step.n = 0;
            step.bml = 0;
            step.bmr = 0;
            step.tml = 0;
            step.tmr = 0;
        end
    end
end