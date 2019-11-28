%% Canvas_2D class
%
% This is a sub-class of the Canvas class, to deal especifically with axes
% that present only 2D behavior, on the Cross process app.
%
%% Authors
%%%
% * Pedro Cortez F Lopes (pedrocortez@id.uff.br)
%%%
% * Rafael Lopez Rangel (rafaelrangel@tecgraf.puc-rio.br)
%%%
% * Luiz Fernando Martha (lfm@tecgraf.puc-rio.br)
%
%% History
% @version 1.01
%
% Initial version (1.00): September 2019
%%%
% Initially prepared for the course CIV 2801 - Fundamentos de Computação
% Gráfica, 2019, second term, Department of Civil Engineering, PUC-Rio.
%
% Version 1.01: October 2019
%%%
% Created private properties control, firstPosition, and
% firstPositionGiven.
% Added fourth argument (control) to constructor method.
% Implemented mouse callback methods (onButtonDown, onButtonUp, and
% onMouseMove, which call corresponding methods of CrossControl object.
%
%% Class definition
classdef Canvas_2D < Canvas
    %% Public properties - mouse events
    properties (Access = public)
        control = [];               % handle to Cross control object
        firstPosition = [];         % x and y coordinates of the first pointer position.
        firstPositionGiven = false; % flag indicating that first point was selected.
    end

    %% Constructor method
    methods
        function this = Canvas_2D(ax,fig,fcn,control)
            if (nargin == 0)
                ax  = [];
                fig = [];
                fcn = [];
            elseif (nargin <= 2)
                fcn = [];
            end
            this = this@Canvas(ax,fig,fcn);
            this.control = control;
            this.ax.XLimMode = 'manual';
            this.ax.YLimMode = 'manual';
        end
    end
    
    %% Public methods
    % Implementation of the abstract methods declared in super-class Canvas.
    methods
        %------------------------------------------------------------------
        % Fits axis limits to display everything drawn on canvas
        function fit2view(this,bBox)
            % Compute canvas height/width ratio
            h_w = this.ax.Position(4)/this.ax.Position(3);
            
            % Check if a bounding box was already provided
            if (nargin == 2)
                if ~isempty(bBox)
                    % Get x and y vectors
                    x = [bBox(1),bBox(3)]; x = [min(x) max(x)];
                    y = [bBox(2),bBox(4)]; y = [min(y) max(y)];
                    
                    % Compute window sizes based on model bounding box size
                    % increased by current free border factor.
                    % Place window center at model bounding box center pos.
                    %%%%% COMPLETE HERE - CANVAS_2D: 01a %%%%%
                    Lx = diff(x) * (1.0 + this.freeBorder); Mx = mean(x);
                    Ly = diff(y) * (1.0 + this.freeBorder); My = mean(y);
                    %%%%% COMPLETE HERE - CANVAS_2D: 01a %%%%%
                    y_x = Ly / Lx;
                    
                    % If axIsEq, make sure bound box fits while respecting
                    % proportional limits
                    if this.axIsEq
                    %%%%% COMPLETE HERE - CANVAS_2D: 02a %%%%%
                        if y_x > h_w
                            Lx = Ly / h_w;
                        else
                            Ly = Lx * h_w;
                        end
                    %%%%% COMPLETE HERE - CANVAS_2D: 02a %%%%%
                    end
                    
                    % Set limits and return
                    %%%%% COMPLETE HERE - CANVAS_2D: 03a %%%%%
                    this.ax.XLim = Mx + 0.5*[-Lx,Lx];
                    this.ax.YLim = My + 0.5*[-Ly,Ly];
                    %%%%% COMPLETE HERE - CANVAS_2D: 03a %%%%%
                    return;
                end
            end
            
            % Get list of handles to graphic objects drawn on this.ax
            plots = this.ax.Children;
            
            % If there is nothing drawn on this.ax, return
            if isempty(plots)
                if ~this.axIsEq
                    this.ax.XLim = [-5,5];
                    this.ax.YLim = [-5,5];
                elseif h_w > 1
                    this.ax.XLim = [-5,5];
                    this.ax.YLim = [-5*h_w,5*h_w];
                else
                    this.ax.XLim = [-5/h_w,5/h_w];
                    this.ax.YLim = [-5,5];
                end
                return
            end
            
            % Get maximum and minimum coordinates
            if ~strcmp(plots(1).Type,'text')
                xmax = max(plots(1).XData);
                xmin = min(plots(1).XData);
                ymax = max(plots(1).YData);
                ymin = min(plots(1).YData);
            else
                xmax = max(plots(1).Position(1));
                xmin = min(plots(1).Position(1));
                ymax = max(plots(1).Position(2));
                ymin = min(plots(1).Position(2));
            end
            
            for i = 2:length(plots)
                if ~strcmp(plots(i).Type,'text')
                    xmax = max([xmax,max(plots(i).XData)]);
                    xmin = min([xmin,min(plots(i).XData)]);
                    ymax = max([ymax,max(plots(i).YData)]);
                    ymin = min([ymin,min(plots(i).YData)]);
                else
                    xmax = max([xmax,max(plots(i).Position(1))]);
                    xmin = min([xmin,min(plots(i).Position(1))]);
                    ymax = max([ymax,max(plots(i).Position(2))]);
                    ymin = min([ymin,min(plots(i).Position(2))]);
                end
            end
            
            % Compute window sizes based on model bounding box size
            % increased by current free border factor.
            % Place window center at model bounding box center position
            %%%%% COMPLETE HERE - CANVAS_2D: 01b %%%%%
            Lx = (xmax - xmin) * (1.0 + this.freeBorder);
            Mx = (xmax + xmin) * 0.5;
            
            Ly = (ymax - ymin) * (1.0 + this.freeBorder);
            My = (ymax + ymin) * 0.5;
            %%%%% COMPLETE HERE - CANVAS_2D: 01b %%%%%
            
            y_x = Ly/Lx;
            
            % Adjust window limits such that window rectangle has same
            % aspect ratio of viewport rectangle
            if this.axIsEq
            %%%%% COMPLETE HERE - CANVAS_2D: 02b %%%%%
                if y_x > h_w
                    Lx = Ly / h_w;
                else
                    Ly = Lx * h_w;
                end
            %%%%% COMPLETE HERE - CANVAS_2D: 02b %%%%%
            end
            
            % Compute adjusted window limits
            %%%%% COMPLETE HERE - CANVAS_2D: 03b %%%%%
            xmin = Mx - (Lx * 0.5);
            xmax = Mx + (Lx * 0.5);
            
            ymin = My - (Ly * 0.5);
            ymax = My + (Ly * 0.5);
            %%%%% COMPLETE HERE - CANVAS_2D: 03b %%%%%
            
            this.ax.XLim = [xmin,xmax];
            this.ax.YLim = [ymin,ymax];
        end
        
        %------------------------------------------------------------------
        % Mouse button down callback - related to axes object
        % Input:
        % * this  = handle to this canvas object
        % * obj   = handle to graphical object that was clicked on
        % * event = struct with event data
        function ax_onButtonDown(~,~,~)
        end
        
        %------------------------------------------------------------------
        % Mouse button down callback - generic callback, called from an
        % Emouse object.
        % Input:
        % * this  = handle to this canvas object
        % * pt    = current cursor coordinates
        % * whichMouseButton = 'left', 'right', 'center', 'double click'
        function onButtonDown(this,pt,whichMouseButton)
            switch whichMouseButton
                case 'left'
                    % Store first position coordinates
                    this.firstPosition = pt;
                    
                    % Set boolean flag
                    this.firstPositionGiven = true;
                    
                    % Call Cross control button down method
                    this.control.onButtonDown(this,pt);
            end
        end
        
        %------------------------------------------------------------------
        % Mouse button up callback - generic callback, called from an
        % Emouse object.
        % Input:
        % * this  = handle to this canvas object
        % * pt    = current cursor coordinates
        % * whichMouseButton = 'left', 'right', 'center', 'double click'
        function onButtonUp(this,pt,~)
            % Call Cross control button up method
            this.control.onButtonUp(this,pt);

            % Set boolean flag
            this.firstPositionGiven = false;
        end
        
        %------------------------------------------------------------------
        % Mouse move callback - generic callback, called from an
        % Emouse object.
        % Input:
        % * this  = handle to this canvas object
        % * pt    = current cursor coordinates
        function onMouseMove(this,pt)
            % Check if mouse is collecting second point
            if this.firstPositionGiven
                % Check if second point is different from first
                if all(this.firstPosition(1:2,1) ~= pt(1:2,1))                    
                    % Call Cross control mouse move method
                    this.control.onMouseMove(this,pt);
                end
            end
        end
        
        %------------------------------------------------------------------
        % Mouse scroll callback - generic callback, called from an
        % Emouse object.
        % Input:
        % * this  = handle to this canvas object
        % * pt    = current cursor coordinates
        function onMouseScroll(~,~)
        end
    end
end