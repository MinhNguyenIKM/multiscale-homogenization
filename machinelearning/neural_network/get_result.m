clear all;
load A;
load bi;
load cn;
load d0;
load dn;
load w;
%sigmoid = @(X) 2 ./ (1 + exp(-2*X)) - 1 ;
a1 = (-1:0.1:1);
a2 = a1;
X = [a1; a2]';
%X2 = tramnmx(X,min(X)',max(X)');
L = length(A);
N = length(w{1});
for t = 1 : length(a1)
    x = X(t,:); 
    for i = 1 : L
        fNN(t,i) = 0;
        y = A{i} * x' + bi{i};
        for n = 1 : N
           fNN(t,i) = fNN(t,i) + cn{i}(n) * tansig(w{i}(n,:) * y + dn{i}(n)); 
        end
        fNN(t,i) = fNN(t,i) + d0{i};
    end
end


f = a1.^2 + a2.^2;
for i = 1 : size(fNN,1)
   fDD1D(i) = sum(fNN(i,:)); 
end

fDD1D = postmyself(fDD1D,0,2);
error = rms(f-fDD1D);
%f1 = 2*(f-min(f)) / (max(f)-min(f)) - 1;
%fres = 2*(fNN1D-min(fNN1D)) / (max(fNN1D)-min(fNN1D)) - 1;

% scatter3(a1,a2,fNN)

function t = postmyself(tn, mint, maxt)
    [R,Q]=size(tn);
    oneQ = ones(1,Q);
    t = (tn+1)/2;
    t = t.*((maxt-mint)*oneQ) + mint*oneQ;
end