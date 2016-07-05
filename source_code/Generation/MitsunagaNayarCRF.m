function [lin_fun, pp] = MitsunagaNayarCRF(stack, stack_exposure, N, nSamples, sampling_strategy)
%
%       [lin_fun, pp] = MitsunagaNayarCRF(stack, stack_exposure, N, nSamples, sampling_strategy)
%
%       This function computes camera response function using Mitsunaga and
%       Nayar method.
%
%        Input:
%           -stack: a stack of LDR images. If the stack is a single or
%           double values are assumed to be in [0,1]
%           -stack_exposure: an array containg the exposure time of each
%           image. Time is expressed in second (s)
%           -N: polynomial degree of the inverse CRF
%           -nSamples: number of samples for computing the CRF
%           -sampling_strategy: how to select samples:
%               -'Grossberg': picking samples according to Grossberg and
%               Nayar algorithm (CDF based)
%               -'RandomSpatial': picking random samples in the image
%               -'RegularSpatial': picking regular samples in the image
%
%        Output:
%           -pp: a polynomial encoding the inverse CRF
%           -lin_fun: tabled CRF
%
%     Copyright (C) 2015-16  Francesco Banterle
% 
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <http://www.gnu.org/licenses/>.
%

if(~exist('nSamples', 'var'))
    nSamples = 256;
end

if(~exist('sampling_strategy', 'var'))
    sampling_strategy = 'RegularSpatial';
end

if(~exist('N', 'var'))
    N = -1;
end

if(isempty(stack))
    error('MitsunagaNayarCRF: a stack cannot be empty!');
end

if(isempty(stack_exposure))
    error('MitsunagaNayarCRF: a stack_exposure cannot be empty!');
end

col = size(stack, 3);

if(isa(stack, 'uint8'))
    stack = single(stack) / 255.0;
end

if(isa(stack, 'uint16'))
    stack = single(stack) / 65535.0;
end

%sorting exposures
[stack_exposure_sorted, ind] = sort(stack_exposure, 'ascend');

if(sum(abs(stack_exposure_sorted - stack_exposure)) > 0.0)
    stack_sorted = zeros(size(stack));
    for i=1:length(stack_exposure)
        stack_sorted(:,:,:,i) = stack(:,:,:,ind(i)); 
    end
    
    stack = stack_sorted;
    stack_exposure = stack_exposure_sorted;
        
    clear('stack_sorted');
    clear('stack_exposure_sorted');
end

stack_samples = LDRStackSubSampling(stack, stack_exposure, nSamples, sampling_strategy );

if(N > 0)
    [pp, ~] = MitsunagaNayarCRFClassic(stack_samples, stack_exposure, N);
else
    [pp, err] = MitsunagaNayarCRFClassic(stack_samples, stack_exposure, 2);
    
    for i=3:10
        [t_pp, t_err] = MitsunagaNayarCRFClassic(stack_samples, stack_exposure, i);
        if(t_err < err)
            err = t_err;
            pp = t_pp;
        end
    end
end

lin_fun = zeros(256, col);

gray = 0.5 * ones(1, col);
for c=1:col
    gray(c) = polyval(pp(:,c), gray(c));
end

scale = FindChromaticyScale([0.5, 0.5, 0.5], gray);

for c=1:col
    lin_fun(:,c) = scale(c) * polyval(pp(:,c), 0:(1.0 / 255.0):1);
end

end