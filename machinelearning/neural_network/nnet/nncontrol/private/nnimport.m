function nnimport(cmd,arg1,arg2,arg3)
%NNIMPORT Neural Network Import GUI for the Neural Network Controller Toolbox.
%
%  Synopsis
%
%    nnimport(cmd,arg1,arg2,arg3)
%
%  Warning!!
%
%    This function may be altered or removed in future
%    releases of the Neural Network Toolbox. We recommend
%    you do not write code which calls this function.
%    This function is generally being called from a Simulink block.

% Orlando De Jesus, Martin Hagan, 1-25-00
% Copyright 1992-2008 The MathWorks, Inc.
% $Revision: 1.5.2.3 $ $Date: 2008/06/20 08:04:06 $


% CONSTANTS
tag= 'Import_NN_Par_fig';

% DEFAULTS
if nargin == 0, cmd = ''; else cmd = lower(cmd); end

% FIND WINDOW IF IT EXISTS
fig=findall(0,'type','figure','tag',tag);
if (size(fig,1)==0), fig=0; end

if length(get(fig,'children')) == 0, fig = 0; end

if fig
   ud = get(fig,'userdata');
end

if strcmp(cmd,'init')
  if fig==0  
    StdColor = get(0,'DefaultFigureColor');
    % PointsToPixels = 72/get(0,'ScreenPixelsPerInch'); % we should not need this anymore
    StdUnit = 'character';
    ud.Handles.parent=arg1;
    ud.Handles.type_net=arg2;
    ud.Handles.ret_func=arg3;
    
    if strcmp(ud.Handles.type_net,'nnpredict') | strcmp(ud.Handles.type_net,'narma_l2')
       me = 'Import Neural Network Plant Parameters';
    else
       me = 'Import Neural Network Plant-Controller Parameters';
    end
    
    uipos = getuipos;
    
    fig = figure('Units','points', ...
      'Interruptible','off', ...
      'BusyAction','cancel', ...
      'HandleVis','Callback', ...
    'Color',StdColor, ...
    'IntegerHandle','off', ...
    'MenuBar','none', ...
    'Name',me, ...
    'NumberTitle','off', ...
    'Units', StdUnit, ...
    'PaperUnits','points', ...
    'Position',uipos.fig, ...
    'Tag',tag, ...
    'Resize', 'off', ...
     'WindowStyle','modal');
   h1 = uicontrol('Parent',fig, ...
    'Unit',StdUnit, ...
    'BackgroundColor',StdColor, ...
    'Position',uipos.h1_1, ...
    'Style','frame');
   h1 = uicontrol('Parent',fig, ...
    'Unit',StdUnit, ...
    'BackgroundColor',StdColor, ...
    'Position',uipos.h1_2, ...
    'String','Import From:', ...
    'Style','text');
   ud.Handles.Wbutton = uicontrol('Parent',fig, ...
    'Unit',StdUnit, ...
    'BackgroundColor',StdColor, ...
    'Callback','nncontrolutil(''nnimport'',''radiobutton'',gcbf);nncontrolutil(''nnimport'',''workspace'',gcbf);', ...
    'ListboxTop',0, ...
    'Position',uipos.Wbutton, ...
    'String','Workspace', ...
    'Style','radiobutton', ...
    'Tag','Wbutton', ...
      'ToolTipStr','If selected, the network objects will be taken from the MATLAB workspace.',...
    'Value',1);
   ud.Handles.Mbutton = uicontrol('Parent',fig, ...
    'Unit',StdUnit, ...
    'BackgroundColor',StdColor, ...
    'Callback','nncontrolutil(''nnimport'',''radiobutton'',gcbf);nncontrolutil(''nnimport'',''matfile'',gcbf);', ...
    'ListboxTop',0, ...
    'Position',uipos.Mbutton, ...
    'String','MAT-file', ...
    'Style','radiobutton', ...
      'ToolTipStr','If selected, the network objects will be taken from a MAT-file.',...
    'Tag','Mbutton');
   set(ud.Handles.Wbutton,'UserData',[ud.Handles.Mbutton]);
   set(ud.Handles.Mbutton,'UserData',[ud.Handles.Wbutton]);
   ud.Handles.FileNameText = uicontrol('Parent',fig, ...
    'Unit',StdUnit, ...
    'BackgroundColor',StdColor, ...
     'Enable','off', ...
    'ListboxTop',0, ...
    'Position',uipos.FileNameText, ...
    'String','MAT-filename:', ...
    'Style','text', ...
      'ToolTipStr','Enter the name of the MAT-file where the network objects are.',...
    'Tag','FileNameText');
   ud.Handles.FileNameEdit = uicontrol('Parent',fig, ...
    'Unit',StdUnit, ...
    'BackgroundColor',[1 1 1], ...
     'Enable','off', ...
    'Callback','nncontrolutil(''nnimport'',''clearpath'',gcbf);nncontrolutil(''nnimport'',''matfile'',gcbf);', ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',uipos.FileNameEdit, ...
    'String','', ...
    'Style','edit', ...
      'ToolTipStr','Enter the name of the MAT-file where the network objects are.',...
    'Tag','FileNameEdit');
   ud.Handles.BrowseButton = uicontrol('Parent',fig, ...
    'Unit',StdUnit, ...
     'Enable','off', ...
    'Callback','nncontrolutil(''nnimport'',''browsemat'',gcbf);', ...
    'ListboxTop',0, ...
    'Position',uipos.BrowseButton, ...
    'String','Browse', ...
      'ToolTipStr','Browse the disk to select a MAT-file.',...
    'Tag','BrowseButton');
   h1 = uicontrol('Parent',fig, ...
    'Unit',StdUnit, ...
    'BackgroundColor',StdColor, ...
    'ListboxTop',0, ...
    'Position',uipos.h1_3, ...
    'Style','frame');
   ud.Handles.ModelText = uicontrol('Parent',fig, ...
    'Unit',StdUnit, ...
    'BackgroundColor',StdColor, ...
    'ListboxTop',0, ...
    'Position',uipos.ModelText, ...
    'String','Workspace Contents', ...
    'Style','text', ...
    'Tag','ModelText');
   ud.Handles.ModelList = uicontrol('Parent',fig, ...
    'Unit',StdUnit, ...
    'BackgroundColor',[1 1 1], ...
    'Position',uipos.ModelList, ...
    'Style','listbox', ...
    'Tag','ModelList', ...
      'ToolTipStr','Present the network objects found in the MATLAB workspace or MAT-file.',...
    'Value',1);
   h1 = uicontrol('Parent',fig, ...
    'Unit',StdUnit, ...
    'BackgroundColor',StdColor, ...
    'ListboxTop',0, ...
    'Position',uipos.h1_4, ...
    'Style','frame');
   h1 = uicontrol('Parent',fig, ...
    'Unit',StdUnit, ...
    'BackgroundColor',StdColor, ...
    'ListboxTop',0, ...
    'Position',uipos.h1_5, ...
    'String','Neural Network Models', ...
    'Style','text');
    EditUd = struct('ListIndex',0,'String','');
    if strcmp(ud.Handles.type_net,'nnmodref')
      h1 = uicontrol('Parent',fig, ...
       'Unit',StdUnit, ...
       'BackgroundColor',StdColor, ...
       'HorizontalAlignment','left', ...
       'ListboxTop',0, ...
       'Position',uipos.h1_6, ...
       'String','Controller', ...
       'Style','text', ...
       'Tag','ControllerText');
      ud.Handles.ControllerEdit = uicontrol('Parent',fig, ...
       'Unit',StdUnit, ...
         'BackgroundColor',[1 1 1], ...
       'Callback','nncontrolutil(''nnimport'',''editcallback'',gcbf);', ...
       'HorizontalAlignment','left', ...
       'ListboxTop',0, ...
       'Position',uipos.ControllerEdit, ...
       'String','', ...
       'Style','edit', ...
        'UserData',EditUd,...
         'ToolTipStr','Controller object to be imported.',...
       'Tag','ControllerEdit');
      ud.Handles.ControllerButton = uicontrol('Parent',fig, ...
       'Unit',StdUnit, ...
       'Callback','nncontrolutil(''nnimport'',''buttoncallback'',gcbf);', ...
       'Position',uipos.ControllerButton, ...
       'String','-->', ...
        'UserData',ud.Handles.ControllerEdit,...
         'ToolTipStr','Select the network controller object to be imported.',...
       'Tag','ControllerButton');
    end
    h1 = uicontrol('Parent',fig, ...
     'Unit',StdUnit, ...
    'BackgroundColor',StdColor, ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',uipos.h1_7, ...
    'String','Plant', ...
    'Style','text', ...
      'Tag','PlantText');
   ud.Handles.PlantEdit = uicontrol('Parent',fig, ...
    'Unit',StdUnit, ...
    'BackgroundColor',[1 1 1], ...
    'Callback','nncontrolutil(''nnimport'',''editcallback'',gcbf);', ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',uipos.PlantEdit, ...
    'String','', ...
    'Style','edit', ...
     'UserData',EditUd,...
      'ToolTipStr','Plant object to be imported.',...
    'Tag','PlantEdit');
   ud.Handles.PlantButton = uicontrol('Parent',fig, ...
    'Unit',StdUnit, ...
    'Callback','nncontrolutil(''nnimport'',''buttoncallback'',gcbf);', ...
    'Position',uipos.PlantButton, ...
    'String','-->', ...
     'UserData',ud.Handles.PlantEdit,...
      'ToolTipStr','Select the network plant object to be imported.',...
    'Tag','PlantButton');
   h1 = uicontrol('Parent',fig, ...
    'Unit',StdUnit, ...
    'BackgroundColor',StdColor, ...
    'ListboxTop',0, ...
    'Position',uipos.h1_8, ...
    'Visible', 'off',...
    'Style','frame');
   ud.Handles.HelpButton = uicontrol('Parent',fig, ...
    'Unit',StdUnit, ...
    'Callback','nncontrolutil(''nnimport'',''windowstyle'',gcbf,''normal'');nncontrolutil(''nnimporthelp'',''main'',gcbf);', ...
    'ListboxTop',0, ...
    'Position',uipos.HelpButton, ...
    'String','Help', ...
      'ToolTipStr','Call the Import Network help window.',...
    'Tag','HelpButton');
   ud.Handles.CancelButton = uicontrol('Parent',fig, ...
    'Unit',StdUnit, ...
    'Callback','nncontrolutil(''nnimport'',''cancel'',gcbf);', ...
    'ListboxTop',0, ...
    'Position',uipos.CancelButton, ...
    'String','Cancel', ...
      'ToolTipStr','Discard the import action and close this menu',...
    'Tag','CancelButton');
   ud.Handles.OKButton = uicontrol('Parent',fig, ...
    'Unit',StdUnit, ...
    'Callback','nncontrolutil(''nnimport'',''apply'',gcbf);', ...
    'ListboxTop',0, ...
    'Position',uipos.OKButton, ...
    'String','OK', ...
      'ToolTipStr','Send the selected neural network to the Simulink model.',...
    'Tag','OKButton');

  end
   set(fig,'UserData',ud,'visible','on','WindowStyle','modal')
   nncontrolutil('nnimport','workspace',gcbf);
   
elseif strcmp(cmd,'cancel')
   H=get(ud.Handles.parent,'userdata');
   arg1=get(H.gcbh_ptr,'userdata');
   arg2=get(H.gcb_ptr,'userdata');
   feval(ud.Handles.ret_func,'',arg1,arg2,'');
   delete(fig)
   return;
   
elseif strcmp(cmd,'windowstyle')
   set(fig,'visible','on','WindowStyle',arg2)
   return;
   
elseif strcmp(cmd,'radiobutton')
   val = get(gcbo,'Value');
   sibs = get(gcbo,'UserData');
   
   if ~val,
      set(gcbo,'Value',1);
   elseif val==1,
      set(sibs,'Value',0);
      set(ud.Handles.FileNameEdit,'String','', ...
         'UserData',struct('FileName',[],'PathName',[]));
      if strcmp(ud.Handles.type_net,'nnmodref')
         set([ud.Handles.PlantEdit,...
            ud.Handles.ControllerEdit],'String','','UserData',...
            struct('ListIndex',0,'String',''));
      else
         set(ud.Handles.PlantEdit,'String','','UserData',...
            struct('ListIndex',0,'String',''));
      end
   end % if/else val
   
elseif strcmp(cmd,'editcallback'),
   %---Callback for the Plant and Controller Edit boxes
   %---These boxes should contain an index into the List Box string
   %---The Index should be zero when an invalid name is entered
   TryString = get(gcbo,'String');
   udEdit = get(gcbo,'UserData');
   
   if isempty(TryString), % empty value, leave it that way
      udEdit.ListIndex=0;
      udEdit.String='';
   else      
      IndList = strmatch(TryString,ud.ListData.Names,'exact');
      
      if isempty(IndList),
          % Revert to last valid entry
         if isempty(udEdit.ListIndex),
            set(gcbo,'String','');
         else
            set(gcbo,'String',udEdit.String);
         end, %if/else isempty(udEdit)
         WarnStr=['You must enter a network object from the list box.'];
         warndlg(WarnStr,'Import Warning','modal');
      else, % Store the list index
         udEdit.ListIndex=IndList;
         udEdit.String=TryString;
      end % if/else isempty(IndList);
   end % if/else isempty(TryString);
   set(gcbo,'UserData',udEdit);
   
elseif strcmp(cmd,'matfile'),
   set(ud.Handles.ModelText,'string','MAT-file Contents');
   set([ud.Handles.FileNameText,...
         ud.Handles.FileNameEdit,...
         ud.Handles.BrowseButton],'enable','on');
   set(ud.Handles.FileNameText,'String','MAT-filename:');
   set(ud.Handles.BrowseButton,'Callback','nncontrolutil(''nnimport'',''browsemat'',gcbf);');
   set(ud.Handles.FileNameEdit,...
      'Callback','nncontrolutil(''nnimport'',''clearpath'',gcbf);nncontrolutil(''nnimport'',''matfile'',gcbf);');
   
   FileName = get(ud.Handles.FileNameEdit,'String');   
   if isempty(FileName),
      Data=struct('Names','','Objects',[]);
   else
      try
         VAR=load(FileName);
         WorkspaceVars=whos('-file',FileName);
         sysvar=cell(size(WorkspaceVars));
         s=0;
         for ct=1:size(WorkspaceVars,1),
            VarClass=WorkspaceVars(ct).class;
            if (strcmp(VarClass,'network')) & isequal(2,length(WorkspaceVars(ct).size)),
               % Only look for Non-array (TF, SS, and ZPK) LTI objects
               s=s+1;
               sysvar(s)={WorkspaceVars(ct).name};
            end % if isa
         end % for ct
         sysvar=sysvar(1:s);
         
         DataObjects = cell(2,1);
         for ctud=1:s,
            DataObjects{ctud} = eval(cat(2,'VAR.',sysvar{ctud}));
         end % for
         Data = struct('Names',{sysvar},'Objects',{DataObjects});
         
      catch me
         warndlg(me.message,'Import Warning','modal'); 
         set(ud.Handles.FileNameEdit,'String','');
         FileName='';
         Data=struct('Names','','Objects',[]);
      end % try/catch
   end % if/else check on FileName
   
   LocalFinishLoad(fig,ud,FileName,Data)
   
elseif strcmp(cmd,'workspace')
   set(ud.Handles.ModelText,'string','Workspace Contents');
   set([ud.Handles.FileNameText,...
         ud.Handles.FileNameEdit,...
         ud.Handles.BrowseButton],'enable','off');
   
   %----Look for all workspace variables of class 'ss', 'tf', or 'zpk'
   WorkspaceVars=evalin('base','whos');
   sysvar=cell(size(WorkspaceVars));
   s=0;
   for ct=1:size(WorkspaceVars,1),
      VarClass=WorkspaceVars(ct).class;
      if (strcmp(VarClass,'network'))  & isequal(2,length(WorkspaceVars(ct).size)),
         % Only look for Non-array (TF, SS, and ZPK) LTI objects
         s=s+1;
         sysvar(s,1)={WorkspaceVars(ct).name};
      end % if isa
   end % for ct
   sysvar=sysvar(1:s,1);
   
   DataObjects = cell(s,1);
   for ctud=1:s,
      DataObjects{ctud} = evalin('base',sysvar{ctud});
   end
   
   Data = struct('Names',{sysvar},'Objects',{DataObjects});
   
   set(ud.Handles.ModelList,'String',sysvar)
   
   %---Update the Import Figure Userdata
   ud.ListData=Data;
   set(fig,'UserData',ud);
      
elseif strcmp(cmd,'browsemat')
   filterspec = '*.mat';
   
   udFileEdit = get(ud.Handles.FileNameEdit,'UserData');
   LastPath = udFileEdit.PathName;
   CurrentPath=pwd;
   if ~isempty(LastPath),
      cd(LastPath);
   end
   [filename,pathname] = uigetfile(filterspec,'Import file:');
   if ~isempty(LastPath),
      cd(CurrentPath);
   end
   
   if filename,
      if ~strcmpi(pathname(1:end-1),CurrentPath)
         ImportStr = [pathname,filename(1:end-4)];
      else
         ImportStr = filename(1:end-4);
      end
      set(ud.Handles.FileNameEdit,'String',ImportStr);
      nncontrolutil('nnimport','matfile',fig);
      if strcmp(ud.Handles.type_net,'nnmodref')
         set([ud.Handles.PlantEdit,...
            ud.Handles.ControllerEdit],'String','','UserData',...
            struct('ListIndex',0,'String',''));
      else
         set(ud.Handles.PlantEdit,'String','','UserData',...
            struct('ListIndex',0,'String',''));
      end
   end
   
elseif strcmp(cmd,'clearpath') & (fig)
   %---Callback for the SImulink File box
   %    Whenever a new name is entered, update the Userdata
   NewName = get(gcbo,'String');
   indDot = findstr(NewName,'.');
   if ~isempty(indDot),
      NewName=NewName(1:indDot(end)-1);
      set(ud.Handles.FileNameEdit,'String',NewName)   
   end
      
elseif strcmp(cmd,'buttoncallback')
   %---Callback for the Arrow Buttons
   EditBox = get(gcbo,'UserData');
   AllNames = get(ud.Handles.ModelList,'String');
   if ~isempty(AllNames), % Make sure these is something in the list
      SelectedName = get(ud.Handles.ModelList,'Value');
      udEdit = get(EditBox ,'UserData');
      udEdit.String = AllNames{SelectedName};
      udEdit.ListIndex = SelectedName;
      set(EditBox,'String',AllNames{SelectedName},'UserData',udEdit);
   end
   
elseif strcmp(cmd,'apply'), % Send the new Feedback structure to the Parent's Userdata
      PlantOK=0;ControllerOK=0;
      %---Plant
      udPlantEdit = get(ud.Handles.PlantEdit,'UserData');
      if udPlantEdit.ListIndex~=0, 
         ud.ModelData.Plant.Name = udPlantEdit.String;
         ud.ModelData.Plant.Object = ...
           ud.ListData.Objects{udPlantEdit.ListIndex};
         
         if strcmp(ud.Handles.type_net,'narma_l2')
            if ud.ModelData.Plant.Object.numLayers~=6
               warndlg('The neural network plant must have 6 layers.',...
               'Import Warning','modal');
               return
            end
            if ud.ModelData.Plant.Object.numInputs~=3
               warndlg('The neural network plant must have 3 inputs.',...
               'Import Warning','modal');
               return
            end
            if ud.ModelData.Plant.Object.layers{6}.dimensions~=1
               warndlg('The neural network plant must have one output.',...
               'Import Warning','modal');
               return
            end
            if ~strcmp(ud.ModelData.Plant.Object.layers{1}.transferFcn,'tansig') | ...
                  ~strcmp(ud.ModelData.Plant.Object.layers{3}.transferFcn,'tansig')
               warndlg('The transfer function of the first and third layer on the neural network plant must be TANSIG.',...
               'Import Warning','modal');
               return
            end
            if ~strcmp(ud.ModelData.Plant.Object.layers{2}.transferFcn,'purelin') | ...
                  ~strcmp(ud.ModelData.Plant.Object.layers{4}.transferFcn,'purelin') | ...
                  ~strcmp(ud.ModelData.Plant.Object.layers{5}.transferFcn,'purelin') | ...
                  ~strcmp(ud.ModelData.Plant.Object.layers{6}.transferFcn,'purelin')
               warndlg('The transfer function of the second, fourth, fifth and sixth Layer on the neural network plant must be PURELIN.',...
               'Import Warning','modal');
               return
            end
            S1=ud.ModelData.Plant.Object.layers{1}.dimensions;
            if ud.ModelData.Plant.Object.biasConnect(1)==0
               B1=zeros(S1,1);
            else
               B1=ud.ModelData.Plant.Object.b{1};
            end
            if ud.ModelData.Plant.Object.biasConnect(2)==0
               B2=0;
            else
               B2=ud.ModelData.Plant.Object.b{2};
            end
            if ud.ModelData.Plant.Object.biasConnect(3)==0
               B3=zeros(S1,1);
            else
               B3=ud.ModelData.Plant.Object.b{3};
            end
            if ud.ModelData.Plant.Object.biasConnect(4)==0
               B4=0;
            else
               B4=ud.ModelData.Plant.Object.b{4};
            end
            if ud.ModelData.Plant.Object.biasConnect(5)~=0 ...
                  ud.ModelData.Plant.Object.biasConnect(6)~=0
               warndlg('The fifth and sixth layers of the neural network plant must no have biases.',...
               'Import Warning','modal');
               return
            end
            if size(ud.ModelData.Plant.Object.inputConnect)~=[6 3] |...
                  sum(sum(ud.ModelData.Plant.Object.inputConnect))~=3 | ...
                  ud.ModelData.Plant.Object.inputConnect(1,1)~=1 | ...
                  ud.ModelData.Plant.Object.inputConnect(3,2)~=1 | ...
                  ud.ModelData.Plant.Object.inputConnect(5,3)~=1
               warndlg('The neural network plant input must be connected to layers 1, 3 and 5.',...
               'Import Warning','modal');
               return
            else
               IW1_1=ud.ModelData.Plant.Object.IW{1,1};
               IW3_2=ud.ModelData.Plant.Object.IW{3,2};
               IW5_3=ud.ModelData.Plant.Object.IW{5,3};
               Ni=max(ud.ModelData.Plant.Object.inputWeights{1,1}.delays)+1;
            end
            if size(ud.ModelData.Plant.Object.outputConnect)~=[1 6] | ...
                  sum(ud.ModelData.Plant.Object.outputConnect)~=1 | ...
                  ud.ModelData.Plant.Object.outputConnect(6)~=1
               warndlg('The neural network plant output must be connected to layer 6.',...
               'Import Warning','modal');
               return
            end
            if size(ud.ModelData.Plant.Object.layerConnect)~=[6 6] | ...
                  sum(sum(ud.ModelData.Plant.Object.layerConnect))~=5 | ...
                  ud.ModelData.Plant.Object.layerConnect(2,1)~=1 | ...
                  ud.ModelData.Plant.Object.layerConnect(6,2)~=1 | ...
                  ud.ModelData.Plant.Object.layerConnect(4,3)~=1 | ...
                  ud.ModelData.Plant.Object.layerConnect(5,4)~=1 | ...
                  ud.ModelData.Plant.Object.layerConnect(6,5)~=1
               warndlg('The neural network plant layers are not correctly connected.',...
               'Import Warning','modal');
               return
            else
               LW2_1=ud.ModelData.Plant.Object.LW{2,1};
               LW4_3=ud.ModelData.Plant.Object.LW{4,3};
               LW5_4=ud.ModelData.Plant.Object.LW{5,4};
               LW6_5=ud.ModelData.Plant.Object.LW{6,5};
               LW6_2=ud.ModelData.Plant.Object.LW{6,2};
               Nj=max(ud.ModelData.Plant.Object.layerWeights{2,1}.delays);
            end
         else
            if ud.ModelData.Plant.Object.numLayers~=2
               warndlg('The neural network plant must have 2 layers.',...
               'Import Warning','modal');
               return
            end
            if ud.ModelData.Plant.Object.numInputs~=1
               warndlg('The neural network plant must have 1 input.',...
               'Import Warning','modal');
               return
            end
            if ud.ModelData.Plant.Object.layers{2}.dimensions~=1
               warndlg('The neural network plant must have one output.',...
               'Import Warning','modal');
               return
            end
            if ~strcmp(ud.ModelData.Plant.Object.layers{1}.transferFcn,'tansig')
               warndlg('The transfer function of the first layer of the neural network plant must be TANSIG.',...
               'Import Warning','modal');
               return
            end
            if ~strcmp(ud.ModelData.Plant.Object.layers{2}.transferFcn,'purelin')
               warndlg('The transfer function of the second layer of the neural network plant must be PURELIN.',...
               'Import Warning','modal');
               return
            end
            S1=ud.ModelData.Plant.Object.layers{1}.dimensions;
            if ud.ModelData.Plant.Object.biasConnect(1)==0
               B1=zeros(S1,1);
            else
               B1=ud.ModelData.Plant.Object.b{1};
            end
            if ud.ModelData.Plant.Object.biasConnect(2)==0
               B2=0;
            else
               B2=ud.ModelData.Plant.Object.b{2};
            end
            if sum(ud.ModelData.Plant.Object.inputConnect==[1;0])~=2
               warndlg('The neural network plant input must be connected to layer 1.',...
               'Import Warning','modal');
               return
            else
               IW=ud.ModelData.Plant.Object.IW{1,1};
               Ni=max(ud.ModelData.Plant.Object.inputWeights{1,1}.delays)+1;
            end
            if sum(ud.ModelData.Plant.Object.outputConnect==[0 1])~=2
               warndlg('The neural network plant output must be connected to layer 2.',...
               'Import Warning','modal');
               return
            end
            if sum(ud.ModelData.Plant.Object.layerConnect(:)==[0; 1; 1; 0])~=4
               warndlg('The neural network plant layers are not correctly connected.',...
               'Import Warning','modal');
               return
            else
               LW1_2=ud.ModelData.Plant.Object.LW{1,2};
               LW2_1=ud.ModelData.Plant.Object.LW{2,1};
               Nj=max(ud.ModelData.Plant.Object.layerWeights{1,2}.delays);
            end
         end
         PlantOK=1;
      end
               
      %---Controller
      if strcmp(ud.Handles.type_net,'nnmodref')
         udControllerEdit = get(ud.Handles.ControllerEdit,'UserData');
         if udControllerEdit.ListIndex~=0, 
            ud.ModelData.Controller.Name = udControllerEdit.String;
            ud.ModelData.Controller.Object = ...
              ud.ListData.Objects{udControllerEdit.ListIndex};
          
            if ud.ModelData.Controller.Object.numLayers~=2
               warndlg('The neural network controller must have 2 layers.',...
               'Import Warning','modal');
               return
            end
            if ud.ModelData.Controller.Object.numInputs~=2
               warndlg('The neural network controller must have 2 inputs.',...
               'Import Warning','modal');
               return
            end
            if ud.ModelData.Controller.Object.layers{2}.dimensions~=1
               warndlg('The neural network controller must have one output.',...
               'Import Warning','modal');
               return
            end
            if ~strcmp(ud.ModelData.Controller.Object.layers{1}.transferFcn,'tansig')
               warndlg('The transfer function of the first layer of the neural network controller must be TANSIG.',...
               'Import Warning','modal');
               return
            end
            if ~strcmp(ud.ModelData.Controller.Object.layers{2}.transferFcn,'purelin')
               warndlg('The transfer function of the second layer of the neural network controller must be PURELIN.',...
               'Import Warning','modal');
               return
            end
            S1c=ud.ModelData.Controller.Object.layers{1}.dimensions;
            if ud.ModelData.Controller.Object.biasConnect(1)==0
               B1_c=zeros(S1,1);
            else
               B1_c=ud.ModelData.Controller.Object.b{1};
            end
            if ud.ModelData.Controller.Object.biasConnect(2)==0
               B2_c=0;
            else
               B2_c=ud.ModelData.Controller.Object.b{2};
            end
            if sum(ud.ModelData.Controller.Object.inputConnect(:)==[1;0;1;0])~=4
               warndlg('The neural network controller input must be connected to layer 1.',...
               'Import Warning','modal');
               return
            else
               IW_r=ud.ModelData.Controller.Object.IW{1,1};
               IW_y=ud.ModelData.Controller.Object.IW{1,2};
               Nrc=max(ud.ModelData.Controller.Object.inputWeights{1,1}.delays)+1;
               Njc=max(ud.ModelData.Controller.Object.inputWeights{1,2}.delays)+1;
            end
            if sum(ud.ModelData.Controller.Object.outputConnect==[0 1])~=2
               warndlg('The neural network controller output must be connected to layer 2.',...
               'Import Warning','modal');
               return
            end
            if sum(ud.ModelData.Controller.Object.layerConnect(:)==[0; 1; 1; 0])~=4
               warndlg('The neural network controller layers are not correctly connected.',...
               'Import Warning','modal');
               return
            else
               IW_u=ud.ModelData.Controller.Object.LW{1,2};
               LW_c=ud.ModelData.Controller.Object.LW{2,1};
               Nic=max(ud.ModelData.Controller.Object.layerWeights{1,2}.delays);
            end
            ControllerOK=1;
         end
      end
      
      figure_variables=get(ud.Handles.parent,'userdata');
      parent_simulink=get(figure_variables.gcbh_ptr,'userdata');
      if PlantOK
         if strcmp(ud.Handles.type_net,'narma_l2')
            set_param(parent_simulink,'IW1_1',mat2str(IW1_1,20));  
            set_param(parent_simulink,'IW3_2',mat2str(IW3_2,20));  
            set_param(parent_simulink,'IW5_3',mat2str(IW5_3,20));  
            set_param(parent_simulink,'LW2_1',mat2str(LW2_1,20));  
            set_param(parent_simulink,'LW4_3',mat2str(LW4_3,20));  
            set_param(parent_simulink,'LW5_4',mat2str(LW5_4,20));  
            set_param(parent_simulink,'LW6_5',mat2str(LW6_5,20));  
            set_param(parent_simulink,'LW6_2',mat2str(LW6_2,20));  
            set_param(parent_simulink,'B1',mat2str(B1,20));  
            set_param(parent_simulink,'B2',mat2str(B2,20));  
            set_param(parent_simulink,'B3',mat2str(B3,20));  
            set_param(parent_simulink,'B4',mat2str(B4,20));  
            set_param(parent_simulink,'S1',mat2str(S1,20));  
%            set_param(parent_simulink,'Ni',mat2str(Ni,20));  
%            set_param(parent_simulink,'Nj',mat2str(Nj,20));  
         else
            set_param(parent_simulink,'IW',mat2str(IW,20));  
            set_param(parent_simulink,'LW1_2',mat2str(LW1_2,20));  
            set_param(parent_simulink,'LW2_1',mat2str(LW2_1,20));  
            set_param(parent_simulink,'B1',mat2str(B1,20));  
            set_param(parent_simulink,'B2',mat2str(B2,20));  
            set_param(parent_simulink,'S1',mat2str(S1,20));  
            set_param(parent_simulink,'Ni',mat2str(Ni,20));  
            set_param(parent_simulink,'Nj',mat2str(Nj,20));  
         end
      end
      if ControllerOK
         set_param(parent_simulink,'IW_y',mat2str(IW_y,20));  
         set_param(parent_simulink,'IW_u',mat2str(IW_u,20));  
         set_param(parent_simulink,'IW_r',mat2str(IW_r,20));  
         set_param(parent_simulink,'LW_c',mat2str(LW_c,20));  
         set_param(parent_simulink,'B1_c',mat2str(B1_c,20));  
         set_param(parent_simulink,'B2_c',mat2str(B2_c,20));  
         set_param(parent_simulink,'S1c',mat2str(S1c,20));  
         set_param(parent_simulink,'Nic',mat2str(Nic,20));  
         set_param(parent_simulink,'Njc',mat2str(Njc,20));  
         set_param(parent_simulink,'Nrc',mat2str(Nrc,20));  
      end
      if PlantOK | ControllerOK
         H=get(ud.Handles.parent,'userdata');
         arg1=get(H.gcbh_ptr,'userdata');
         arg2=get(H.gcb_ptr,'userdata');
         feval(ud.Handles.ret_func,'',arg1,arg2,'');
         delete(fig)   
         return
      end
      
   warndlg('You must define a neural network to be imported.',...
           'Import Warning','modal');
      
   set(fig,'UserData',ud)

   uiresume(fig)
   
end

%-----------------------------Internal Functions--------------------------
%%%%%%%%%%%%%%%%%%%%%%%
%%% LocalFinishLoad %%%
%%%%%%%%%%%%%%%%%%%%%%%
function LocalFinishLoad(ImportFig,ud,FileName,Data)

%---Update the FileNameEdit Userdata
[P,F]=fileparts(FileName);
udNames = get(ud.Handles.FileNameEdit,'UserData');
udNames.PathName=P; 
udNames.FileName=F;
set(ud.Handles.FileNameEdit,'UserData',udNames)

%---Update the Import Figure Userdata
set(ud.Handles.ModelList,'String',Data.Names,'value',1)
ud.ListData=Data;
set(ImportFig,'UserData',ud);



function uipos = getuipos


sunits = get(0, 'Units');
set (0, 'Units', 'character');
ssinchar = get(0, 'ScreenSize');
set (0, 'Units', sunits);

outborder = 1.3333;
inborder = 1;
framew = 33;
butwsmall = 6;
butwbig = framew-(inborder*2);
butwmed = 12;
labelh = 1.53846;



figw = (3*framew) + (2*outborder) + (3*inborder) + butwsmall;
figh = 15;

figl = (ssinchar(3) - figw) / 2;
figb = (ssinchar(4) - figh) / 2;

uipos.fig = [figl,figb,figw,figh];

uipos.h1_1 = [outborder,0.692308,framew,11.6923]; %frame 1 - Import From
uipos.h1_3 = [outborder+inborder+framew,3.38462,framew,9]; % frame2 - Workspace Contents
uipos.h1_4 = [outborder+(3*inborder)+(2*framew)+butwsmall,3.38462,framew,9]; % frame3 - Neural Network Models
uipos.h1_8 = [outborder+inborder+framew,0.692308,(2*framew)+(2*inborder)+butwsmall,2.15385]; %frame4 % Bottom Frame

uipos.h1_2 = [uipos.h1_1(1)+((framew-15)/2),11.3846,15,labelh]; % Import From
uipos.ModelText = [uipos.h1_3(1)+((framew-22)/2),11.3846,22,labelh]; % Workspace Contents
uipos.h1_5 = [uipos.h1_4(1)+((framew-25)/2),11.3846,25,1.53846]; % Neural Network Models

uipos.Wbutton = [outborder*2,8.84615,framew-(outborder*2),labelh];
uipos.Mbutton = [outborder*2,6.69231,framew-(outborder*2),labelh];

uipos.FileNameText = [outborder*2,4.61538,framew-(outborder*2),labelh];
uipos.FileNameEdit = [outborder*2,3.07692,framew-(outborder*2),labelh];
uipos.BrowseButton = [outborder*2,1.07692,framew-(outborder*2),labelh];


uipos.ModelList = [outborder+framew+(inborder*2),3.76923,framew-(inborder*2),7.92308];

uipos.h1_6 = [outborder+(framew*2)+butwsmall+(inborder*4),8.61538,framew-(inborder*2),labelh];
uipos.ControllerEdit = [outborder+(framew*2)+butwsmall+(inborder*4),7.53846,framew-(inborder*2),labelh];
uipos.ControllerButton = [outborder+framew*2+inborder*2,7.53846,butwsmall,labelh];
uipos.h1_7 = [outborder+(framew*2)+butwsmall+(inborder*4),5.15385,framew-(inborder*2),labelh];
uipos.PlantEdit = [outborder+(framew*2)+butwsmall+(inborder*4),4.07692,framew-(inborder*2),labelh];
uipos.PlantButton = [outborder+framew*2+inborder*2,4.07692,butwsmall,labelh];

%uipos.HelpButton = [outborder+framew+(inborder*2),1,butwmed,labelh];
uipos.CancelButton = [figw-(inborder*2)-butwmed,1,butwmed,labelh];
%uipos.OKButton = [uipos.h1_8(1)+((uipos.h1_8(3)-butwmed)/2),1,butwmed,labelh];
uipos.OKButton = [uipos.CancelButton(1)-butwmed-inborder,1,butwmed,labelh];
uipos.HelpButton = [uipos.OKButton(1)-butwmed-inborder,1,butwmed,labelh];
