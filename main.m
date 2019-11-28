%% Cross06
%
% This is a MATLAB program for solving a continuous beam using the
% Cross Process.
% Euler-Bernoulli flexural behavior is assumed (Navier beam theory).
% This is an initial version without any GUI (Graphics User Interface).
%
% This program implements the Cross Process for continuous beams with
% uniformly distributed loads in each spam.
%
% For more details of this process, refer to the book "Análise de
% Estruturas: Conceitos e Métodos Básicos", Second Edition, by Luiz
% Fernando Martha, Elsevier, 2017.
%
%% Object oriented classes
% This program adopts an Object Oriented Programming (OOP) paradigm, in
% which the following OOP classes are implemented:
%%%
% * <crosssolver.html *CrossSolver*> class.
% * <crossmember.html *CrossMember*> class.
% * <crossnode.html *CrossNode*> class.
% * <crossstep.html *CrossStep*> class.
% * <crosscontrol.html *CrossControl*> class.
% * <crossdraw.html *CrossDraw*> class.
%
%% Author
% Luiz Fernando Martha
%
%% History
% @version 1.05
%
% Initial version: August 2019
%%%
% Initially prepared for the course CIV 2801 - Fundamentos de Computação
% Gráfica, 2019, second term, Department of Civil Engineering, PUC-Rio.
%
% Version 1.01: September 2019
%%%
% Creation of a simple dialog (figure) with a canvas (axes) to display
% a continous beam model with suports, uniformely distributed forces, and
% dimension lines.
%
% Version 1.02: September 2019
%%%
% Creation two other canvas (axes) to display deformed configuration and
% bending moment of continous beam.
%
% Version 1.04: October 2019
%%%
% Handling of mouse events in canvases - Part 1.
% Events that do not involve mouse drag: internal support insertion and 
% deletion in model canvas and node balancing in bending moment canvas.
%
% Version 1.05: October 2019
%%%
% Handling of mouse events in canvases - Part 2.
% Events that involve mouse drag: interactive change of distributed load
% value and interactive move of support.
%
% Version 1.06: October 2019
%%%
% Implementation of Cross iterative steps solution canvas.
%
%% Initialization

% Clear workspace
clear
close(findall(0,'Type','figure'));
clc

% Add path to canvas, cross, and images folders
addpath('mouse','canvas','cross','gui','images');

%% Start up app
CrossGUI
