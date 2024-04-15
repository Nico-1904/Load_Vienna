function x = dBto(dB)
% converts dB to linear
%
% input:
%   dB: [] array of values in dB
%
% output:
%   x:  [] array of input dimension with linear values

x = 10.^(dB/10);

end

