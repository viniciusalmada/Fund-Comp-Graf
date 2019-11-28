%% Class definition
classdef MouseEvents < Emouse
    %% Constructor method
    methods
        function this = MouseEvents(fig,cnvs)
            this = this@Emouse(fig,cnvs);
        end
    end
    %% Protected methods
    methods (Access = protected)
        %------------------------------------------------------------------
        function this = downAction(this)
            this.canvas.onButtonDown(this.currentPosition,this.whichMouseButton);
        end
        
        %------------------------------------------------------------------
        function this = moveAction(this)
            this.canvas.onMouseMove(this.currentPosition);
        end
        
        %------------------------------------------------------------------
        function this = upAction(this)
            this.canvas.onButtonUp(this.currentPosition,this.whichMouseButton);
        end
        
        %------------------------------------------------------------------
        % Matlab requires implementaion of all superclass abstract methods
        function scrollAction(~)
        end
    end
end