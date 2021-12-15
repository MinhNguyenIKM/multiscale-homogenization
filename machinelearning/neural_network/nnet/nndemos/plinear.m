function dy=plinear(t,y)
%PLINEAR Differential equation system for desired linear pendulum.
%  
%  PLINEAR(T,Y)
%    T - Time.
%    Y - Current state of inverted pendulum.
%  Returns derivatives of the pendulum state.
%  
%  The state vector Y has three values:
%    Y(1) - Pendulum angle from -2 pi to 2 pi radians.
%    Y(2) - Pendulum angular velocity in radians/second.
%    Y(3) - Demand angle for the pendulum.
%  
%  NOTES: Angle is 0 radians when the pendulum points up.
%         Demand stays constant, its derivative is always 0.
%  
%  See also APPCS1, PMODEL.

% Mark Beale, 12-15-93
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.11.2.3 $  $Date: 2007/11/09 20:48:29 $

if nargin < 2,error('NNET:Arguments','Not enough input arguments.'), end

% STATE
angle  = y(1);
vel    = y(2);
demand = y(3);

% CALCULATE DERIVATIVES
dangle  = vel;
dvel    = -9*angle - 6*vel + 9*demand;
ddemand = 0;

% RETURN DERIVATIVES
dy = [dangle; dvel; ddemand];
