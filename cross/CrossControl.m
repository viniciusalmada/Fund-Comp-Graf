%% CrossControl class
%
% This class implements methods to control the analysis of continuous
% beams by the Cross process.
%
%% Author
% Luiz Fernando Martha
%
%% History
% @version 1.02
%
% Initial version (1.00): September 2019
%%%
% Initially prepared for the course CIV 2801 - Fundamentos de Computação
% Gráfica, 2019, second term, Department of Civil Engineering, PUC-Rio.
%
% Version 1.01: October 2019
%%%
% Several modifications and improvements:
% - Creation of private methods updateDraw and resetSolver.
% - Initialization of MouseEvents object, whose handle is stored as a
%   private property.
% - Implementation of methods openFile and saveFile.
% - Implemented mouse callback methods (onButtonDown, onButtonUp, and
%   onMouseMove.
%
% Version 1.02: October 2019
%%%
% Implementation of iterative Cross solution canvas.
%
%% Class definition
classdef CrossControl < handle
    %% Public properties
    properties (Access = public)
        solver = []; % handle to Cross solver object
    end
    
    %% Private properties
    properties (Access = private)
        app = []; % handle to GUI app object
        draw = []; % handle to CrossDraw object
        canvas_model = []; % handle to model canvas
        canvas_deformed = []; % handle to deformed configuration canvas
        canvas_moment = []; % handle to bending moment canvas
        canvas_iterativesolution = []; % handle to iterative solution canvas
        mouse_events = []; % handle to mouse events object
        inserting_sup = false; % flag for inserting support mode
        deleting_sup = false; % flag for deleting support mode
        changing_load = false; % flag for changing load mode
        moving_sup = false; % flag for moving support
    end
    
    %% Constructor method
    methods
        %------------------------------------------------------------------
        function control = CrossControl(app)
            if (nargin > 0)
                control.app = app;
            end
        end
    end
    
    %% Private methods
    methods (Access = private)
        %------------------------------------------------------------------
        % Update Cross draw object
        function updateDraw(control)
            % Create cross draw object passing solver object to it.
            crossdraw = CrossDraw(control.solver);
            control.draw = crossdraw;
            
            % Provide handle to functions that updates display of all canvas
            control.canvas_model.setUpdateFcn(@crossdraw.model);
            control.canvas_deformed.setUpdateFcn(@crossdraw.deformedConfig);
            control.canvas_moment.setUpdateFcn(@crossdraw.bendingMomDiagram);
            control.canvas_iterativesolution.setUpdateFcn(@crossdraw.interativeSolution);
            
            % Provide handle to function that returns model bounding box for all canvas
            control.canvas_model.setBoundBoxFcn(@crossdraw.crossBoundBox);
            control.canvas_deformed.setBoundBoxFcn(@crossdraw.crossBoundBox);
            control.canvas_moment.setBoundBoxFcn(@crossdraw.crossBoundBox);
            control.canvas_iterativesolution.setBoundBoxFcn(@crossdraw.crossBoundBox);
        end
        
        %------------------------------------------------------------------
        % Reset Cross solver
        function resetSolver(control,nmemb,supinit,supend,decplc,EI,len,q)
            % Clean current Cross model if it exists
            if ~isempty(control.solver)
                control.solver.clean();
            end
            
            % Create new Cross solver model and initialize it
            if (nargin == 1)
                control.solver = CrossSolver();
            else
                control.solver = CrossSolver(nmemb,supinit,supend,decplc,EI,len,q);
            end
            control.solver.initStiffness();
            control.solver.initNodes();
            control.solver.initMoments();
            
            % Update cross draw object
            control.updateDraw();
            
            % Update init and end support icons
            control.app.updateSupInit(control.solver.supinit);
            control.app.updateSupEnd(control.solver.supend);
            
            % Update display of canvases
            control.canvas_model.update();
            control.canvas_deformed.update();
            control.canvas_moment.update();
            control.canvas_iterativesolution.update();
            
            % Print model data and initial bending moments
            control.solver.printModelInfo(1);
            control.solver.printResults(1);
        end
        
        %------------------------------------------------------------------
        % Insert an internal support in the continuous beam model.
        % It is assumed that the given support position an is valid.
        % Input:
        % m: member index in which internal support is inserted
        % pos: position of inserted support inside member
        function insertSup(control,m,pos)
            %%%%%%% COMPLETE HERE - CROSS_CONTROL: 08 %%%%%%%
            nmemb = control.solver.nmemb + 1;
            supinit = control.solver.supinit;
            supend = control.solver.supend;
            decplc = control.solver.decplc;
            EI = control.solver.getEIMembers;
            len = control.solver.getLenMembers;
            q = control.solver.getQMembers;
            
            lenMembPicked = len(m);
            len(m) = pos;
            
            newMemb = CrossMember();
            newMemb.len = lenMembPicked - pos;
            newMemb.q = q(m);
            newMemb.EI = EI(m);
            
            EI = [EI(1:m) newMemb.EI EI(m+1:end)];
            len = [len(1:m) newMemb.len len(m+1:end)];
            q = [q(1:m) newMemb.q q(m+1:end)];
            control.resetSolver(nmemb,supinit,supend,decplc,EI,len,q);
            %%%%%%% COMPLETE HERE - CROSS_CONTROL: 08 %%%%%%%
        end
        
        %------------------------------------------------------------------
        % Delete an internal support from the continuous beam model.
        % If there is only one interior support, it will not be deleted.
        % Input:
        % n: index of internal support to delete (from 1 to nnode)
        function deleteSup(control,n)
            if control.solver.nnode == 1
                return
            end
            
            %%%%%%% COMPLETE HERE - CROSS_CONTROL: 09 %%%%%%%
            nmemb = control.solver.nmemb - 1;
            supinit = control.solver.supinit;
            supend = control.solver.supend;
            decplc = control.solver.decplc;
            EI = control.solver.getEIMembers;
            len = control.solver.getLenMembers;
            q = control.solver.getQMembers;
            
            membJoined = CrossMember();
            membJoined.len = len(n) + len(n+1);
            membJoined.q = mean([q(n),q(n+1)]);
            membJoined.EI = mean([EI(n),EI(n)]);
            
            EI(n) = membJoined.EI;
            EI(n+1) = [];
            len(n) = membJoined.len;
            len(n+1) = [];
            q(n) = membJoined.q;
            q(n+1) = [];
            
            control.resetSolver(nmemb,supinit,supend,decplc,EI,len,q);
            %%%%%%% COMPLETE HERE - CROSS_CONTROL: 09 %%%%%%%
        end
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        % Start up Cross program. Create a Cross solver object with a
        % default continous beam model. Initialize Cross parameters and
        % beam spans with bending fixed-end  moments. Print model
        % and initial results.
        % Create Cross draw object and
        function startup(control,fig_app,ax_model,ax_deformed,ax_moment,ax_iterativesolution)
            % Create model canvas
            control.canvas_model = Canvas_2D(ax_model,fig_app,[],control);
            control.canvas_model.Ruler( false );
            
            % Create deformed configuration canvas
            control.canvas_deformed = Canvas_2D(ax_deformed,fig_app,[],control);
            control.canvas_deformed.Ruler( false );
            
            % Create bending moment canvas
            control.canvas_moment = Canvas_2D(ax_moment,fig_app,[],control);
            control.canvas_moment.Ruler( false );
            
            
            % Create iterative solution canvas
            control.canvas_iterativesolution = Canvas_2D(ax_iterativesolution,fig_app,[],control);
            control.canvas_iterativesolution.Ruler( false );
            
            % Create default Cross solver object
            control.resetSolver();
            % Initialize object to manage mouse events
            control.mouse_events = MouseEvents(fig_app,control.canvas_model);
        end
        
        %------------------------------------------------------------------
        % Resize canvas: called when axes graphical component is resized.
        function resizeCanvas(control,ax)
            if ~isempty(ax.canvas)
                control.canvas_model.update();
                control.canvas_deformed.update();
                control.canvas_moment.update();
                control.canvas_iterativesolution.update();
            end
        end
        
        %------------------------------------------------------------------
        % Open file with continuous beam model for Cross process analysis.
        function openFile(control,filename)
            % Open file with given file name for reading
            fid = fopen(filename,'rt');
            
            % Read moment precision (number of decimal places)
            decplc = fscanf(fid,'%f',1);
            if decplc < 0 || decplc > 2
                decplc = 1;
            end
            
            % Read support boundary conditions
            bdrycnd = fscanf(fid,'%f',2);
            supinit = bdrycnd(1);
            supend = bdrycnd(2);
            
            % Read number of members and dimension arrays
            nmemb = fscanf(fid,'%f',1);
            EI = ones(1,nmemb) * 10000;
            len = zeros(1,nmemb);
            q = zeros(1,nmemb);
            
            % Read member lengths and uniform load
            for i = 1:nmemb
                membprop = fscanf(fid,'%f',2);
                len(i) = membprop(1);
                q(i) = membprop(2);
            end
            
            % Create Cross solver object with read data
            control.resetSolver(nmemb,supinit,supend,decplc,EI,len,q);
            
            % Close file
            fclose(fid);
        end
        
        %------------------------------------------------------------------
        % Save current continuous beam model for Cross process analysis in
        % a file
        function saveFile(control,filename)
            % Open file with given file name for writing
            fid = fopen(filename,'wt+');
            
            % Write moment precision (number of decimal places)
            fprintf(fid, '%d\n', control.solver.decplc);
            
            % Write support boundary conditions
            fprintf(fid, '%d  %d\n', control.solver.supinit, ...
                control.solver.supend);
            
            % Write number of members
            fprintf(fid, '%d\n', control.solver.nmemb);
            
            % Write member lengths and uniform load
            for i = 1:control.solver.nmemb
                fprintf(fid, '%d  %d\n', control.solver.membs(i).len, ...
                    control.solver.membs(i).q);
            end
            
            % Close file
            fclose(fid);
        end
        
        %------------------------------------------------------------------
        % Restart continous beam Cross analysis.
        % Initialize Cross parameters and beam spans bending with
        % fixed-end moments. Print model and initial bending moment
        % results.
        function restart(control)
            %%%%%%% COMPLETE HERE - CROSS_CONTROL: 01 %%%%%%%
            control.solver.printModelInfo(1);
            control.solver.initStiffness();
            control.solver.initNodes();
            control.solver.initMoments();
            control.solver.printResults(1);
            %%%%%%% COMPLETE HERE - CROSS_CONTROL: 01 %%%%%%%
            
            
            % Update display of result canvases
            control.canvas_deformed.update();
            control.canvas_moment.update();
            control.canvas_iterativesolution.update();
        end
        
        %------------------------------------------------------------------
        % Solves one step of Cross Process for continuous beams: solve the
        % node with maximum absolute value of unbalanced moment.
        % Print bending moment resulta after step.
        function autoStep(control)
            %%%%%%% COMPLETE HERE - CROSS_CONTROL: 02 %%%%%%%
            control.solver.autoStepSolver();
            control.solver.printResults(1);
            %%%%%%% COMPLETE HERE - CROSS_CONTROL: 02 %%%%%%%
            
            % Update display of result canvases
            control.canvas_deformed.update();
            control.canvas_moment.update();
            control.canvas_iterativesolution.update();
        end
        
        %------------------------------------------------------------------
        % Processes direct solver of Cross Process for continuous beams.
        % Print final bending moment results.
        function goThru(control)
            %%%%%%% COMPLETE HERE - CROSS_CONTROL: 03 %%%%%%%
            control.solver.goThruSolver();
            control.solver.printResults(1);
            %%%%%%% COMPLETE HERE - CROSS_CONTROL: 03 %%%%%%%
            
            % Update display of result canvases
            control.canvas_deformed.update();
            control.canvas_moment.update();
            control.canvas_iterativesolution.update();
        end
        
        %------------------------------------------------------------------
        % Set up number of decimal places for iterative Cross Process
        % of continuous beams.
        % Reprint current bending moment results.
        function setPrecision(control,decplc)
            %%%%%%% COMPLETE HERE - CROSS_CONTROL: 04 %%%%%%%
            control.solver.setMomentToler(decplc);
            control.solver.printResults(1);
            %%%%%%% COMPLETE HERE - CROSS_CONTROL: 04 %%%%%%%
            
            % Update display of moment canvas
            control.canvas_moment.update();
            control.canvas_iterativesolution.update();
        end
        
        %------------------------------------------------------------------
        % Toggle initial beam support condition and restart continous
        % beam Cross analysis.
        function toggleSupInit(control)
            %%%%%%% COMPLETE HERE - CROSS_CONTROL: 05 %%%%%%%
            if control.solver.supinit == 0
                control.solver.supinit = 1;
            else
                control.solver.supinit = 0;
            end
            control.restart();
            %%%%%%% COMPLETE HERE - CROSS_CONTROL: 05 %%%%%%%
            
            % Update display of canvases
            control.canvas_model.update();
            control.canvas_deformed.update();
            control.canvas_moment.update();
            control.canvas_iterativesolution.update();
        end
        
        %------------------------------------------------------------------
        % Toggle end beam support condition and restart continous
        % beam Cross analysis.
        function toggleSupEnd(control)
            %%%%%%% COMPLETE HERE - CROSS_CONTROL: 06 %%%%%%%
            if control.solver.supend == 0
                control.solver.supend = 1;
            else
                control.solver.supend = 0;
            end
            control.restart();
            %%%%%%% COMPLETE HERE - CROSS_CONTROL: 06 %%%%%%%
            
            % Update display of canvases
            control.canvas_model.update();
            control.canvas_deformed.update();
            control.canvas_moment.update();
            control.canvas_iterativesolution.update();
        end
        
        %------------------------------------------------------------------
        % Set insert support mode: either true or false
        function insertSupMode(control,value)
            control.inserting_sup = value;
        end
        
        %------------------------------------------------------------------
        % Set delete support mode: either true or false
        function deleteSupMode(control,value)
            control.deleting_sup = value;
        end
        %------------------------------------------------------------------
        % Mouse button down callback.
        % Input:
        % * cnv  = handle to this canvas object
        % * pt   = current cursor coordinates
        function onButtonDown(control,cnv,pt)
            if cnv == control.canvas_moment
                % Do nothing: treat event at button up mode
            elseif control.inserting_sup && cnv == control.canvas_model
                % Do nothing: treat event at button up mode
            elseif control.deleting_sup && cnv == control.canvas_model
                % Do nothing: treat event at button up mode
            elseif cnv == control.canvas_model
                stat = control.draw.pickMemberLoad(cnv.getContext(),pt);
                if stat == control.draw.MembLoadFound
                    control.changing_load = true;
                    control.moving_sup = false;
                    return
                end
                stat = control.draw.pickSupMove(cnv.getContext(),pt);
                if stat == control.draw.SupMoveFound
                    control.changing_load = false;
                    control.moving_sup = true;
                    return
                end
            end
        end
        
        %------------------------------------------------------------------
        % Mouse button up callback.
        % Input:
        % * cnv  = handle to this canvas object
        % * pt   = current cursor coordinates
        function onButtonUp(control,cnv,pt)
            if cnv == control.canvas_moment
                %%%%%%% COMPLETE HERE - CROSS_CONTROL: 07 %%%%%%%
                n = control.draw.pickInteriorSup(cnv.getContext(),pt);
                if n > 0
                    if control.solver.isNodeUnbalanced(n)
                        control.solver.processNode(n);
                        control.solver.printResults(1);
                        control.canvas_deformed.update();
                        control.canvas_moment.update();
                        control.canvas_iterativesolution.update();
                    end
                end
                %%%%%%% COMPLETE HERE - CROSS_CONTROL: 07 %%%%%%%
            elseif control.inserting_sup && cnv == control.canvas_model
                [stat,m,pos] = control.draw.pickInsertSup(pt);
                if stat == control.draw.ValidSupInsertion
                    control.insertSup(m,pos);
                    control.app.updateTextMessage();
                elseif stat == control.draw.BeamLineNotFound
                    control.app.setTextMessage('Internal support should be on the beam line.');
                elseif stat == control.draw.SupInsertionNotValid
                    control.app.setTextMessage('Internal support cannot be close to other support.');
                end
                control.app.resetInsertSup();
            elseif control.deleting_sup && cnv == control.canvas_model
                [stat,n] = control.draw.pickDeleteSup(pt);
                if stat == control.draw.ValidSupDeletion
                    control.deleteSup(n);
                    control.app.updateTextMessage();
                elseif stat == control.draw.SupDelMinNumSup
                    control.app.setTextMessage('Single interior support cannot be deleted.');
                elseif stat == control.draw.SupDelNotFound
                    control.app.setTextMessage('No interior support was found.');
                end
                control.app.resetDeleteSup();
            elseif cnv == control.canvas_model
                if control.changing_load
                    [m,q] = control.draw.setMemberLoad(cnv.getContext(),pt);
                    if m > 0
                        %%%%%%% COMPLETE HERE - CROSS_CONTROL: 10 %%%%%%%
                        control.solver.membs(m).q = q;
                        control.canvas_model.update();
                        control.restart();
                        control.app.updateTextMessage();
                        %%%%%%% COMPLETE HERE - CROSS_CONTROL: 10 %%%%%%%
                    end
                    control.changing_load = false;
                    return
                end
                if control.moving_sup
                    [n,shift] = control.draw.setSupMove(cnv.getContext(),pt);
                    if (n > 0) && (abs(shift) > 0)
                        %%%%%%% COMPLETE HERE - CROSS_CONTROL: 11 %%%%%%%
                        control.solver.membs(n).len = control.solver.membs(n).len...
                            + shift;
                        control.solver.membs(n+1).len = control.solver.membs(n+1).len...
                            - shift;
                        control.canvas_model.update();
                        control.restart();
                        control.app.updateTextMessage();
                        %%%%%%% COMPLETE HERE - CROSS_CONTROL: 11 %%%%%%%
                    end
                    control.moving_sup = false;
                    return
                end
            end
        end
        
        %------------------------------------------------------------------
        % Mouse move callback - generic callback, called from an
        % Emouse object.
        % Input:
        % * cnv  = handle to this canvas object
        % * pt   = current cursor coordinates
        function onMouseMove(control,cnv,pt)
            if cnv == control.canvas_moment
                % Do nothing: treat event at button up mode
            elseif control.inserting_sup && cnv == control.canvas_model
                % Do nothing: treat event at button up mode
            elseif control.deleting_sup && cnv == control.canvas_model
                % Do nothing: treat event at button up mode
            elseif cnv == control.canvas_model
                if control.changing_load
                    control.draw.updateMemberLoad(cnv.getContext(),pt);
                    return
                end
                if control.moving_sup
                    control.draw.updateSupMove(cnv.getContext(),pt);
                    return
                end
            end
        end
    end
end