function out = Butterworth_2d(im,d,n)
%// Your code with meshgrid fix
h=size(im,1);
w=size(im,2);
fftim = fftshift(fft2(double(im)));
[x y]=meshgrid(-floor(w/2):floor(w/2)-1,-floor(h/2):floor(h/2)-1);
%hhp=(1./(d./(x.^2+y.^2).^0.5).^(2*n));

%%%%%%// New code
B = sqrt(2) - 1; %// Define B
D = sqrt(x.^2 + y.^2); %// Define distance to centre
hhp = 1 ./ (1 + B * ((d ./ D).^(2 * n)));
out_spec_centre = fftim .* hhp;

%// Uncentre spectrum
out_spec = ifftshift(out_spec_centre);

%// Inverse FFT, get real components
out = real(ifft2(out_spec));
% figure;imagesc(out)
end