%% CrossSolver class
%
% This classe is a Solver of Cross Process of continuous beams.
% Euler-Bernoulli flexural behavior is assumed (Navier beam theory).
%
% This file contains an implementation of the Cross Process for
% continuous beams with uniformly distributed loads in each spam.
%
% This is an iterative method that in each step the unbalanced moment
% of a node is distributed among the two adjacent member sections.
% In addition, due to this node moment balancing, carry-over portions
% of the balancing moments are transmitted to the opposite ends of the
% adjacent members.
%
% For more details of this process, refer to the book "Análise de
% Estruturas: Conceitos e Métodos Básicos", Second Edition, by Luiz
% Fernando Martha, Elsevier, 2017.
%
%% Associated classes
% The following OOP classes are associated:
%%%
% * <crossmember.html *CrossMember*> class.
% * <crossnode.html *CrossNode*> class.
%
%% Author
% Luiz Fernando Martha
%
%% History
% @version 1.02
%
% Initial version (1.00): August 2019
%%%
% Initially prepared for the course CIV 2801 - Fundamentos de Computação
% Gráfica, 2019, second term, Department of Civil Engineering, PUC-Rio.
%
% Version 1.01: October 2019
%%%
% Reset all nodes rotations in method initNodes.
% Created method resetNodeRotations.
% Added call to method resetNodeRotations in method goThruSolver.
%
% Version 1.02: October 2019
%%%
% Created the following properties:
% - maximum number of steps constant
% - current number of steps
% - vector of iterative Cross steps
%
%% Class definition
classdef CrossSolver < handle
    %%
    % <https://www.mathworks.com/help/matlab/ref/handle-class.html
    % See documentation on *handle* super-class>.
    
    %% Public attributes
    properties (SetAccess = public, GetAccess = public)
        nmemb = 0;         % number of members
        nnode = 0;         % number of balanced (interior) nodes
        membs = [];        % vector of members
        nodes = [];        % vector of nodes
        supinit = 0;       % left end support condition
        supend = 1;        % right end support condition
        totalLen = 0;      % total length
        decplc = 1;        % number of decimal places for moments
        numSteps = 0;      % number of iterative Cross steps
        stepVector = [];   % vector of Cross steps
    end
    
    %% Class (constant) properties
    properties (Constant)
        maxNumSteps = 50;   % maximum number of iterative Cross steps
    end
    
    %% Constructor method
    methods
        %------------------------------------------------------------------
        function cross = CrossSolver(nmemb,supinit,supend,decplc,EI,len,q)
            if (nargin > 0)
                cross.nmemb = nmemb;
                cross.nnode = nmemb - 1;
                membs(1,cross.nmemb) = CrossMember();
                for i = 1:cross.nmemb
                    membs(i).EI = EI(i);
                    membs(i).len = len(i);
                    membs(i).q = q(i);
                end
                cross.membs = membs;
                nodes(1,cross.nnode) = CrossNode();
                cross.nodes = nodes;
                cross.supinit = supinit;
                cross.supend = supend;
                cross.decplc = decplc;
            else
                cross.nmemb = 3;
                cross.nnode = 2;
                membs(1,cross.nmemb) = CrossMember();
                membs(1).EI = 10000;
                membs(1).len = 8;
                membs(1).q = 8;
                membs(2).EI = 10000;
                membs(2).len = 6;
                membs(2).q = 38;
                membs(3).EI = 10000;
                membs(3).len = 6;
                membs(3).q = 28;
                cross.membs = membs;
                nodes(1,cross.nnode) = CrossNode();
                cross.nodes = nodes;
                cross.supinit = 0;
                cross.supend = 1;
                cross.decplc = 1;
            end
            cross.initStiffness();
            cross.initNodes();
            cross.updateTotalLen();
            cross.numSteps = 0;
            stepVector(1,cross.maxNumSteps) = CrossStep();
            cross.stepVector = stepVector;
        end
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        % Initializes member stiffness coefficients.
        function cross = initStiffness(cross)
            if cross.supinit == 0
                %%%%%%% COMPLETE HERE - CROSS_SOLVER: 01 %%%%%%%
                cross.membs(1).k = 3 * cross.membs(1).EI / cross.membs(1).len;
            elseif cross.supinit == 1
                %%%%%%% COMPLETE HERE - CROSS_SOLVER: 02 %%%%%%%
                cross.membs(1).k = 4 * cross.membs(1).EI / cross.membs(1).len;
            else % Extremidade livre
                cross.membs(1).k = 0;
            end
            
            if cross.supend == 0
                %%%%%%% COMPLETE HERE - CROSS_SOLVER: 03 %%%%%%%
                cross.membs(cross.nmemb).k = 3 * cross.membs(cross.nmemb).EI / cross.membs(cross.nmemb).len;
            elseif cross.supend == 1
                %%%%%%% COMPLETE HERE - CROSS_SOLVER: 04 %%%%%%%
                cross.membs(cross.nmemb).k = 4 * cross.membs(cross.nmemb).EI / cross.membs(cross.nmemb).len;
            else % Extremidade livre
                cross.membs(cross.nmemb).k = 0;
            end
            
            for i = 2:cross.nmemb-1
                %%%%%%% COMPLETE HERE - CROSS_SOLVER: 05 %%%%%%%
                cross.membs(i).k = 4 * cross.membs(i).EI / cross.membs(i).len;
                %%%%%%% COMPLETE HERE - CROSS_SOLVER: 05 %%%%%%%
            end
        end
        
        %------------------------------------------------------------------
        % Initializes nodes: compute moment distribution coefficients and
        % carry-over factors.
        function cross = initNodes(cross)
            % Compute moment distribution coefficients of each node
            for i = 1:cross.nnode
                %%%%%%% COMPLETE HERE - CROSS_SOLVER: 06 %%%%%%%
                cross.nodes(i).dl = cross.membs(i).k / (cross.membs(i).k + cross.membs(i+1).k);
                cross.nodes(i).dr = cross.membs(i+1).k / (cross.membs(i).k + cross.membs(i+1).k);
                cross.nodes(i).rot = 0;
                %%%%%%% COMPLETE HERE - CROSS_SOLVER: 06 %%%%%%%
            end
            
            % Compute moment transmission coefficients of each node
            for i = 1:cross.nnode
                %%%%%%% COMPLETE HERE - CROSS_SOLVER: 07 %%%%%%%
                cross.nodes(i).tl = 1/2;
                cross.nodes(i).tr = 1/2;
                %%%%%%% COMPLETE HERE - CROSS_SOLVER: 07 %%%%%%%
            end
            if cross.supinit == 0 || cross.supinit == 2
                %%%%%%% COMPLETE HERE - CROSS_SOLVER: 08 %%%%%%%
                cross.nodes(1).tl = 0;
                %%%%%%% COMPLETE HERE - CROSS_SOLVER: 08 %%%%%%%
            end
            if cross.supend == 0 || cross.supinit == 2
                %%%%%%% COMPLETE HERE - CROSS_SOLVER: 09 %%%%%%%
                cross.nodes(end).tr = 0;
                %%%%%%% COMPLETE HERE - CROSS_SOLVER: 09 %%%%%%%
            end
        end
        
        %------------------------------------------------------------------
        % Sets number of decimal places for moments.
        % Input arguments:
        %  decplc: number of decimal places for moments.
        function cross = setMomentToler(cross,decplc)
            cross.decplc = decplc;
        end
        
        %------------------------------------------------------------------
        % Initializes member moments with fixed end values.
        function cross = initMoments(cross)
            len = cross.membs(1).len;
            len2 = len * len;
            q = cross.membs(1).q;
            if cross.supinit == 0
                %%%%%%% COMPLETE HERE - CROSS_SOLVER: 10 %%%%%%%
                cross.membs(1).ml = 0;
                cross.membs(1).mr = - q * len2 / 8;
                %%%%%%% COMPLETE HERE - CROSS_SOLVER: 10 %%%%%%%
            elseif cross.supinit == 1
                %%%%%%% COMPLETE HERE - CROSS_SOLVER: 11 %%%%%%%
                cross.membs(1).ml = q * len2 / 12;
                cross.membs(1).mr = - q * len2 / 12;
                %%%%%%% COMPLETE HERE - CROSS_SOLVER: 11 %%%%%%%
            else
                cross.membs(1).ml = 0;
                cross.membs(1).mr = - q * len2 / 2;
            end
            
            len = cross.membs(cross.nmemb).len;
            len2 = len * len;
            q = cross.membs(cross.nmemb).q;
            if cross.supend == 0
                %%%%%%% COMPLETE HERE - CROSS_SOLVER: 12 %%%%%%%
                cross.membs(cross.nmemb).ml = q * len2 / 8;
                cross.membs(cross.nmemb).mr = 0;
                %%%%%%% COMPLETE HERE - CROSS_SOLVER: 12 %%%%%%%
            elseif cross.supend == 1
                %%%%%%% COMPLETE HERE - CROSS_SOLVER: 13 %%%%%%%
                cross.membs(cross.nmemb).ml = q * len2 / 12;
                cross.membs(cross.nmemb).mr = - q * len2 / 12;
                %%%%%%% COMPLETE HERE - CROSS_SOLVER: 13 %%%%%%%
            else
                cross.membs(cross.nmemb).ml = q * len2 / 2;
                cross.membs(cross.nmemb).mr = 0;
            end
            
            for i = 2:cross.nmemb-1
                len = cross.membs(i).len;
                len2 = len * len;
                q = cross.membs(i).q;
                %%%%%%% COMPLETE HERE - CROSS_SOLVER: 14 %%%%%%%
                cross.membs(i).ml = q * len2 / 12;
                cross.membs(i).mr = -q * len2 / 12;
                %%%%%%% COMPLETE HERE - CROSS_SOLVER: 14 %%%%%%%
            end
            
            % Reset number of iterative Cross steps
            cross.numSteps = 0;
        end
        
        %------------------------------------------------------------------
        % Reset all nodes rotations.
        function resetNodeRotations(cross)
            for i = 1:cross.nnode
                cross.nodes(i).rot = 0;
            end
        end
        
        %------------------------------------------------------------------
        % Update total continous beam length.
        function updateTotalLen(cross)
            cross.totalLen = 0;
            for i = 1:cross.nmemb
                cross.totalLen = cross.totalLen + cross.membs(i).len;
            end
        end
        
        %------------------------------------------------------------------
        % Checks if node is unbalanced
        function flag = isNodeUnbalanced(cross,n)
            momtol = 10^-(cross.decplc+1);  % tol. for check unbalanced moment 
            unbal = cross.membs(n).mr + cross.membs(n+1).ml;
            if abs(unbal) > momtol
                flag = true;
            else
                flag = false;
            end
        end
        
        %------------------------------------------------------------------
        % Gets the node of continuous beam that has the maximum absolute
        % value of unbalanced moment.
        % Output:
        %  n: index of the found node. If all the nodes have unbalanced
        %     moment value below current moment tolerance, returns a
        %     non-valid null (0) index.
        function n = getMaxUnbalNode(cross)
            momtol = 10^-(cross.decplc+1);  % tol. for check unbalanced moment
            maxunbal = momtol;  
            n = 0;
            for i = 1:cross.nnode
            unbal = cross.membs(i).mr + cross.membs(i+1).ml;
                if abs(unbal) > maxunbal
                    n = i;
                    maxunbal = abs(unbal);
                end
            end
        end
        
        %------------------------------------------------------------------
        % Performs one iterative step of the Cross Process of a continuous
        % beam.  Distributes the unbalanced moment of a given node among
        % the two adjacent beam sections.  Transmits the carry-over
        % portions of the balancing moments to the opposite ends of the
        % adjacent members.
        % Input arguments:
        %  n: is the index of the target node to be processed
        function cross = processNode(cross,n)
            % unbal: unbalanced moment
            % bml:   balancing moment at left of node
            % bmr:   balancing moment at right of node
            % tml:   carry-over moment at left of node
            % tmr:   carry-over moment at right of node
            % drot:  node rotation increment

            %%%%%%% COMPLETE HERE - CROSS_SOLVER: 15 %%%%%%%
            unbal = cross.membs(n).mr + cross.membs(n+1).ml;
            bml = -unbal * cross.nodes(n).dl;
            bmr = -unbal * cross.nodes(n).dr;
            tml = bml * cross.nodes(n).tl;
            tmr = bmr * cross.nodes(n).tr;
            
            cross.membs(n).mr = cross.membs(n).mr + bml;
            cross.membs(n).ml = cross.membs(n).ml + tml;
            cross.membs(n+1).mr = cross.membs(n+1).mr + tmr;
            cross.membs(n+1).ml = cross.membs(n+1).ml + bmr;
            %%%%%%% COMPLETE HERE - CROSS_SOLVER: 15 %%%%%%%
 
            % Increment iterative Cross step vector
            cross.numSteps = cross.numSteps + 1;
            cross.stepVector(cross.numSteps).n = n;
            cross.stepVector(cross.numSteps).bml = bml;
            cross.stepVector(cross.numSteps).bmr = bmr;
            cross.stepVector(cross.numSteps).tml = tml;
            cross.stepVector(cross.numSteps).tmr = tmr;
            cross.stepVector(cross.numSteps);
            
            % Update node rotation
            drot = - unbal / (cross.membs(n).k + cross.membs(n+1).k);
            cross.nodes(n).rot = cross.nodes(n).rot + drot;
       end
        
        %------------------------------------------------------------------
        % Solves one step of Cross Process for continuous beams for a given
        % node. If the node index is not valid, returns a false (0) status
        % flag. If the target node unbalaced moment absolute value is 
        % less than the current moment tolerance, returns a false (0)
        % status flag. Otherwise returns a true (1) status flag.
        % Input arguments:
        %  n: is the index of the target node to be processed
        function status = nodeStepSolver(cross,n)
            status = 0;
            if n < 1 || n > cross.nnode
                return
            end

            momtol = 10^-(cross.decplc+1);  % tol. for check unbalanced moment

            unbal = cross.membs(n).mr + cross.membs(n+1).ml;
            if abs(unbal) < momtol
                return
            end
            
            cross.processNode(n);
            status = 1;
        end
        
        %------------------------------------------------------------------
        % Checks to see whether there is more Cross steps to go: returns a
        % true (1) status if there is at least one step to go; returns a
        % false (1) status otherwise.
        function status = moreStepsToGo(cross)
            status = 0;
            n = cross.getMaxUnbalNode();
            if n > 0
                status = 1;
            end
        end
        
        %------------------------------------------------------------------
        % Solves one step of Cross Process for continuous beams: solve the
        % node with maximum absolute value of unbalanced moment.
        function status = autoStepSolver(cross)
            status = 0;
            n = cross.getMaxUnbalNode();
            if n > 0
                cross.processNode(n);
                status = 1;
            end
        end
        
        %------------------------------------------------------------------
        % Processes direct solver of Cross Process for continuous beams.
        function cross = goThruSolver(cross)
            cross.initMoments();
            cross.resetNodeRotations();
            while cross.autoStepSolver() ~= 0
                
            end
        end
        
        %------------------------------------------------------------------
        % Prints continuous beam model information.
        % Input arguments:
        %  out: integer identifier of the output text file
        function cross = printModelInfo(cross,out)
            fprintf(out, '\n=========================================================\n');
            fprintf(out, '         CROSS - Cross Process of Continuous Beam\n');
            fprintf(out, '    PONTIFICAL CATHOLIC UNIVERSITY OF RIO DE JANEIRO\n');
            fprintf(out, '   DEPARTMENT OF CIVIL AND ENVIRONMENTAL ENGINEERING\n');
            fprintf(out, '                            \n');
            fprintf(out, '   CIV2801 - FUNDAMENTOS DE COMPUTACAO GRAFICA APLICADA\n');
            fprintf(out, '=========================================================\n');
            
            fprintf(out, '\n\n\n____________ M O D E L  I N F O R M A T I O N ____________\n');
            
            fprintf(out, ' MEMBERS  EI [kNm^2]    HINGEi HINGEf  LENGTH [m]  Distrib. Load [kN/m]\n');
            for i = 1:cross.nmemb
                if i == 1 && cross.supinit == 0
                    hingei = 'yes';
                else
                    hingei = 'no';
                end
                
                if i == cross.nmemb && cross.supend == 0
                    hingef = 'yes';
                else
                    hingef = 'no';
                end
                EI = cross.membs(i).EI;
                len = cross.membs(i).len;
                q = cross.membs(i).q;
                fprintf(out, '%5d  %9d %12s %6s  %6.2f %15.2f\n', ...
                            i, EI, hingei, hingef, len, q);
            end
        end
        
        %------------------------------------------------------------------
        % Prints analysis results.
        % Input arguments:
        %  out: integer identifier of the output text file
        function cross = printResults(cross,out)

            fprintf(out, '\n_____________ A N A L Y S I S  R E S U L T S _____________\n');

            fprintf(out, ' MEMBERS      Mom.Init [kNm]   Mom.End [kNm]\n');
            for i = 1:cross.nmemb
                ml = cross.membs(i).ml;
                mr = cross.membs(i).mr;
                ml_txt = sprintf('%.*f',cross.decplc,ml);
                mr_txt = sprintf('%.*f',cross.decplc,mr);
                fprintf(out, '%5d %15s %16s\n', i, ml_txt, mr_txt);
            end
        end

        function EIs = getEIMembers(cross)
            EIs = zeros(1,cross.nmemb);
            for n = 1:cross.nmemb
                EIs(n) = cross.membs(n).EI;
            end
        end
        
        
        function lens = getLenMembers(cross)
            lens = zeros(1,cross.nmemb);
            for n = 1:cross.nmemb
                lens(n) = cross.membs(n).len;
            end
        end
        
        
        function qs = getQMembers(cross)
            qs = zeros(1,cross.nmemb);
            for n = 1:cross.nmemb
                qs(n) = cross.membs(n).q;
            end
        end
        
        %------------------------------------------------------------------
        % Cleans data structure of a CrossSolver object.
        function cross = clean(cross)
            cross.nmemb = 0;
            cross.nnode = 0;
            cross.membs = [];
            cross.nodes = [];
            cross.supinit = 0;
            cross.supend = 0;
            cross.totalLen = 0;
            cross.decplc = 2;
            cross.numSteps = 0;
            cross.stepVector = [];
        end
    end
end