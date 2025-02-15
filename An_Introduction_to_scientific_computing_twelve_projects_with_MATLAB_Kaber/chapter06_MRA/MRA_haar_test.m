%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%    An Introduction to Scientific Computing          %%%%%%%
%%%%%%%    I. Danaila, P. Joly, S. M. Kaber & M. Postel     %%%%%%%
%%%%%%%                 Springer, 2005                      %%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%   MRA: Multi Resolution Analysis
%%   Looking for the Haar wavelet
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
      clear all; close all;
%     MRA levels   
      nbni=10;
%     sampling points 
      nbp=MRA_pntniv(nbni);   
      fprintf('\n MRA levels  %d',nbni);
      fprintf('\n Sampling points   %d',nbp);
%     mean value interpolation                
      [ue,x]=MRA_pwcte(nbni);MRA_steps(x,ue);uo=zeros(1,nbp); 
%     recomposition by Haar wavelets
      is=-1;ur=uo;uo(20)=1.;
      [ur,uw]=MRA_haar(ur,uo,nbp,nbni,is);
%     plotting the signal 
      nf=10; figure(nf);fs=18;
      xm=[0.,1.];ym1=[-0.4,-0.4];ym2=[0.4,0.4];
      plot(x,ur,'b',xm,ym1,'white',xm,ym2,'white'); 
      title('Haar wavelet','FontSize',fs);
%     recomposition by Haar wavelets
      uo=zeros(1,nbp);
      is=-1;ur2=uo;uo(20)=1.;uo(24)=1.;
      [ur2,uw]=MRA_haar(ur2,uo,nbp,nbni,is);
      uo=zeros(1,nbp);
      is=-1;ur3=uo;uo(120)=1.;uo(124)=1.;
      [ur3,uw]=MRA_haar(ur3,uo,nbp,nbni,is);
%     plotting the signals 
      nf=11; figure(nf);fs=18;
      plot(x,ur2,'b',x,ur3,'r',xm,ym1,'white',xm,ym2,'white');
      title('Haar wavelets','FontSize',fs);