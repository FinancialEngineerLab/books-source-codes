function[samp]=hammer(npt)
%
% This function returns the abscissas and weights of the 
% integration points for npt equal up to 7
%
%
samp=zeros(npt,3);
%
if npt==1
    samp=[1/3.  1/3.  1/2.];
elseif (npt==2 | npt==3)
    npt=3;
    samp=[1/6.  1/6.   1/6.; ...
          2/3   1./6   1/6.; ...
          1/6.  2./3.  1/6]; 
elseif (npt==4 | npt==5)
    npt=4;
    samp= [1/3    1/3   -27/96; ...
           1/5    1/5.   25/96;...
           3/5    1/5.   25/96;...
           1/5    3/5    25/96];
elseif npt==6
    a = 0.445948490915965;  b = 0.091576213509771;
    samp= [   a       a       0.111690794839005; ...
           1-2*a      a       0.111690794839005; ...
              a     1-2*a     0.111690794839005; ...
              b       b       0.054975871827661; ...
            1-2*b     b       0.054975871827661; ...
              b      1-2*b    0.054975871827661]; 
elseif npt==7
    a = (6+sqrt(15))/21 ; b = 4/7 -a;
    A = (155+sqrt(15))/2400; B = (31/240 -A);
samp= [   1/3       1/3       9/80; ...
           a        a         A   ; ...
          1-2*a     a         A   ; ...
           a      1-2*a       A   ; ...
           b        b         B   ; ...
         1-2*b      b         B   ; ...
           b      1-2*b       B]; 
end 
% 
% End function hammer