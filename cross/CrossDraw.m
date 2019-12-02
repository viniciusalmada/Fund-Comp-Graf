%% CrossDraw class
%
% This class implements methods to plot graphical results
% from the Cross process of continuous beams.
%
%% Author
% Luiz Fernando Martha
%
%% History
% @version 1.03
%
% Initial version: September 2019
%%%
% Initially prepared for the course CIV 2801 - Fundamentos de Computa√ß√£o
% Gr√°fica, 2019, second term, Department of Civil Engineering, PUC-Rio.
%
% Version 1.01: September 2019
%%%
% Creation of functions to display deformed configuration and bending moment
% of continous beam.
%
% Version 1.01: October 2019
%%%
% Creation of functions to manipulate continous beam model in the model
% canvas (internal support insertion and deletion) and to force moment
% balancing at an interior node through mouse events.
%
% Version 1.02: October 2019
%%%
% Creation of functions to manipulate continous beam model in the model
% canvas: interactive change of distributed member load and interactive
% move of support.
%
% Version 1.03: October 2019
%%%
% Implementation of iterative Cross solution draw functions.
%
%% Class definition
classdef CrossDraw < handle
	%% Public properties
	properties
		solver = []; % handle to an object of the CrossSolver class
		mSupSize
		mArrowSize
		mGapLoadArrow
	end
	
	%% Class (constant) properties
	properties (Constant)
		supsize_fac = 0.02; % factor for support size
		loadsize_fac = 0.7; % factor for maximum load size
		minloadsize_fac = 0.012 % factor for minimum load size
		arrowsize_fac = 0.01; % factor for load arrow size
		loadstep_fac = 0.05; % factor for load step
		picktol_fac = 0.01; % factor for picking a point
		minmemblen_fac = 0.05; % factor for minimum member length
		iterativesolutionsize_fac = 0.60; % percentage of size of iterative solution
		solutionrow_size = 15 % number of pixels of iterative solution row
		textshift_fac = 0.015; % factor for shifting horizontaly text in interative solution table
		sectionshift_fac = 0.01; % factor for shifting section line in solution beam
		sectionsize_fac = 0.01; % factor for section line size in solution beam
		ValidSupInsertion = 1; % status for valid support insertion
		BeamLineNotFound = 2; % status for beam line not found for support insertion
		SupInsertionNotValid = 3; % status for not valid position for support insertion
		SupDelMinNumSup = 1; % status for minimum number of internal supports
		ValidSupDeletion = 2; % status for valid support deletion
		SupDelNotFound = 3; % status for support not found for deletion
		MembLoadFound = 1; % status for pick member load found
		MembLoadNotFound = 2 % status for pick member not found
		SupMoveFound = 1; % status for support found for moving
		SupMoveNotFound = 2; % status for support not found for moving
		
		BLUE = [0 0 1];
		BLACK = [0 0 0];
		RED = [1 0 0];
		MAGENTA = [1 0 1];
		GREY = [0.2 0.2 0.2];
		GREEN = [0 0.3 0];
		arrowLoad_fac = 0.02;
		deformMax_fac = 0.80;
		arrowSpacing_fac = 0.02;
        HING = 0;
        CLAMP = 1;
        FREE = 2;
	end
	
	%% Private properties
	properties (Access = private)
		pickmember = 0; % current member load picked
		picksup = 0; % current support picked
		orig_suppos = 0; % original moving support position
		hnd_draft = []; % handle to draft graphics object being displayed
		initMoments = []; % array of member initial moments
	end
	
	%% Constructor method
	methods
		%------------------------------------------------------------------
		function draw = CrossDraw(solver)
			if (nargin > 0)
				draw.solver = solver;
				draw.mSupSize = solver.totalLen * CrossDraw.supsize_fac;
				draw.mArrowSize = solver.totalLen * CrossDraw.arrowLoad_fac;
				draw.mGapLoadArrow = solver.totalLen * CrossDraw.arrowSpacing_fac;
			end
		end
	end
	
	%% Class (static) auxiliary functions
	methods (Static)
		%------------------------------------------------------------------
		% Plots a square with defined center coordinates, side length and
		% color.
		% Input arguments:
		%  cnv: graphics context (axes)
		%  x: center coordinate on the X axis
		%  y: center coordinate on the Y axis
		%  l: side length
		%  c: color (RGB vector)
		function square(cnv,x,y,l,c)
			X = [x - l/2, x + l/2, x + l/2, x - l/2];
			Y = [y - l/2, y - l/2, y + l/2, y + l/2];
			fill(cnv, X, Y, c);
		end
		
		%------------------------------------------------------------------
		% Plots a draft version of a square with defined center coordinates,
		% side length and color.
		% It draws a hollow square and sets its parent property as the
		% given handle to the group of graphics objects.
		% Input arguments:
		%  cnv: graphics context (axes)
		%  hnd: handle to group of graphics objects
		%  x: center coordinate on the X axis
		%  y: center coordinate on the Y axis
		%  l: side length
		%  c: color (RGB vector)
		function draftSquare(cnv,hnd,x,y,l,c)
			X = [x - l/2, x + l/2, x + l/2, x - l/2, x - l/2];
			Y = [y - l/2, y - l/2, y + l/2, y + l/2, y - l/2];
			plot(cnv, X, Y, 'color', c, 'Parent', hnd);
		end
		
		%------------------------------------------------------------------
		% Plots a triangle with defined top coordinates, height, base,
		% orientation, and color.
		% Input arguments:
		%  cnv: graphics context (axes)
		%  x: top coordinate on the X axis
		%  y: top coordinate on the Y axis
		%  h: triangle height
		%  b: triangle base
		%  ang: angle (in radian) between the axis of symmetry and the
		%	   horizontal direction (counterclockwise) - 0 rad when
		%	   triangle is pointing left
		%  c: color (RGB vector)
		function triangle(cnv,x,y,h,b,ang,c)
			cx = cos(ang);
			cy = sin(ang);
			
			X = [x, x + h * cx + b/2 * cy, x + h * cx - b/2 * cy];
			Y = [y, y + h * cy - b/2 * cx, y + h * cy + b/2 * cx];
			fill(cnv, X, Y, c);
        end
        
        function pot(cnv,x,y,h,b,ang,c)
			cx = cos(ang);
			cy = sin(ang);
			
			X = [x, x + h * cx + b/2 * cy,x, x + h * cx - b/2 * cy];
			Y = [y, y + h * cy - b/2 * cx,y, y + h * cy + b/2 * cx];
			line(cnv, X, Y, 'Color',c,'LineWidth',1.5);
		end
		
		%------------------------------------------------------------------
		% Plots a draft version of a triangle with defined top coordinates,
		% height, base, orientation, and color.
		% It draws a hollow triangle and sets its parent property as the
		% given handle to the group of graphics objects.
		% Input arguments:
		%  cnv: graphics context (axes)
		%  hnd: handle to group of graphics objects
		%  x: top coordinate on the X axis
		%  y: top coordinate on the Y axis
		%  h: triangle height
		%  b: triangle base
		%  ang: angle (in radian) between the axis of symmetry and the
		%	   horizontal direction (counterclockwise) - 0 rad when
		%	   triangle is pointing left
		%  c: color (RGB vector)
		function draftTriangle(cnv,hnd,x,y,h,b,ang,c)
			cx = cos(ang);
			cy = sin(ang);
			
			X = [x, x + h * cx + b/2 * cy, x + h * cx - b/2 * cy, x];
			Y = [y, y + h * cy - b/2 * cx, y + h * cy + b/2 * cx, y];
			plot(cnv, X, Y, 'color', c, 'Parent', hnd);
		end
		
		%------------------------------------------------------------------
		% Plots a circle with defined center coordinates, radius and color.
		% This method is used to draw hinges on 2D models.
		% Input arguments:
		%  cnv: graphics context (axes)
		%  x: center coordinate on the X axis
		%  y: center coordinate on the Y axis
		%  r: circle radius
		%  c: color (RGB vector)
		function circle(cnv,x,y,r,c)
			circ = 0 : pi/50 : 2*pi;
			xcirc = x + r * cos(circ);
			ycirc = y + r * sin(circ);
			plot(cnv, xcirc, ycirc, 'color', c);
		end
		
		%------------------------------------------------------------------
		% Plots an arrow with defined beggining coordinates, length,
		% arrowhead height, arrowhead base, orientation, and color.
		% This method is used to draw load symbols on 2D models.
		% Input arguments:
		%  cnv: graphics context (axes)
		%  x: beggining coordinate on the X axis
		%  y: beggining coordinate on the Y axis
		%  l: arrow length
		%  h: arrowhead height
		%  b: arrowhead base
		%  ang: pointing direction (angle in radian with the horizontal
		%	   direction - counterclockwise) - 0 rad when pointing left
		%  c: color (RGB vector)
		function arrow2D(cnv,x,y,l,h,b,ang,c)
			cx = cos(ang);
			cy = sin(ang);
			
			X = [x, x + l * cx];
			Y = [y, y + l * cy];
			line(cnv, X, Y, 'Color', c);
			CrossDraw.triangle(cnv, x, y, h, b, ang, c);
        end
        
        function arrow2DA(cnv,x,y,l,h,b,ang,c)
			cx = sin(ang);
			cy = cos(ang);
			
			X = [x, x - l * cx];
			Y = [y, y + l * cy];
			line(cnv, X, Y, 'Color', c,'LineWidth',1.5);
			CrossDraw.pot(cnv, x-cx, cy, h, b, ang+deg2rad(-90), c);
		end
		
		function draftArrow2D(cnv,hnd,x,y,l,h,b,ang,c)
			cx = cos(ang);
			cy = sin(ang);
			
			X = [x, x + l * cx];
			Y = [y, y + l * cy];
			line(cnv, X, Y, 'Color', c,'Parent',hnd);
			CrossDraw.draftTriangle(cnv,hnd, x, y, h, b, ang, c);
		end
		
		%------------------------------------------------------------------
		% Plots a third gender support symbol
		function thirdGenSupport(cnv,x,y,h,c,isOnLeft)
			w = h / 4;
			horLines = linspace(y-h/2,y+h/2,6);
			line(cnv,[x x],[y-h/2 y+h/2],'Color',c,'LineWidth',1.2)
			for i=1:numel(horLines)-1
				if isOnLeft==1
					line(cnv,[x x-w],[horLines(i+1) horLines(i)],'Color',c)
				else
					line(cnv,[x+w x],[horLines(i+1) horLines(i)],'Color',c)
				end
			end
		end
		
		
		%------------------------------------------------------------------
		% Plots a third gender support symbol
		function draftThirdGenSupport(cnv,hnd,x,y,h,c,isOnLeft)
			w = h / 4;
			horLines = linspace(y-h/2,y+h/2,6);
			line(cnv,[x x],[y-h/2 y+h/2],'Color',c,'LineWidth',1.2, 'Parent', hnd)
			for i=1:numel(horLines)-1
				if isOnLeft==1
					line(cnv,[x x-w],[horLines(i+1) horLines(i)],'Color',c, 'Parent', hnd)
				else
					line(cnv,[x+w x],[horLines(i+1) horLines(i)],'Color',c, 'Parent', hnd)
				end
			end
		end
		
		 % Funcao criada para as funcoes de forma
		% artinit = articulaÁ„o inicial. Apoio simples = 0, Engaste = 1,
		% Livre = 2
		% artend = articulaÁ„o final. Apoio simples = 0, Engaste = 1, Livre
		% = 2
		function [N2, N4] = funcoes_forma(artinit, artend, len, x)
						
			if artinit == CrossDraw.CLAMP && artend == CrossDraw.CLAMP
				
				N2 = x - (2 .* x.^2 / len) + (x.^3 / len^2);
				N4 = - (x.^2 / len) + (x.^3 / len^2);
				
			elseif artinit == CrossDraw.HING && artend == CrossDraw.CLAMP
				
				N2 = 0;
				N4 = - (x / 2) + (x.^3 / 2 / len^2);
				
			elseif artinit == CrossDraw.CLAMP && artend == CrossDraw.HING
				
				N2 = x - (3 .* x.^2 / 2 / len) + (x.^3 / 2 / len^2);
				N4 = 0;
				
			elseif artinit == CrossDraw.HING && artend == CrossDraw.HING
				
				N2 = 0;
				N4 = 0;
				
			elseif artinit == CrossDraw.FREE && artend == CrossDraw.CLAMP
				
				N2 = 0;
				N4 = - (x.^2 / len) + (x.^3 / len^2);
				
			elseif artinit == CrossDraw.CLAMP && artend == CrossDraw.FREE
				
				N2 = x - (2 .* x.^2 / len) + (x.^3 / len^2);
				N4 = 0;
																
			end
			
		end
		
		%------------------------------------------------------------------
		
		% Funcao criada para o engastamento perfeito
		% artinit = articulaÁ„o inicial. Apoio simples = 0, Engaste = 1
		% artend = articulaÁ„o final. Apoio simples = 0, Engaste = 1
		function [v01] = engastamento_perfeito(artinit, artend, len, q, EI, x)
			
			if artinit == CrossDraw.CLAMP && artend == CrossDraw.CLAMP
				
				v01 = (q / EI) .* ( ( - len^2 .* x.^2 ./ 24) + ( len .* x.^3 ./ 12 ) - ( x.^4 ./ 24 ) );
				
			elseif artinit == CrossDraw.HING && artend == CrossDraw.CLAMP
				
				v01 = (q / EI) .* ( ( - len^3 .* x ./ 48) + ( len .* x.^3 ./ 16 ) - ( x.^4 ./ 24 ) );
				
			elseif artinit == CrossDraw.CLAMP && artend == CrossDraw.HING
				
				v01 = (q / EI) .* ( ( - len^2 .* x.^2 ./ 16) + ( 5 .* len .* x.^3 ./ 48 ) - ( x.^4 ./ 24 ) );
				
			elseif artinit == CrossDraw.HING && artend == CrossDraw.HING
				
				v01 = (q / EI) .* ( ( - len^3 .* x ./ 24) + ( len .* x.^3 ./ 12 ) - ( x.^4 ./ 24 ) );
				
			elseif artinit == CrossDraw.CLAMP && artend == CrossDraw.FREE
				
				v01 = (-q / EI) .* ( (x.^4 ./ 24) + (len^2 .* x.^2 ./ 4) - (len .* x.^3 ./ 6));
				
			elseif artinit == CrossDraw.FREE && artend == CrossDraw.CLAMP
				
				v01 = (q / EI) .* ( (-x.^4 ./ 24) + (len^3 .* x ./ 6) - (len^4 ./ 8) );
				
			end
						
		end
		
		%------------------------------------------------------------------
		% Snap a value to the closest step value.
		function snap_val = snapToStepValue(val,step)
			fp = val / step;   % "fraction" part
			ip = floor(fp);	% integer part
			fp = fp - ip;
			if fp > 0.5
				snap_val = (ip + 1.0) * step;
			elseif fp < -0.5
				snap_val = (ip - 1.0) * step;
			else
				snap_val = ip * step;
			end
		end
	end
	
	%% Protect methods
	methods (Access = protected) % Access from methods in subclasses
		function max_load = getMaxLoad(draw)
			max_load = 0;
			for i = 1:draw.solver.nmemb
				if(abs(draw.solver.membs(i).q) > max_load)
					max_load = abs(draw.solver.membs(i).q);
				end
			end
		end
		
		% -----------------------------------------------------------------
		% Draw support
		% canvas = axes where support will drawed
		% x,y = support coordinates
		% color = 3x1 vector with RGB parameters
		% fixRotation = boolean value to draw correct support
		function drawSupport(draw,canvas,x,y,color,sup,vargin)
			if sup == 1
				CrossDraw.thirdGenSupport(canvas,x,y,2*draw.mSupSize,color,vargin)
			elseif sup == 0
				CrossDraw.triangle(canvas,x,y,draw.mSupSize,draw.mSupSize,-pi/2,color)
			end
		end
		
		% -----------------------------------------------------------------
		% Draw member
		% canvas = axes where member will be drawed
		% x,y = initial member node coordinates
		% member = CrossMember object
		% endMember = end member node coordinates
		function endMember = drawMember(~,canvas,x,y,member)
			len = member.len;
			line(canvas,[x len+x],[y y],'Color',CrossDraw.BLACK,...
				'LineWidth',1.5);
			endMember = len + x;
		end
		
		%------------------------------------------------------------------
		% Draws a continuous beam model.
		% Input:
		% - posy: Y position of continuous beam axis.
		% - unbalanced_node: flag for unbalanced node.
		%	  if  set, display corresponding support in red color.
		function beam(draw,cnv,posy,unbalanced_node)
			crossSolver = draw.solver;
			
			% Draw first support
			draw.drawSupport(cnv,0,posy,CrossDraw.BLUE,crossSolver.supinit,1)
			
			% Draw first member
			firstMember = crossSolver.membs(1);
			supPosition = draw.drawMember(cnv,0,posy,firstMember);
			
			% Draw intermediate support(s) and member(s)
			for i = 2:crossSolver.nmemb
				if (unbalanced_node)
					if crossSolver.isNodeUnbalanced(i-1)
						draw.drawSupport(cnv,supPosition,posy,CrossDraw.RED,0)
					else
						draw.drawSupport(cnv,supPosition,posy,CrossDraw.BLUE,0)
					end
				else
					draw.drawSupport(cnv,supPosition,posy,CrossDraw.BLUE,0)
				end
				supPosition = draw.drawMember(cnv,supPosition,posy,crossSolver.membs(i));
			end
			
			% Draw last support
			draw.drawSupport(cnv,supPosition,posy,CrossDraw.BLUE, crossSolver.supend,0)
		end
		
		%--------------------------------------------------------------------------------------------
		% Draws a continuous beam model for the Cross iterative soluction.
		% It draws the values of the moment distribution coefficients at
		% the interior nodes and draws the bending moments values at
		% the member ends.
		% Input:
		% - posy: Y position of continuous beam axis.
		%	  if  set, display corresponding support in red color.
		function beamSolution(draw,cnv,posy)
			
			% Compute size of shift for text, size of shift for section line,
			% and size of section line based on a factor of total beam length
			totalLen = draw.solver.totalLen;
			textShift = draw.textshift_fac * totalLen;
			sectionShift = draw.sectionshift_fac * totalLen;
			sectionline = draw.sectionsize_fac * totalLen;
			sectionline_half = sectionline * 0.5;
			
			line(cnv, [0, totalLen], [posy, posy], 'Color', [0 0 0]);
			
			supsize = draw.solver.totalLen * CrossDraw.supsize_fac;
			draw.drawSupport(cnv,0,posy,draw.BLUE,draw.solver.supinit,1)
			
			% Draw interior supports and moment distribution coefficients
			% of interior nodes
			len = draw.solver.membs(1).len;
			sup_pos = len;
			for i = 2:draw.solver.nmemb
				n = i - 1;
				
				dl = draw.solver.nodes(n).dl;
				str_dl = sprintf('%.2f',dl);
				txt_dl = text(cnv, sup_pos-textShift, posy, str_dl);
				txt_dl.HorizontalAlignment = 'right';
				txt_dl.VerticalAlignment = 'bottom';
				txt_dl.Color = [0 0 1];
				txt_dl.EdgeColor = draw.BLUE;
				txt_dl.Margin = 0.5;
				txt_dl.FontWeight = 'bold';
				
				dr = draw.solver.nodes(n).dr;
				str_dr = sprintf('%.2f',dr);
				txt_dr = text(cnv, sup_pos+textShift, posy, str_dr);
				txt_dr.HorizontalAlignment = 'left';
				txt_dr.VerticalAlignment = 'bottom';
				txt_dr.Color = [0 0 1];
				txt_dr.EdgeColor = draw.BLUE;
				txt_dr.Margin = 0.5;
				txt_dr.FontWeight = 'bold';
				
				CrossDraw.triangle(cnv,sup_pos,posy,supsize,supsize,-pi/2,[0 0 1]);
				len = draw.solver.membs(i).len;
				sup_pos = sup_pos + len;
			end
			
			draw.drawSupport(cnv,sup_pos,posy,draw.BLUE,draw.solver.supend,0)
			
			% Draw member bending moments
			sup_pos = 0;
			for i = 1:draw.solver.nmemb
				line(cnv, [sup_pos+sectionShift, sup_pos+sectionShift],...
					[posy-sectionline_half, posy+sectionline_half], 'Color', [0 0 0]);
				
				ml = draw.solver.membs(i).ml;
				str_ml = sprintf('%.*f',draw.solver.decplc,ml);
				txt_ml = text(cnv, sup_pos+textShift, posy, str_ml);
				txt_ml.HorizontalAlignment = 'left';
				txt_ml.VerticalAlignment = 'top';
				
				len = draw.solver.membs(i).len;
				sup_pos = sup_pos + len;
				
				line(cnv, [sup_pos-sectionShift, sup_pos-sectionShift],...
					[posy-sectionline_half, posy+sectionline_half], 'Color', [0 0 0]);
				
				mr = draw.solver.membs(i).mr;
				str_mr = sprintf('%.*f',draw.solver.decplc,mr);
				txt_mr = text(cnv, sup_pos-textShift, posy, str_mr);
				txt_mr.HorizontalAlignment = 'right';
				txt_mr.VerticalAlignment = 'top';
			end
			
		end
		
		%------------------------------------------------------------------
		% Draw the uniform load of a member.
		% Input arguments:
		%  cnv: graphics context (axes)
		%  init_pos: initial position of load
		%  len: length of load
		%  q: uniform load value
		%  load_size: size of load
		%  load_step: step size for drawing arrows
		%  arrowsize: size of arrow head
		function memberLoad(draw,cnv,init_pos,len,q,load_size,~,arrowsize)
			
			arrowCount = floor(len / draw.mGapLoadArrow);
			arrowPos = init_pos + (len - draw.mGapLoadArrow * ...
				(arrowCount - 1)) / 2;
			loadInit = arrowPos;
			
			% Draw load arrows
			for j = 1:arrowCount
				if q > 0
					CrossDraw.arrow2D(cnv,arrowPos,0,load_size,...
						arrowsize, arrowsize, pi/2, draw.RED);
				else
					CrossDraw.arrow2D(cnv,arrowPos,0,load_size,...
						arrowsize, arrowsize, -pi/2, draw.RED);
				end
				arrowPos = arrowPos + draw.mGapLoadArrow;
			end
			
			% Draw load top/bottom line
			loadEnd=arrowPos - draw.mGapLoadArrow;
			if q > 0
				line(cnv,[loadInit loadEnd],[load_size load_size],...
					'Color',[1 0 0]);
				text(cnv,init_pos+len/2, load_size,...
					[num2str(q) ' kN/m'],...
					'Color', 'r','HorizontalAlignment','center',...
					'VerticalAlignment','bottom')
			else
				line(cnv,[loadInit loadEnd],[-load_size -load_size],...
					'Color',[1 0 0]);
				text(cnv,init_pos+len/2, -load_size,...
					[num2str(q) ' kN/m'],...
					'Color', 'r','HorizontalAlignment','center',...
					'VerticalAlignment','top')
			end
		end
		
		%------------------------------------------------------------------
		% Draw a draft version of the uniform load of a member and set
		% the parent property of each graphic object as the given handle
		% to the group of graphics objects.
		% Input arguments:
		%  cnv: graphics context (axes)
		%  hnd: handle to group of graphics objects
		%  init_pos: initial position of load
		%  len: length of load
		%  q: uniform load value
		%  load_size: size of load
		%  load_step: step size for drawing arrows
		function draftMemberLoad(draw,cnv,hnd,init_pos,len,q,load_size,~,arrowsize)
			arrowCount = floor(len / draw.mGapLoadArrow);
			arrowPos = init_pos + (len - draw.mGapLoadArrow * ...
				(arrowCount - 1)) / 2;
			loadInit = arrowPos;
			
			% Draw load arrows
			for j = 1:arrowCount
				if q > 0
					CrossDraw.draftArrow2D(cnv,hnd,arrowPos,0,load_size,...
						arrowsize, arrowsize, pi/2, draw.GREEN);
				else
					CrossDraw.draftArrow2D(cnv,hnd,arrowPos,0,load_size,...
						arrowsize, arrowsize, -pi/2, draw.GREEN);
				end
				arrowPos = arrowPos + draw.mGapLoadArrow;
			end
			
			% Draw load top/bottom line
			loadEnd=arrowPos - draw.mGapLoadArrow;
			if q > 0
				line(cnv,[loadInit loadEnd],[load_size load_size],...
					'Color',draw.GREEN,'Parent',hnd);
				text(cnv,init_pos+len/2, load_size,...
					[num2str(q) ' kN/m'],...
					'Color', draw.GREEN,'HorizontalAlignment','center',...
					'VerticalAlignment','bottom','Parent',hnd)
			else
				line(cnv,[loadInit loadEnd],[-load_size -load_size],...
					'Color',draw.GREEN,'Parent',hnd);
				text(cnv,init_pos+len/2, -load_size,...
					[num2str(q) ' kN/m'],...
					'Color', draw.GREEN,'HorizontalAlignment','center',...
					'VerticalAlignment','top','Parent',hnd)
			end
		end
		
		function dimensionMember(draw,cnv,initPos,len,halfY,c)
			y = -0.80 * halfY;
			lenTxt = sprintf('%.*f m',draw.solver.decplc,len);
			t = text(cnv,initPos + len/2,y,lenTxt,...
				'Color', c,'HorizontalAlignment','center');
			textInit = t.Extent(1);
			textEnd = textInit + t.Extent(3);
			line(cnv,[initPos textInit],[y y],'Color', c);
			line(cnv,[textEnd initPos+len],[y y],'Color', c);
			line(cnv,[initPos-t.Extent(4)/3 initPos+t.Extent(4)/3], ...
				[y-t.Extent(4)/3 y+t.Extent(4)/3],'Color', c);
			line(cnv,...
				[initPos+len-t.Extent(4)/3 initPos+len+t.Extent(4)/3],...
				[y-t.Extent(4)/3 y+t.Extent(4)/3],'Color',c);
		end
		
		function draftDimensionMember(draw,cnv,hnd,initPos,len,halfY,c)
			y = -0.90 * halfY;
			t = text(cnv,initPos + len/2,y,...
				[num2str(round(len,draw.solver.decplc)) 'm'],...
				'Color', c,'HorizontalAlignment','center',...
				'Parent',hnd);
			textInit = t.Extent(1);
			textEnd = textInit + t.Extent(3);
			line(cnv,[initPos textInit],[y y],'Color', c,'Parent',hnd);
			line(cnv,[textEnd initPos+len],[y y],'Color', c,'Parent',hnd);
			line(cnv,[initPos-t.Extent(4)/3 initPos+t.Extent(4)/3], ...
				[y-t.Extent(4)/3 y+t.Extent(4)/3],'Color', c,...
				'Parent',hnd);
			line(cnv,...
				[initPos+len-t.Extent(4)/3 initPos+len+t.Extent(4)/3],...
				[y-t.Extent(4)/3 y+t.Extent(4)/3],'Color',c,...
				'Parent',hnd);
		end
	end
	
	%% Public methods
	methods
		%------------------------------------------------------------------
		% Returns the bounding box (x and y limits) of a continuous beam
		% model. The returned box has xmin = 0, xmax = totalLen,
		% ymin = -totalLen * 0.05, ymax = +totalLen * 0.05, in which
		% totalLen is the length of the entire beam model.
		% The y limits are fictitious. They are equal in module and
		% equal to a small percentage of the total length to force
		% the adjustment of the box in the y direction, keeping y = 0
		% in the center of the canvas.
		function bbox = crossBoundBox(draw)
			totalLen = draw.solver.totalLen;
			bbox(1) =  0;
			bbox(2) = -totalLen * 0.01;
			bbox(3) =  totalLen;
			bbox(4) =  totalLen * 0.01;
		end
		
		%------------------------------------------------------------------
		% Draws a continuous beam model with applied loads.
		function model(draw,cnv)
			% Clear canvas
			cla(cnv);
			
			% Draw continous beam without highlighting unbalanced nodes
			draw.beam(cnv,0,false);
			
			% Draw applied loads
			%%%%%%% COMPLETE HERE - CROSSDRAW: 01 %%%%%%%
			halfYsize = diff(cnv.YLim) * 0.5;
			max_load = draw.getMaxLoad();
			arrowsize = draw.solver.totalLen * CrossDraw.arrowsize_fac;
			minload_size = draw.solver.totalLen * CrossDraw.minloadsize_fac;
			load_step = draw.solver.totalLen * CrossDraw.loadstep_fac;
			init_pos = 0;
			for i = 1:draw.solver.nmemb
				len = draw.solver.membs(i).len;
				load_size = CrossDraw.loadsize_fac * halfYsize * ...
					(abs(draw.solver.membs(i).q) / max_load);
				if load_size < minload_size
					load_size = minload_size;
				end
				q = draw.solver.membs(i).q;
				draw.memberLoad(cnv,init_pos,len,q,load_size,load_step,arrowsize);
				init_pos = init_pos + len;
			end
			
			% Draw dimensions lines
			initPos = 0;
			for i=1:draw.solver.nmemb
				len = draw.solver.membs(i).len;
				draw.dimensionMember(cnv,initPos,len,...
					halfYsize,draw.GREY);
				initPos = initPos + len;
			end
			%%%%%%% COMPLETE HERE - CROSSDRAW: 01 %%%%%%%
		end
		
		%------------------------------------------------------------------
		% Draws a continuous beam model with its deformed configuration.
		function deformedConfig(draw,cnv)
			% Clear canvas
			cla(cnv);
			
			% Draw continous beam without highlighting unbalanced nodes
			draw.beam(cnv,0,false);
			
			% Draw deformed configuration
			%%%%%%% COMPLETE HERE - CROSSDRAW: 02 %%%%%%%
			halfYsize = diff(cnv.YLim) * 0.5;
            maxDisplOnScreen = draw.deformMax_fac * halfYsize;
            initPos=0;
            totalDisc = 50;
            v0 = zeros(1,totalDisc * draw.solver.nmemb);
            x0 = zeros(1,totalDisc * draw.solver.nmemb);
            for i=1:draw.solver.nmemb
                % Member attributes
                q = draw.solver.membs(i).q;
                EI = draw.solver.membs(i).EI;
                L = draw.solver.membs(i).len;
                L2 = L * L;
                L3 = L * L * L;
                x = linspace(0,L,totalDisc);
                if i==1 %% First member
                    endNodeRot = draw.solver.nodes(i).rot;
                    if draw.solver.supinit == CrossDraw.HING
                        v01 = draw.engastamento_perfeito(CrossDraw.HING,CrossDraw.CLAMP,L,q,EI,x);
                        [N2, N4] = draw.funcoes_forma(CrossDraw.HING,CrossDraw.CLAMP,L,x);
                        initNodeRot = (q/EI * (-L3/48)) + (-1/2) * endNodeRot;
                    elseif draw.solver.supinit == CrossDraw.CLAMP
                        v01 = draw.engastamento_perfeito(CrossDraw.CLAMP,CrossDraw.CLAMP,L,q,EI,x);
                        [N2, N4] = draw.funcoes_forma(CrossDraw.CLAMP,CrossDraw.CLAMP,L,x);
                        initNodeRot = 0;
                    elseif draw.solver.supinit == CrossDraw.FREE
                        v01 = draw.engastamento_perfeito(CrossDraw.FREE,CrossDraw.CLAMP,L,q,EI,x);
                        [N2, N4] = draw.funcoes_forma(CrossDraw.FREE,CrossDraw.CLAMP,L,x);
                        initNodeRot = (q*(L3/6))/EI + endNodeRot;
                    end
                elseif i==draw.solver.nmemb %% Last member
                    initNodeRot = draw.solver.nodes(i-1).rot;
                    if draw.solver.supend == CrossDraw.HING
                        v01 = draw.engastamento_perfeito(1,CrossDraw.HING,L,q,EI,x);
                        [N2, N4] = draw.funcoes_forma(1,CrossDraw.HING,L,x);
                        endNodeRot = (q/EI * ((-L3/8) + (5*L3/16) - (L3/6))) + ...
                            (-1/2) * initNodeRot;
                    elseif draw.solver.supend == CrossDraw.CLAMP
                        v01 = draw.engastamento_perfeito(CrossDraw.CLAMP,CrossDraw.CLAMP,L,q,EI,x);
                        [N2, N4] = draw.funcoes_forma(CrossDraw.CLAMP,CrossDraw.CLAMP,L,x);
                        endNodeRot = 0;
                    elseif draw.solver.supend == CrossDraw.FREE
                        v01 = draw.engastamento_perfeito(CrossDraw.CLAMP,CrossDraw.FREE,L,q,EI,x);
                        [N2, N4] = draw.funcoes_forma(CrossDraw.CLAMP,CrossDraw.FREE,L,x);
                        endNodeRot = (L^3*-q)/(6*EI) + initNodeRot;
                    end
                else %% Intermediate members
                    v01 = draw.engastamento_perfeito(1,1,L,q,EI,x);
                    [N2, N4] = draw.funcoes_forma(1,1,L,x);
                    initNodeRot = draw.solver.nodes(i-1).rot;
                    endNodeRot = draw.solver.nodes(i).rot;
                end
                v02 = initNodeRot .* N2 + endNodeRot .* N4;
                v0(1,((i-1)*totalDisc+1):((i)*totalDisc)) = v01 + v02;
                x0(1,((i-1)*totalDisc+1):((i)*totalDisc)) = initPos+x;
                initPos = initPos + L;
            end
            maxDisp = max(abs(v0));
            factor = maxDisplOnScreen / maxDisp;
            line(cnv,x0,v0.*factor,'Color',[235, 113, 52] *1/255);
            
            nodePos = draw.solver.membs(1).len;
            for i=1:draw.solver.nnode
                rot = draw.solver.nodes(i).rot * factor;
                if draw.solver.isNodeUnbalanced(i)
                    CrossDraw.arrow2DA(cnv,nodePos,0,maxDisplOnScreen*0.8,maxDisplOnScreen*0.3,maxDisplOnScreen*0.2,rot,[1 0 0])
                else
                    CrossDraw.arrow2DA(cnv,nodePos,0,maxDisplOnScreen*0.8,maxDisplOnScreen*0.3,maxDisplOnScreen*0.2,rot,[235, 113, 52] *1/255)
                end
                nodePos = nodePos + draw.solver.membs(i+1).len;
            end
			%%%%%%% COMPLETE HERE - CROSSDRAW: 02 %%%%%%%
		end
		
		%------------------------------------------------------------------
		% Draws a continuous beam model with its bending moment diagram
		% indicating the values at the ends and the maximum value of
		% non-linear diagrams.
		function bendingMomDiagram(draw,cnv)
			% Clear canvas
			cla(cnv);
			
			% Draw continous beam highlighting unbalanced nodes
			draw.beam(cnv,0,true);
			
			% Draw bending moment diagram
			%%%%%%% COMPLETE HERE - CROSSDRAW: 03 %%%%%%%
			initPos=0;
			totalDisc = 50;
			halfYsize = diff(cnv.YLim) * 0.5;
			maxMomentOnScreen = draw.deformMax_fac * halfYsize;
			M0 = zeros(1,totalDisc * draw.solver.nmemb);
			x0 = zeros(1,totalDisc * draw.solver.nmemb);
			for i=1:draw.solver.nmemb
				% Member attributes
				q = draw.solver.membs(i).q;
				L = draw.solver.membs(i).len;
				ml = draw.solver.membs(i).ml;
				mr = draw.solver.membs(i).mr;
				x = linspace(0,L,totalDisc);
				M = -ml * (L-x)/L + mr * (x/L) + (q*L)/2 .*x - q/2 .* x.^2;
				M0(1,((i-1)*totalDisc+1):((i)*totalDisc)) = M;
				x0(1,((i-1)*totalDisc+1):((i)*totalDisc)) = x+initPos;
				initPos = initPos + L;
			end
			maxM = max(abs(M0));
			factorMom = maxMomentOnScreen / maxM;
			line(cnv,x0,-M0.*factorMom,'Color',draw.MAGENTA);
			x=0;
			for i=1:draw.solver.nmemb
				initInd = (i-1) * totalDisc + 1;
				endInd = i * totalDisc;
				len = draw.solver.membs(i).len;
				line(cnv,[x x],[-M0(initInd)*factorMom 0],'Color',draw.MAGENTA);
				line(cnv,[x+len x+len],[-M0(endInd)*factorMom 0],'Color',draw.MAGENTA);
				x = x + len;
			end
			
			initPos=0;
			for i=1:draw.solver.nmemb
				% Member attributes
				L = draw.solver.membs(i).len;
				ml = draw.solver.membs(i).ml;
				mr = draw.solver.membs(i).mr;
				
				% Texts
				mlText = sprintf('%.*f kNm',draw.solver.decplc,-ml);
				mrText = sprintf('%.*f kNm',draw.solver.decplc,mr);
				if ml < 0
					text(cnv,initPos,ml*factorMom,mlText,...
						'Color', draw.MAGENTA,...
						'HorizontalAlignment','left',...
						'VerticalAlignment','top')
					text(cnv,initPos+L,-mr*factorMom,mrText,...
						'Color', draw.MAGENTA,...
						'HorizontalAlignment','right',...
						'VerticalAlignment','top')
				else
					text(cnv,initPos,ml*factorMom,mlText,...
						'Color', draw.MAGENTA,...
						'HorizontalAlignment','left',...
						'VerticalAlignment','bottom')
					text(cnv,initPos+L,-mr*factorMom,mrText,...
						'Color', draw.MAGENTA,...
						'HorizontalAlignment','right',...
						'VerticalAlignment','bottom')
				end
				initPos = initPos + L;
			end
			%%%%%%% COMPLETE HERE - CROSSDRAW: 03 %%%%%%%
		end
		
		%------------------------------------------------------------------
		% Draws a continuous beam with distribution coefficients and
		% member end bending moments in Cross sign convention.
		% Draws interative Cross solution table.
		function interativeSolution(draw,cnv)
			% Clear canvas
			cla(cnv);
			
			% Compute size of shift for text based on a
			% factor of total beam length
			totalLen = draw.solver.totalLen;
			textShift = draw.textshift_fac * totalLen;
			
			% Compute size of Y iterative solution
			canvasYsize = diff(cnv.YLim);
			solution_strip = draw.iterativesolutionsize_fac * canvasYsize;
			beamYstrip = canvasYsize - solution_strip;
			
			% Compute iterative solution row size in model coordinates
			solution_row = canvasYsize * (draw.solutionrow_size / cnv.Position(4));
			
			% Compute maximum number of visible solution rows
			max_numrows = floor(solution_strip/solution_row);
			
			% In case there is no iterative solution step, store initial
			% (fixed end) member bending moments
			if draw.solver.numSteps == 0
				draw.initMoments = [];
				draw.initMoments = zeros(1,2*draw.solver.nmemb);
				for i = 1:draw.solver.nmemb
					draw.initMoments(2*i -1) = draw.solver.membs(i).ml;
					draw.initMoments(2*i) = draw.solver.membs(i).mr;
				end
			end
			
			% Find top stage in table based on maximum number of rows
			topStage =  draw.solver.numSteps - max_numrows + 1;
			if topStage < 0
				topStage = 0;
			end
			
			% Find number of visible rows
%			 num_rows = draw.solver.numSteps - topStage + 1;
			
			% Draw continous beam
			posy = (canvasYsize - beamYstrip) * 0.5;
			draw.beamSolution(cnv,posy);
			
			% Draw iterative solution table
			%%%%%%% COMPLETE HERE - CROSSDRAW: 04 %%%%%%%
			% Draw top line to first row
			lineYPos = solution_row;
			line(cnv,[0 totalLen], [lineYPos lineYPos],'Color',draw.BLACK);
			lineYPos = lineYPos - solution_row;
			textYPos = solution_row * 0.5;
			if topStage == 0
				step0Txt = text(cnv,-textShift,textYPos,'0');
				step0Txt.HorizontalAlignment = 'right';
				step0Txt.VerticalAlignment = 'middle';
				currentLen = 0;
				for in = 1:draw.solver.nmemb
					ml = sprintf('%.*f',draw.solver.decplc,draw.initMoments(2*in - 1));
					mr = sprintf('%.*f',draw.solver.decplc,draw.initMoments(2*in));
					text(cnv,currentLen + textShift, textYPos, ml, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
					memberLen = draw.solver.membs(in).len;
					text(cnv,currentLen + memberLen - textShift, textYPos, mr, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
					currentLen = currentLen + memberLen;
				end
				line(cnv,[0 totalLen], [lineYPos lineYPos],'Color',draw.BLACK);
				lineYPos = lineYPos - solution_row;
				textYPos = textYPos - solution_row;
			end
			
			if draw.solver.numSteps > 0
%				 if draw.solver.numSteps > max_numrows
%					 c = draw.solver.numSteps - max_numrows;
%				 else
%					 c = 1;
%				 end
				
				k = 0;
				lim = topStage;
				if lim == 0
					lim = 1;
				end
				
				for j = lim:draw.solver.numSteps
					k = k + 1;
					sup_pos = 0;
					n = draw.solver.stepVector(j).n;
					
					for i = 1:n
						sup_pos = sup_pos + draw.solver.membs(i).len;
					end
					line(cnv, [0 totalLen], [lineYPos lineYPos], 'Color', [0 0 0]);
					sup_pos1 = sup_pos - draw.solver.membs(n).len;
					sup_pos2 = sup_pos + draw.solver.membs(n+1).len;
					
					tml = draw.solver.stepVector(j).tml;
					str_tml = sprintf('%.*f',draw.solver.decplc,tml);
					txt_tml = text(cnv, sup_pos1 + textShift, textYPos, str_tml);
					txt_tml.HorizontalAlignment = 'left';
					txt_tml.VerticalAlignment = 'middle';
		 
					bml = draw.solver.stepVector(j).bml;
					str_bml = sprintf('%.*f',draw.solver.decplc,bml);
					txt_bml = text(cnv, sup_pos - textShift, textYPos, str_bml);
					txt_bml.HorizontalAlignment = 'right';
					txt_bml.VerticalAlignment = 'middle';
		 
					bmr = draw.solver.stepVector(j).bmr;
					str_bmr = sprintf('%.*f',draw.solver.decplc,bmr);
					txt_bmr = text(cnv, sup_pos + textShift, textYPos, str_bmr);
					txt_bmr.HorizontalAlignment = 'left';
					txt_bmr.VerticalAlignment = 'middle';
		 
					tmr = draw.solver.stepVector(j).tmr;
					str_tmr = sprintf('%.*f',draw.solver.decplc,tmr);
					txt_tmr = text(cnv, sup_pos2 - textShift, textYPos, str_tmr);
					txt_tmr.HorizontalAlignment = 'right';
					txt_tmr.VerticalAlignment = 'middle';
		 
					step = j;
					str_step = sprintf('%.*f',0,step);
					txt_step = text(cnv, 0 - textShift, textYPos, str_step);
					txt_step.HorizontalAlignment = 'right';
					txt_step.VerticalAlignment = 'middle';
					
					lineYPos = lineYPos - solution_row;
					textYPos = textYPos - solution_row;
				end
			end
			%%%%%%% COMPLETE HERE - CROSSDRAW: 04 %%%%%%%
		end
		
		%------------------------------------------------------------------
		% Try to pick an interior support for a given mouse point point.
		% If found a support, return its index. Otherwise, return a null
		% inde
		% Output:
		% - n: index of interior support
		%  (if null, no interior support was found)
		function n = pickInteriorSup(draw,~,pt)
			n = 0;
			%%%%%%% COMPLETE HERE - CROSSDRAW: 05 %%%%%%%
			supsize = draw.solver.totalLen * CrossDraw.supsize_fac;
			node_pos = 0;
			for i = 1:draw.solver.nmemb-1
				len = draw.solver.membs(i).len;
				node_pos = node_pos + len;
				if inpolygon(pt(1),pt(2),...
						[node_pos-supsize,...
						node_pos+supsize,...
						node_pos+supsize,...
						node_pos-supsize],...
						[-supsize,-supsize,supsize,supsize])
					n = i;
					return
				end
			end
			%%%%%%% COMPLETE HERE - CROSSDRAW: 05 %%%%%%%
		end
		
		%------------------------------------------------------------------
		% Try to pick a position for inserting an interior support for a
		% given mouse point.
		% Input:
		% - pt: given point in model canvas
		% Output:
		% - stat: pick point status:
		%		 ValidSupInsertion = 1
		%		 BeamLineNotFound = 2
		%		 SupInsertionNotValid = 3
		% - m: index of pick member
		% - pos: position of inserted support inside pick member
		% The conditions for successfully inserting an interior support are:
		% - The given point should close to the continous beam line.
		% - The given point should not be close to an existing interior
		%   support
		function [stat,m,pos] = pickInsertSup(draw,pt)
			stat = draw.BeamLineNotFound;
			m = 0;
			pos = 0;
			minMembLen = draw.solver.totalLen * CrossDraw.minmemblen_fac;
			totalLen = draw.solver.totalLen;
			pick_tol = draw.solver.totalLen * CrossDraw.picktol_fac;
			%%%%%%% COMPLETE HERE - CROSSDRAW: 06 %%%%%%%
			% Checks if the point is in the tolerance rectangle
			len1 = draw.solver.membs(1).len;
			lenend = draw.solver.membs(end).len;
			if inpolygon(pt(1),pt(2),...
					[0 totalLen totalLen 0],...
					[-pick_tol/2 -pick_tol/2 pick_tol/2 pick_tol/2])
				
				if inpolygon( pt(1), pt(2), ...
						[ - len1 * CrossDraw.minmemblen_fac, len1 * CrossDraw.minmemblen_fac, ...
						len1 * CrossDraw.minmemblen_fac, - len1 * CrossDraw.minmemblen_fac ], ...
						[- pick_tol, - pick_tol, pick_tol, pick_tol] ) && (draw.solver.supinit == 0 || draw.solver.supinit == 1)
					
					stat = CrossDraw.SupInsertionNotValid;
					
					% Verificate the last support
					
				elseif inpolygon( pt(1), pt(2), ...
						[ totalLen - lenend * CrossDraw.minmemblen_fac, totalLen + lenend * CrossDraw.minmemblen_fac, ...
						totalLen + lenend * CrossDraw.minmemblen_fac, totalLen - lenend * CrossDraw.minmemblen_fac ], ...
						[- pick_tol, - pick_tol, pick_tol, pick_tol] ) && (draw.solver.supend == 0 || draw.solver.supend == 1)
					
					stat = CrossDraw.SupInsertionNotValid;
					
				else
					initPos = 0;
					for i = 1:draw.solver.nmemb
						initPos = initPos + draw.solver.membs(i).len;
						% Member clicked has founded
						if pt(1) < initPos
							len = draw.solver.membs(i).len;
							len2 = initPos - pt(1);
							len1 = len - len2;
							
							% Pick on member that has the minMembLen
							if len1 < minMembLen && len2 < minMembLen
								stat = draw.SupInsertionNotValid;
								m = i;
								return
							end
							
							% Pick on member bigger than minMembLen
							if len1 >= minMembLen && len2 >= minMembLen
								stat = draw.ValidSupInsertion;
								pos = len1;
								m = i;
								return
							end
							
							% Pick on member that result in a left minMembLen
							if len1 >= minMembLen && len2 < minMembLen
								stat = draw.ValidSupInsertion;
								pos = len - minMembLen;
								m = i;
								return
							end
							
							% Pick on member that result in a right minMembLen
							if len1 < minMembLen && len2 >= minMembLen
								stat = draw.ValidSupInsertion;
								pos = minMembLen;
								m = i;
								return
							end
						end
					end
				end
			end
			%%%%%%% COMPLETE HERE - CROSSDRAW: 06 %%%%%%%
		end
		
		%------------------------------------------------------------------
		% Try to pick an interior support for deletion for a given mouse point.
		% Input:
		% - pt: given point in model canvas
		% Output:
		% - stat: pick point status:
		%		 SupDelMinNumSup = 1
		%		 ValidSupDeletion = 2
		%		 SupDelNotFound = 3
		% - n: index of internal support to delete (from 1 to nnode)
		% The conditions for successfully deleting an interior support are:
		% - The given point should close to an interior support.
		% - There must be at least two interior supports
		function [stat,n] = pickDeleteSup(draw,pt)
			n = 0;
			if draw.solver.nnode < 2
				stat = draw.SupDelMinNumSup;
				return
			end
			%%%%%%% COMPLETE HERE - CROSSDRAW: 07 %%%%%%%
			totalLen = draw.solver.totalLen;
			supsize = draw.solver.totalLen * CrossDraw.supsize_fac;
			node_pos = 0;
			
			len1 = draw.solver.membs(1).len;
			lenend = draw.solver.membs(end).len;
			for i = 1:draw.solver.nmemb-1
				len = draw.solver.membs(i).len;
				node_pos = node_pos + len;
				if inpolygon(pt(1),pt(2),...
						[node_pos-supsize,...
						node_pos+supsize,...
						node_pos+supsize,...
						node_pos-supsize],...
						[-supsize,-supsize,supsize,supsize])
					% Verificate the initial support
					
					if inpolygon( pt(1), pt(2), ...
							[ - len1 * CrossDraw.minmemblen_fac, len1 * CrossDraw.minmemblen_fac, len1 * CrossDraw.minmemblen_fac, - len1 * CrossDraw.minmemblen_fac ], ...
							[- supsize, - supsize, supsize, supsize] ) && draw.solver.supinit == 2
						
						stat = CrossDraw.SupDelNotFound;
						
						return
						
						% Verificate the last support
						
					elseif inpolygon( pt(1), pt(2), ...
							[ totalLen - lenend * CrossDraw.minmemblen_fac, totalLen + len1 * CrossDraw.minmemblen_fac, ...
							totalLen + len1 * CrossDraw.minmemblen_fac, totalLen - len1 * CrossDraw.minmemblen_fac ], ...
							[- supsize, - supsize, supsize, supsize] ) && draw.solver.supend == 2
						
						stat = CrossDraw.SupDelNotFound;
						
						return
						
						% Verificate the internal supports
						
					else
						n = i;
						stat = draw.ValidSupDeletion;
					end
					return
				end
			end
			stat = draw.SupDelNotFound;
			%%%%%%% COMPLETE HERE - CROSSDRAW: 07 %%%%%%%
		end
		
		%------------------------------------------------------------------
		% Try to pick a member load for a given mouse point point.
		% If found a member load, display its draft version.
		% Save pick member index and handle to draft graphics object.
		% Output:
		% - stat: pick point status:
		%		 MembLoadFound = 1
		%		 MembLoadNotFound = 2
		function stat = pickMemberLoad(draw,cnv,pt)
			stat = draw.MembLoadNotFound;
			draw.pickmember = 0;
			draw.hnd_draft = [];
			halfYsize = diff(cnv.YLim) * 0.5;
			max_load = draw.getMaxLoad();
			minload_size = draw.solver.totalLen * CrossDraw.minloadsize_fac;
			pick_tol = draw.solver.totalLen * CrossDraw.picktol_fac;
			load_step = draw.solver.totalLen * CrossDraw.loadstep_fac;
			%%%%%%% COMPLETE HERE - CROSSDRAW: 08 %%%%%%%
			arrowsize = draw.solver.totalLen * CrossDraw.arrowsize_fac;
			init_pos = 0;
			for i = 1:draw.solver.nmemb
				len = draw.solver.membs(i).len;
				q = draw.solver.membs(i).q;
				load_size = CrossDraw.loadsize_fac * halfYsize * ...
					(abs(q) / max_load);
				load_size = max(load_size, minload_size);
				if q > 0
					in = inpolygon(pt(1),pt(2),...
						[init_pos init_pos+len init_pos+len init_pos],...
						[load_size-pick_tol load_size-pick_tol load_size+pick_tol load_size+pick_tol]);
				else
					in = inpolygon(pt(1),pt(2),...
						[init_pos init_pos+len init_pos+len init_pos],...
						[-load_size-pick_tol -load_size-pick_tol -load_size+pick_tol -load_size+pick_tol]);
				end
				
				if in
					draw.pickmember = i;
					% Create group for graphics group
					draw.hnd_draft = hggroup(cnv);
					% Draw draft version of member load
					draw.draftMemberLoad(cnv,draw.hnd_draft,init_pos,len,q,load_size,load_step,...
						arrowsize);
					stat = draw.MembLoadFound;
					return
				end
				init_pos = init_pos + len;
			end
			%%%%%%% COMPLETE HERE - CROSSDRAW: 08 %%%%%%%
		end
		
		%------------------------------------------------------------------
		% If there is a pick member load, delete current draft graphics
		% object and redisplay it in the new position defined by
		% given mouse point point.
		function updateMemberLoad(draw,cnv,pt)
			if ~isempty(draw.hnd_draft)
				delete(draw.hnd_draft);
				draw.hnd_draft = [];
			end
			if draw.pickmember < 1
				return
			end
			halfYsize = diff(cnv.YLim) * 0.5;
			max_load = draw.getMaxLoad();
			load_step = draw.solver.totalLen * CrossDraw.loadstep_fac;
			%%%%%%% COMPLETE HERE - CROSSDRAW: 09 %%%%%%%
			arrowsize = draw.solver.totalLen * CrossDraw.arrowsize_fac;
			init_pos = 0;
			for i = 1:draw.pickmember-1
				len = draw.solver.membs(i).len;
				init_pos = init_pos + len;
			end
			len = draw.solver.membs(draw.pickmember).len;
			
			load_size = abs(pt(2));
			
			q = (load_size * max_load) / (CrossDraw.loadsize_fac * halfYsize);
			
			q = draw.snapToStepValue(q,0.5);
			
			if pt(2) < 0
				q = q * (-1);
			end
			
			load_size = CrossDraw.loadsize_fac * halfYsize * ...
				(abs(q) / max_load);
			minload_size = draw.solver.totalLen * CrossDraw.minloadsize_fac;
			load_size = max(load_size, minload_size);
			draw.hnd_draft = hggroup(cnv);
			draw.draftMemberLoad(cnv,draw.hnd_draft,init_pos,len,q,load_size,load_step,arrowsize);
			%%%%%%% COMPLETE HERE - CROSSDRAW: 09 %%%%%%%
		end
		
		%------------------------------------------------------------------
		% If there is a pick member load, delete current draft graphics
		% object and return pick member and load value defined by
		% given mouse point point.
		% Also reset handle to current draft graphics object and index
		% of current picked member.
		% Output:
		% - m: index of member
		% - q: updated uniform load value
		function [m,q] = setMemberLoad(draw,cnv,pt)
			if ~isempty(draw.hnd_draft)
				delete(draw.hnd_draft);
				draw.hnd_draft = [];
			end
			m = draw.pickmember;
			draw.pickmember = 0;
			q = 0;
			if m < 1
				return
			end
			halfYsize = diff(cnv.YLim) * 0.5;
			max_load = draw.getMaxLoad();
			%%%%%%% COMPLETE HERE - CROSSDRAW: 10 %%%%%%%
			load_size = abs(pt(2));
			q = (load_size * max_load) / (CrossDraw.loadsize_fac * halfYsize);
			q = draw.snapToStepValue(q,0.5);
			if pt(2) < 0
				q = q * (-1);
			end
			%%%%%%% COMPLETE HERE - CROSSDRAW: 10 %%%%%%%
		end
		
		%------------------------------------------------------------------
		% Try to pick a support for a given mouse point point.
		% If found a support, display its draft version.
		% Save pick support index and handle to draft graphics object.
		% Output:
		% - stat: pick point status:
		%		 SupMoveFound = 1
		%		 SupMoveNotFound = 2
		function stat = pickSupMove(draw,cnv,pt)
			stat = draw.SupMoveNotFound;
			draw.picksup = 0;
			draw.hnd_draft = [];
			%%%%%%% COMPLETE HERE - CROSSDRAW: 11 %%%%%%%
			halfYsize = diff(cnv.YLim) * 0.5;
			max_load = draw.getMaxLoad();
			minload_size = draw.solver.totalLen * CrossDraw.minloadsize_fac;
			load_step = draw.solver.totalLen * CrossDraw.loadstep_fac;
			arrowsize = draw.solver.totalLen * CrossDraw.arrowsize_fac;
			supsize = draw.solver.totalLen * CrossDraw.supsize_fac;
			totalLen = draw.solver.totalLen;
			node_pos = 0;

			% 1 for supinit, 
			% 2 for first internal support, etc.
			% (draw.solver.nnode + 2) for supend
			lastSup = draw.solver.nnode + 2;
			for ind = 1:lastSup
				inpol = inpolygon(pt(1),pt(2),...
							[node_pos - supsize,...
							node_pos + supsize,...
							node_pos + supsize,...
							node_pos - supsize],...
							[-supsize,-supsize,supsize,supsize]);
				if inpol
					draw.picksup = ind;
					stat = draw.SupMoveFound;
					draw.hnd_draft = hggroup(cnv);
					
					% Apoio inicial, simples
					if ind == 1 && draw.solver.supinit == 0
						draw.draftTriangle(cnv,draw.hnd_draft,node_pos,0,...
							supsize,supsize,-pi/2,draw.GREEN);
					% Apoio inicial, engastado
					elseif ind == 1 && draw.solver.supinit == 1
						draw.draftThirdGenSupport(cnv,draw.hnd_draft,node_pos,...
							0,supsize,draw.GREEN,true);
					% Apoio inicial, livre
					elseif ind == 1 && draw.solver.supinit == 2
						% Do nothing
						return
					end
					
					% Apoio final, simples
					if ind == lastSup && draw.solver.supend == 0
						draw.draftTriangle(cnv,draw.hnd_draft,node_pos,0,...
							supsize,supsize,-pi/2,draw.GREEN);
					% Apoio final, engastado
					elseif ind == lastSup && draw.solver.supend == 1
						 draw.draftThirdGenSupport(cnv,draw.hnd_draft,node_pos,...
							0,supsize,draw.GREEN,false);
					elseif ind == lastSup && draw.solver.supend == 2
						% Do nothing
						return						 
					end

					if ind == 1
						qR = draw.solver.membs(ind).q;
						lenR = draw.solver.membs(ind).len;

						loadSizeR = CrossDraw.loadsize_fac * halfYsize * ...
							(abs(qR) / max_load);
						loadSizeR = max(loadSizeR, minload_size);

						draw.draftMemberLoad(cnv,draw.hnd_draft,node_pos,lenR,...
							qR,loadSizeR,load_step,arrowsize);
						draw.draftDimensionMember(cnv,draw.hnd_draft,node_pos,lenR,...
							halfYsize,draw.GREEN);
						return
					elseif ind == lastSup
						qL = draw.solver.membs(ind-1).q;
						lenL = draw.solver.membs(ind-1).len;

						loadSizeL = CrossDraw.loadsize_fac * halfYsize * ...
							(abs(qL) / max_load);
						loadSizeL = max(loadSizeL, minload_size);

						draw.draftMemberLoad(cnv,draw.hnd_draft,totalLen-lenL,lenL,...
							qL,loadSizeL,load_step,arrowsize);
						draw.draftDimensionMember(cnv,draw.hnd_draft,totalLen-lenL,lenL,...
							halfYsize,draw.GREEN);
						return
					else
						qL = draw.solver.membs(ind-1).q;
						qR = draw.solver.membs(ind).q;
						lenL = draw.solver.membs(ind-1).len;
						lenR = draw.solver.membs(ind).len;

						loadSizeL = CrossDraw.loadsize_fac * halfYsize * ...
							(abs(qL) / max_load);
						loadSizeL = max(loadSizeL, minload_size);
						loadSizeR = CrossDraw.loadsize_fac * halfYsize * ...
							(abs(qR) / max_load);
						loadSizeR = max(loadSizeR, minload_size);

						draw.draftMemberLoad(cnv,draw.hnd_draft,node_pos-lenL,lenL,...
							qL,loadSizeL,load_step,arrowsize);
						draw.draftDimensionMember(cnv,draw.hnd_draft,node_pos-lenL,lenL,...
							halfYsize,draw.GREEN);
						draw.draftMemberLoad(cnv,draw.hnd_draft,node_pos,lenR,...
							qR,loadSizeR,load_step,arrowsize);
						draw.draftDimensionMember(cnv,draw.hnd_draft,node_pos,lenR,...
							halfYsize,draw.GREEN);
						return
					end
                end
                if ind < lastSup
                    node_pos = node_pos + draw.solver.membs(ind).len;
                end
			end
			%%%%%%% COMPLETE HERE - CROSSDRAW: 11 %%%%%%%
		end
		
		%------------------------------------------------------------------
		% If there is a pick support, delete current draft graphics
		% object and redisplay it in the new position defined by
		% given mouse point point.
        function updateSupMove(draw,cnv,pt)
            if ~isempty(draw.hnd_draft)
                delete(draw.hnd_draft);
                draw.hnd_draft = [];
            end
            if draw.picksup == 0
                return
            end
            %%%%%%% COMPLETE HERE - CROSSDRAW: 12 %%%%%%%
            minMembLen = draw.solver.totalLen * CrossDraw.minmemblen_fac;
            halfYsize = diff(cnv.YLim) * 0.5;
            max_load = draw.getMaxLoad();
            minload_size = draw.solver.totalLen * CrossDraw.minloadsize_fac;
            load_step = draw.solver.totalLen * CrossDraw.loadstep_fac;
            arrowsize = draw.solver.totalLen * CrossDraw.arrowsize_fac;
            supsize = draw.solver.totalLen * CrossDraw.supsize_fac;
            totalLen = draw.solver.totalLen;
            node_pos = 0;
            
            lastSup = draw.solver.nnode + 2;
            if draw.picksup > 1 && draw.picksup < lastSup
                for i = 2:draw.picksup
                    len = draw.solver.membs(i-1).len;
                    node_pos = node_pos + len;
                end
            elseif draw.picksup == lastSup
                node_pos = totalLen;
            end
            
            if draw.picksup == 1
                memberRLen = draw.solver.membs(1).len;
                maxX = memberRLen - minMembLen; % if negative, maxX is less than minimumn
                maxX = max(maxX, minMembLen);
                
                memberLLen = [];
                minX = [];
            elseif draw.picksup == lastSup
                memberLLen = draw.solver.membs(end).len;
                if memberLLen < minMembLen
                    minX = node_pos;
                else
                    minX = node_pos - (memberLLen - minMembLen);
                end
                
                memberRLen = [];
                maxX = [];
            else
                memberLLen = draw.solver.membs(draw.picksup - 1).len;
                memberRLen = draw.solver.membs(draw.picksup).len;
                
                if memberLLen <= minMembLen
                    minX = node_pos;
                else
                    minX = node_pos - (memberLLen - minMembLen);
                end
                
                if memberRLen <= minMembLen
                    maxX = node_pos;
                else
                    maxX = node_pos + (memberRLen - minMembLen);
                end
            end
            
            if draw.picksup == 1
                if pt(1) <= maxX
                    nodeX = draw.snapToStepValue(pt(1),0.1);
                    nodeDiff = node_pos - nodeX;
                    RLen = memberRLen + nodeDiff;
                else
                    nodeX = maxX;
                    RLen = minMembLen;
                end
            elseif draw.picksup == lastSup
                if pt(1) >= minX
                    nodeX = draw.snapToStepValue(pt(1),0.1);
                    nodeDiff = node_pos - nodeX;
                    LLen = memberLLen - nodeDiff;
                else
                    nodeX = minX;
                    LLen = minMembLen;
                end
            else
                if pt(1) >= minX && pt(1) <= maxX
                    nodeX = draw.snapToStepValue(pt(1),0.1);
                    nodeDiff = node_pos - nodeX;
                    LLen = memberLLen - nodeDiff;
                    RLen = memberRLen + nodeDiff;
                elseif pt(1) < minX
                    nodeX = minX;
                    nodeDiff = node_pos - nodeX;
                    LLen = minMembLen;
                    RLen = memberRLen + nodeDiff;
                elseif pt(1) > maxX
                    nodeX = maxX;
                    nodeDiff = node_pos - nodeX;
                    LLen = memberLLen - nodeDiff;
                    RLen = minMembLen;
                end
            end
            
            % Draw the support
            draw.hnd_draft = hggroup(cnv);
            if draw.picksup == 1
                if draw.solver.supinit == 0
                    draw.draftTriangle(cnv,draw.hnd_draft,nodeX,0,...
                        supsize,supsize,-pi/2,draw.GREEN);
                elseif draw.solver.supinit == 01
                    draw.draftThirdGenSupport(cnv,draw.hnd_draft,nodeX,...
                        0,supsize,draw.GREEN,true);
                end
            elseif draw.picksup == lastSup
                if draw.solver.supend == 0
                    draw.draftTriangle(cnv,draw.hnd_draft,nodeX,0,...
                        supsize,supsize,-pi/2,draw.GREEN);
                elseif draw.solver.supend == 1
                    draw.draftThirdGenSupport(cnv,draw.hnd_draft,nodeX,...
                        0,supsize,draw.GREEN,false);
                end
            else
                draw.draftTriangle(cnv,draw.hnd_draft,nodeX,0,...
                    supsize,supsize,-pi/2,draw.GREEN);
            end
            
            % Draw the member Load and the dimension load
            if draw.picksup == 1
                qR = draw.solver.membs(1).q;
                
                loadSizeR = CrossDraw.loadsize_fac * halfYsize * ...
                    (abs(qR) / max_load);
                loadSizeR = max(loadSizeR, minload_size);
                
                draw.draftMemberLoad(cnv,draw.hnd_draft,nodeX,RLen,...
                    qR,loadSizeR,load_step,arrowsize);
                draw.draftDimensionMember(cnv,draw.hnd_draft,nodeX,RLen,...
                    halfYsize,draw.GREEN);
                return
            elseif draw.picksup == lastSup
                qL = draw.solver.membs(end).q;
                lenLast = draw.solver.membs(end).len;
                
                loadSizeL = CrossDraw.loadsize_fac * halfYsize * ...
                    (abs(qL) / max_load);
                loadSizeL = max(loadSizeL, minload_size);
                
                draw.draftMemberLoad(cnv,draw.hnd_draft,totalLen - lenLast,LLen,...
                    qL,loadSizeL,load_step,arrowsize);
                draw.draftDimensionMember(cnv,draw.hnd_draft,totalLen - lenLast,LLen,...
                    halfYsize,draw.GREEN);
                return
            else
                qL = draw.solver.membs(draw.picksup-1).q;
                qR = draw.solver.membs(draw.picksup).q;
                
                loadSizeL = CrossDraw.loadsize_fac * halfYsize * ...
                    (abs(qL) / max_load);
                loadSizeL = max(loadSizeL, minload_size);
                loadSizeR = CrossDraw.loadsize_fac * halfYsize * ...
                    (abs(qR) / max_load);
                loadSizeR = max(loadSizeR, minload_size);
                
                draw.draftMemberLoad(cnv,draw.hnd_draft,node_pos-memberLLen,LLen,...
                    qL,loadSizeL,load_step,arrowsize);
                draw.draftDimensionMember(cnv,draw.hnd_draft,node_pos-memberLLen,LLen,...
                    halfYsize,draw.GREEN);
                draw.draftMemberLoad(cnv,draw.hnd_draft,nodeX,RLen,...
                    qR,loadSizeR,load_step,arrowsize);
                draw.draftDimensionMember(cnv,draw.hnd_draft,nodeX,RLen,...
                    halfYsize,draw.GREEN);
            end
            %%%%%%% COMPLETE HERE - CROSSDRAW: 12 %%%%%%%
        end
		
		%------------------------------------------------------------------
		% If there is a pick support, delete current draft graphics
		% object and return pick support and new position defined by
		% given mouse point point.
		% Also reset handle to current draft graphics object and index
		% of current picked support.
		% Output:
		% - n: index of support (from 1 to nmembs+1)
		% - shift: support position shift (negative or positive)
		function [n,shift] = setSupMove(draw,~,pt)
			n = 0;
			shift = 0;
			if ~isempty(draw.hnd_draft)
				delete(draw.hnd_draft);
				draw.hnd_draft = [];
			end
			if draw.picksup < 1
				return
			end
			n = draw.picksup;
			%%%%%%% COMPLETE HERE - CROSSDRAW: 13 %%%%%%%
			minMembLen = draw.solver.totalLen * CrossDraw.minmemblen_fac;
            totalLen = draw.solver.totalLen;
            node_pos = 0;
			lastSup = draw.solver.nnode + 2;
			if draw.picksup > 1 && draw.picksup < lastSup
				for i = 2:draw.picksup
					len = draw.solver.membs(i-1).len;
					node_pos = node_pos + len;
				end
			elseif draw.picksup == lastSup
				node_pos = totalLen;
			end

			if draw.picksup == 1
				memberRLen = draw.solver.membs(1).len;
				maxX = memberRLen - minMembLen; % if negative, maxX is less than minimumn
				maxX = max(maxX, minMembLen);

				minX = [];
			elseif draw.picksup == lastSup
				memberLLen = draw.solver.membs(end).len;
                if memberLLen < minMembLen
                    minX = node_pos;
                else
                    minX = node_pos - (memberLLen - minMembLen);
                end
				maxX = [];
			else
				memberLLen = draw.solver.membs(draw.picksup - 1).len;
				memberRLen = draw.solver.membs(draw.picksup).len;

				if memberLLen <= minMembLen
					minX = node_pos;
				else
					minX = node_pos - (memberLLen - minMembLen);
				end
				
				if memberRLen <= minMembLen
					maxX = node_pos;
				else
					maxX = node_pos + (memberRLen - minMembLen);
				end
			end

			if draw.picksup == 1
				if pt(1) <= maxX
					nodeX = draw.snapToStepValue(pt(1),0.1);
                else
                    nodeX = maxX;
				end
			elseif draw.picksup == lastSup
				if pt(1) >= minX
					nodeX = draw.snapToStepValue(pt(1),0.1);
                else
                    nodeX = minX;
				end
			else
				if pt(1) >= minX && pt(1) <= maxX
					nodeX = draw.snapToStepValue(pt(1),0.1);
				elseif pt(1) < minX
					nodeX = minX;
				elseif pt(1) > maxX
					nodeX = maxX;
				end
			end
			shift = nodeX - node_pos;
			%%%%%%% COMPLETE HERE - CROSSDRAW: 13 %%%%%%%
			draw.picksup = 0;
			draw.orig_suppos = 0;
		end
		
		%------------------------------------------------------------------
		% Cleans data structure of a CrossSolver object.
		function draw = clean(draw)
			draw.solver = [];
			draw.initMoments = [];
		end
	end
end