%% CrossNode class
%
% This class defines a node of a continuous beam for the Cross Process.
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
classdef CrossNode < handle
    %%
    % <https://www.mathworks.com/help/matlab/ref/handle-class.html
    % See documentation on *handle* super-class>.
    
    %% Public attributes
    properties (SetAccess = public, GetAccess = public)
        dl = 0;            % left moment distribution coefficient
        dr = 0;            % right moment distribution coefficient
        tl = 0;            % left moment carry-over (transmission) factor
        tr = 0;            % right moment carry-over (transmission) factor
        rot = 0;           % node rotation
    end
    
    %% Constructor method
    methods
        %------------------------------------------------------------------
        function node = CrossNode(dl,dr,tl,tr,rot)
            if (nargin > 0)
                node.dl = dl;
                node.dr = dr;
                node.tl = tl;
                node.tr = tr;
                node.rot = rot;
            end
        end
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        % Cleans data structure of a CrossNode object.
        function node = clean(node)
            node.dl = 0;
            node.dr = 0;
            node.tl = 0;
            node.tr = 0;
            node.rot = 0;
        end
    end
end