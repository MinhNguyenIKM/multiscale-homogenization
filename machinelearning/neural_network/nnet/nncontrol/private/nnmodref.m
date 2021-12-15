function nnmodref(cmd,arg1,arg2,arg3)
%NNMODREF Neural Network Model Reference Controller GUI for Neural Network Controller Toolbox.
%
%  Synopsis
%
%    nnmodref(cmd,arg1,arg2,arg3)
%
%  Warning!!
%
%    This function may be altered or removed in future
%    releases of the Neural Network Toolbox. We recommend
%    you do not write code which calls this function.
%    This function is generally being called from a Simulink block.

% Orlando De Jesus, Martin Hagan, 1-25-00
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.7.2.8 $ $Date: 2008/10/31 06:22:09 $


% CONSTANTS
me = 'Model Reference Control';

% DEFAULTS
if nargin == 0, cmd = ''; else cmd = lower(cmd); end

% FIND WINDOW IF IT EXISTS
fig = 0;

% 9/3/99 We alow the program to see hidden handles
fig=findall(0,'type','figure','name',me);
if (size(fig,1)==0), fig=0; end

if length(get(fig,'children')) == 0, fig = 0; end

% GET WINDOW DATA IF IT EXISTS
if fig
  H = get(fig,'userdata');
  
  if strcmp(cmd,'')
    if get(H.gcbh_ptr,'userdata')~=arg1
      delete(fig);
      fig=0;
    end
  else
    if strcmp(cmd,'close')
       delete(fig)
       return;
    end
    % ODJ 1-13-00 We check if the field SimulationStatus exist before reading that field
    if isfield(get(H.gcbh_ptr),'UserData')
       if isfield(get_param(get_param(get(H.gcbh_ptr,'userdata'),'parent'),'objectparameters'),'SimulationStatus')
          SimulationStatus=get_param(get_param(get(H.gcbh_ptr,'userdata'),'parent'),'simulationstatus');
       else
          SimulationStatus='none';
       end
    else
       SimulationStatus='none';
    end
    if (strcmp(SimulationStatus,'running') | strcmp(SimulationStatus,'paused')) & ~strcmp(cmd,'close')
      set(H.error_messages,'string','You must stop the simulation to change NN configuration parameters.');
      return;
    end
  end
end

%==================================================================
% Activate the window.
%
% ME() or ME('')
%==================================================================

if strcmp(cmd,'')
  if fig
    figure(fig)
    if strcmp(arg3,'nnident')
      set(H.error_messages,'string',sprintf('Generate or import data before training the neural network controller.'));
    else
      set(H.error_messages,'string',sprintf('Perform plant identification before controller training.'));
    end
    set(fig,'visible','on')
  else
    nncontrolutil('nnmodref','init',arg1,arg2,arg3)
  end

%==================================================================
% Close the window.
%
% ME() or ME('')
%==================================================================

elseif strcmp(cmd,'close') & (fig)
   delete(fig)
   return;

elseif strcmp(cmd,'stop_sim')
  fig2=findall(0,'type','figure','tag','ind_adap_data');
  if (size(fig2,1)==0), fig2=0; end
  f2=get(fig2,'userdata');
  f2.stop=1;
  set(fig2,'UserData',f2);
  return;
       
elseif (strcmp(cmd,'apply') | strcmp(cmd,'ok')) & (fig)
  arg1=get(H.gcbh_ptr,'userdata');
  
  epochs_c = get(H.epochs_c_ptr,'userdata');
  set_param(arg1,'epochs_c',num2str(epochs_c));
    
  retraining_c = get(H.retraining_c_ptr,'userdata');
  set_param(arg1,'retraining_c',num2str(retraining_c));
  
  max_r = get(H.max_r_ptr,'userdata');
  set_param(arg1,'max_r',num2str(max_r));
    
  min_r = get(H.min_r_ptr,'userdata');
  set_param(arg1,'min_r',num2str(min_r));
    
  max_r_int = get(H.max_r_int_ptr,'userdata');
  set_param(arg1,'max_r_int',num2str(max_r_int));
    
  min_r_int = get(H.min_r_int_ptr,'userdata');
  set_param(arg1,'min_r_int',num2str(min_r_int));
    
  sam_training_c = get(H.sam_training_c_ptr,'userdata');
  set_param(arg1,'sam_training_c',num2str(sam_training_c));
    
  S1c = get(H.S1c_ptr,'userdata');
  set_param(arg1,'S1c',num2str(S1c));
    
  Ref_file = get(H.Ref_file_ptr,'userdata');
  set_param(arg1,'Ref_file',Ref_file);
  
  Nrc = get(H.Nrc_ptr,'userdata');
  set_param(arg1,'Nrc',num2str(Nrc));
  
  Nic = get(H.Nic_ptr,'userdata');
  set_param(arg1,'Nic',num2str(Nic));
  
  Njc = get(H.Njc_ptr,'userdata');
  set_param(arg1,'Njc',num2str(Njc));
    
  Use_Inc_training = get(H.Use_Inc_training_ptr,'userdata');
  set_param(arg1,'Use_Inc_training',num2str(Use_Inc_training)); 
    
  Use_Previous_Weights = get(H.Use_Previous_Weights_ptr,'userdata');
  set_param(arg1,'Use_Previous_Weights',num2str(Use_Previous_Weights)); 
    
  IW_r = get(H.IW_r_ptr,'userdata');
  IW_u = get(H.IW_u_ptr,'userdata');
  IW_y = get(H.IW_y_ptr,'userdata');
  LW_c = get(H.LW_c_ptr,'userdata');
  B1_c = get(H.B1_c_ptr,'userdata');
  B2_c = get(H.B2_c_ptr,'userdata');
    
  set_param(arg1,'IW_y',mat2str(IW_y,20));  
  set_param(arg1,'IW_u',mat2str(IW_u,20));  
  set_param(arg1,'IW_r',mat2str(IW_r,20));  
  set_param(arg1,'LW_c',mat2str(LW_c,20));  
  set_param(arg1,'B1_c',mat2str(B1_c,20));  
  set_param(arg1,'B2_c',mat2str(B2_c,20));  
  
  if strcmp(cmd,'ok')
     delete(fig)
  end
  
%==================================================================
% Execute Identification Training.
%
% ME('training')
%==================================================================

elseif strcmp(cmd,'training') & (fig)
  arg1=get(H.gcbh_ptr,'userdata');
  arg2=get(H.gcb_ptr,'userdata');
  nnident('',arg1,arg2,'nnmodref');
  
%==================================================================
% Execute Controller Training.
%
% ME('training')
%==================================================================

elseif (strcmp(cmd,'training_con') | strcmp(cmd,'cont_training_con') | strcmp(cmd,'data_ok') | ...
      strcmp(cmd,'gen_data') | strcmp(cmd,'have_file')) & (fig)
  if strcmp(cmd,'gen_data') & (fig)
    H.Data_Imported=0;
    set(fig,'UserData',H);

  elseif strcmp(cmd,'have_file') & (fig)
    ImportStr=arg1;
    H.Data_Imported=1;
    if nargin==3
       Data_Name=arg2;
    else
       U_Name=arg2;
       Y_Name=arg3;
    end
  end
  
  set(H.Train_con,'enable','off')
  set(H.Cancel_but,'enable','off')
  set(H.OK_but,'enable','off')
  set(H.Apply_but,'enable','off')
  set(H.Handles.Menus.File.Save_NN,'enable','off')
  set(H.Handles.Menus.File.Save_Exit_NN,'enable','off')
  
  if (strcmp(cmd,'gen_data') | strcmp(cmd,'have_file'))%strcmp(cmd,'start_training')
    arg1=get(H.gcbh_ptr,'userdata');
  
    a1 = str2num(get(H.max_r_edit,'string'));
    if ~sanitycheckparam(a1),
      max_r=get_param(arg1,'max_r'); 
      present_error(fig,H,H.max_r_edit,max_r,1, ...
        'Please correct the maximum reference value');  
      return
    else max_r=a1; set(H.max_r_ptr,'userdata',a1); end
    
    a1 = str2num(get(H.min_r_edit,'string'));
    min_r=get_param(arg1,'min_r'); 
    if ~sanitycheckparam(a1),
      present_error(fig,H,H.min_r_edit,min_r,1, ...
        'Please correct the minimum reference value.');  
      return
    elseif a1>=max_r
      present_error(fig,H,H.min_r_edit,min_r,1, ...
        'Please correct the maximum and minimum reference values.');  
      return
    else min_r=a1; set(H.min_r_ptr,'userdata',a1); end
    
    a1 = str2num(get(H.max_r_int_edit,'string'));
    if ~sanitycheckparam(a1) | a1<=0 ,
      max_r_int=get_param(arg1,'max_r_int'); 
      present_error(fig,H,H.max_r_int_edit,max_r_int,1, ...
        'You must enter a valid number for the maximum interval value over which the random input is constant.');  
      return
    else max_r_int=a1; set(H.max_r_int_ptr,'userdata',a1); end
    
    a1 = str2num(get(H.min_r_int_edit,'string'));
    min_r_int=get_param(arg1,'min_r_int'); 
    if ~sanitycheckparam(a1) | a1<=0,
      present_error(fig,H,H.min_r_int_edit,min_r_int,1, ...
        'You must enter a valid number for the minimum interval value over which the random input is constant.');  
      return
    elseif a1>=max_r_int
      present_error(fig,H,H.min_r_int_edit,min_r_int,1, ...
        'You must enter valid maximum and minimum interval values for constant reference input.');  
      return
    else min_r_int=a1; set(H.min_r_int_ptr,'userdata',a1); end
    
    a1 = str2num(get(H.sam_training_c_edit,'string'));
    if length(a1) == 0, a1=0; end
    if ~sanitycheckparam(a1) | a1<1 | ceil(a1)~=a1,
      sam_training_c=get_param(arg1,'sam_training_c'); 
      present_error(fig,H,H.sam_training_c_edit,sam_training_c,1, ...
        'Please correct the number of controller training samples.');  
      return
    else sam_training_c=a1; set(H.sam_training_c_ptr,'userdata',a1); end
    
    Ts=get_param(arg1,'Ts'); 
    set(H.Sampling_time,'string',Ts);
    Ts=str2num(Ts);
  
    fig2=findall(0,'type','figure','tag','ind_adap_data');
    if (size(fig2,1)==0), fig2=0; end
    
    if strcmp(cmd,'have_file')
      if nargin==3
        if isempty(ImportStr)   % Workspace
          tr_dat=evalin('base',Data_Name);
          if ~isfield(tr_dat,'.flag')
             tr_dat.flag=ones(size(tr_dat.Y));
          end
          if ~isfield(tr_dat,'.Ts')
             tr_dat.Ts=Ts;
          end
        else
          a1 = ImportStr; 
          a2 = which(cat(2,a1,'.mat'));
          if (length(a1) == 0 | length(a2) == 0), 
             present_error(fig,H,0,0,0, ...
                'You must enter a valid filename for your training data, or the file directory must be defined in the MATLAB Path.'); 
             return
          else file_data=a1; end
          temp=load (file_data,Data_Name);
          tr_dat.U=getfield(temp,Data_Name,'U');
          tr_dat.Y=getfield(temp,Data_Name,'Y');
          if isfield(eval(cat(2,'temp.',Data_Name)),'flag')
             tr_dat.flag=getfield(temp,Data_Name,'flag');
          else
             tr_dat.flag=ones(size(tr_dat.Y));
          end
          if isfield(eval(cat(2,'temp.',Data_Name)),'Ts')
             tr_dat.Ts=getfield(temp,Data_Name,'Ts');
          else
             tr_dat.Ts=Ts;
          end
        end
      else
        if isempty(ImportStr)   % Workspace
          tr_dat=struct('U',evalin('base',U_Name),'Y',evalin('base',Y_Name));
          tr_dat.flag=ones(size(tr_dat.Y));
          tr_dat.Ts=Ts;
        else
          a1 = ImportStr; 
          a2 = which(cat(2,a1,'.mat'));
          if (length(a1) == 0 | length(a2) == 0), 
             present_error(fig,H,0,0,0, ...
                'You must enter a valid filename for your training data, or the file directory must be defined in the MATLAB Path.'); 
             return
          else file_data=a1; end
          temp=load (file_data,U_Name,Y_Name);
          tr_dat.U=getfield(temp,U_Name);
          tr_dat.Y=getfield(temp,Y_Name);
          tr_dat.flag=ones(size(tr_dat.Y));
          tr_dat.Ts=Ts;
        end
      end
      
      % We verify direction of the input vectors.
      if size(tr_dat.U,1)<=1
         tr_dat.U=tr_dat.U';
      end
      if size(tr_dat.Y,1)<=1
         tr_dat.Y=tr_dat.Y';
      end
      if size(tr_dat.flag,1)<=1
         tr_dat.flag=tr_dat.flag';
      end
      sam_training_c=size(tr_dat.Y,1)-1;
      
      if fig2==0
        pos_fig2=get(fig,'Position');
        fig2 = figure('Units','character',...
                 'Interruptible','off', ...
                 'BusyAction','cancel', ...
                 'HandleVis','Callback', ...
                 'Name',           'Input-Output Data for NN Model Reference Control',...
                 'Tag',            'ind_adap_data',...
                 'NumberTitle',    'off',...
                 'Position',       pos_fig2, ...
                 'IntegerHandle',  'off',...
                 'Toolbar',        'none', ...
                'WindowStyle','modal');
        f2.h1=axes('Position',[0.13 0.60 0.74 0.32],'Parent',fig2);
        f2.h2=axes('Position',[0.13 0.15 0.74 0.32],'Parent',fig2);
        f2.message= uicontrol('Parent',fig2, ...
                                 'Units','normalized', ...
                                 'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
                                 'FontWeight','bold', ...
                                 'ForegroundColor',[0 0 1], ...
                                 'ListboxTop',0, ...
                                 'Position',[1-(0.4476+0.01),0.0095,0.4476,0.0635], ...
                                 'Style','text', ...
                                 'Tag','StaticText1');
      else
        f2=get(fig2,'userdata');
        figure(fig2);
      end            
    
      f2.accept_but = uicontrol('Parent',fig2, ...
     'Units','character', ...
       'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
     'Callback','nncontrolutil(''nnmodref'',''data_ok'');', ...
     'ListboxTop',0, ...
     'Position',[0.5333,0.2051,19,1.5385], ...
     'String','Accept Data', ...
      'Tag','Pushbutton1');
   
      st=sprintf('The imported data has %d samples.\nPlease Accept or Reject Data to continue.',sam_training_c);
      set(H.error_messages,'string',st);   
      set(f2.message,'string',st);   
    else   %strcmp(cmd,'gen_data')
      a1 = get(H.reference_model,'string');
      udFileEdit = get(H.reference_model,'UserData');
      LastPath = udFileEdit.PathName;
      if isempty(LastPath),
         a2 = which(cat(2,a1,'.mdl'));
      else
         a2 = which(cat(2,LastPath,cat(2,a1,'.mdl')));
      end
      if (length(a1) == 0 | length(a2) == 0), 
         Ref_file=get_param(arg1,'Ref_file'); 
         present_error(fig,H,H.reference_model,a1,0, ...
            'You must enter a valid filename for your reference model'); 
         return
      else 
         Ref_file=a1;
         OpenFlag=1;
         ErrorFlag=isempty(find_system(0,'flat','Name',Ref_file));
         if ErrorFlag,
           ErrorFlag=~(exist(Ref_file)==4);
           if ~ErrorFlag,
              OpenFlag=0;
              load_system(Ref_file);
           end
         end
         if ErrorFlag,
           ErrMsg=[Ref_file ' must be the name of a Simulink model.'];
           present_error(fig,H,H.reference_model,a1,0,ErrMsg); 
           return
         end
          
         blk=get_param(Ref_file,'blocks');
         iblk=0;oblk=0;
         for k=1:size(blk,1)
           if strcmp(get_param(cat(2,cat(2,Ref_file,'/'),blk{k}),'blocktype'),'Inport')
              iblk=iblk+1;
           end
           if strcmp(get_param(cat(2,cat(2,Ref_file,'/'),blk{k}),'blocktype'),'Outport')
              oblk=oblk+1;
           end
         end
         if ~OpenFlag,close_system(Ref_file,0);end

         if iblk~=1 | oblk~=1
           present_error(fig,H,H.reference_model,a1,0, ...
              'The Simulink reference model must have one Inport and one Outport'); 
           return
         end
         ref_path=a2(1:findstr(a2,a1)-1); set(H.Ref_file_ptr,'userdata',Ref_file);  
      end
  
      if fig2==0
        pos_fig2=get(fig,'Position');
        fig2 = figure('Units',          'character',...
                 'Interruptible','off', ...
                 'BusyAction','cancel', ...
                 'HandleVis','Callback', ...
                 'Name',           'Input-Output Data for NN Model Reference Control',...
                 'Tag',            'ind_adap_data',...
                 'NumberTitle',    'off',...
                 'Position',       pos_fig2, ...
                 'IntegerHandle',  'off',...
                 'Toolbar',        'none', ...
                'WindowStyle','modal');
        f2.h1=axes('Position',[0.13 0.60 0.74 0.32],'Parent',fig2);
        f2.h2=axes('Position',[0.13 0.15 0.74 0.32],'Parent',fig2);
        f2.message= uicontrol('Parent',fig2, ...
                                 'Units','normalized', ...
                                 'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
                                 'FontWeight','bold', ...
                                 'ForegroundColor',[0 0 1], ...
                                 'ListboxTop',0, ...
                                 'Position',[1-(0.4476+0.01),0.0095,0.4476,0.0635], ...
                                 'Style','text', ...
                                 'Tag','StaticText1');
      else
        f2=get(fig2,'userdata');
        figure(fig2);
      end            
    
      f2.accept_but = uicontrol('Parent',fig2, ...
     'Units','character', ...
       'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
     'Callback','nncontrolutil(''nnmodref'',''stop_sim'');', ...
     'ListboxTop',0, ...
     'Position',[0.5333,0.2051,19,1.5385], ...
     'String','Stop Simulation', ...
      'Tag','Pushbutton1');
      f2.stop=0;
      set(fig2,'UserData',f2);
      
      set(H.error_messages,'string','Simulating plant. Wait until sample data points are generated');
      drawnow; % pause needed to refresh the message
      
      options=simset('OutputPoints','all');
      step_size=(max_r_int+min_r_int)/2;
      k=1;
      k1=1;
      % We change cursor shape.
      set(fig,'pointer','watch');
      Actual_path=pwd;
      if isempty(ref_path)
         ref_path=Actual_path;
      end
      cd(ref_path);
      tr_dat.Ts=Ts;
      while k<=sam_training_c
        if ceil((k1-1)/step_size)==(k1-1)/step_size
          newsample=rand*(max_r-min_r)+min_r;
          k1=1;
          step_size=ceil(max([min([(rand*(max_r_int-min_r_int)+min_r_int) max_r_int]) min_r_int])/Ts);
        end
        k1=k1+1;
        tr_dat.U(k,1)=newsample;
        % Change to process models with no states
        ss=warning;
        warning('off');
        [time,xx0,yy] = sim(Ref_file,[(k-1)*Ts k*Ts],options,[[(k-1)*Ts k*Ts]' [tr_dat.U(k) tr_dat.U(k)]']);
        warning(ss);
        if size(xx0,1)>0
            options.InitialState=xx0(size(xx0,1),:);
        end
        tr_dat.Y(k+1,1)=yy(size(yy,1));
        
        if ceil(k/100)==k/100
          f2=get(fig2,'userdata');
          if f2.stop~=0
            st=sprintf('Simulation stopped by the user.\nPlease Accept or Reject Data to continue.');
            set(H.error_messages,'string',st);   
            H.Data_Available=0;
            set(fig,'UserData',H);
            sam_training_c=k;
            k=k+1;
            break
          end
           
          st=sprintf('Processing sample # %d of %d total samples.',k,sam_training_c);
          set(H.error_messages,'string',st);   
          set(f2.message,'string',st);   
          
          plot((0:k-1)*Ts,tr_dat.U(1:k),'Parent',f2.h1);
          plot((0:k-1)*Ts,tr_dat.Y(2:k+1),'Parent',f2.h2);
    
          set(get(f2.h1,'Title'),'string','Reference Model Input','fontweight','bold');
          set(get(f2.h2,'Title'),'string','Reference Model Output','fontweight','bold');
          set(get(f2.h1,'XLabel'),'string','time (s)');
          set(get(f2.h2,'XLabel'),'string','time (s)');
          
          set(fig2,'UserData',f2);
          drawnow;
        end
        k=k+1;
      end
      if ~f2.stop
         st=sprintf('Simulation concluded.\nPlease Accept or Reject Data to continue.');
         set(H.error_messages,'string',st);   
         set(f2.message,'string',st);   
      end
      set(fig,'pointer','arrow');
      cd(Actual_path);
      tr_dat.U(k,1)=newsample;         % We require U and Y have the same size.
      
      set(f2.message,'string',st);
      set(f2.accept_but,'Callback','nncontrolutil(''nnmodref'',''data_ok'');', ...
     'String','Accept Data');
    end
      
    set(H.max_r_edit,'enable','off')
    set(H.max_r_text,'enable','off')
    set(H.min_r_edit,'enable','off')
    set(H.min_r_text,'enable','off')
    set(H.max_r_int_edit,'enable','off')
    set(H.max_r_int_text,'enable','off')
    set(H.min_r_int_edit,'enable','off')
    set(H.min_r_int_text,'enable','off')
    set(H.sam_training_c_text,'enable','off')
    set(H.sam_training_c_edit,'enable','off')
    set(H.BrowseButton,'enable','off');
    set(H.reference_model,'enable','off');
    set(H.reference_model_text,'enable','off');
  
    f2.refuse_but = uicontrol('Parent',fig2, ...
     'Units','character', ...
       'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
     'Callback','nncontrolutil(''nnmodref'',''data_NO_ok'');', ...
     'ListboxTop',0, ...
     'Position',[20.5,0.2051,19,1.5385], ...
     'String','Refuse Data', ...
      'Tag','Pushbutton1');
    
    plot((0:sam_training_c-1)*Ts,tr_dat.U(1:sam_training_c),'Parent',f2.h1);
    plot((0:sam_training_c-1)*Ts,tr_dat.Y(2:sam_training_c+1),'Parent',f2.h2);
    set(f2.h1,'xlim',[0 (sam_training_c-1)*Ts]);
    set(f2.h2,'xlim',[0 (sam_training_c-1)*Ts]);
    
    set(get(f2.h1,'Title'),'string','Reference Model Input','fontweight','bold');
    set(get(f2.h2,'Title'),'string','Reference Model Output','fontweight','bold');
    set(get(f2.h1,'XLabel'),'string','time (s)');
    set(get(f2.h2,'XLabel'),'string','time (s)');
      
    set(fig,'userdata',H)
    set(fig2,'UserData',f2);
    save(cat(2,tempdir,'ind_adap_data2.mat'));
    return;
    
  elseif strcmp(cmd,'data_ok')
    load(cat(2,tempdir,'ind_adap_data2.mat'));
    delete(cat(2,tempdir,'ind_adap_data2.mat'));
    delete(fig2);
  
    N2=length(tr_dat.U);
    st=sprintf('Your training data set has %d samples.\nYou can now train the network.',N2-1);
    set(H.error_messages,'string',st);   

    if H.Training_done==1
       set(H.Apply_but,'enable','on');
       set(H.OK_but,'enable','on');
       set(H.Handles.Menus.File.Save_NN,'enable','on')
       set(H.Handles.Menus.File.Save_Exit_NN,'enable','on')
    end
    set(H.Train_con,'enable','on')
    set(H.Cancel_but,'enable','on'); 
    
    H.Data_Available=1;
    if H.Data_Imported
       H.Data_Generated=0;
       set(H.Gen_data_but,'String','Erase Imported Data', ...
         'Callback','nncontrolutil(''nnmodref'',''erase_data'')', ...
         'TooltipString','The imported data will be erased and the Training Data menu will be enabled.');
    else
       H.Data_Generated=1;
       set(H.Gen_data_but,'String','Erase Generated Data', ...
         'Callback','nncontrolutil(''nnmodref'',''erase_data'')', ...
         'TooltipString','The generated data will be erased and the Training Data menu will be enabled.');
    end
    set(fig,'userdata',H)
    
    save(cat(2,tempdir,'nnmodrefdata.mat'));
    return
      
  elseif strcmp(cmd,'training_con') 
    load(cat(2,tempdir,'nnmodrefdata.mat'));
    HH=msgbox({['The Neural Network is being configured.'] ['Training will start shortly.'] },me,'warn'); 
    delete(findobj(HH,'style','pushbutton'));
    drawnow;   % Pause works better here that drawnow.
     
    a1 = str2num(get(H.epochs_c_edit,'string'));
    if length(a1) == 0, a1=0; end
    if a1<2 | ceil(a1)~=a1 | ~sanitycheckparam(a1), 
      epochs_c=get_param(arg1,'epochs_c'); 
      present_error(fig,H,H.epochs_c_edit,epochs_c,1, ...
        'Please correct the number of controller training epochs per segment.');  
      delete(HH);
      return
    else epochs_c=a1; set(H.epochs_c_ptr,'userdata',a1); end
    
    a1 = str2num(get(H.retraining_c_edit,'string'));
    if length(a1) == 0, a1=0; end
    if a1<1 | ceil(a1)~=a1 | ~sanitycheckparam(a1), 
      retraining_c=get_param(arg1,'retraining_c'); 
      present_error(fig,H,H.retraining_c_edit,retraining_c,1, ...
        'Please, correct the controller training segments value');  
      delete(HH);
      return
    else retraining_c=a1; set(H.retraining_c_ptr,'userdata',a1); end
    
    a1 = str2num(get(H.Hidden_layer_size,'string'));
    if length(a1) == 0, a1=0; end
    if a1<1 | ceil(a1)~=a1 | ~sanitycheckparam(a1), 
      S1c=get_param(arg1,'S1c'); 
      present_error(fig,H,H.Hidden_layer_size,S1c,1, ...
        'You must initialize the size of the hidden layer before starting the simulation.');  
      delete(HH);
      return
    else S1c=a1; set(H.S1c_ptr,'userdata',S1c);  end
     
    a1 = str2num(get(H.Delayed_ref_input,'string'));
    if (length(a1) == 0) | (a1 < 1) | (floor(a1)~=a1) | ~sanitycheckparam(a1), 
      Nrc=get_param(arg1,'Nrc'); 
      present_error(fig,H,H.Delayed_ref_input,Nrc,1, ...
        'You must enter a valid number of delayed reference inputs');  
      delete(HH);
      return
    else Nrc=a1; set(H.Nrc_ptr,'userdata',Nrc);  end
  
    a1 = str2num(get(H.Delayed_contr_output,'string'));
    if (length(a1) == 0) | (a1 < 1) | (floor(a1)~=a1) | ~sanitycheckparam(a1), 
      Nic=get_param(arg1,'Nic'); 
      present_error(fig,H,H.Delayed_contr_output,Nic,1, ...
        'You must enter a valid number of delayed controller outputs');  
      delete(HH);
      return
    else Nic=a1; set(H.Nic_ptr,'userdata',Nic);  end
  
    a1 = str2num(get(H.Delayed_output,'string'));
    if (length(a1) == 0) | (a1 < 1) | (floor(a1)~=a1) | ~sanitycheckparam(a1), 
      Njc=get_param(arg1,'Njc'); 
      present_error(fig,H,H.Delayed_output,Njc,1, ...
        'You must enter a valid number of delayed plant outputs');  
      delete(HH);
      return
    else Njc=a1; set(H.Njc_ptr,'userdata',Njc);  end
    
    Use_Inc_training=get(H.Use_Inc_training_but,'value');
    set(H.Use_Inc_training_ptr,'userdata',Use_Inc_training); 
    
    Use_Previous_Weights=get(H.Use_Previous_Weights_but,'value');
    set(H.Use_Previous_Weights_ptr,'userdata',Use_Previous_Weights); 
    
    mint=str2num(get_param(arg1,'mint'));
    maxt=str2num(get_param(arg1,'maxt'));
    minp=str2num(get_param(arg1,'minp'));
    maxp=str2num(get_param(arg1,'maxp'));
    Nj=str2num(get_param(arg1,'Nj'));
    Ni=str2num(get_param(arg1,'Ni'));
    S1=str2num(get_param(arg1,'S1'));
    IW=eval(strvcat(get_param(arg1,'IW')));
    LW2_1=eval(strvcat(get_param(arg1,'LW2_1')));
    LW1_2=eval(strvcat(get_param(arg1,'LW1_2')));
    B1=eval(strvcat(get_param(arg1,'B1')));
    B2=eval(strvcat(get_param(arg1,'B2')));
    
    Normalize=str2num(get_param(arg1,'Normalize')); 
    set(H.Normalize_data,'value',Normalize);
  
    S2=1;
    tf1 = 'tansig';
    tf2 = 'purelin';
    mM=[mint maxt];
    for k=2:Njc
      mM=[mM;mint maxt];
    end
    for k=1:Nic
      mM=[mM;minp maxp];
    end
    for k=1:Nrc
      mM=[mM;min_r max_r];
    end
    ws = warning('off','NNET:Obsolete');
    netn = newff(mM,[S1c S2 S1 S2],{tf1,tf2,tf1,tf2},'trainlm');
    warning(ws)
    
    IW_y=netn.IW{1,1}(1:S1c,1:Njc);
    IW_u=netn.IW{1,1}(1:S1c,Njc+1:Njc+Nic);
    IW_r=netn.IW{1,1}(1:S1c,Njc+Nic+1:Njc+Nic+Nrc);
    B1_c=netn.b{1};
    B2_c=netn.b{2};
    LW_c=netn.LW{2,1};
  
    if Use_Previous_Weights & ~isempty(strvcat(get_param(arg1,'IW_y')))
      IW_rb = get(H.IW_r_ptr,'userdata');
      IW_ub = get(H.IW_u_ptr,'userdata');
      IW_yb = get(H.IW_y_ptr,'userdata');
      LW_cb = get(H.LW_c_ptr,'userdata');
      B1_cb = get(H.B1_c_ptr,'userdata');
      B2_cb = get(H.B2_c_ptr,'userdata');
  
      IW_y2 = eval(strvcat(get_param(arg1,'IW_y')));
      IW_r2 = eval(strvcat(get_param(arg1,'IW_r')));
      IW_u2 = eval(strvcat(get_param(arg1,'IW_u')));
      LW_c2 = eval(strvcat(get_param(arg1,'LW_c')));
      B1_c2 = eval(strvcat(get_param(arg1,'B1_c')));
      B2_c2 = eval(strvcat(get_param(arg1,'B2_c')));
      if (size(IW_y2)==size(IW_y)) & (size(IW_r2)==size(IW_r)) & (size(IW_u2)==size(IW_u)) & (size(LW_c2)==size(LW_c)) & (size(B1_c2)==size(B1_c)) & (size(B2_c2)==size(B2_c)) 
           % If Weights different from last generated, we use Simulink weights.
        if (size(IW_yb)==size(IW_y)) & (size(IW_rb)==size(IW_r)) & (size(IW_ub)==size(IW_u)) & (size(LW_cb)==size(LW_c)) & (size(B1_cb)==size(B1_c)) & (size(B2_cb)==size(B2_c)) 
              % We only compare IW1_1 to see if we have same values in simulink model and menu.
           cx=IW_yb==IW_y2;
              % Different weights, we ask which we want we prefer.
           if sum(cx(:))~=size(IW_y(:),1)
              if ishghandle(HH)
                 delete(HH);
              end
              switch questdlg(...
                    {'You have a set of weights in the Simulink model and another set of weights generated in the current training process.'
                     ' ';
                     'Select which set of weights you want to use. If you select Simulink model weights, the generated weights are discarded.'
                     ' '},...
                     'Weight Selection','Simulink Model Weights','Generated Weights','Generated Weights');
              case 'Simulink Model Weights'
                 overwriteOK = 1;
              case 'Generated Weights'
                 overwriteOK = 0;
              end % switch questdlg
           else
              overwriteOK = 0;
           end
        else
           overwriteOK = 0;
        end
        if overwriteOK
           IW_y = IW_y2;
           IW_r = IW_r2;
           IW_u = IW_u2;
           LW_c = LW_c2;
           B1_c = B1_c2;
           B2_c = B2_c2;
        else
           IW_y = IW_yb;
           IW_r = IW_rb;
           IW_u = IW_ub;
           LW_c = LW_cb;
           B1_c = B1_cb;
           B2_c = B2_cb;
        end
      end
    end
    
    ws = warning('off','NNET:Obsolete');
    netn = newff([mint maxt],[S1c S2 S1 S2],{tf1,tf2,tf1,tf2},'trainbfgc');
    warning(ws)
    
    netn.trainParam.show=1;
    netn.trainParam.epochs=epochs_c;
     
    netn.layerConnect(1,2)=1;
    netn.layerWeights{1,2}.delays=[1:Nic];
    netn.layerConnect(1,4)=1;
    netn.layerWeights{1,4}.delays=[1:Njc];
    netn.LW{1,2}=IW_u;
    netn.LW{1,4}=IW_y;
    netn.layerWeights{3,2}.delays=[0:Ni-1];
    netn.LW{3,2}=IW;
    netn.layerConnect(3,4)=1;
    netn.layerWeights{3,4}.delays=[1:Nj];
    netn.LW{3,4}=LW1_2;
    netn.LW{4,3}=LW2_1;
    netn.b{3}=B1;
    netn.b{4}=B2;
    netn.layerWeights{3,4}.learn=0;
    netn.layerWeights{3,2}.learn=0;
    netn.layerWeights{4,3}.learn=0;
    netn.biases{3}.learn=0;
    netn.biases{4}.learn=0;
    netn.inputWeights{1,1}.delays=[0:Nrc-1];
    netn.IW{1,1}=IW_r;
    netn.b{1}=B1_c;
    netn.b{2}=B2_c;
    netn.LW{2,1}=LW_c;
     
  end
  retraining_size=fix(sam_training_c/retraining_c);
  
  if Normalize
     U=(tr_dat.U-min_r)*2/(max_r-min_r)-1;
     Y=(tr_dat.Y-mint)*2/(maxt-mint)-1;
  else
     U=tr_dat.U;
     Y=tr_dat.Y;
  end
  if ishghandle(HH)
     delete(HH);
  end
  drawnow;            % works better than drawnow
  if Use_Inc_training==0
     for rt=1:retraining_c
        Partition=retraining_size; %min([retraining_size max([200 fix(sam_training_c/retraining_c/25)])]);
        for k=1:Partition
           rrxx{k}=(U(retraining_size*(rt-1)+k:Partition:retraining_size*rt-Partition+k)');
           yyxx{k}=(Y(retraining_size*(rt-1)+k+1:Partition:retraining_size*rt-Partition+k+1)');
        end
        ui=cell(0,0);
        par_size=size(rrxx{1},2);
        for kk=1:Nrc-1
           ui{kk}=[];
           for k2=1:par_size
              up=retraining_size*(rt-1)+Partition*(k2-1)-Nrc+2;
              if up<=0
                 ui{kk}=[ui{kk} 0];
              else
                 ui{kk}=[ui{kk} U(up)];
              end
           end
        end
        st=sprintf('Training segment # %d of %d: ',rt,retraining_c);
        set(H.error_messages,'string',st);   
     
        if rt==1
           [netn,tr,Yout,E,Pf,Af,flag_stop] = trainbfgc(netn,rrxx,yyxx,ui,[],epochs_c,Partition,par_size);
        else
           Ai=Af;
        %  Only important last Af value
           for kk=1:size(Af,1)
              for k2=1:size(Af,2)
                 Ai{kk,k2}(1:size(Af{1},2))=Af{kk,k2}(size(Af{1},2));
              end
           end
           [netn,tr,Yout,E,Pf,Af,flag_stop] = trainbfgc(netn,rrxx,yyxx,ui,Ai,epochs_c,Partition,par_size);
        end
        if flag_stop
           break
        end
     end
  else
     Partition=0; 
     for rt=1:retraining_c
        Partition=Partition+retraining_size; 
        for k=1:Partition
           rrxx{k}=(U(k:Partition:retraining_size*rt-Partition+k)');
           yyxx{k}=(Y(k+1:Partition:retraining_size*rt-Partition+k+1)');
        end
        ui{1}=[];
        par_size=size(rrxx{1},2);
        for kk=1:Nrc-1
           for k2=1:par_size
              up=Partition*(k2-1)-Nrc+2;
              if up<=0
                 ui{kk}=[ui{kk} 0];
              else
                 ui{kk}=[ui{kk} U(up)];
              end
           end
        end
        st=sprintf('Training segment # %d of %d: ',rt,retraining_c);
        set(H.error_messages,'string',st);   
     
        [netn,tr,Yout,E,Pf,Af,flag_stop] = trainbfgc(netn,rrxx,yyxx,ui,[],epochs_c,Partition,par_size);
        if flag_stop
           break
        end
     end
  end

  if flag_stop
     set(H.error_messages,'string','Training stopped by the user. You can generate or import new data, continue training or save results by selecting OK or Apply.');
     HH=msgbox({['Training stopped by the user.'] ['Plots with the reference input, and reference output and neural network output (controller + plant) will be presented shortly.'] },me,'warn'); 
     delete(findobj(HH,'style','pushbutton'));
else
     set(H.error_messages,'string','Training complete. You can generate or import new data, continue training or save results by selecting OK or Apply.');
     HH=msgbox({['Training complete.'] ['Plots with the reference input, and reference output and neural network output (controller + plant) will be presented shortly.'] },me,'warn'); 
     delete(findobj(HH,'style','pushbutton'));
  end
  drawnow;   % Pause works better here that drawnow.
    
  xx=mat2cell(U(1:sam_training_c)',1,ones(sam_training_c,1));
  [Yout,Pf,Af,E,perf] =sim(netn,xx);
  Yout=cell2mat(Yout);
  
  fig2=findall(0,'type','figure','tag','ind_adap_data0');
  if (size(fig2,1)==0), fig2=0; end
  matlab_position=get(0,'screensize');
  matlab_units=get(0,'units');
  if strcmp(matlab_units,'pixels');
     matlab_position=matlab_position*H.PointsToPixels;
  end
  if fig2==0
      units_fig2=get(fig,'Units');
      pos_fig2=get(fig,'pos');
      pos_fig2(1) = pos_fig2(1)+(pos_fig2(3)/4);pos_fig2(2) = pos_fig2(2)-(pos_fig2(4)/4);
      fig2 = figure('Units',        units_fig2,...
                 'Interruptible','off', ...
                 'BusyAction','cancel', ...
                 'HandleVis','Callback', ...
                 'Name',           'Plant Response for NN Model Reference Control',...
                 'Tag',            'ind_adap_data0',...
                 'NumberTitle',    'off',...
                 'Position',       pos_fig2, ...
                 'IntegerHandle',  'off',...
                 'Toolbar',        'none');
      f2.h1=axes('Position',[0.13 0.60 0.74 0.32],'Parent',fig2);
      f2.h2=axes('Position',[0.13 0.15 0.74 0.32],'Parent',fig2);
  else
      f2=get(fig2,'userdata');
      figure(fig2);
  end            
  
  plot((0:sam_training_c-1)*Ts,tr_dat.U(1:sam_training_c),'Parent',f2.h1);
  if Normalize
     plot((0:sam_training_c-1)*Ts,tr_dat.Y(2:sam_training_c+1),'b',(0:sam_training_c-1)*Ts, ...
          (Yout(1:sam_training_c)+1)*(maxt-mint)/2+mint,'g','Parent',f2.h2);
  else
     plot((0:sam_training_c-1)*Ts,tr_dat.Y(2:sam_training_c+1),'b',(0:sam_training_c-1)*Ts, ...
          Yout(1:sam_training_c),'g','Parent',f2.h2);
  end
  set(f2.h1,'xlim',[0 (sam_training_c-1)*Ts]);
  set(f2.h2,'xlim',[0 (sam_training_c-1)*Ts]);

  set(get(f2.h1,'Title'),'string','Reference Model Input','fontweight','bold');
  set(get(f2.h2,'Title'),'string','Reference Model Output (blue), Neural Network Output (green)','fontweight','bold');
  set(get(f2.h1,'XLabel'),'string','time (s)');
  set(get(f2.h2,'XLabel'),'string','time (s)');
    
  set(fig2,'UserData',f2);
  save(cat(2,tempdir,'nnmodrefdata.mat'));
  
  set(H.IW_r_ptr,'userdata',netn.IW{1,1}); 
  set(H.IW_u_ptr,'userdata',netn.LW{1,2}); 
  set(H.IW_y_ptr,'userdata',netn.LW{1,4}); 
  set(H.LW_c_ptr,'userdata',netn.LW{2,1}); 
  set(H.B1_c_ptr,'userdata',netn.b{1}); 
  set(H.B2_c_ptr,'userdata',netn.b{2}); 

  H.Training_done=1;
  set(H.Apply_but,'enable','on');
  set(H.OK_but,'enable','on');
  set(H.Handles.Menus.File.Save_NN,'enable','on')
  set(H.Handles.Menus.File.Save_Exit_NN,'enable','on')
  set(H.Train_con,'enable','on')
  set(H.Cancel_but,'enable','on')
  
  set(H.Use_Previous_Weights_ptr,'userdata',1);
  set(H.Use_Previous_Weights_but,'value',1);
  
  if ishghandle(HH)
     delete(HH);
  end
  arg1=get(H.gcbh_ptr,'userdata');
  arg2=get(H.gcb_ptr,'userdata');
  nncontrolutil('nnmodref','',arg1,arg2,'');
  
elseif strcmp(cmd,'browsesim')
   filterspec = '*.mdl';
   
   udFileEdit = get(H.reference_model,'UserData');
   LastPath = udFileEdit.PathName;
   CurrentPath=pwd;
   if ~isempty(LastPath),
      cd(LastPath);
   end
   [filename,pathname] = uigetfile(filterspec,'Simulink Reference Model:');
   if ~isempty(LastPath),
      cd(CurrentPath);
   end
   
   if filename,
      if ~strcmpi(pathname(1:end-1),CurrentPath)
         ImportStr = [pathname,filename(1:end-4)];
      else
         ImportStr = filename(1:end-4);
      end
      udFileEdit.PathName=pathname;
      udFileEdit.FileName=filename;
      set(H.reference_model,'String',filename(1:end-4),'UserData',udFileEdit);
   end
   
elseif strcmp(cmd,'clearpath') & (fig)
   %---Callback for the SImulink File box
   %    Whenever a new name is entered, update the Userdata
   NewName = get(gcbo,'String');
   indDot = findstr(NewName,'.');
   if ~isempty(indDot),
      NewName=NewName(1:indDot(end)-1);
      set(H.reference_model,'String',NewName)   
   end
      
elseif strcmp(cmd,'erase_data') & (fig)
  set(H.max_r_edit,'enable','on')
  set(H.max_r_text,'enable','on')
  set(H.min_r_edit,'enable','on')
  set(H.min_r_text,'enable','on')
  set(H.max_r_int_edit,'enable','on')
  set(H.max_r_int_text,'enable','on')
  set(H.min_r_int_edit,'enable','on')
  set(H.min_r_int_text,'enable','on')
  set(H.sam_training_c_text,'enable','on')
  set(H.sam_training_c_edit,'enable','on')
  set(H.BrowseButton,'enable','on');
  set(H.reference_model,'enable','on');
  set(H.reference_model_text,'enable','on');
  
  H.Data_Generated=0;
  H.Data_Imported=0;
  H.Data_Available=0;
  set(H.Train_con,'enable','off')
  if exist(cat(2,tempdir,'ind_adap_data2.mat'))
     delete(cat(2,tempdir,'ind_adap_data2.mat'));
  end
  if exist(cat(2,tempdir,'nnmodrefdata.mat'))
     delete(cat(2,tempdir,'nnmodrefdata.mat'));
  end
  set(fig,'UserData',H);
  set(H.Gen_data_but,'String','Generate Training Data', ...
           'Callback','nncontrolutil(''nnmodref'',''gen_data'')', ...
           'TooltipString','Generate data to be used in training the neural network controller.');
  set(H.error_messages,'string',sprintf('Generate or import data before training the neural network controller.'));
        
elseif strcmp(cmd,'data_no_ok') & (fig)
  
  set(H.Cancel_but,'enable','on')
  if H.Training_done
     set(H.OK_but,'enable','on')
     set(H.Apply_but,'enable','on')
     set(H.Handles.Menus.File.Save_NN,'enable','on')
     set(H.Handles.Menus.File.Save_Exit_NN,'enable','on')
  end
  if H.Data_Available
    load(cat(2,tempdir,'nnmodrefdata.mat'),'N2');
    set(H.Train_con,'enable','on')
    st=sprintf('Your training data set has %d samples.\nYou can now train the network.',N2-1);
    set(H.error_messages,'string',st);   
  else
    set(H.error_messages,'string',sprintf('Generate or import data before training the neural network controller.'));
    set(H.max_r_edit,'enable','on')
    set(H.max_r_text,'enable','on')
    set(H.min_r_edit,'enable','on')
    set(H.min_r_text,'enable','on')
    set(H.max_r_int_edit,'enable','on')
    set(H.max_r_int_text,'enable','on')
    set(H.min_r_int_edit,'enable','on')
    set(H.min_r_int_text,'enable','on')
    set(H.sam_training_c_text,'enable','on')
    set(H.sam_training_c_edit,'enable','on')
    set(H.BrowseButton,'enable','on');
    set(H.reference_model,'enable','on');
    set(H.reference_model_text,'enable','on');
  end
  drawnow; % pause needed to refresh the message
  
  fig2=findall(0,'type','figure','tag','ind_adap_data');
  if (size(fig2,1)==0), fig2=0; end
  
  delete(fig2);
  if exist(cat(2,tempdir,'ind_adap_data2.mat'))
     delete(cat(2,tempdir,'ind_adap_data2.mat'));
  end
  
  % We refresh the menu.
  arg1=get(H.gcbh_ptr,'userdata');
  arg2=get(H.gcb_ptr,'userdata');
  nncontrolutil('nnmodref','',arg1,arg2,'');
  
%==================================================================
% Initialize the window.
%
% ME('init')
%==================================================================

elseif strcmp(cmd,'init') & (~fig)
  % 1-13-00 ODJ We check if the system is locked.
  sys_par=arg2;
  sys_par2=arg2;
  while ~isempty(sys_par2)
      sys_par=sys_par2;
      sys_par2=get_param(sys_par,'parent');
  end
  if strcmp('on',get_param(sys_par,'lock'))
      window_en='off';
  else
      window_en='on';
  end

  H.StdColor = get(0,'DefaultUicontrolBackgroundColor');
  H.StdUnit='points';
  H.PointsToPixels = 72/get(0,'ScreenPixelsPerInch');
  
  uipos = getuipos;
  StdUnits = 'character';
  
  fig = figure('Units',StdUnits, ...
   'Interruptible','off', ...
   'BusyAction','cancel', ...
   'HandleVis','Callback', ...
  'CloseRequestFcn','nncontrolutil(''nnmodref'',''close'')', ...
   'Color',[0.8 0.8 0.8], ...
  'MenuBar','none', ...
   'Name',me, ...
   'numbertitle','off', ...
   'IntegerHandle',  'off',...
  'PaperUnits','points', ...
  'Position',uipos.fig, ...
  'Tag','Fig4', ...
  'ToolBar','none');
  frame4 = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.8 0.8 0.8], ...
  'ListboxTop',0, ...
  'Position',uipos.frame4, ...
  'Style','frame', ...
  'Tag','Frame4');
  frame5 = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.8 0.8 0.8], ...
  'ListboxTop',0, ...
  'Position',uipos.frame5, ...
  'Style','frame', ...
  'Tag','Frame5');
  h1 = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.8 0.8 0.8], ...
    'Enable',window_en, ...
  'ListboxTop',0, ...
  'Position',uipos.h1_1, ...
  'String','Training Parameters', ...
  'Style','text', ...
  'Tag','StaticText1');
  frame1 = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.8 0.8 0.8], ...
  'ListboxTop',0, ...
  'Position',uipos.frame1, ...
  'Style','frame', ...
  'Tag','Frame1');
  h1 = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.8 0.8 0.8], ...
    'Enable',window_en, ...
  'ListboxTop',0, ...
  'Position',uipos.h1_2, ...
  'String','Training Data', ...
  'Style','text', ...
  'Tag','StaticText1');
  frame6 = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.8 0.8 0.8], ...
  'ListboxTop',0, ...
  'Position',uipos.frame6, ...
  'Style','frame', ...
  'Tag','Frame6');
  h1 = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.8 0.8 0.8], ...
    'Enable',window_en, ...
  'ListboxTop',0, ...
  'Position',uipos.h1_3, ...
  'String','Network Architecture', ...
  'Style','text', ...
  'Tag','StaticText1');
  H.Title_nnmodref = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.8 0.8 0.8], ...
  'FontSize',14, ...
  'ListboxTop',0, ...
  'Position',uipos.Title_nnmodref, ...
  'String','Model Reference Control', ...
  'Style','text', ...
  'Tag','Title_nnmodref');
  H.Use_Inc_training_but = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.8 0.8 0.8], ...
    'Enable',window_en, ...
  'ListboxTop',0, ...
  'Position',uipos.Use_Inc_training_but, ...
  'String','Use Cumulative Training', ...
  'Style','checkbox', ...
   'ToolTipStr','Trains the controller by adding one segment of data at a time to the training set.',...
  'Tag','checkbox1');
  H.epochs_c_text = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.8 0.8 0.8], ...
    'Enable',window_en, ...
   'HorizontalAlignment','right', ...
  'ListboxTop',0, ...
  'Position',uipos.epochs_c_text, ...
  'String','Controller Training Epochs', ...
  'Style','text', ...
   'ToolTipStr','Defines the number of iterations per training segment.',...
  'Tag','StaticText2');
  H.epochs_c_edit = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[1 1 1], ...
    'Enable',window_en, ...
  'ListboxTop',0, ...
  'Position',uipos.epochs_c_edit, ...
  'Style','edit', ...
  'Callback',['nncontrolutil(''nnmodref'',''check_params'',''epochs_c_edit'', ''', get(H.epochs_c_text, 'String'),''');'], ...
   'ToolTipStr','Defines the number of iterations per training segment.',...
  'Tag','epochs_c_edit');
  H.Sampling_text = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
   'BackgroundColor',[0.8 0.8 0.8], ...
   'Enable','off', ...
   'HorizontalAlignment','right', ...
  'ListboxTop',0, ...
  'Position',uipos.Sampling_text, ...
  'String','Sampling Interval (sec)', ...
  'Style','text', ...
   'ToolTipStr','Sampling interval at which the data will be collected from the Simulink plant model.',...
  'Tag','StaticText1');
  H.Sampling_time = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[1 1 1], ...
   'Enable','off', ...
  'ListboxTop',0, ...
  'Position',uipos.Sampling_time, ...
  'Style','edit', ...
   'ToolTipStr','Sampling interval at which the data will be collected from the Simulink plant model.',...
   'Callback',['nncontrolutil(''nnmodref'',''check_params'',''Sampling_time'', ''', get(H.Sampling_text, 'String') ,''');'], ...
  'Tag','Sampling_time');
  H.retraining_c_text = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.8 0.8 0.8], ...
    'Enable',window_en, ...
   'HorizontalAlignment','right', ...
  'ListboxTop',0, ...
  'Position',uipos.retraining_c_text, ...
  'String','Controller Training Segments', ...
  'Style','text', ...
   'ToolTipStr','Defines how many segments the training data will be divided into.',...
  'Tag','StaticText2');
  H.retraining_c_edit = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[1 1 1], ...
    'Enable',window_en, ...
  'ListboxTop',0, ...
  'Position',uipos.retraining_c_edit, ...
  'Style','edit', ...
  'Callback',['nncontrolutil(''nnmodref'',''check_params'',''retraining_c_edit'', ''', get(H.retraining_c_text, 'String'),''');'], ...
  'ToolTipStr','Defines how many segments the training data will be divided into.',...
  'Tag','retraining_c_edit');
  H.max_r_text = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.8 0.8 0.8], ...
    'Enable',window_en, ...
   'HorizontalAlignment','right', ...
  'ListboxTop',0, ...
  'Position',uipos.max_r_text, ...
  'String','Maximum Reference Value', ...
  'Style','text', ...
   'ToolTipStr','Defines an upper bound on the random reference input for training.',...
  'Tag','StaticText2');
  H.max_r_edit = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[1 1 1], ...
    'Enable',window_en, ...
  'ListboxTop',0, ...
  'Position',uipos.max_r_edit , ...
  'Style','edit', ...
  'Callback',['nncontrolutil(''nnmodref'',''check_params'',''max_r_edit'', ''', get(H.max_r_text, 'String'),''');'], ...
  'ToolTipStr','Defines an upper bound on the random reference input for training.',...
  'Tag','max_r_edit');
  H.min_r_text = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.8 0.8 0.8], ...
    'Enable',window_en, ...
   'HorizontalAlignment','right', ...
  'ListboxTop',0, ...
  'Position',uipos.min_r_text, ...
  'String','Minimum Reference Value', ...
  'Style','text', ...
   'ToolTipStr','Defines a lower bound on the random reference input for training.',...
  'Tag','StaticText2');
  H.min_r_edit = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[1 1 1], ...
    'Enable',window_en, ...
  'ListboxTop',0, ...
  'Position',uipos.min_r_edit, ...
  'Style','edit', ...
  'Callback',['nncontrolutil(''nnmodref'',''check_params'',''min_r_edit'', ''', get(H.min_r_text, 'String'),''');'], ...
  'ToolTipStr','Defines a lower bound on the random reference input for training.',...
  'Tag','EditText1');
  H.max_r_int_text = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.8 0.8 0.8], ...
    'Enable',window_en, ...
  'ListboxTop',0, ...
  'Position',uipos.max_r_int_text, ...
  'String','Maximum Interval Value (sec)', ...
  'Style','text', ...
  'HorizontalAlignment', 'right',...
   'ToolTipStr','Defines a maximum interval over which the random reference input will remain constant.',...
  'Tag','StaticText2');
  H.max_r_int_edit = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[1 1 1], ...
    'Enable',window_en, ...
  'ListboxTop',0, ...
  'Position',uipos.max_r_int_edit, ...
  'Style','edit', ...
   'Callback',['nncontrolutil(''nnmodref'',''check_params'',''max_r_int_edit'', ''', get(H.max_r_int_text, 'String'),''');'], ...
   'ToolTipStr','Defines a maximum interval over which the random reference input will remain constant.',...
  'Tag','max_r_edit');
  H.min_r_int_text = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.8 0.8 0.8], ...
    'Enable',window_en, ...
   'HorizontalAlignment','right', ...
  'ListboxTop',0, ...
  'Position',uipos.min_r_int_text, ...
  'String','Minimum Interval Value (sec)', ...
  'Style','text', ...
   'ToolTipStr','Defines a minimum interval over which the random reference input will remain constant.',...
  'Tag','StaticText2');
  H.min_r_int_edit = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[1 1 1], ...
  'Enable',window_en, ...
  'ListboxTop',0, ...
  'Position',uipos.min_r_int_edit, ...
  'Style','edit', ...
  'Callback',['nncontrolutil(''nnmodref'',''check_params'',''min_r_int_edit'', ''', get(H.min_r_int_text, 'String'),''');'], ...
  'ToolTipStr','Defines a minimum interval over which the random reference input will remain constant.',...
  'Tag','EditText1');
  H.Hidden_layer_text = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.8 0.8 0.8], ...
    'Enable',window_en, ...
   'HorizontalAlignment','right', ...
  'ListboxTop',0, ...
  'Position',uipos.Hidden_layer_text, ...
  'String','Size of Hidden Layer', ...
  'Style','text', ...
   'ToolTipStr','Defines the size of the second layer of the neural network controller.',...
  'Tag','StaticText1');
  H.Hidden_layer_size = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[1 1 1], ...
    'Enable',window_en, ...
  'ListboxTop',0, ...
  'Position',uipos.Hidden_layer_size, ...
  'Style','edit', ...
   'ToolTipStr','Defines the size of the second layer of the neural network controller.',...
   'Callback',['nncontrolutil(''nnmodref'',''check_params'',''Hidden_layer_size'', ''', get(H.Hidden_layer_text, 'String'),''');'], ...
  'Tag','Hidden_layer');
  H.reference_model_text = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.8 0.8 0.8], ...
    'Enable',window_en, ...
  'ListboxTop',0, ...
  'Position',uipos.reference_model_text, ...
  'String','Reference Model:', ...
  'Style','text', ...
  'HorizontalAlignment', 'right', ...
   'ToolTipStr','Simulink file containing the reference model.',...
  'Tag','StaticText1');
  H.BrowseButton = uicontrol('Parent',fig, ...
  'Unit',StdUnits, ...
  'Callback','nncontrolutil(''nnmodref'',''browsesim'',gcbf);', ...
    'Enable',window_en, ...
  'ListboxTop',0, ...
  'Position',uipos.BrowseButton, ...
  'String','Browse', ...
   'ToolTipStr','Browse the disk to select a Simulink file.',...
  'Tag','BrowseButton');
  H.reference_model = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[1 1 1], ...
  'Callback','nncontrolutil(''nnmodref'',''clearpath'',gcbf);', ...
    'Enable',window_en, ...
  'HorizontalAlignment','left', ...
  'ListboxTop',0, ...
  'Position',uipos.reference_model, ...
  'Style','edit', ...
   'ToolTipStr','Simulink file containing the reference model.',...
  'Tag','Reference_model');
  H.Delayed_ref_input_text = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.8 0.8 0.8], ...
    'Enable',window_en, ...
   'HorizontalAlignment','right', ...
  'ListboxTop',0, ...
  'Position',uipos.Delayed_ref_input_text, ...
  'String','No. Delayed Reference Inputs', ...
  'Style','text', ...
   'ToolTipStr','Defines how many delays on the reference input will be used to feed the controller.',...
  'Tag','StaticText1');
  H.Delayed_ref_input = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[1 1 1], ...
    'Enable',window_en, ...
  'ListboxTop',0, ...
  'Max',500, ...
  'Min',1, ...
  'Position',uipos.Delayed_ref_input, ...
  'Style','edit', ...
  'Tag','Nr', ...
   'Callback',['nncontrolutil(''nnmodref'',''check_params'',''Delayed_ref_input'', ''', get(H.Delayed_ref_input_text, 'String'),''');'], ...
   'ToolTipStr','Defines how many delays on the reference input will be used to feed the controller.',...
  'Value',1);
  H.Delayed_contr_output_text = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.8 0.8 0.8], ...
    'Enable',window_en, ...
   'HorizontalAlignment','right', ...
  'ListboxTop',0, ...
  'Position',uipos.Delayed_contr_output_text, ...
  'String','No. Delayed Controller Outputs', ...
  'Style','text', ...
   'ToolTipStr','Defines how many delays on the controller 0utput (same as plant input) will be used to feed the controller.',...
  'Tag','StaticText1');
  H.Delayed_contr_output = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[1 1 1], ...
    'Enable',window_en, ...
  'ListboxTop',0, ...
  'Max',500, ...
  'Min',1, ...
  'Position',uipos.Delayed_contr_output, ...
  'Style','edit', ...
  'Tag','Ni', ...
   'ToolTipStr','Defines how many delays on the controller output (same as plant input) will be used to feed the controller.',...
   'Callback',['nncontrolutil(''nnmodref'',''check_params'',''Delayed_contr_output'', ''', get(H.Delayed_contr_output_text, 'String'),''');'], ...
  'Value',1);
  H.Delayed_output_text = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.8 0.8 0.8], ...
    'Enable',window_en, ...
   'HorizontalAlignment','right', ...
  'ListboxTop',0, ...
  'Position',uipos.Delayed_output_text, ...
  'String','No. Delayed Plant Outputs', ...
  'Style','text', ...
   'ToolTipStr','Defines how many delays on the plant output will be used to feed the controller.',...
  'Tag','StaticText1');
  H.Delayed_output = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[1 1 1], ...
    'Enable',window_en, ...
  'ListboxTop',0, ...
  'Max',500, ...
  'Min',1, ...
  'Position',uipos.Delayed_output, ...
  'Style','edit', ...
  'Tag','Nj', ...
   'Callback',['nncontrolutil(''nnmodref'',''check_params'',''Delayed_output'', ''', get(H.Delayed_output_text, 'String'),''');'], ...
   'ToolTipStr','Defines how many delays on the plant output will be used to feed the controller.',...
  'Value',1);
  H.sam_training_c_text = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.8 0.8 0.8], ...
    'Enable',window_en, ...
   'HorizontalAlignment','right', ...
  'ListboxTop',0, ...
  'Position',uipos.sam_training_c_text, ...
  'String','Controller Training Samples', ...
  'Style','text', ...
   'ToolTipStr','Defines how many data points will be generated for training.',...
   'Tag','StaticText2');
H.sam_training_c_edit = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[1 1 1], ...
    'Enable',window_en, ...
  'ListboxTop',0, ...
  'Position',uipos.sam_training_c_edit, ...
  'Style','edit', ...
   'Callback',['nncontrolutil(''nnmodref'',''check_params'',''sam_training_c_edit'', ''', get(H.sam_training_c_text, 'String'),''');'], ...
   'ToolTipStr','Defines how many data points will be generated for training.',...
  'Tag','sam_training_c_edit');

  H.Use_Previous_Weights_but = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.8 0.8 0.8], ...
    'Enable',window_en, ...
  'ListboxTop',0, ...
  'Position',uipos.Use_Previous_Weights_but, ...
  'String','Use Current Weights', ...
  'Style','checkbox', ...
   'ToolTipStr','If selected, the current weights are used as initial values for continued training.',...
  'Tag','checkbox1');
  H.Normalize_data = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.8 0.8 0.8], ...
   'Enable','off', ...
  'ListboxTop',0, ...
  'Position',uipos.Normalize_data, ...
  'String','Normalize Training Data', ...
  'Style','checkbox', ...
  'Tag','checkbox2', ...
   'ToolTipStr','If selected, the reference model input-output data will be normalized.',...
  'Value',1);
  H.Train_con = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
  'Callback','nncontrolutil(''nnmodref'',''training_con'');', ...
  'Enable','off', ...
  'ListboxTop',0, ...
  'Position',uipos.Train_con, ...
  'String','Train Controller', ...
   'ToolTipStr','Train the controller using the parameters shown in this window.',...
   'Tag','Pushbutton1');
  H.Rep_Train_con = 0;
  H.Cont_Train_con = 0;
  H.Train_NN = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
  'Callback','nncontrolutil(''nnmodref'',''training'');', ...
    'Enable',window_en, ...
  'ListboxTop',0, ...
  'Position',uipos.Train_NN, ...
  'String','Plant Identification', ...
   'ToolTipStr','Opens a window where you can develop the neural network plant model.',...
  'Tag','Pushbutton1');
  H.OK_but = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
  'Callback','nncontrolutil(''nnmodref'',''ok'')', ...
  'Enable','off', ...
  'ListboxTop',0, ...
  'Position',uipos.OK_but, ...
  'String','OK', ...
   'ToolTipStr','Save the parameters into the neural network controller block and close this window.',...
  'Tag','OK_but');
  H.Cancel_but = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
  'Callback','nncontrolutil(''nnmodref'',''close'')', ...
  'ListboxTop',0, ...
  'Position',uipos.Cancel_but, ...
  'String','Cancel', ...
   'ToolTipStr','Discard the neural network controller parameters.',...
   'Tag','Pushbutton1');
  H.Apply_but = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
  'Callback','nncontrolutil(''nnmodref'',''apply'')', ...
  'Enable','off', ...
  'ListboxTop',0, ...
  'Position',uipos.Apply_but, ...
  'String','Apply', ...
   'ToolTipStr','Save the parameters into the neural network controller block.',...
  'Tag','Apply_but');
  H.error_messages = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
  'FontWeight','bold', ...
  'ForegroundColor',[0 0 1], ...
  'ListboxTop',0, ...
  'Position',uipos.error_messages, ...
  'Style','text', ...
  'ToolTipStr','Feedback line with important messages for the user.',...
  'Tag','StaticText1');

 H.Gen_data_but = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
  'Callback','nncontrolutil(''nnmodref'',''gen_data'')', ...
    'Enable',window_en, ...
  'ListboxTop',0, ...
  'Position',uipos.Gen_data_but, ...
  'String','Generate Training Data', ...
  'Tag','Pushbutton1', ...
  'TooltipString','Generate data to be used in training the neural network controller.');
 H.Get_data_file_but = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
  'Callback','nncontrolutil(''nndataimport'',''init'',gcbf,''ref'');',...
    'Enable',window_en, ...
  'ListboxTop',0, ...
  'Position',uipos.Get_data_file_but, ...
  'String','Import Data', ...
  'Tag','Pushbutton1', ...
   'TooltipString','Import training data from the workspace or from a file.');
 H.Save_to_file_but = uicontrol('Parent',fig, ...
  'Units',StdUnits, ...
  'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
  'Callback','nncontrolutil(''nndataexport'',''init'',gcbf,''ref'');',...
    'Enable',window_en, ...
  'ListboxTop',0, ...
  'Position',uipos.Save_to_file_but, ...
  'String','Export Data', ...
  'Tag','Pushbutton1', ...
   'TooltipString','Export training data to the workspace or to a file.');

 H.Training_done=0;
 H.Data_Generated=1;
 H.Data_Available=0;
 H.Data_Imported=0;

 % We create the menus for the block.
 H.Handles.Menus.File.Top= uimenu('Parent',fig, ...
   'Label','File');
 H.Handles.Menus.File.ImportModel = uimenu('Parent',...
   H.Handles.Menus.File.Top,...
   'Label','Import Network...',...
   'Accelerator','I',...
   'Callback','nncontrolutil(''nnimport'',''init'',gcbf,''nnmodref'',''nnmodref'');',...
    'Enable',window_en, ...
   'Tag','ImportModel');
 H.Handles.Menus.File.Export = uimenu('Parent',H.Handles.Menus.File.Top, ...
   'Label','Export Network...', ...
   'Accelerator','E', ...
   'Callback','nncontrolutil(''nnexport'',''init'',gcbf,''nnmodref'',''nnmodref'')', ...
    'Enable',window_en, ...
   'Tag','ExportMenu');
 H.Handles.Menus.File.Save_NN = uimenu('Parent',...
   H.Handles.Menus.File.Top,...
   'Label','Save',...
   'Separator','on', ...
   'Enable','off', ...
   'Accelerator','S',...
   'Callback','nncontrolutil(''nnmodref'',''apply'');',...
   'Tag','ImportModel');
 H.Handles.Menus.File.Save_Exit_NN = uimenu('Parent',...
   H.Handles.Menus.File.Top,...
   'Label','Save and Exit',...
   'Enable','off', ...
   'Accelerator','A',...
   'Callback','nncontrolutil(''nnmodref'',''ok'');',...
   'Tag','ImportModel');
 H.Handles.Menus.File.Close = uimenu('Parent',H.Handles.Menus.File.Top, ...
   'Callback','nncontrolutil(''nnmodref'',''close'',gcbf);', ...
   'Separator','on', ...
   'Label','Exit without saving', ...
   'Accelerator','X', ...
   'Tag','CloseMenu');

 H.Handles.Menus.Window.Top = uimenu(fig, 'Label', 'Window', ...
   'Callback', winmenu('callback'), 'Tag', 'winmenu');
 winmenu(fig);  % Initialize the submenu

 H.Handles.Menus.Help.Top = uimenu('Parent',fig, ...
   'Label','Help');
 H.Handles.Menus.Help.Main = uimenu('Parent',H.Handles.Menus.Help.Top, ...
   'Label','Main Help', ...
   'Callback','nncontrolutil(''nnmodrefhelp'',''main'');',...
   'Accelerator','H');
 H.Handles.Menus.Help.TrainContr = uimenu('Parent',H.Handles.Menus.Help.Top, ...
   'Label','Training Controller...', ...
   'Separator','on',...
   'CallBack','nncontrolutil(''nnmodrefhelp'',''train_contr'');');
 H.Handles.Menus.Help.PlantIdent = uimenu('Parent',H.Handles.Menus.Help.Top, ...
   'Label','Plant Identification...', ...
   'CallBack','nncontrolutil(''nnmodrefhelp'',''plant_ident'');');
 H.Handles.Menus.Help.Simulation = uimenu('Parent',H.Handles.Menus.Help.Top, ...
   'Label','Simulation...', ...
   'Separator','on',...
   'CallBack','nncontrolutil(''nnmodrefhelp'',''simulation'');');

  H.gcbh_ptr = uicontrol('Parent',fig,'visible','off');
  set(H.gcbh_ptr,'userdata',arg1);
  H.gcb_ptr = uicontrol('Parent',fig,'visible','off');
  set(H.gcb_ptr,'userdata',arg2);
  
  S1c=get_param(arg1,'S1c');                % S1c is ASCII
  if isempty(S1c)        % If the field is empty we initialize default value.
     S1c=num2str(0);
  else
     set(H.Hidden_layer_size,'string',S1c);     
  end
  H.S1c_ptr = uicontrol('Parent',fig,'visible','off');
  set(H.S1c_ptr,'userdata',str2num(S1c));     % S1c is saved as number
  
  Ts=get_param(arg1,'Ts'); 
  if isempty(Ts)        % If the field is empty we initialize default value.
     Ts=num2str(0);
  else
     set(H.Sampling_time,'string',Ts);
  end
  
  Ref_file=get_param(arg1,'Ref_file'); 
  if isempty(Ts)        % If the field is empty we initialize default value.
     Ref_file='';
  end
  set(H.reference_model,'string',Ref_file,'UserData',struct('FileName',Ref_file,'PathName',[]));
  H.Ref_file_ptr = uicontrol('Parent',fig,'visible','off');
  set(H.Ref_file_ptr,'userdata',Ref_file);
  
  Nrc=get_param(arg1,'Nrc'); 
  if isempty(Nrc)        % If the field is empty we initialize default value.
     Nrc=num2str(0);
  else
     set(H.Delayed_ref_input,'string',Nrc);
  end
  H.Nrc_ptr = uicontrol('Parent',fig,'visible','off');
  set(H.Nrc_ptr,'userdata',str2num(Nrc));
  
  Nic=get_param(arg1,'Nic'); 
  if isempty(Nic)        % If the field is empty we initialize default value.
     Nic=num2str(0);
  else
     set(H.Delayed_contr_output,'string',Nic);
  end
  H.Nic_ptr = uicontrol('Parent',fig,'visible','off');
  set(H.Nic_ptr,'userdata',str2num(Nic));
  
  Njc=get_param(arg1,'Njc'); 
  if isempty(Njc)        % If the field is empty we initialize default value.
     Njc=num2str(0);
  else
     set(H.Delayed_output,'string',Njc);
  end
  H.Njc_ptr = uicontrol('Parent',fig,'visible','off');
  set(H.Njc_ptr,'userdata',str2num(Njc));
  
  Use_Inc_training=get_param(arg1,'Use_Inc_training'); 
  if isempty(Use_Inc_training)        % If the field is empty we initialize default value.
     Use_Inc_training=num2str(0);
  end
  set(H.Use_Inc_training_but,'value',str2num(Use_Inc_training));
  H.Use_Inc_training_ptr = uicontrol('Parent',fig,'visible','off');
  set(H.Use_Inc_training_ptr,'userdata',str2num(Use_Inc_training));
  
  Use_Previous_Weights=get_param(arg1,'Use_Previous_Weights'); 
  if isempty(Use_Previous_Weights)        % If the field is empty we initialize default value.
     Use_Previous_Weights=num2str(1);
  end
  set(H.Use_Previous_Weights_but,'value',str2num(Use_Previous_Weights));
  H.Use_Previous_Weights_ptr = uicontrol('Parent',fig,'visible','off');
  set(H.Use_Previous_Weights_ptr,'userdata',str2num(Use_Previous_Weights));
  
  sam_training_c=get_param(arg1,'sam_training_c'); 
  if isempty(sam_training_c)        % If the field is empty we initialize default value.
     sam_training_c=num2str(0);
  else
     set(H.sam_training_c_edit,'string',sam_training_c);
  end
  H.sam_training_c_ptr = uicontrol('Parent',fig,'visible','off');
  set(H.sam_training_c_ptr,'userdata',str2num(sam_training_c));
  
  epochs_c=get_param(arg1,'epochs_c'); 
  if isempty(epochs_c)        % If the field is empty we initialize default value.
     epochs_c=num2str(0);
  else
     set(H.epochs_c_edit,'string',num2str(epochs_c));
  end
  H.epochs_c_ptr = uicontrol('Parent',fig,'visible','off');
  set(H.epochs_c_ptr,'userdata',str2num(epochs_c));
       
  retraining_c=get_param(arg1,'retraining_c'); 
  if isempty(retraining_c)        % If the field is empty we initialize default value.
     retraining_c=num2str(0);
  else
     set(H.retraining_c_edit,'string',num2str(retraining_c));
  end
  H.retraining_c_ptr = uicontrol('Parent',fig,'visible','off');
  set(H.retraining_c_ptr,'userdata',str2num(retraining_c));
       
  max_r=get_param(arg1,'max_r'); 
  if isempty(max_r)        % If the field is empty we initialize default value.
     max_r=num2str(0);
  else
     set(H.max_r_edit,'string',num2str(max_r));
  end
  H.max_r_ptr = uicontrol('Parent',fig,'visible','off');
  set(H.max_r_ptr,'userdata',str2num(max_r));
    
  min_r=get_param(arg1,'min_r'); 
  if isempty(min_r)        % If the field is empty we initialize default value.
     min_r=num2str(0);
  else
     set(H.min_r_edit,'string',num2str(min_r));
  end
  H.min_r_ptr = uicontrol('Parent',fig,'visible','off');
  set(H.min_r_ptr,'userdata',str2num(min_r));
    
  max_r_int=get_param(arg1,'max_r_int'); 
  if isempty(max_r_int)        % If the field is empty we initialize default value.
     max_r_int=num2str(0);
  else
     set(H.max_r_int_edit,'string',num2str(max_r_int));
  end
  H.max_r_int_ptr = uicontrol('Parent',fig,'visible','off');
  set(H.max_r_int_ptr,'userdata',str2num(max_r_int));
    
  min_r_int=get_param(arg1,'min_r_int'); 
  if isempty(min_r_int)        % If the field is empty we initialize default value.
     min_r_int=num2str(0);
  else
     set(H.min_r_int_edit,'string',num2str(min_r_int));
  end
  H.min_r_int_ptr = uicontrol('Parent',fig,'visible','off');
  set(H.min_r_int_ptr,'userdata',str2num(min_r_int));
    
  Normalize=str2num(get_param(arg1,'Normalize')); 
  if isempty(Normalize)        % If the field is empty we initialize default value.
     Normalize=0;
  end
  set(H.Normalize_data,'value',Normalize);
  
  % ODJ 1-13-00 Default values are assigned if the weight fields are empty.
  IW_r=eval(strvcat(get_param(arg1,'IW_r')),'0'); 
  H.IW_r_ptr = uicontrol('Parent',fig,'visible','off');
  set(H.IW_r_ptr,'userdata',IW_r);
    
  % ODJ 1-13-00 Default values are assigned if the weight fields are empty.
  IW_u=eval(strvcat(get_param(arg1,'IW_u')),'0'); 
  H.IW_u_ptr = uicontrol('Parent',fig,'visible','off');
  set(H.IW_u_ptr,'userdata',IW_u);
    
  % ODJ 1-13-00 Default values are assigned if the weight fields are empty.
  IW_y=eval(strvcat(get_param(arg1,'IW_y')),'0'); 
  H.IW_y_ptr = uicontrol('Parent',fig,'visible','off');
  set(H.IW_y_ptr,'userdata',IW_y);
    
  % ODJ 1-13-00 Default values are assigned if the weight fields are empty.
  LW_c=eval(strvcat(get_param(arg1,'LW_c')),'0'); 
  H.LW_c_ptr = uicontrol('Parent',fig,'visible','off');
  set(H.LW_c_ptr,'userdata',LW_c);
    
  % ODJ 1-13-00 Default values are assigned if the weight fields are empty.
  B1_c=eval(strvcat(get_param(arg1,'B1_c')),'0'); 
  H.B1_c_ptr = uicontrol('Parent',fig,'visible','off');
  set(H.B1_c_ptr,'userdata',B1_c);
    
  % ODJ 1-13-00 Default values are assigned if the weight fields are empty.
  B2_c=eval(strvcat(get_param(arg1,'B2_c')),'0'); 
  H.B2_c_ptr = uicontrol('Parent',fig,'visible','off');
  set(H.B2_c_ptr,'userdata',B2_c);
    
  set(fig,'userdata',H)
  
  if strcmp(arg3,'nnident')
     set(H.error_messages,'string',sprintf('Generate or import data before training the neural network controller.'));
  else
     set(H.error_messages,'string',sprintf('Perform plant identification before controller training.'));
  end
  
  elseif strcmp(cmd,'check_params')
      
      checkparam(arg1, H, arg2);

end

function present_error(fig,H,text_field,field_value,field_type,message)

if H.Data_Available
   set(H.Train_con,'enable','on'); 
end
if H.Training_done
   set(H.OK_but,'enable','on')
   set(H.Apply_but,'enable','on')
   set(H.Handles.Menus.File.Save_NN,'enable','on')
   set(H.Handles.Menus.File.Save_Exit_NN,'enable','on')
end
set(H.Cancel_but,'enable','on'); 
if text_field~=0
   if field_type      % Number
      set(text_field,'string',num2str(field_value));
   else               % ASCII or No change.
      set(text_field,'string',field_value);
   end
else
   text_field=0;
end   
set(H.error_messages,'string',message);
errordlg(message,'Model Reference Control Warning','modal');
set(fig,'pointer','arrow');


function paramok = checkparam(param2check, handles, paramlabel)

paramok = true; %set to true initially
paramH = getfield(handles, param2check);
paramval = str2num(get(paramH, 'String'));

try
    % Common Checks for all params
    message = 'Illegal value assigned to parameter';
    
    if ~sanitycheckparam(paramval)
        error('NNET:nnmodref:gui',message);
    end  
    
catch    
    message = sprintf('Illegal value assigned to ''%s'' parameter', paramlabel);
    errordlg(message,'Model Reference Control Warning','modal');
    paramok = false;
end



function paramok = sanitycheckparam(param)

if isempty(param) || iscell(param) ...
    || ~isscalar(param) || ~isnumeric(param) ...
        || ~isfinite(param) || ~isreal(param)        
    paramok = false;
    return;
end

paramok = true;




function uipos = getuipos

tlabelw = 25;
labelw = 33;
editw = 12;
border = 1.3333;
labelh = 1.5;
edith = 1.53846;


figw = 2* ((border*2) + labelw + editw + (2*border));
figh = 34.7179;

butwbig = (figw-(border*10))/3;
butwsmall = (figw-(border*8)-(2*butwbig))/3;
buth = 1.69231;

sunits = get(0, 'Units');
set (0, 'Units', 'character');
ssinchar = get(0, 'ScreenSize');
set (0, 'Units', sunits);

figl = (ssinchar(3) - figw) / 2;
figb = (ssinchar(4) - figh) / 2;

uipos.fig = [figl,figb,figw,figh];

framew = figw - (border*2);

uipos.frame4 = [border,0.205128,framew,2.25641];
uipos.frame5 = [border,2.66667,framew,6.87179];
uipos.frame1 = [border,10.5641,framew,11.7949];
uipos.frame6= [border,23.1795,framew,7.48718];

labell = (figw-tlabelw)/2;
uipos.h1_1 = [labell,8.5641,tlabelw,labelh];
uipos.h1_2 = [labell,21.3077,tlabelw,labelh];
uipos.h1_3 = [labell,29.6154,tlabelw,labelh];


uipos.Hidden_layer_text = [border*2,27.9026,labelw,labelh];
uipos.Sampling_text = [border*2,25.6462,labelw,labelh];
uipos.max_r_text = [border*2,19.8,labelw,labelh];
uipos.min_r_text = [border*2,17.5436,labelw,labelh];
uipos.max_r_int_text = [border*2,15.2872,labelw,labelh];
uipos.min_r_int_text = [border*2,13.0308,labelw,labelh];
uipos.epochs_c_text = [border*2,6.46667,labelw,labelh];
uipos.Normalize_data = [border*4,23.4923,labelw,labelh];


fc2l = border*2 + labelw + 1.5;
uipos.Hidden_layer_size = [fc2l,28.1026,editw,edith];
uipos.Sampling_time = [fc2l,25.8462,editw,edith];
uipos.max_r_edit = [fc2l,20,editw,edith];
uipos.min_r_edit= [fc2l,17.7436,editw,edith];
uipos.max_r_int_edit = [fc2l,15.4872,editw,edith];
uipos.min_r_int_edit = [fc2l,13.2308,editw,edith];
uipos.epochs_c_edit = [fc2l,6.66667,editw,edith];

scl = fc2l + editw + (border*2);
uipos.Delayed_ref_input_text = [scl,27.9026,labelw,labelh];
uipos.Delayed_contr_output_text = [scl,25.6462,labelw,labelh];
uipos.Delayed_output_text = [scl,23.3897,labelw,labelh];
uipos.sam_training_c_text = [scl,19.8,labelw,labelh];
uipos.reference_model_text = [scl,15.2872,labelw,labelh];
uipos.retraining_c_text= [scl,6.46667,labelw,labelh];


sc2l = scl + labelw + border;
uipos.Delayed_ref_input = [sc2l,28.1026,editw,edith];
uipos.Delayed_contr_output = [sc2l,25.8462,editw,edith];
uipos.Delayed_output = [sc2l,23.5897,editw,edith];
uipos.sam_training_c_edit = [sc2l,20,editw,edith];
uipos.retraining_c_edit = [sc2l,6.66667,editw,edith];
uipos.BrowseButton = [sc2l,15.4872,editw,edith];

uipos.reference_model = [scl,13.2308,labelw+editw+border,labelh];
uipos.Title_nnmodref = [(figw-framew)/2,31.5897,framew,2.23077];


uipos.Gen_data_but = [border*4,10.9487,butwbig,buth];
uipos.Get_data_file_but = [(figw-butwbig)/2,10.9487,butwbig,buth];
uipos.Save_to_file_but = [figw-(border*4)-butwbig,10.9487,butwbig,buth];

uipos.Use_Previous_Weights_but = [border*4,4.92308,labelw,edith];
uipos.Use_Inc_training_but = [figw-(border*4)-labelw,4.92308,labelw,edith];


uipos.Train_NN = [border*2,3.07692,butwbig,buth];
uipos.Train_con  = [uipos.Train_NN(1) + border + butwbig,3.07692,butwbig,buth];
uipos.OK_but = [uipos.Train_con(1) + border + butwbig,3.07692,butwsmall,buth];
uipos.Cancel_but = [uipos.OK_but(1) + border + butwsmall,3.07692,butwsmall,buth];
uipos.Apply_but = [uipos.Cancel_but(1) + border + butwsmall,3.07692,butwsmall,buth];

uipos.error_messages = [border+(0.3*border),0.307692,framew-(0.6*border),2.05128];


