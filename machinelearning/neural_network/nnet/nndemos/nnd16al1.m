function nnd16al1(cmd,arg1,arg2,arg3)
%NND16AL1 ART1 layer 1 demonstration.

% $Revision: 1.6.2.1 $
% Copyright 1994-2002 PWS Publishing Company and The MathWorks, Inc.
% First Version, 8-31-95.

%==================================================================

% GLOBALS
global p;
global bp;
global bn;
global W21;

% CONSTANTS
me = 'nnd16al1';
Fs = 8192;
W1p = eye(2);
W1n = ones(2)-eye(2);

% DEFAULTS
if nargin == 0, cmd = ''; else cmd = lower(cmd); end

% FIND WINDOW IF IT EXISTS
fig = nndfgflg(me);
if length(get(fig,'children')) == 0, fig = 0; end

% GET WINDOW DATA IF IT EXISTS
if fig
  H = get(fig,'userdata');
  fig_axis = H(1);         % window axis
  desc_text = H(2);        % handle to first line of text sequence
  big_axis = H(3);         % Big axis
  p1_on = H(4);
  p1_off = H(5);
  p2_on = H(6);
  p2_off = H(7);
  bp_bar = H(8);
  bp_text = H(9);
  bn_bar = H(10);
  bn_text = H(11);
  edit_w11 = H(12);
  edit_w21 = H(13);
  edit_w12 = H(14);
  edit_w22 = H(15);
  old_ptr = H(16);
  last_ptr = H(17);
  big_line = H(18);
end

%==================================================================
% Activate the window.
%
% ME() or ME('')
%==================================================================

if strcmp(cmd,'')
  if fig
    figure(fig)
    set(fig,'visible','on')
  else
    feval(me,'init')
  end

%==================================================================
% Close the window.
%
% ME() or ME('')
%==================================================================

elseif strcmp(cmd,'close') & (fig)
  delete(fig)

%==================================================================
% Initialize the window.
%
% ME('init')
%==================================================================

elseif strcmp(cmd,'init') & (~fig)

  % CONSTANTS
  p1 = 0;
  p2 = 1;
  bp = 1;
  bn = 1.5;
  W21 = [1 1; 0 1];
  p = [p1; p2];

  % NEW DEMO FIGURE
  fig = nndemof2(me,'DESIGN','ART1 Layer 1','','Chapter 16');

  set(fig, ...
    'windowbuttondownfcn',nncallbk(me,'down'), ...
    'BackingStore','off',...
    'nextplot','add');
  H = get(fig,'userdata');
  fig_axis = H(1);
  desc_text = H(2);

  % ICON
  nndicon(16,458,363,'shadow')

  % FIRST INPUT SLIDER
  x = 30;
  y = 130;
  text(x,y,'Input p(1):',...
    'color',nndkblue,...
    'fontw','bold',...
    'fontsize',12,...
    'horizontalalignment','left')
  p1_off = uicontrol(...
    'units','points',...
    'pos',[x+80 y-10 30 20],...
    'style','radio',...
    'string','0',...
    'back',nnltgray,...
    'value',1-p1,...
    'callback',[me '(''p1off'')']);
  p1_on = uicontrol(...
    'units','points',...
    'pos',[x+115 y-10 30 20],...
    'style','radio',...
    'string','1',...
    'back',nnltgray,...
    'value',p1,...
    'callback',[me '(''p1on'')']);

  % SECOND INPUT SLIDER
  x = 210;
  y = 130;
  text(x,y,'Input p(2):',...
    'color',nndkblue,...
    'fontw','bold',...
    'fontsize',12,...
    'horizontalalignment','left')
  p2_off = uicontrol(...
    'units','points',...
    'pos',[x+80 y-10 30 20],...
    'style','radio',...
    'string','0',...
    'back',nnltgray,...
    'value',1-p2,...
    'callback',[me '(''p2off'')']);
  p2_on = uicontrol(...
    'units','points',...
    'pos',[x+115 y-10 30 20],...
    'style','radio',...
    'string','1',...
    'back',nnltgray,...
    'value',p2,...
    'callback',[me '(''p2on'')']);

  % EXCITITORY BIAS SLIDER BAR
  x = 30;
  y = 100;
  len = 140;
  text(x,y,'Bias b+:',...
    'color',nndkblue,...
    'fontw','bold',...
    'fontsize',12,...
    'horizontalalignment','left')
  bp_text = text(x+len,y,sprintf('%3.1f',bp),...
    'color',nndkblue,...
    'fontw','bold',...
    'fontsize',12,...
    'horizontalalignment','right');
  text(x,y-36,'0.0',...
    'color',nndkblue,...
    'fontw','bold',...
    'fontsize',10,...
    'horizontalalignment','left')
  text(x+len,y-36,'3.0',...
    'color',nndkblue,...
    'fontw','bold',...
    'fontsize',10,...
    'horizontalalignment','right');
  bp_bar = uicontrol(...
    'units','points',...
    'position',[x y-25 len 16],...
    'style','slider',...
    'backg',nnltgray,...
    'callback',[me '(''bp'')'],...
    'min',0,...
    'max',3,...
    'value',bp);

  % INHIBITORY BIAS SLIDER BAR
  x = 30;
  y = 50;
  len = 140;
  text(x,y,'Bias b-:',...
    'color',nndkblue,...
    'fontw','bold',...
    'fontsize',12,...
    'horizontalalignment','left')
  bn_text = text(x+len,y,sprintf('%3.1f',bn),...
    'color',nndkblue,...
    'fontw','bold',...
    'fontsize',12,...
    'horizontalalignment','right');
  text(x,y-36,'0.0',...
    'color',nndkblue,...
    'fontw','bold',...
    'fontsize',10,...
    'horizontalalignment','left')
  text(x+len,y-36,'3.0',...
    'color',nndkblue,...
    'fontw','bold',...
    'fontsize',10,...
    'horizontalalignment','right');
  bn_bar = uicontrol(...
    'units','points',...
    'position',[x y-25 len 16],...
    'style','slider',...
    'backg',nnltgray,...
    'callback',[me '(''bn'')'],...
    'min',0,...
    'max',3,...
    'value',bn);

  % WEIGHTS
  x = 250;
  y = 25;
  bracket_x = [1 0 0 1]*10;
  bracket_y = [0 0 1 1]*10;
  text(x-5,y+35,'W2:1=','fontsize',16,...
    'fontweight','bold',...
    'color',nndkblue,...
    'horiz','right')
  plot(bracket_x+x,bracket_y*7+y,...
    'color',nndkblue,...
    'linewidth',3);
  plot(-bracket_x+x+100,bracket_y*7+y,'color',nndkblue,'linewidth',3);
  edit_w11 = uicontrol(...
    'units','points',...
    'style','edit',...
    'position',[x+10 y+40 35 20],...
    'string',num2str(W21(1,1)),...
    'callback',nncallbk(me,'w11'));
  edit_w12 = uicontrol(...
    'units','points',...
    'style','edit',...
    'position',[x+55 y+40 35 20],...
    'string',num2str(W21(1,2)),...
    'callback',nncallbk(me,'w12'));
  edit_w21 = uicontrol(...
    'units','points',...
    'style','edit',...
    'position',[x+10 y+10 35 20],...
    'string',num2str(W21(2,1)),...
    'callback',nncallbk(me,'w21'));
  edit_w22 = uicontrol(...
    'units','points',...
    'style','edit',...
    'position',[x+55 y+10 35 20],...
    'string',num2str(W21(2,2)),...
    'callback',nncallbk(me,'w22'));

  % BIG AXES
  big_axis = nnsfo('a1','Response','Time','Outputs n1(1), n1(2)');
  set(big_axis,...
    'position',[50 170 300 170],...
    'xlim',[-0.004 0.204],...
    'xtick',0:0.05:0.2,...
    'ylim',[-0.55 0.55],...
    'ytick',-0.5:0.25:0.5)
  big_line = plot([-0.004 0.204],[0 0],'--',...
    'color',nndkblue,...
    'CreateFcn','');

  % PLOT RESPONSE
  [T,Y] = ode45('nndalay1',[0 0.2],[0;0]);
  Y = Y';
  T = T';
  set(fig,'nextplot','add')
  last1 = plot(T,Y(1,:),...
    'color',nnred,...
    'linewidth',2,...
    'CreateFcn','');
  last2 = plot(T,Y(2,:),...
    'color',nngreen,...
    'linewidth',2,...
    'CreateFcn','');
  last = [last1; last2];

  % BUTTONS
  uicontrol(...
    'units','points',...
    'position',[410 150 60 20],...
    'string','Update',...
    'callback',[me '(''update'')'])
  uicontrol(...
    'units','points',...
    'position',[410 120 60 20],...
    'string','Clear',...
    'callback',[me '(''clear'')'])
  uicontrol(...
    'units','points',...
    'position',[410 90 60 20],...
    'string','Contents',...
    'callback','nndtoc')
  uicontrol(...
    'units','points',...
    'position',[410 60 60 20],...
    'string','Close',...
    'callback',[me '(''close'')'])

  % SAVE WINDOW DATA AND LOCK
  old_ptr = uicontrol('visible','off','userdata',[]);
  last_ptr = uicontrol('visible','off','userdata',last);

  H = [fig_axis, ...
       desc_text,...
       big_axis, ...
       p1_on p1_off p2_on p2_off, ...
       bp_bar bp_text bn_bar bn_text,...
       edit_w11 edit_w21 edit_w12 edit_w22,...
       old_ptr, last_ptr,...
       big_line];

  set(fig,'userdata',H,'nextplot','new')

  % INSTRUCTION TEXT
  feval(me,'instr');

  % LOCK WINDOW
  set(fig,...
   'nextplot','new',...
   'color',nnltgray);

  nnchkfs;

%==================================================================
% Display the instructions.
%
% ME('instr')
%==================================================================

elseif strcmp(cmd,'instr') & (fig)
  nnsettxt(desc_text,...
    'Adjust the inputs,',...
    'biases and weights,',...
    'then push [Update]',...
    'to see the layer',...
    'respond.',...
    '',...
    'n1(1) is red,',...
    'n1(2) is green.',...
    '',...
    'Click [Clear] to',...
    'remove old',...
    'responses.')
    
%==================================================================
% Clear input vectors.
%
% ME('clear')
%==================================================================

elseif strcmp(cmd,'clear') & (fig) & (nargin == 1)
  
  % GET DATA
  old = get(old_ptr,'userdata');
  last = get(last_ptr,'userdata');

  % REMOVE OLD
  set(old,'color',nnltyell);
  set(last(1),'color',nnred)
  set(last(2),'color',nngreen)
  set(big_line,'color',nndkblue);
  drawnow
  delete(old);

  % NEW LINE

  % SAVE DATA
  set(old_ptr,'userdata',[]);

%==================================================================
% Respond to p1 on.
%
% ME('p1on')
%==================================================================

elseif strcmp(cmd,'p1on')
  
  set(p1_off,'value',0)

%==================================================================
% Respond to p1 off.
%
% ME('p1off')
%==================================================================

elseif strcmp(cmd,'p1off')
  
  set(p1_on,'value',0)

%==================================================================
% Respond to p2 on.
%
% ME('p2on')
%==================================================================

elseif strcmp(cmd,'p2on')
  
  set(p2_off,'value',0)

%==================================================================
% Respond to p2 off.
%
% ME('p2off')
%==================================================================

elseif strcmp(cmd,'p2off')
  
  set(p2_on,'value',0)

%==================================================================
% Respond to upper bias slider.
%
% ME('bp')
%==================================================================

elseif strcmp(cmd,'bp')
  
  % GET DATA
  bp = get(bp_bar,'value');

  % UPDATE BAR
  set(bp_text,'string',sprintf('%3.1f',bp))

%==================================================================
% Respond to lower bias slider.
%
% ME('bn')
%==================================================================

elseif strcmp(cmd,'bn')
  
  % GET DATA
  bn = get(bn_bar,'value');

  % UPDATE BAR
  set(bn_text,'string',sprintf('%3.1f',bn))

%==================================================================
% Respond to weight value change.
%
% ME('w11')
%==================================================================

elseif strcmp(cmd,'w11')
  
  % GET DATA
  w11 = str2num(get(edit_w11,'string')) ~= 0;

  % UPDATE BAR
  set(edit_w11,'string',sprintf('%g',w11))

%==================================================================
% Respond to weight value change.
%
% ME('w12')
%==================================================================

elseif strcmp(cmd,'w12')
  
  % GET DATA
  w12 = str2num(get(edit_w12,'string')) ~= 0;

  % UPDATE BAR
  set(edit_w12,'string',sprintf('%g',w12))

%==================================================================
% Respond to weight value change.
%
% ME('w21')
%==================================================================

elseif strcmp(cmd,'w21')
  
  % GET DATA
  w21 = str2num(get(edit_w21,'string')) ~= 0;

  % UPDATE BAR
  set(edit_w21,'string',sprintf('%g',w21))

%==================================================================
% Respond to weight value change.
%
% ME('w22')
%==================================================================

elseif strcmp(cmd,'w22')
  
  % GET DATA
  w22 = str2num(get(edit_w22,'string')) ~= 0;

  % UPDATE BAR
  set(edit_w22,'string',sprintf('%g',w22))

%==================================================================
% Respond to time constant slider.
%
% ME('update')
%==================================================================

elseif strcmp(cmd,'update')

  % GET DATA
  p1 = get(p1_on,'value');
  p2 = get(p2_on,'value');
  bp = get(bp_bar,'value');
  bn = get(bn_bar,'value');
  W21 = [str2num(get(edit_w11,'string')),...
         str2num(get(edit_w12,'string'));
         str2num(get(edit_w21,'string')),...
         str2num(get(edit_w22,'string'))];
  old = get(old_ptr,'userdata');
  last = get(last_ptr,'userdata');
  p = [p1; p2];

  % MAKE LAST LINE OLD
  set(last,'color',nndkgray);
  old = [old last];
  if size(old,2) > 1
    gone = old(:,1);
    old(:,1) = [];
  else
    gone = [];
  end
  set(gone,'color',nnltyell);
  set(old,'color',nnltgray)
  drawnow
  delete(gone);

  % PLOT RESPONSE
  [T,Y] = ode45('nndalay1',[0 0.2],[0;0]);
  Y = Y';
  T = T';

  set(fig,'nextplot','add')
  axes(big_axis)

  ind = find(Y(1,:) < -0.55 | Y(1,:) > 0.55);
  if length(ind) == 0
    ind = length(T);
  else
    ind = ind(1)-1;
  end
  last1 = plot(T(1:ind),Y(1,1:ind),...
    'color',nnred,...
    'linewidth',2,...
    'CreateFcn','');

  ind = find(Y(2,:) < -0.55 | Y(2,:) > 0.55);
  if length(ind) == 0
    ind = length(T);
  else
    ind = ind(1)-1;
  end
  last2 = plot(T(1:ind),Y(2,1:ind),...
    'color',nngreen,...
    'linewidth',2,...
    'CreateFcn','');
  set(big_line,'color',nndkblue);
  last = [last1; last2];
  set(fig,'nextplot','new')

  % SAVE DATA
  set(old_ptr,'userdata',old);
  set(last_ptr,'userdata',last);

end

