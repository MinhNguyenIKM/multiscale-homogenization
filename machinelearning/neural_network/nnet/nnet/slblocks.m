function blkStruct = slblocks
%SLBLOCKS Defines the block library for a specific Toolbox or Blockset.

% Mark Beale, 11-31-97
% Copyright 1992-2005 The MathWorks, Inc.
% $Revision: 1.12.4.2 $

blkStruct.Name = sprintf('Neural\nNetwork\nBlockset');
blkStruct.OpenFcn = 'neural';
blkStruct.IsFlat  = 0;% Is this library "flat" (i.e. no subsystems)?

% blkStruct.MaskDisplay = '';


% Define the library list for the Simulink Library browser.
% Return the name of the library model and the name for it.
Browser(1).Library = 'neural';
Browser(1).Name    = 'Neural Network Toolbox';
Browser(1).IsFlat  = 0; % Is this library "flat" (i.e. no subsystems)?

blkStruct.Browser = Browser;

% End of slblocks.m
