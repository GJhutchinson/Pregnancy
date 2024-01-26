function [S_0,f_IVIM,D,Dstar] = fit_IVIM(b,S,mask)
%This function works by fitting low b-value data to a fast monoexponential
%decay, and high b-value data to a slow monoexponential decay to generate
%initial guesses of D and D*. These are then used in a final IVIM fit to
%determine fit values. 

%Inputs 
%b - b values s/mm^2
%S - image of size Y x X x Slices x b-values
%mask - mask of which voxels to fit, of size Y x X x Slices

%Outputs
%S_0 initial signal from IVIM fit
%f_IVIM - IVIM fraction
%D - Slow diffusion coefficient (mm^2/s)
%D* - Psuedodiffusion coefficient (mm^2/s)


S = double(S);
%Fit options
options = optimset('MaxFunEvals',1e6,'TolFun',1e-6,'MaxIter',1e6, 'Display', 'off');

idx = find(mask);
[y,x,slice_n] = ind2sub(size(mask),idx);

%Mono and bi-exponential functions for fitting data to
mono_exp = @(x,x_data) x(1).*exp(-x(2).*x_data);
bi_exp = @(x,x_data) x(1).*( (1-x(2)).*exp(-x(3).*x_data) + x(2).*exp(-x(4).*x_data));

%Cutoff for fast and slow b-value initial fits.
fast_b_cutoff = 128;
slow_b_cutoff = 200;

%fast fit - low bvalues
%[S0 D*]
lb_mono_fast = [0 0.025];
ub_mono_fast = [100000 1];
x0_mono_fast = [30000 0.2];

%Slow fit
%[S0 D*]
lb_mono_slow = [0 0];
ub_mono_slow = [100000 0.025];
x0_mono_slow = [30000 0.002];

%IVIM bounds; x0 depends on mono-exp fits
lb_bi_exp = [0 0 0 0.025];
ub_bi_exp = [45000 1 0.025 1];

IVIM = zeros([length(x),4]);

parfor n = 1:length(x)
    %Mono exp fits to provide estimates of D and D*
    mono_fast = lsqcurvefit(mono_exp,x0_mono_fast,b(b<=fast_b_cutoff),squeeze(S(y(n),x(n),slice_n(n),1:length(b(b<=fast_b_cutoff))))',lb_mono_fast,ub_mono_fast,options);
    mono_slow = lsqcurvefit(mono_exp,x0_mono_slow,b(b>=slow_b_cutoff),squeeze(S(y(n),x(n),slice_n(n),end-length(b(b>=slow_b_cutoff))+1:end))',lb_mono_slow,ub_mono_slow,options);
    
    %Bi exponential fit initial guesses depend on mono-exp fits
    %[S0 fIVIM D D*]
    x0_bi_exp = [mono_fast(1) 0.4 mono_slow(2) mono_fast(2)];
    IVIM(n,:) = lsqcurvefit(bi_exp,x0_bi_exp,b,squeeze(S(y(n),x(n),slice_n(n),:))',lb_bi_exp,ub_bi_exp,options);
end

%Repack into IVIM maps
f_IVIM = zeros(size(mask));
D = zeros(size(mask));
Dstar = zeros(size(mask));
S_0 = zeros(size(mask));

for n = 1:length(x)
    S_0(y(n),x(n),slice_n(n)) = IVIM(n,1); 
    f_IVIM(y(n),x(n),slice_n(n)) = IVIM(n,2);
    D(y(n),x(n),slice_n(n)) = IVIM(n,3);
    Dstar(y(n),x(n),slice_n(n)) = IVIM(n,4);
end


