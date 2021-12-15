function nndataexport(cmd,arg1,arg2,arg3)
%NNDATAEXPORT Data Export GUI for the Neural Network Controller Toolbox.
%
%  Synopsis
%
%    nndataexport(cmd,arg1,arg2,arg3)
%
%  Warning!!
%
%    This function may be altered or removed in future
%    releases of the Neural Network Toolbox. We recommend
%    you do not write code which calls this function.
%    This function is generally being called from a Simulink block.

% Orlando De Jesus, Martin Hagan, 1-25-00
% Copyright 1992-2005 The MathWorks, Inc.
% $Revision: 1.5.2.2 $ $Date: 2005/12/22 18:18:28 $


% CONSTANTS
me = 'Export Data.';

% DEFAULTS
if nargin == 0, cmd = ''; else cmd = lower(cmd); end

% FIND WINDOW IF IT EXISTS
fig=findall(0,'type','figure','name',me);
if (size(fig,1)==0), fig=0; end

if length(get(fig,'children')) == 0, fig = 0; end

if fig
   ud = get(fig,'userdata');
end

if strcmp(cmd,'init')
  if strcmp(arg2,'ref')
    if ~exist(cat(2,tempdir,'nnmodrefdata.mat'))
      warndlg('There is no data to export.','Export Warning','modal');
      return      
    end
  else
    if ~exist(cat(2,tempdir,'nnidentdata.mat'))
      warndlg('There is no data to export.','Export Warning','modal');
      return      
    end
  end
  if fig==0  
    StdColor = get(0,'DefaultFigureColor');
    PointsToPixels = 72/get(0,'ScreenPixelsPerInch');
    StdUnit = 'character';
    ud.Handles.parent=arg1;
    ud.Handles.type_net=arg2;

%ud = ExportData;
%ud.ListData = struct('Names','','Objects',[]);

uipos = getuipos;

%---Open an Export figure
    fig = figure('Color',StdColor, ...
     'Interruptible','off', ...
     'BusyAction','cancel', ...
     'HandleVis','Callback', ...
    'MenuBar','none', ...
     'Visible','on',...
     'Name',me, ...
     'IntegerHandle','off',...
     'NumberTitle','off', ...
     'Resize', 'off', ...
     'WindowStyle','modal',...
     'Units', StdUnit, ...
     'Position',uipos.fig, ...
    'Tag','nndataexport');

%---Add the Export List controls
    b = uicontrol('Parent',fig, ...
    'Units',StdUnit, ...
      'BackgroundColor',StdColor, ...
      'Position',uipos.b_1, ...
     'Style','frame');
    b = uicontrol('Parent',fig, ...
    'Units',StdUnit, ...
      'BackgroundColor',StdColor, ...
    'Position',uipos.b_2, ...
    'String','Select', ...
    'Style','text');
    ud.Handles.nnplant = uicontrol('Parent',fig, ...
     'Units',StdUnit, ...
     'HorizontalAlignment','right', ...
    'BackgroundColor',StdColor, ...
    'ListboxTop',0, ...
    'Position',uipos.nnplant, ...
    'String','Data Structure Name:', ...
    'Style','text', ...
    'Tag','Radiobutton1', ...
     'ToolTipStr','Defines the name of the data structure.',...
     'Value',1);
    ud.Handles.nnplantedit = uicontrol('Parent',fig, ...
    'Units',StdUnit, ...
    'BackgroundColor',[1 1 1], ...
    'ListboxTop',0, ...
    'Position',uipos.nnplantedit, ...
    'String','tr_dat', ...
    'Style','edit', ...
     'ToolTipStr','You can select the name for the data structure.',...
    'Tag','EditText1');

  %---Add the window buttons
    b = uicontrol('Parent',fig, ...
    'Units',StdUnit, ...
    'BackgroundColor',StdColor, ...
    'Position',uipos.b_3, ...
    'Style','frame');
    ud.Handles.DiskButton = uicontrol('Parent',fig, ...
    'Units',StdUnit, ...
    'Position',uipos.DiskButton, ...
     'Callback','nncontrolutil(''nndataexport'',''disk'',gcbf);',...
    'String','Export to Disk', ...
     'ToolTipStr','Export the data structure to a file.',...
    'Tag','DiskButton');
    ud.Handles.WorkspaceButton = uicontrol('Parent',fig, ...
    'Units',StdUnit, ...
    'Position',uipos.WorkspaceButton, ...
     'Callback','nncontrolutil(''nndataexport'',''workspace'',gcbf);',...
    'String','Export to Workspace', ...
     'ToolTipStr','Export the data structure to the MATLAB workspace.',...
    'Tag','WorkspaceButton');
    ud.Handles.HelpButton= uicontrol('Parent',fig, ...
    'Units',StdUnit, ...
    'Position',uipos.HelpButton, ...
     'Callback','nncontrolutil(''nndataexport'',''windowstyle'',gcbf,''normal'');nncontrolutil(''nndataexporthelp'',''main'',gcbf);',...
    'String','Help', ...
     'ToolTipStr','Calls the help window for the export window.',...
    'Tag','HelpButton');
    ud.Handles.CancelButton = uicontrol('Parent',fig, ...
    'Units',StdUnit, ...
     'Position',uipos.CancelButton, ...
     'Callback','nncontrolutil(''nndataexport'',''cancel'',gcbf);',...
    'String','Cancel', ...
     'ToolTipStr','Discard the export action and close this menu.',...
    'Tag','CancelButton');

  end
  set(fig,'UserData',ud,'visible','on','WindowStyle','modal')
  
elseif strcmp(cmd,'cancel')
   delete(fig)
   return;
   
elseif strcmp(cmd,'windowstyle')
   set(fig,'visible','on','WindowStyle',arg2)
   return;
   
elseif strcmp(cmd,'workspace') | strcmp(cmd,'disk')
   % We check if some option selected.
   if strcmp(ud.Handles.type_net,'ref')
      load(cat(2,tempdir,'nnmodrefdata.mat'),'tr_dat');
   else
      load(cat(2,tempdir,'nnidentdata.mat'),'tr_dat');
   end
   name_data=get(ud.Handles.nnplantedit,'string');
   if isempty(name_data),
      warndlg('There is no data to export.','Export Warning','modal');
      return      
   end
   
   overwrite=0;
   w = evalin('base','whos');
   Wname = {w.name};
   
   figure_variables=get(ud.Handles.parent,'userdata');
   parent_simulink=get(figure_variables.gcbh_ptr,'userdata');
      
   % We check for Controller and object structure.
   if ~isempty(strmatch(name_data,...
      Wname,'exact')),
      overwrite=1;
   end
   
   if strcmp(cmd,'workspace')
      if overwrite
         switch questdlg(...
              {'At least one of the items you are exporting to'
               'the workspace already exists.'
               ' ';
               'Exporting will overwrite the existing variables.'
               ' '
               'Do you want to continue?'},...
               'Variable Name Conflict','Yes','No','No');
            
        case 'Yes'
           overwriteOK = 1;
        case 'No'
           overwriteOK = 0;
        end % switch questdlg
      else
        overwriteOK = 1;
      end % if/else overwrite
      
      if overwriteOK 
        assignin('base',name_data,tr_dat);
        delete(fig)   
      end
   else
      fname = '*';
      fname=[fname,'.mat']; % Revisit for CODA -- is a .mat extension already provide
      [fname,p]=uiputfile(fname,'Export to Disk');
      if fname,
         fname = fullfile(p,fname);
         eval([name_data '= tr_dat;']);
         save(fname,name_data);
         delete(fig)   
      end
   end
   
end





function uipos = getuipos


sunits = get(0, 'Units');
set (0, 'Units', 'character');
ssinchar = get(0, 'ScreenSize');
set (0, 'Units', sunits);

figw = 55;
figh = 10.7692;
figl = (ssinchar(3) - figw) / 2;
figb = (ssinchar(4) - figh) / 2;

uipos.fig = [figl,figb,figw,figh];

uipos.b_1 = [1,6,53,3.38462];
uipos.b_3 = [1,0.384615,53,5.38462];
uipos.b_2 = [21.2,8.38462,11.2,1.46154];

uipos.nnplant = [4,6.41538,24,1.53846];
uipos.nnplantedit = [30,6.61538,18,1.53846];

uipos.DiskButton = [2.8,3.15385,25,1.53846];
uipos.WorkspaceButton = [2.8,1.07692,25,1.53846];
uipos.HelpButton = [31,1.07692,20.4,1.53846];
uipos.CancelButton = [31,3.15385,20.4,1.53846];

