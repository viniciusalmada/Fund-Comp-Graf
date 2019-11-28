% %% Emouse class
%
% This is an abstract class to facilitate the development of applications
% that handle mouse events on canvas (axes: the drawing area of a GUI
% application in MATLAB).
%
%% Description
%
% The abstract *Emouse* class presents, in addition to the constructor
% method, 4 private concrete methods (implemented) and 4 abstract methods
% that must be implemented by the client user. Its use is achieved by
% creating a client subclass that inherits its properties and implements
% the 4 abstract methods:
%%%
% * *downAction*: This method must be implemented with the procedures to
%                 be performed when the user presses a mouse button.
%%%
% * *moveAction*: This method must be implemented with the procedures to
%                 be performed when the user moves the mouse.
%%%
% * *upAction*: This method must be implemented with the procedures to
%               be performed when the user releases the mouse button that
%               was pressed.
%%%
% * *scrollAction*: This method must be implemented with the procedures to
%                   be performed when the user uses the mouse scroll.
%
% The constructor of the abstract *Emouse* class has 2 input arguments: 
%%%
% * The handle to the target *figure* object (dialog).
%%%
% * The handle to the initial current *axes* object (canvas) in the
%   target figure. 
%
% These arguments must be provided by the client user.
% It is possible to have more than one *axes* in the *figure*.
% The current axes is updated to the axes found at the position of the
% mouse in the button down event.
% It is assumed that the Units property of the *figure* and all their
% *axes* are consistent.
%
%% Authors
%%%
% * Emersson Duvan Torres Sánchez (emersson80@hotmail.com)
%%%
% * Luiz Fernando Martha (lfm@tecgraf.puc-rio.br)
%
%% History
% @version 2.00
%
% Initial version: October 2017
%%%
% Initially prepared for the MSc dissertation "Desenvolvimento de uma
% classe no contexto da POO para gerenciamento genérico de eventos de
% mouse em um canvas no ambiente MATLAB.
% Modified for the course CIV 2801 - Fundamentos de Computação Gráfica,
% 2017, second term, Department of Civil Engineering, PUC-Rio.
%%%
% Modified to version 2.00 in September 2019 by PCLopes 
%                                              (pedrocortez@id.uff.br)
% The property 'canvas' now might reffer to a handle to an object of the
% Canvas class, not necessarily an Axes object anymore.
%
%% Class definition
classdef Emouse < handle
    %% Protected attributes
    properties (Access = protected)
        dialog = [];                % dialog (figure) associated to mouse events.
        canvas = [];                % canvas associated to mouse events.
        mouseButtonMode = 'up';     % Button mouse states, 'up' or 'down'.
        whichMouseButton = 'none';  % 'none', 'left', 'right', 'center', or 'double click' at button mouse down.
		verticalScrollCount = 0;    % Counter for scroll.
		scrollAllowed = false;      % Flag to scroll events.
        currentPosition = [];       % x and y coordinates of the current pointer position.
    end
    
    %% Constructor method
    methods
        %------------------------------------------------------------------
        % Constructor method, intended to initialize an object of this
        % class.
        % This method associates the mouse button down, mouse move,
        % and mouse button up events on the target figure with
        % the private eButtonDown, eMouseMove, and eButtonUp methods,
        % respectively.
        % Input arguments:
        %  dlg: handle to the target figure object (dialog).
        %  cnvs: handle to the initial axes (canvas) of the target figure.
        function this = Emouse(dlg,cnvs)
            this.dialog = dlg;
            this.canvas = cnvs;
            this.dialog.WindowButtonDownFcn = @this.eButtonDown;
            this.dialog.WindowButtonMotionFcn = @this.eMouseMove;
            this.dialog.WindowButtonUpFcn = @this.eButtonUp;
            this.dialog.WindowScrollWheelFcn = @this.eUseScroll;
        end
    end
    
    %% Protected abstract methods
    methods (Abstract = true, Access = protected)
        %------------------------------------------------------------------
        % This method must be implemented by a client subclass with the
        % procedures to be performed when the user presses a mouse button.
        downAction(this)

        %------------------------------------------------------------------
        % This method must be implemented by a client subclass with the
        % procedures to be performed when when the user moves the mouse.
        moveAction(this)

        %------------------------------------------------------------------
        % This method must be implemented by a client subclass with the
        % procedures to be performed when the when the user releases the
        % mouse button that was pressed.
        upAction(this)
		
		%------------------------------------------------------------------
        % This method must be implemented by a client subclass with the
        % procedures to be performed when the when the user utilizes the
        % mouse scroll.
        scrollAction(this)
    end
    
    %% Private methods
    methods (Access = private)
        %------------------------------------------------------------------
        % This method is a callback function associated with mouse button
        % down event on the target canvas.
        % The method finds, in the list of axes (canvases) of the 
        % target figure (dialog), the axes (canvas) in which the button
        % down position is located.
        % The method also determines which button was pressed, updates the
        % whichMouseButton property with this information, sets the
        % mouseButtonMode property to down, sets the current position to
        % the mouse button down position, and calls the abstract
        % downAction method.
        function eButtonDown(this,~,~)
            units = this.dialog.Units;
            this.dialog.Units = 'pixels';
            figPt = this.dialog.CurrentPoint;
            this.dialog.Units = units;
            % Find the target canvas.
            % First check to see whether there are panel containers
            % for the canvases. It is assumed that there is only one
            % canvas per panel.
            allPanelsInFigure = findobj(this.dialog,'Type','uipanel');
            if size(allPanelsInFigure,1) > 0
                for i=1:size(allPanelsInFigure,1)
                    units = allPanelsInFigure(i).Units;
                    allPanelsInFigure(i).Units = 'pixels';
                    limits = allPanelsInFigure(i).Position;
                    allPanelsInFigure(i).Units = units;
                    left = limits(1);
                    right = limits(1) + limits(3);
                    bottom = limits(2);
                    top = limits(2) + limits(4);
                    if (figPt(1) >= left && figPt(1) <= right && ...
                        figPt(2) >= bottom && figPt(2) <= top)
                        AxesInPanel = findobj(allPanelsInFigure(i),'Type','axes');
                        try
                            this.canvas = AxesInPanel(1).canvas;
                        catch
                            this.canvas = AxesInPanel(1);
                        end
                        break
                    end
                end
            else
            % If the canvases are not inside panel containers, find 
            % target canvas directly in dialog.
                allAxesInFigure = findobj(this.dialog,'Type','axes');
                for i=1:size(allAxesInFigure,1)
                    units = allAxesInFigure(i).Units;
                    allAxesInFigure(i).Units = 'pixels';
                    limits = allAxesInFigure(i).Position;
                    allAxesInFigure(i).Units = units;
                    left = limits(1);
                    right = limits(1) + limits(3);
                    bottom = limits(2);
                    top = limits(2) + limits(4);
                    if (figPt(1) >= left && figPt(1) <= right && ...
                        figPt(2) >= bottom && figPt(2) <= top)
                        try
                            this.canvas = allAxesInFigure(i).canvas;
                        catch
                            this.canvas = allAxesInFigure(i);
                        end
                        break
                    end
                end
            end

            % Do nothing if button down event was not on a canvas.
            if size(this.canvas,2) < 1
                return
            end
            
            % Get which button was pressed.
            this.whichMouseButton = this.dialog.SelectionType;

            if strcmp(this.whichMouseButton,'alt')
                this.whichMouseButton = 'right';
            end
            if strcmp(this.whichMouseButton,'normal')
                this.whichMouseButton = 'left';
            end
            if strcmp(this.whichMouseButton,'extend')
                this.whichMouseButton = 'center';
            end           
            if strcmp(this.whichMouseButton,'open')
                this.whichMouseButton = 'double click';
            end
            
            % Set button mode as down, get button down location, and
            % call client (subclass) button down action method.
            this.mouseButtonMode = 'down';
            try
                pt = this.canvas.getContext.CurrentPoint;
            catch
                pt = this.canvas.CurrentPoint;
            end
            xP = pt(:, 1);
            yP = pt(:, 2);
			zP = pt(:, 3);
            this.currentPosition = [xP yP zP]';
            this.downAction();
        end
        
        %------------------------------------------------------------------
        % This method is a callback function associated with mouse move
        % events on the target figure (dialog).
        % It sets the current position to the current mouse position on
        % the target axes (canvas) and calls the abstract moveAction
        % method.
        function eMouseMove(this,~,~)
            % Get current mouse location, and call client (subclass)
            % mouse move action method.
            try
                pt = this.canvas.getContext.CurrentPoint;
            catch
                pt = this.canvas.CurrentPoint;
            end
            xP = pt(:, 1);
            yP = pt(:, 2);
			zP = pt(:, 3);
            this.currentPosition = [xP yP zP]';
            this.moveAction();
        end
        
        %------------------------------------------------------------------
        % This method is a callback function associated with mouse button
        % up events on the target figure (dialog).
        % It sets the mouseButtonMode property to up, sets the current
        % position to the mouse button up position on the target axes
        % (canvas), and calls the abstract upAction method.
        function eButtonUp(this,~,~)
            % Do nothing if button down event was not on a canvas.
            if strcmp(this.whichMouseButton,'none')
                return
            end
            
            % Set button mode as up, get button up location, and
            % call client (subclass) button up action method.
            this.mouseButtonMode = 'up';
            try
                pt = this.canvas.getContext.CurrentPoint;
            catch
                pt = this.canvas.CurrentPoint;
            end
            xP = pt(:, 1);
            yP = pt(:, 2);
			zP = pt(:, 3);
            this.currentPosition = [xP yP zP]';
            this.upAction();

            % Reset mouse button type for next sequence of 
            % button down - mouse move - button up events.
            this.whichMouseButton = 'none';
        end
        
		%------------------------------------------------------------------
		% This method is a callback function associated with mouse scroll
        % events on the target figure (dialog).
        % It sets the current position to the current mouse position on
        % the window coordinate system and calls the abstract scrollAction
        % method.
		function eUseScroll(this,~,event)
            % Get the scroll intensity.
			this.verticalScrollCount = event.VerticalScrollCount;
            
            units = this.dialog.Units;
            this.dialog.Units = 'pixels';
            figPt = this.dialog.CurrentPoint;
            this.dialog.Units = units;
            % Find the target canvas.
            % First check to see whether there are panel containers
            % for the canvases. It is assumed that there is only one
            % canvas per panel.
            allPanelsInFigure = findobj(this.dialog,'Type','uipanel');
            if size(allPanelsInFigure,1) > 0
                for i=1:size(allPanelsInFigure,1)
                    units = allPanelsInFigure(i).Units;
                    allPanelsInFigure(i).Units = 'pixels';
                    limits = allPanelsInFigure(i).Position;
                    allPanelsInFigure(i).Units = units;
                    left = limits(1);
                    right = limits(1) + limits(3);
                    bottom = limits(2);
                    top = limits(2) + limits(4);
                    if (figPt(1) >= left && figPt(1) <= right && ...
                        figPt(2) >= bottom && figPt(2) <= top)
                        AxesInPanel = findobj(allPanelsInFigure(i),'Type','axes');
                        try
                            this.canvas = AxesInPanel(1).canvas;
                        catch
                            this.canvas = AxesInPanel(1);
                        end
                        break
                    end
                end
            else
            % If the canvases are not inside panel containers, find 
            % target canvas directly in dialog.
                allAxesInFigure = findobj(this.dialog,'Type','axes');
                for i=1:size(allAxesInFigure,1)
                    units = allAxesInFigure(i).Units;
                    allAxesInFigure(i).Units = 'pixels';
                    limits = allAxesInFigure(i).Position;
                    allAxesInFigure(i).Units = units;
                    left = limits(1);
                    right = limits(1) + limits(3);
                    bottom = limits(2);
                    top = limits(2) + limits(4);
                    if (figPt(1) >= left && figPt(1) <= right && ...
                        figPt(2) >= bottom && figPt(2) <= top)
                        try
                            this.canvas = allAxesInFigure(i).canvas;
                        catch
                            this.canvas = allAxesInFigure(i);
                        end
                        break
                    end
                end
            end

            % Do nothing if button down event was not on a canvas.
            if size(this.canvas,2) < 1
                return
            end
            
            % Normal zoom obtains negative values for this counter and vice
            % versa
            if (this.verticalScrollCount > 0)
                direction = 'minus';
                this.scrollAllowed = true;
            elseif (this.verticalScrollCount < 0)
                direction = 'plus';
                this.scrollAllowed = true;
            end
            
            % Executes if scroll event happens on a canvas. Get scroll 
			% window location and call client (subclass) scroll action
			% method.
            try
                ax = this.canvas.getContext;
            catch
                ax = this.canvas;
            end
            if this.scrollAllowed
                if is2D(ax)
                    pt = ax.CurrentPoint;
                    cx = pt(1, 1);
                    cy = pt(1, 2);
                    this.scrollAction(direction,cx,cy);
                else
                    pt = ax.CurrentPoint;
                    wx = pt(1);
                    wy = pt(2);
                    this.scrollAction(direction,wx,wy);
                end
            end
            
            % Reset scroll and target canvas for next events.
            this.scrollAllowed = false;
        end
        
        %------------------------------------------------------------------
        % Initializes property values of an Emouse object.
        function this = clean(this)
            this.dialog = [];
            this.canvas = [];
            this.mouseButtonMode = 'up';
            this.whichMouseButton = 'none';
			this.verticalScrollCount = 0;
			this.scrollAllowed = false;
            this.currentPosition = [];
        end
    end
end
