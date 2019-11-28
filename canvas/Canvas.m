%% Canvas class - APP DESIGNER (uiaxes/uifigure)
%
% This is an abstract class to facilitate the development of graphical
% applications that deal with MATLAB axes objects as canvases to draw
% models, plot graphs and enable mouse interactivity.
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
% @version 1.00
%
% Initial version: September 2019
%%%
% Initially prepared for the course CIV 2801 - Fundamentos de Computação
% Gráfica, 2019, second term, Department of Civil Engineering, PUC-Rio.
%
%% Class definition
classdef Canvas < handle
    %% Protected attributes
    properties (SetAccess = protected, GetAccess = protected)
        ax          =  [];  % handle to axes object that defines canvas
        fig         =  [];  % handle to figure where canvas is located
        
        updateFcn   =  [];  % handle to function that details how to update
                            %                             drawing on canvas
                           
        boundBoxFcn =  [];  % handle to function that computes model bound
                            %                                           box
                           
        axIsEq      =   1;  % flag indicating if axes style is 'equal'
        freeBorder  = 0.1;  % free border propotion
    end
    %% Constructor method
    methods
        %------------------------------------------------------------------
        % Input:
        % * ax  = handle to axes associated to canvas
        % * fig = handle to figure where canvas is placed
        % * fcn = handle to function that details how to update drawing on
        %                                                           canvas
        function this = Canvas(ax,fig,fcn)
            % Check input
            if (nargin == 0)
                % If no axes or figure were provided, initialize both
                ax = uiaxes();
                fig = ax.Parent;
            elseif isempty(ax)
                if ~isempty(fig)
                    % If no handles to axes object were provided, but a
                    % handle to figure was, initialize axes on this figure
                    ax = uiaxes(fig);
                else
                    % If no axes or figure were provided, initialize both
                    ax = uiaxes();
                    fig = ax.Parent;
                end
            end
            
            % By default, set 'hold' axes property to 'on'
            % This avoids unwanted deletion of plots, when dealing with
            % multiple plots on the same canvas.
            hold(ax,'on');
            
            % Set canvas object properties
            this.ax  =  ax;
            this.fig = fig;
            if (nargin > 2)
                this.updateFcn = fcn;
            end
            
            % By default, define canvas as equal (proportional).
            % Users may change this by calling 'this.Equal(false)' after
            % initializing Canvas object.
            this.Equal(true);
            
            % Set handle to axes.DeleteFcn. Ensures that this canvas object
            % will be erased if axes is closed.
            this.ax.DeleteFcn = @this.onDeletion;
            
            % Set a handle back to canvas from uiaxes object
            this.ax.addprop('canvas');
            this.ax.canvas = this;
        end
    end
    %% Public methods
    methods
        %------------------------------------------------------------------
        % DOES NOT WORK FOR APP DESIGNER - MATLAB R2019a
        % Override ButtonDownFcn callback, associated to 'ax'.
        % If user provides a handle to a function, that will be set as the
        % callback, otherwise, it will be directed to the abstract method
        % 'ax_onButtonDown'.
        function overrideAxButtonDownFcn(~,~) %(this,fcn)
            %if (nargin < 2)
            %    fcn = @this.ax_onButtonDown;
            %end
            %this.ax.ButtonDownFcn = fcn;
        end
        %------------------------------------------------------------------
        % Store handle to function that updates canvas
        % Input arguments:
        %  fcn: handle to update function to be used by canvas
        function setUpdateFcn(this,fcn)
            this.updateFcn = fcn;
        end
        %------------------------------------------------------------------
        % Store handle to function that computes bounding box
        % Input arguments:
        %  fcn: handle to bound box function to be used by canvas
        function setBoundBoxFcn(this,fcn)
            this.boundBoxFcn = fcn;
        end
        %------------------------------------------------------------------
        % Calls function to update canvas
        % Input arguments:
        %  varargin: list with a variable number of input arguments,
        %            related to the redraw function to be used
        % Output arguments:
        %  output: true (canvas successfully updated), false (nothing was
        %                                                            done)
        function output = update(this,varargin)
            % If no redraw function was previously specified, do nothing
            if isempty(this.updateFcn)
                output = false;
                this.fit2view(evalBoundBox(this));
                return
            end
            
            % If user provided a bounding box function, call it now
            thereIsBoundbox = false;
            if ~isempty(this.boundBoxFcn)
                this.fit2view(evalBoundBox(this));
                thereIsBoundbox = true;
            end
            
            % Updates canvas with specified redraw function
            if (nargin > 1)
                this.updateFcn(this.ax,varargin);
            else
                this.updateFcn(this.ax);
            end
           
            % If no bounding box function was provided, call fit2view
            if ~thereIsBoundbox
                this.fit2view();
            end
             output = true;
        end
        %------------------------------------------------------------------
        function setFreeBorder(this,b)
            % Free border property is a proportion of the bounding box
            % size, so it makes no sense to allow users to set -1 or less.
            % Any value between (-1,0) results on a zoom centered on the
            % drawing's midpoint coordinates.
            if b <= -1
                return
            end
            this.freeBorder = b;
            this.fit2view(evalBoundBox(this));
        end
        %------------------------------------------------------------------
        % Returns handle to axes associated to canvas object
        function ax = getContext(this)
            ax = this.ax;
        end
        %------------------------------------------------------------------
        % Returns handle to figure associated to canvas object
        function fig = getDialog(this)
            fig = this.fig;
        end
        %------------------------------------------------------------------
        function Equal(this,eq)
            this.axIsEq = eq;
            if eq
                axis(this.ax,'equal');
            else
                axis(this.ax,'normal');
            end
            this.fit2view(evalBoundBox(this));
        end
        %------------------------------------------------------------------
        function Grid(this,turnOnorOff)
            this.ax.XGrid = turnOnorOff;
            this.ax.YGrid = turnOnorOff;
            this.ax.ZGrid = turnOnorOff;
        end
        %------------------------------------------------------------------
        function Ruler(this,turnOn)
            if turnOn
                this.ax.XAxis.Visible =  'on';
                this.ax.YAxis.Visible =  'on';
                this.ax.ZAxis.Visible =  'on';
            else
                this.ax.XAxis.Visible = 'off';
                this.ax.YAxis.Visible = 'off';
                this.ax.ZAxis.Visible = 'off';
            end
            
        end
        %------------------------------------------------------------------
        function Clipping(this,turnOn)
            if turnOn
                this.ax.Clipping =  'on';
            else
                this.ax.Clipping = 'off';
            end
        end
        %------------------------------------------------------------------
        function Clean(this)
            cla(this.ax);
        end
    end
    %% Private methods
    methods (Access = private)
        %------------------------------------------------------------------
        function onDeletion(this,~,~)
            delete(this.ax);
            this.kill();
        end
        %------------------------------------------------------------------
        % Calls function to set bounding box
        function bBox = evalBoundBox(this)
            if ~isempty(this.boundBoxFcn)
                bBox = this.boundBoxFcn();
            else
                bBox = [];
            end
        end
    end
    %% Abstract methods
    % Declaration of abstract methods implemented in derived sub-classes.
    methods (Abstract)
        %------------------------------------------------------------------
        % Fits axis limits to display everything drawn on canvas.
        % Input arguments:
        %  bBox: bounding box vector 
        %          2D : [left bottom right up] - xy
        %          3D : [near left bottom far right up] - xyz
        fit2view(this,bBox);
        
        %------------------------------------------------------------------
        % Mouse button down callback - related to axes object
        % Input:
        % * this  = handle to this canvas object
        % * obj   = handle to graphical object that was clicked on
        % * event = struct with event data
        ax_onButtonDown(this,obj,event);
        
        %------------------------------------------------------------------
        % Mouse button down callback - generic callback, should be called
        % from figure related events.
        % Input:
        % * this  = handle to this canvas object
        % * pt    = current cursor coordinates
        % * whichMouseButton = 'left', 'right', 'center', 'double click'
        onButtonDown(this,pt,whichMouseButton);
        
        %------------------------------------------------------------------
        % Mouse button up callback - generic callback, should be called
        % from figure related events.
        % Input:
        % * this  = handle to this canvas object
        % * pt    = current cursor coordinates
        % * whichMouseButton = 'left', 'right', 'center', 'double click'
        onButtonUp(this,pt,whichMouseButton);
        
        %------------------------------------------------------------------
        % Mouse move callback - generic callback, should be called
        % from figure related events.
        % Input:
        % * this  = handle to this canvas object
        % * pt    = current cursor coordinates
        onMouseMove(this,pt);
        
        %------------------------------------------------------------------
        % Mouse scroll callback - generic callback, should be called
        % from figure related events.
        % Input:
        % * this  = handle to this canvas object
        % * pt    = current cursor coordinates
        onMouseScroll(this,pt);
    end
    %% Destructor method
    methods
        function kill(this)
            this.ax          = [];
            this.fig         = [];
            this.updateFcn   = [];
            this.boundBoxFcn = [];
            this.axIsEq      = [];
            this.freeBorder  = [];
            delete(this);
        end
    end
end

