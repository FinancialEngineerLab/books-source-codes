function output = FFT_Faltung(sig1, sig2)
% Die Funktion f�hrt eine schnelle Faltung mittels FFT aus
% Input:
% sig1 = Messsignal
% sig2 = Filter-Impulsantwort
% Output:
% output = gefiltertes Messignal
%--------------------------------------------------------------------------

% kopieren der Eingangsvektoren
sig1 = double(sig1(:));
sig2 = double(sig2(:));

% Faltungssatz sig(m) * h(n) = output(m+n-1):
outlength = length(sig1)+length(sig2)-1;
% n�chste Zweierpotenz f�r FFT
fftsize = 2^nextpow2(outlength);

% Messsignal
%mit Nullen auf fftsize auff�llen
sig1 = [sig1; zeros(fftsize-length(sig1),1)];
%Berechnung des Frequenzspektrums
sig1 = fft(sig1,fftsize);

% Filter - Impulsantwort
%mit Nullen auf fftsize auff�llen
sig2 = [sig2; zeros(fftsize-length(sig2),1)];
%Berechnung des Frequenzspektrums
sig2 = fft(sig2,fftsize);
 
% Faltung durch Multiplikation der Spektren
% R�cktransformation in den Zeitbereich
conv_raw = ifft(sig1.*sig2);

% R�ckgabe Ergebnis
output = transpose(conv_raw(1:outlength));