function [m,b,r] = postreg(a,t,hide)
%POSTREG Postprocesses the trained network response with a linear regression.
%  
%  Syntax
%
%    [m,b,r] = postreg(Y,T)
%    [m,b,r] = postreg(Y,T,X)
%
%  Description
%  
%    POSTREG postprocesses the network training
%    set by performing a linear regression between one element
%     of the network response and the corresponding target.
%  
%    POSTREG(Y,T) takes these inputs,
%      Y - 1xQ array of network outputs. One element of the network output.
%      T - 1xQ array of targets. One element of the target vector.
%    and returns and plots,
%      M - Slope of the linear regression.
%      B - Y intercept of the linear regression.
%      R - Regression R-value.  R=1 means perfect correlation.
%
%    POSTREG({Atrain,Avalidation,Atest},{Ttrain,Tvalidate,Ttest})
%    returns and plots,
%      M = {Mtrain,Mvalidation,Mtest}
%      B = {Btrain,Bvalidation,Btest}
%      R = {Rtrain,Rvalidation,Rtest}
%    Training values are required. Validation and test values are optional.
%
%    POSTREG(Y,T,'hide')
%    returns M, B, and R without creating a plot.
%  
%  Example
%
%    In this example we normalize a set of training data with
%     PRESTD, perform a principal component transformation on
%     the normalized data, create and train a network using the pca
%     data, simulate the network, unnormalize the output of the
%     network using POSTSTD, and perform a linear regression between 
%     the network outputs (unnormalized) and the targets to check the
%     quality of the network training.
%  
%       p = [-0.92 0.73 -0.47 0.74 0.29; -0.08 0.86 -0.67 -0.52 0.93];
%       t = [-0.08 3.4 -0.82 0.69 3.1];
%       [pn,pp1] = mapstd(p);
%       [tn,tp] = mapstd(t);
%       [ptrans,pp2] = processpca(pn,0.02);
%       net = newff(minmax(ptrans),[5 1],{'tansig' 'purelin'},'trainlm');
%       net = train(net,ptrans,tn);
%       an = sim(net,ptrans);
%       a = mapstd('reverse',an,tp);
%       [m,b,r] = postreg(a,t);
%
%  Algorithm
%
%     Performs a linear regression between the network response
%     and the target, and computes the correlation coefficient
%     (R value) between the network response and the target.
%
%  See also PREMNMX, PREPCA.

% Copyright 1992-2008 The MathWorks, Inc.
% $Revision: 1.1.6.7 $  $Date: 2008/03/13 17:33:19 $

show = nargin<3;
if isreal(a) && isreal(t)
  if any(size(a) ~= size(t)), error('NNET:Arguments','A and T must have the same dimensions'), end
  if (show), clf reset, end
  [tsort,line,m,b,r] = postreg1(a,t);
  if(show), plotreg1(a,t,tsort,line,m,b,r,'','r'); end
elseif iscell(a) && iscell(t)
  if any(size(a) ~= size(t)), error('NNET:Arguments','A and T must have the same dimensions'), end
  if size(a,1) ~= 1, error('NNET:Arguments','A and T cell arrays must only have a single row.'),end
  n = size(a,2);
  if (n<1) || (n>3), error('NNET:Arguments','A and T cell arrays must have 1, 2, or 3 elements.'),end
  for i=1:n
    if any(size(a{i})~=size(t{i})),error('NNET:Arguments','A{i} and T{i} must have the same dimensions.'),end
  end
  screenSize = get(0,'ScreenSize');
  windowWidth = (screenSize(3)-screenSize(1))*0.8;
  windowY = (screenSize(4)-screenSize(2)-windowWidth/2.5)/2+screenSize(2);
  windowX = (screenSize(3)-screenSize(1)-windowWidth)/2+screenSize(1);
  windowPos = [windowX windowY windowWidth windowWidth/2.5];
  if (show)
    clf reset
    set(gcf,'position',windowPos);
  end
  names = {'Training','Validation','Test'};
  colors ={'b' 'g' 'r'};
  m = cell(1,n);
  b = cell(1,n);
  r = cell(1,n);
  for i=1:n
    [tsort,line,m{i},b{i},r{i}] = postreg1(a{i},t{i});
    if (show)
      subplot(1,n,i)
      plotreg1(a{i},t{i},tsort,line,m{i},b{i},r{i},names{i},colors{i});
    end
  end
end
if show
   set(gcf,'menubar','none');
   set(gcf,'toolbar','none');
end

%==========================
function [tsort,line,m,b,r] = postreg1(a,t)

a = a(1,:);
t = t(1,:);

Q = length(a);

h = [t' ones(size(t'))];
at = a';
theta = h\at;
m = theta(1);
b = theta(2);

tsort = sort(t);
line = m*tsort + b;

an = a - mean(a);
tn = t - mean(t);
sta = std(an);
stt = std(tn);
r = an*tn'/(Q - 1);
if (sta~=0)&&(stt~=0)
  r = r/(sta*stt);
end

%==========================
function plotreg1(a,t,tsort,line,m,b,r,name,col)

%Q = length(a);
%v = axis;
%alpha1 = 0.05;
%alpha2 = 0.1;
%llx = alpha1*v(2) + (1-alpha1)*v(1);
%lly = (1-alpha2)*v(4) + alpha2*v(3);
%index = fix(Q/2);

a = a(1,:);
t = t(1,:);

cla reset
plot(t,a,'ok')
hold on
plot(tsort,line,col,'linewidth',2)
plot(tsort,tsort,':k')
xlabel('Targets T');
ylabel(['Outputs Y,  Linear Fit: Y=(',num2str(m,2),')T+(', num2str(b,2), ')']);
axis('square')
title([name ' Outputs vs. Targets, R=' num2str(r)]);
%text(llx,lly,['R = ', num2str(r,3)]);
%set(gca,'xlim',[0 1])
%set(gca,'ylim',[0 1])
legend([name ' Data Points'],'Best Linear Fit','Y = T',-1,'Location','NorthWest');
hold off
