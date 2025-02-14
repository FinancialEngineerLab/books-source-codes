C##############################################################
      PROGRAM PLOTP
C##############################################################
C     This code produces plots of grid, velocity vectors, and
C     profiles, contour lines and color fills for any quantity.
C     The output are postscript files for each page. The code
C     can easily be adapted for interactive use and screen window
C     output, but as this is to some extent hardware-dependent,
C     only postscript output is provided here. The same code
C     is used for both single-grid and multi-grid solutions. Array
C     dimensions NX and NY should be equal to or greater than
C     the maximum number of nodes in respective directions on
C     the finest grid. Up to 128 contours can be ploted. A zoom
C     factor (magnification) and the center point coordinates
C     can be specified. The plots are saved on files which 
C     carry the name + data set number, eg. VECT1.PS for the 
C     plot of velocity vectors from data set 1.
C
C     This is Version 1.3 of the code, August 1997, extended
C     to display turbulence quantities by Martin Schmid.
C
C     The user may modify the code and give it to third
C     parties, provided that an acknowledgement to the
C     source of the original version is retained.
C
C                     M. Peric, IfS, Hamburg, 1997
C                     Milovan.Peric@t-online.de
C=============================================================
      PARAMETER (NX=300,NY=300,NXY=NX*NY)
      COMMON /IPAR/ NI,NJ,NIM,NJM,NIJ,LI(NX),NPRX,NPRY,IAR,
     *       JAR,IEPRX(10),IEPRY(10)
      COMMON /RPAR/ XMIN,YMIN,XMAX,YMAX,XTOT,YTOT,XBOX,YBOX,
     *       XPAGE,YPAGE,AROMAX,SCFG,SCFV,
     *       XPRO(10),YPRO(10),CVAL(128),FI1,FI2
      COMMON /GEO/ X(NXY),Y(NXY),XC(NXY),YC(NXY),FI(NXY),
     *       CVX(20),CVY(20)
      COMMON /VEL/ U(NXY),V(NXY)
      DIMENSION P(NXY),T(NXY),TE(NXY),ED(NXY),PSI(NXY),F2(NXY)
      LOGICAL GRID,VEL,PRES,SF,TEMP,KINE,DISE,LPROF
      CHARACTER FILPOS*10,FILIN*10,FILREF*10,NAME*6,DSN*3
C
C==========================================================
C.....OPEN FILES
C==========================================================
C     Problem name must be that used in the calculation.
C     Input file contains control parameters (what to plot)
C     and must be prepared by the user in advance;
C     results file contains data written by the flow solver
C     (grid, variable values); file with reference data
C     contains profiles of some variables (from experiment or
C     other computations) which shall be plotted along with
C     profiles from result file. A dummy name should be given 
C     if no such data is used.     
C
      PRINT *, ' ENTER PROBLEM NAME (SIX CHARACTERS):  '
      READ(*,'(A6)') NAME
      PRINT *, ' ENTER NAME OF FILE WITH REF. DATA (UP TO 10 CHAR.):  '
      READ(*,'(A10)') FILREF
      OPEN (UNIT=2,FILE=FILREF)
      REWIND 2
C
      WRITE(FILIN,'(A6,4H.pin)') NAME
C
C==========================================================
C.....CHOOSE DATA SET TO PLOT (GRID NUMBER FOR STEADY FLOW)
C==========================================================
C
      DO LK=1,100
C
      PRINT *, ' ENTER DATA SET NUMBER:  '
      READ(*,*) ICOUNT
      IF(ICOUNT.EQ.0) GO TO 555
C
      IF(ICOUNT.LT.10) WRITE(DSN,'(I1,2H  )') ICOUNT
      IF(ICOUNT.GE.10.AND.ICOUNT.LT.100) WRITE(DSN,'(I2,1H )') ICOUNT
      IF(ICOUNT.GE.100) WRITE(DSN,'(I3)') ICOUNT
      WRITE(FILPOS,'(A6,1H.,A3)') NAME,DSN
      OPEN (UNIT=8,FILE=FILPOS,FORM='UNFORMATTED')
      REWIND 8
      OPEN (UNIT=1,FILE=FILIN)
      REWIND 1
C
C     Magnification factor FMAG is used to magnify the figure.
C     XOR and YOR are the coordinates (in physical space) of
C     the point which should be in the center of the plot. The
C     whole plot will be produced always, but if FMAG is large,
C     large portion of the figure will be off paper bounds and
C     will not be seen on printed figure. One can also play with
C     Bounding Box numbers in the PostScript file to adjust what
C     should be seen when a figure is included in text, e.g. using
C     'psfig' in LaTeX. Note that too large a magnification factor
C     may lead to resolution problems.
C 
      READ(1,*) FMAG
      XOR=0.
      YOR=0.
      IF(ABS(FMAG-1.0).GE.0.1) THEN
        READ(1,*) XOR,YOR
      ENDIF
C
C.....READ GRID DATA AND RESULTS FROM UNIT 8
C
      READ(8) ITIM,TIME,NI,NJ,NIM,NJM,NIJ,
     *        (X(IJ),IJ=1,NIJ),(Y(IJ),IJ=1,NIJ),
     *        (XC(IJ),IJ=1,NIJ),(YC(IJ),IJ=1,NIJ),
     *        (PSI(IJ),IJ=1,NIJ),(F2(IJ),IJ=1,NIJ),
     *        (U(IJ),IJ=1,NIJ),(V(IJ),IJ=1,NIJ),
     *        (P(IJ),IJ=1,NIJ),(T(IJ),IJ=1,NIJ)
     *       ,(TE(IJ),IJ=1,NIJ),(ED(IJ),IJ=1,NIJ)
      REWIND 8
      CLOSE(UNIT=8)
C
      DO I=1,NI
	LI(I)=(I-1)*NJ
      END DO
C
C==========================================================
C.....SOLUTION DOMAIN DIMENSIONS, SCALING FACTOR
C==========================================================
C     The solution domain is maped on an area 7 x 7 inches;
C     Postscript unit is a point (72 points in an inch), and
C     in order to enable accurate drawing on printers with
C     a resolution of 2400 x 2400 dot per inch, the coordinates
C     are scaled appropriately (7 x 2400 = 16800, thus 7 inches
C     are represented by 16800 dots; a scaling factor of 0.03
C     is used to convert dots of maximum printer resolution
C     to postscript units). XPAGE and YPAGE define the ploting
C     area of 7 x 7 inches.
C
      XMAX=-1.E20
      YMAX=-1.E20
      XMIN=1.E20
      YMIN=1.E20
      XPAGE=16800.
      YPAGE=16800.
C
      DO IJ=1,NIJ
	XMAX=MAX(XMAX,X(IJ))
	YMAX=MAX(YMAX,Y(IJ))
	XMIN=MIN(XMIN,X(IJ))
	YMIN=MIN(YMIN,Y(IJ))
      END DO
C
      XTOT=XMAX-XMIN
      YTOT=YMAX-YMIN
      SCFX=16800.0/XTOT
      SCFY=16800.0/YTOT
      SCFG=MIN(SCFX,SCFY)
      XTOT=XTOT*SCFG
      YTOT=YTOT*SCFG
C
C.....CALCULATE SHIFT IN COORDINATES IN CASE OF ZOOM
C
      IF(ABS(FMAG-1.0).LT.0.1) THEN
        XOR=0.5*(XMAX+XMIN)
        YOR=0.5*(YMAX+YMIN)
      ENDIF
      XOFFS=0.5*XTOT-(XOR-XMIN)*SCFG*FMAG
      YOFFS=0.5*YTOT-(YOR-XMIN)*SCFG*FMAG
C
C.....GRID COORDINATES AND CENTRAL POINTS COORINATES ON PLOTING PAGE
C
      DO IJ=1,NIJ
	XC(IJ)=(XC(IJ)-XMIN)*SCFG*FMAG+XOFFS
	YC(IJ)=(YC(IJ)-YMIN)*SCFG*FMAG+YOFFS
	X(IJ)=(X(IJ)-XMIN)*SCFG*FMAG+XOFFS
	Y(IJ)=(Y(IJ)-YMIN)*SCFG*FMAG+YOFFS
      END DO
C
      XMIN=0.
      YMIN=0.
      XMAX=XTOT*0.03
      YMAX=YTOT*0.03
C
C==========================================================
C.....CONTROL PARAMETERS AND FLUID PROPERTIES
C==========================================================
C     Logical variables GRID, VEL, PRES, TEMP, KINE, DISE and SF define
C     whether the grid, velocity vectors or profiles, pressure
C     contours or colour fill, temperature contours or
C     colour fill, turbulence kinetic energy contours or colour fill,
C     dissipation rate contours or colour fill, and streamlines or 
C     colour fill will be ploted. If one grid level is to be skiped, set all
C     set all these variables to FALSE. LPROF decides whether to plot the 
C     profils of all quantities except for pressure.
C
      READ(1,*) GRID,VEL,PRES,TEMP,KINE,DISE,SF
C
      IF(GRID.OR.VEL.OR.PRES.OR.TEMP.OR.KINE.OR.SF) THEN 
C
C     UIN and DENSIT are the reference velocity and density
C     used to scale pressure.
C
      READ(1,*) UIN,DENSIT
C
C     Every IARth vector in I-direction and JARth vector in 
C     J-direction will be ploted if VEL=TRUE; NPRX profiles
C     at constant X and NPRY profiles at constant Y will be
C     ploted; maximum velocity vector or profile width will
C     be AROMAX inches.
C
      READ(1,*) IAR,JAR,NPRX,NPRY,AROMAX
      AROMAX=AROMAX*2400.
C
C     XBOX and YBOX define the position of the bottom left corner
C     of the box which contains information about contours
C     (colour scale interpretation). The values are given in inches
C     relative to bottom left corner of the ploting area (e.g. if
C     the geometry is long in X and shorter in Y direction, there
C     is room within the 7 x 7 inches area for the info-box).
C
      READ(1,*) XBOX,YBOX
      XBOX=XBOX*2400.
      YBOX=YBOX*2400.
C
C     XPRO(I) are the coordinates X at which profiles of variables
C     are to be ploted. IEPRX(I) defines for which profile there is
C     comparison data (1 -> comparison data exists, 0 -> no data).
C     XPRO(I) is to be given in meters.
C
      IF(NPRX.NE.0) THEN
	READ(1,*) (XPRO(I),I=1,NPRX)
	READ(1,*) (IEPRX(I),I=1,NPRX)
	DO I=1,NPRX
	  XPRO(I)=XPRO(I)*SCFG
	END DO
      ENDIF
C
C     YPRO(I) are the coordinates Y at which profiles of variables
C     are to be ploted. IEPRY(I) defines for which profile there is
C     comparison data (1 -> comparison data exists, 0 -> no data).
C     YPRO(I) is to be given in meters.
C
      IF(NPRY.NE.0) THEN
	READ(1,*) (YPRO(J),J=1,NPRY)
	READ(1,*) (IEPRY(J),J=1,NPRY)
	DO J=1,NPRY
	  YPRO(J)=YPRO(J)*SCFG
	END DO
      ENDIF
C
      LPROF=(NPRX.GT.0.OR.NPRY.GT.0)
C
C======================================================
C.....plot the grid
C======================================================
C
      if(grid) then
	call bplot('grid',icount)
	call gridpl
	WRITE(7,*) 'p'
	CLOSE(UNIT=7)
      endif
c
C======================================================
c.....plot velocity vectors 
C======================================================
C     NCOL is the number of colours used for colouring
C     velocity vectors according to their magnitude; if
C     NCOL=1, black vectors are ploted.
C
      if(vel) then
	READ(1,*) NCOL
	call setcol(NCOL)
	call bplot('vect',icount)
	call velpl(NCOL)
	WRITE(7,*) 'p'
	CLOSE(UNIT=7)
C
C======================================================
C......PLOT VELOCITY PROFILES   
C======================================================
C
	if(lprof) then
	  scfv=1.
	  do ij=1,nij
	    fi(ij)=u(ij)
	  END DO
	  call profil('U-velocity     ','upro',icount)
C
	  do ij=1,nij
	    fi(ij)=v(ij)
	  END DO
	  call profil('V-velocity     ','vpro',icount)
	endif
C
      endif
c
C======================================================
C.....plot isobars
C======================================================
C     ICON defines how the contour values are defined:
C     if ICON=0, the values are read from input file,
C     otherwise they are calculated between maximum and
C     minimum value, see the routine CONT. NCON is the 
C     number of contours to be ploted. ICOL defines 
C     whether the contours are to be ploted in colour
C     or black (ICOL=0 -> black, otherwise colour).
C     IVEC and IGRID define whether the vector or/and
C     grid plot is to be overlayed over the colour fill
C     plot (0 -> no overlay, 1 -> yes).
C
      if(pres) then
	READ(1,*) icon,ncon,icol,ivec,igrid
	if (icon.eq.0) then
	  READ(1,*) (cval(i),i=1,ncon)
	endif
	scfv=1./(densit*uin**2)
	do ij=1,nij
	  fi(ij)=p(ij)*scfv
	END DO
C
	call bplot('isob',icount)
	call cont(icon,ncon,icol,nim,njm,'ISOBARS        ')
	WRITE(7,*) 'p'
	CLOSE(UNIT=7)
C
C======================================================
C.....PLOT PRESSURE COLOR FILL (IF ICOL.GT.0)
C======================================================
C
	if(icol.gt.0) then
	  call setcol(ncon)
	  call bplot('pres',icount)
	  call paint(ncon,nim,njm,'ISOBARS        ')
	  if(ivec.eq.1) call velpl(0)
	  if(igrid.eq.1) call gridpl
	  WRITE(7,*) 'p'
	  CLOSE(UNIT=7)
	endif
      endif
c
C======================================================
c.....plot temperature contours
C======================================================
C
      if(TEMP) then
	READ(1,*) icon,ncon,icol,ivec,igrid
	if(icon.eq.0) then
	  READ(1,*) (cval(i),i=1,ncon)
	endif
	do ij=1,nij
	  fi(ij)=t(ij)
	END DO
C
	call bplot('isot',icount)
	call cont(icon,ncon,icol,nim,njm,'ISOTHERMS      ')
	WRITE(7,*) 'p'
	CLOSE(UNIT=7)
C
C======================================================
C.....PLOT TEMPERATURE COLOR FILL
C======================================================
C
	if(icol.gt.0) then
	  call setcol(ncon)
	  call bplot('temp',icount)
	  call paint(ncon,nim,njm,'ISOTHERMS      ')
	  if(ivec.eq.1) call velpl(0)
	  if(igrid.eq.1) call gridpl
	  WRITE(7,*) 'p'
	  CLOSE(UNIT=7)
	endif
C
C======================================================
C.....PLOT TEMPERATURE PROFILES
C======================================================
C
	if(lprof) then
	  call profil('Temperature    ','tpro',icount)
	endif
      endif
C
C======================================================
c.....PLOT KINETIC ENERGY CONTOURS
C======================================================
C
      if(KINE) then
	READ(1,*) icon,ncon,icol,ivec,igrid
	if(icon.eq.0) then
	  READ(1,*) (cval(i),i=1,ncon)
	endif
	do ij=1,nij
	  fi(ij)=te(ij)
	END DO
C
	call bplot('isoe',icount)
	call cont(icon,ncon,icol,nim,njm,'TURB. KIN. ENERGY ')
	WRITE(7,*) 'p'
	CLOSE(UNIT=7)
C
C======================================================
C.....PLOT KINETIC ENERGY COLOR FILL
C======================================================
C
	if(icol.gt.0) then
	  call setcol(ncon)
	  call bplot('kine',icount)
	  call paint(ncon,nim,njm,'TURB. KIN. ENERGY   ')
	  if(ivec.eq.1) call velpl(0)
	  if(igrid.eq.1) call gridpl
	  WRITE(7,*) 'p'
	  CLOSE(UNIT=7)
	endif
C
C======================================================
C.....PLOT KINETIC ENERGY PROFILES
C======================================================
C
	if(lprof) then
	  call profil('Kinetic energy ','kpro',icount)
	endif
      endif
C======================================================
c.....PLOT ENERGY DISSIPATIN CONTOURS
C======================================================
C
      if(DISE) then
	READ(1,*) icon,ncon,icol,ivec,igrid
	if(icon.eq.0) then
	  READ(1,*) (cval(i),i=1,ncon)
	endif
	do ij=1,nij
	  fi(ij)=ed(ij)
	END DO
C
	call bplot('isod',icount)
	call cont(icon,ncon,icol,nim,njm,'ISODISSIPATION ')
	WRITE(7,*) 'p'
	CLOSE(UNIT=7)
C
C======================================================
C.....PLOT ENERGY DISSIPATION COLOR FILL
C======================================================
C
	if(icol.gt.0) then
	  call setcol(ncon)
	  call bplot('diss',icount)
	  call paint(ncon,nim,njm,'ISODISSIPATION ')
	  if(ivec.eq.1) call velpl(0)
	  if(igrid.eq.1) call gridpl
	  WRITE(7,*) 'p'
	  CLOSE(UNIT=7)
	endif
C
C======================================================
C.....PLOT ENERGY DISSIPATION PROFILES
C======================================================
C
	if(lprof) then
	  call profil('Energy dissipation ','dpro',icount)
	endif
      endif
C======================================================
c.....calculate stream function values
C======================================================
C     Streamfunction values are calculated at CV corners
C     using mass fluxes throufg cell faces (since the
C     mass flow rate between two streamlines is constant).
C     The value at the south-west corner is zero. Since
C     the contour and colour fill routines operate on
C     values at XC and YC, and PSI is calculated at 
C     locations defined by X and Y, the true XC and YC
C     are copied into P and T arrays and then overwritten
C     by X and Y.    
C
      IF(SF) THEN
	PSI(1)=0.
	DO I=1,NIM
	  II=LI(I)
	  IF(I.NE.1) PSI(II+1)=PSI(II-NJ+1)-F2(II+1)
	  DO J=2,NJM
	    IJ=II+J
	    PSI(IJ)=PSI(IJ-1)+PSI(IJ)
	  END DO
	END DO
C
C.....SET XC=X AND YC=Y FOR PSI-PLOTS
C
	do ij=1,nij
	  fi(ij)=psi(ij)
	  p(ij)=xc(ij)
	  t(ij)=yc(ij)
	  xc(ij)=x(ij)
	  yc(ij)=y(ij)
	END DO
c
C=================================================================
c.....READ CONTROL PARAMETERS AND CONTOUR LEVELS
C=================================================================
C     If ICON=0, contour levels are read from input file; otherwise
C     they are calculated below considering the minimum and 
C     maximum value at the interior and at boundaries.
C
	READ(1,*) icon,ncon,icol,ivec,igrid
	if(icon.eq.0) then
	  READ(1,*) (cval(i),i=1,ncon)
	else
C
c.....FIND MIN AND MAX VALUES OF PSI IN INTERIOR
c
	  psimax=-1.e20
	  psimin=1.e20
	  DO I=1,NIM
	  DO J=1,NJM
	    IJ=LI(I)+J
	    IF(FI(IJ).GT.PSIMAX) THEN
	      XPSMAX=XC(IJ)
	      YPSMAX=YC(IJ)
	      psimax=fi(ij)
	    ENDIF
	    IF(FI(IJ).LT.PSIMIN) THEN
	      psimin=fi(ij)
	      XPSMIN=XC(IJ)
	      YPSMIN=YC(IJ)
	    ENDIF
	  END DO
	  END DO
	  write(*,*) 'psimin = ',psimin,' , X = ',XPSMIN/SCFG,
     *                ' , Y = ',YPSMIN/SCFG
	  write(*,*) 'PSIMAX = ',PSIMAX,' , X = ',XPSMAX/SCFG,
     *                ' , Y = ',YPSMAX/SCFG
C
C.....FIND MIN AND MAX VALUES OF PSI AT BOUNDARY
C
	  PSBMIN= 1.E20
	  PSBMAX=-1.E20
	  DO I=1,NIM
	    IJ=LI(I)+1
	    PSBMIN=MIN(PSBMIN,FI(IJ))
	    PSBMAX=MAX(PSBMAX,FI(IJ))
	    IJ=LI(I)+NJM
	    PSBMIN=MIN(PSBMIN,FI(IJ))
	    PSBMAX=MAX(PSBMAX,FI(IJ))
	  END DO
C
	  DO J=1,NJM
	    IJ=LI(1)+J
	    PSBMIN=MIN(PSBMIN,FI(IJ))
	    PSBMAX=MAX(PSBMAX,FI(IJ))
	    IJ=LI(NIM)+J
	    PSBMIN=MIN(PSBMIN,FI(IJ))
	    PSBMAX=MAX(PSBMAX,FI(IJ))
	  END DO
	  write(*,*) 'psbmin = ',psbmin,' , psbmax = ',psbmax
C
C=================================================================
C.....RANGES OF PSI VALUES, SET NO. OF CONTOURS IN RECIRC. REGIONS
C=================================================================
C     NCMIN contours are defined between the minimum value of PSI
C     at boundary and in the interior; it is chosen as a fraction
C     of NCON, depending on how big is the range DPSMIN.
C   
	  DELPSB=PSBMAX-PSBMIN
	  DPSMIN=PSBMIN-PSIMIN
	  DPSMAX=PSIMAX-PSBMAX
C
	  DM1=MAX(DELPSB,DPSMAX)
	  IF(DPSMIN.LT.0.01*DM1) THEN
	    NCMIN=0
	  ELSEIF(DPSMIN.GE.0.01*DM1.AND.DPSMIN.LT.0.05*DM1) THEN
	    NCMIN=NCON/4
	  ELSEIF(DPSMIN.GE.0.05*DM1.AND.DPSMIN.LT.0.1*DM1) THEN
	    NCMIN=NCON/3
	  ELSEIF(DPSMIN.GE.0.1*DM1.AND.DPSMIN.LT.0.5*DM1) THEN
	    NCMIN=NCON/2
	  ELSE
	    NCMIN=NCON
	  ENDIF
C
C     NCMAX contours are defined between the maximum value of PSI
C     at boundary and in the interior; it is chosen as a fraction
C     of NCON, depending on how big is the range DPSMAX.
C   
	  DM1=MAX(DELPSB,DPSMIN)
	  IF(DPSMAX.LT.0.01*DM1) THEN
	    NCMAX=0
	  ELSEIF(DPSMAX.GE.0.01*DM1.AND.DPSMAX.LT.0.05*DM1) THEN
	    NCMAX=NCON/4
	  ELSEIF(DPSMAX.GE.0.05*DM1.AND.DPSMAX.LT.0.1*DM1) THEN
	    NCMAX=NCON/3
	  ELSEIF(DPSMAX.GE.0.1*DM1.AND.DPSMAX.LT.0.5*DM1) THEN
	    NCMAX=NCON/2
	  ELSE
	    NCMAX=NCON
	  ENDIF
C
c.....SET STREAMFUNCTION CONTOUR LEVELS
c
	  LC=0
	  DPSI=DPSMIN/REAL(NCMIN+1)    
	  DO L=1,NCMIN
	    lc=lc+1
	    cval(lc)=psimin+DPSI*real(l)
	  END DO 
	  lc=lc+1
	  cval(lc)=PSBMIN+1.E-20
C
C     Boundary values are defined as contour lines. If
C     the difference between maximum and minimum values at 
C     boundary is small compared to the full range, no
C     contour values are set between these two values;
C     otherwise, NCON values are defined.
C
	  IF(DELPSB.GT.0.1*(DPSMIN+DPSMAX)) THEN
	    DPSI=DELPSB/REAL(NCON+1)
	    DO L=1,NCON
	      lc=lc+1
	      cval(lc)=PSBMIN+DPSI*real(l)
	    END DO
C
	    LC=LC+1
	    CVAL(LC)=PSBMAX-1.E-20
	  ENDIF
C
	  DPSI=DPSMAX/REAL(NCMAX+1)
	  DO L=1,NCMAX
	    LC=LC+1
	    CVAL(LC)=PSBMAX+DPSI*REAL(L)
	  END DO
C
	  icon=0
	  ncon=lc
	endif
C
C======================================================
C.....PLOT STREAMLINES
C======================================================
C
	call bplot('strl',icount)
	call cont(icon,ncon,icol,nim-1,njm-1,'STREAMLINES     ')
	WRITE(7,*) 'p'
	CLOSE(UNIT=7)
C
C======================================================
C.....PLOT STREAMLINE COLOR FILL
C======================================================
C
	if(icol.gt.0) then
	  call setcol(ncon)
	  call bplot('strc',icount) 
	  call paint(ncon,nim-1,njm-1,'STREAMLINES     ')
	  if(ivec.eq.1) then
	    icol=1
	    do ij=1,nij
	      xc(ij)=p(ij)
	      yc(ij)=t(ij)
	    end do
	    call velpl(0)
	  endif
	  if(igrid.eq.1) call gridpl
	  WRITE(7,*) 'p'
	  CLOSE(UNIT=7)
	endif
      endif
C
      ENDIF
C
C============================================================
C.....END OF OPERATIONS ON THIS DATA SET
C============================================================
C
      CLOSE(UNIT=1)
      END DO
C
  555 CONTINUE
C
      STOP
      END
C
C
C##################################################################
      SUBROUTINE VELPL(NCOL)
C##################################################################
C     This routine plots velocity vectors (every IARth and JARth
C     value in I and J direction, respectively). Colour is defined
C     by RGB values, which range between 0. and 1. for each of 
C     the three base colours. The appropriate values for R, G and B
C     are calculated in the routine SETRGB.
C==================================================================
      PARAMETER (nx=300,NY=300,NXY=NX*NY)
      COMMON /IPAR/ NI,NJ,NIM,NJM,NIJ,LI(NX),NPRX,NPRY,IAR,
     *       JAR,IEPRX(10),IEPRY(10)
      COMMON /RPAR/ XMIN,YMIN,XMAX,YMAX,XTOT,YTOT,XBOX,YBOX,
     *       XPAGE,YPAGE,AROMAX,SCFG,SCFV,
     *       XPRO(10),YPRO(10),CVAL(128),FI1,FI2
      COMMON /GEO/ X(NXY),Y(NXY),XC(NXY),YC(NXY),FI(NXY),
     *       CVX(20),CVY(20)
      COMMON /VEL/ U(NXY),V(NXY)
      COMMON /RGB/ R(255),G(255),B(255)
      CHARACTER TT*17
c
c.....calculate scaling factor for velocities (max. value = aromax)
c
      vmax=-1.0e10
      vmin=1.e10
      do ij=1,nij
	vmean=sqrt(u(ij)**2+v(ij)**2)
	vmin=min(vmin,vmean)
	vmax=max(vmax,vmean)
      end do
      scf=aromax/(vmax+1.e-15)
c
c.....Set colour levels (for NCOL=1, black is used)
c
      delv=(vmax-vmin)/max(real(ncol),1.)
      do n=1,ncol+1
	cval(n)=vmin+real(n-1)*delv
      end do
      WRITE(7,*) '20 w'
      IF(NCOL.EQ.1) WRITE(7,*) '0. 0. 0. col'
c
C=======================================================
c.....Plot vectors at each  IAR-th and JAR-th position
C=======================================================
c
      do i=2,nim,iar
      do j=2,njm,jar
	ij=li(i)+j
	x1=u(ij)*scf+xc(ij)
	y1=v(ij)*scf+yc(ij)
c
C.....Assign colour according to velocity vector magnitude
C
	vm=sqrt(u(ij)**2+v(ij)**2)
	if(ncol.gt.1) then
	  do n=2,ncol+1
	    if(vm.le.cval(n).and.vm.ge.cval(n-1)) THEN
	      WRITE(7,*) R(N-1),G(N-1),B(N-1),' col'
	    ENDIF
	  end do
	endif
C
C....Draw the arrow
C 
	call arrow(xc(ij),yc(ij),x1,y1)
      end do
      end do
c
C=======================================================
c.....write title and vector scale to postscript file
C=======================================================
c
      write(7,*) '0. 0. 0. col'
      tsize=600.
      x1=0.35*xtot
      y1=ytot+3.*tsize
      x2=x1+aromax
      y2=y1
      call arrow(x1,y1,x2,y2)
      x2=x2+tsize
      y2=y2-0.5*tsize
      write(7,*) int(x2),int(y2),'  m'
      write(7,*) '/Times-Roman findfont 500.00 scalefont setfont'
      write(tt,'(4h =  ,1pe8.2,5h m/s )') vmax
      write(7,*) '(',tt,') show'
      y1=y1+2.*tsize
      write(7,*) int(x1),int(y1),'  m'
      write(7,*) '/Helvetica findfont 600.00 scalefont setfont'
      write(tt,'(17hVelocity  Vectors)')
      write(7,*) '(',tt,') show s'
C
      RETURN
      END
C
C##################################################
      SUBROUTINE SETCOL(NCOL)
C##################################################
C     This routine sets the values of R, G, and B
C     composition of the colour table. NCOL values
C     are set so that the range of values from MAX
C     to MIN corresponds to the colour scale from
C     pink to deep blue.
C==================================================
      COMMON /RGB/ R(255),G(255),B(255)
      DIMENSION RT(255),GT(255),BT(255)
C
      IF(NCOL.LT.5) RETURN
C
C----------------------------------
C.....FIVE RANGES IN SPECTRUM
C----------------------------------
      NDC=NCOL/5
      DC=1./REAL(NDC)
C----------------------------------
C.....RANGE 1: PINK TO RED
C----------------------------------
      DO L=1,NDC
	RT(L)=1.
	GT(L)=0.
	BT(L)=1.-(L-1)*DC
      END DO
      NL=NDC
C----------------------------------
C.....RANGE 2: RED TO YELLOW
C----------------------------------
      DO L=1,NDC
	RT(NL+L)=1.
	GT(NL+L)=(L-1)*DC
	BT(NL+L)=0.
      END DO
      NL=NL+NDC
C----------------------------------
C.....RANGE 3: YELLOW TO GREEN
C----------------------------------
      DO L=1,NDC
	RT(NL+L)=1.-(L-1)*DC
	GT(NL+L)=1.
	BT(NL+L)=0.
      END DO
      NL=NL+NDC
C----------------------------------
C.....RANGE 4: GREEN TO LIGHT BLUE
C----------------------------------
      DO L=1,NDC
	RT(NL+L)=0.
	GT(NL+L)=1.
	BT(NL+L)=(L-1)*DC
      END DO
      NL=NL+NDC
C
      NDC=NCOL-4*NDC
      DC=1./REAL(NDC)
C-------------------------------------
C.....RANGE 5: LIGHT BLUE TO DARK BLUE
C-------------------------------------
      DO L=1,NDC
	RT(NL+L)=0.
	GT(NL+L)=1.-(L-1)*DC
	BT(NL+L)=1.
      END DO
C
C.....SWAP THE ORDERING: DARK BLUE TO BE MINIMUM
C
      DO L=1,NCOL
	LL=NCOL-L+1
	R(L)=RT(LL)
	G(L)=GT(LL)
	B(L)=BT(LL)
      END DO
C
      RETURN
      END
C
C#####################################################################
      SUBROUTINE PROFIL(TITLE,FILN,LK)
C#####################################################################
C     This routine draws profiles of the variable FI at given X and
C     Y cross-sections. The cross-sections are defined in input data
C     as XPRO(I) and YPRO(I); ten profiles can be ploted. Calculated
C     profiles can ce compared to reference data (e.g. from an
C     experiment). Reference data should be stored on a file in a
C     format given below (up to 100 points per profile; increase
C     dimension if necessary).
C=====================================================================
      PARAMETER (nx=300,NY=300,NXY=NX*NY)
      COMMON /IPAR/ NI,NJ,NIM,NJM,NIJ,LI(NX),NPRX,NPRY,IAR,
     *       JAR,IEPRX(10),IEPRY(10)
      COMMON /RPAR/ XMIN,YMIN,XMAX,YMAX,XTOT,YTOT,XBOX,YBOX,
     *       XPAGE,YPAGE,AROMAX,SCFG,SCFV,
     *       XPRO(10),YPRO(10),CVAL(128),FI1,FI2
      COMMON /GEO/ X(NXY),Y(NXY),XC(NXY),YC(NXY),FI(NXY),
     *       CVX(20),CVY(20)
      COMMON /PRO/ XP(2),YP(2)
      COMMON /RGB/ R(255),G(255),B(255)
      DIMENSION YPR(100),FIPR(100),XPR(100)
      CHARACTER TITLE*15,TT*17,FILN*4
C
C.....CALCULATE SCALING FACTOR, SCALE VARIABLE (accorning to AROMAX)
C
      FIMAX=0.0
      DO IJ=1,NIJ
	PC=ABS(FI(IJ))
	FIMAX=MAX(FIMAX,PC)
      END DO
      SCF=AROMAX/(FIMAX+1.E-20)
      DO IJ=1,NIJ
	FI(IJ)=SCF*FI(IJ)
      END DO
C
C===============================================================
C.....PROFILES AT GIVEN  X - COORDINATE
C===============================================================
C     We consider quadrilateral elements, made by CV centers;
C     if the line X=XINT crosses two sides of such an element,
C     a segment of the profile between the two crossing points
C     is obtained (since nodes are connected by straight lines
C     and linear interpolation is used, the same crossing points
C     will be found in neighbor elements, so the profile will be
C     continuous). The variable values at the crossing points
C     are obtained by interpolation from two corner nodes. The
C     profile line is thick, the base line is thin.
C
      IF(NPRX.NE.0) THEN
	CALL BPLOT(FILN,LK)
C
	DO K=1,NPRX
	  XINT=XPRO(K)
	  DO I=1,NIM
	  DO J=1,NJM
	    IJ=LI(I)+J
	    CALL PROFX(IJ,IP,XINT)
C
C     IP is the number of crossing points; it has to be two if the
C     line crosses the element. 
C
	    IF(IP.EQ.2) THEN
	      WRITE(7,*) '40 w ',INT(XINT+XP(1)),INT(YP(1)),' m ',
     *                    INT(XINT+XP(2)),INT(YP(2)),' l s'
	      WRITE(7,*) '20 w ',INT(XINT),INT(YP(1)),' m ',
     *                    INT(XINT),INT(YP(2)),' l s'
	    ENDIF
	  END DO
	  END DO
C
C------------------------------------------------------------
C.....COMPARISON WITH REFERENCE DATA
C------------------------------------------------------------
C     Reference data for each profile for which IEPRX=1 should
C     be provided on a file in the following format:
C     The first line is the number of reference points, KPR. It
C     can be zero, so one does not have to have data for each
C     variable at all cross-sections.
C     There follow KPR lines with the Y-coordinate of the reference
C     point and the variable value at that point, FIPR. A diamond
C     symbol is ploted at each point.
C
	  IF(IEPRX(K).NE.0) THEN
	  WRITE(7,*) '32 w'
	  READ(2,*) KPR
	  IF(KPR.NE.0) THEN
	    DO KK=1,KPR
	      READ(2,*) YPR(KK),FIPR(KK)
	    END DO
C
	    DO KK=1,KPR
	      YPR(KK)=YPR(KK)*SCFG
	      FIPR(KK)=XINT+FIPR(KK)*SCF*SCFV
	      WRITE(7,*) int(FIPR(KK)-200.),int(YPR(KK)),' m'
	      WRITE(7,*) int(FIPR(KK)),int(YPR(KK)-200.),' l'
	      WRITE(7,*) int(FIPR(KK)+200.),int(YPR(KK)),' l'
	      WRITE(7,*) int(FIPR(KK)),int(YPR(KK)+200.),' l'
	      WRITE(7,*) int(FIPR(KK)-200.),int(YPR(KK)),' l s'
	    END DO
	  ENDIF
	  ENDIF
	END DO
C
C------------------------------------------------------------
C.....WRITE THE TITLE AND PROFILE SCALE
C------------------------------------------------------------
C
      write(7,*) '0. 0. 0. col'
      TSIZE=600.
      x1=0.35*xtot
      y1=ytot+2.*TSIZE
      x2=x1+aromax
      y2=y1
      write(7,*) x1,y1,' m ',x2,y2,' l s'
      x2=x2+tsize
      y2=y2-0.5*tsize
      write(7,*) '/Helvetica findfont 660.00 scalefont setfont'
      write(7,*) int(x2),int(y2),'  m'
      write(tt,'(5h  =  ,1pe8.2,4h m/s)') fimax
      write(7,*) '(',tt,') show'
      y1=y1+2.*tsize
      write(7,*) int(x1),int(y1),'  m'
      write(7,*) '(',title,') show'
      WRITE(7,*) 's p'
      CLOSE(UNIT=7)
C
      ENDIF
C
C===============================================================
C.....PROFILES AT SPECIFIED Y-CROSS-SECTION
C===============================================================
C
      IF(NPRY.NE.0) THEN
	CALL BPLOT(FILN,LK)
C
	DO K=1,NPRY
	  YINT=YPRO(K)
	  DO I=1,NIM
	  DO J=1,NJM
	    IJ=LI(I)+J
	    CALL PROFY(IJ,IP,YINT)
C
	    IF(IP.EQ.2) THEN
	      WRITE(7,*) '40 w ',INT(XP(1)),INT(YINT+YP(1)),' m ',
     *                    INT(XP(2)),INT(YINT+YP(2)),' l s'
	      WRITE(7,*) '20 w ',INT(XP(1)),INT(YINT),' m ',
     *                    INT(XP(2)),INT(YINT),' l s'
	    ENDIF
	  END DO
	  END DO
C
C.....COMPARISON WITH REFERENCE DATA
C
	  IF(IEPRY(K).NE.0) THEN
	  WRITE(7,*) '32 w'
	  READ(2,*) KPR
	  IF(KPR.NE.0) THEN
	    READ(2,*) (XPR(KK),KK=1,KPR)
	    READ(2,*) (FIPR(KK),KK=1,KPR)
	    DO KK=1,KPR
	      XPR(KK)=XPR(KK)*SCFG
	      FIPR(KK)=XINT+FIPR(KK)*SCF*SCFV
	      WRITE(7,*) int(XPR(KK)),int(FIPR(KK)-200.),' m'
	      WRITE(7,*) int(XPR(KK)-200.),int(FIPR(KK)),' l'
	      WRITE(7,*) int(XPR(KK)),int(FIPR(KK)+200.),' l'
	      WRITE(7,*) int(XPR(KK)+200.),int(FIPR(KK)),' l'
	      WRITE(7,*) int(XPR(KK)),int(FIPR(KK)-200.),' l s'
	    END DO
	  ENDIF
	  ENDIF
	END DO
C
C.....WRITE THE TITLE AND PROFILE SCALE
C
      write(7,*) '0. 0. 0. col'
      x1=0.35*xtot
      y1=ytot+2.*tsize
      x2=x1+aromax
      y2=y1
      write(7,*) x1,y1,' m ',x2,y2,' l s'
      x2=x2+tsize
      y2=y2-0.5*tsize
      write(7,*) '/Helvetica findfont 660.00 scalefont setfont'
      write(7,*) int(x2),int(y2),'  m'
      write(tt,'(5h  =  ,1pe8.2,4h m/s)') fimax
      write(7,*) '(',tt,') show'
      y1=y1+2.*tsize
      write(7,*) int(x1),int(y1),'  m'
      write(7,*) '(',title,') show'
      WRITE(7,*) 's p'
      CLOSE(UNIT=7)
C
      ENDIF
C
      RETURN
      END
C
C
C##########################################################
      SUBROUTINE PROFX(IJ,IP,XINT)
C##########################################################
C     This routine checks if the line X=XINT crosses an
C     element, defined by the south-west corner index IJ.
C     For each side of the element, it calls routine PROPX
C     to find the crossing point. The coordinates of the
C     crossing point are stored as XP and YP. IP is the
C     number of crossing points found.
C==========================================================
      PARAMETER (nx=300,NY=300,NXY=NX*NY)
      COMMON /IPAR/ NI,NJ,NIM,NJM,NIJ,LI(NX),NPRX,NPRY,IAR,
     *       JAR,IEPRX(10),IEPRY(10)
      COMMON /RPAR/ XMIN,YMIN,XMAX,YMAX,XTOT,YTOT,XBOX,YBOX,
     *       XPAGE,YPAGE,AROMAX,SCFG,SCFV,
     *       XPRO(10),YPRO(10),CVAL(128),FI1,FI2
      COMMON /GEO/ X(NXY),Y(NXY),XC(NXY),YC(NXY),FI(NXY),
     *       CVX(20),CVY(20)
      COMMON /PRO/ XP(2),YP(2)
C
C.....FIND IF XINT CROSSES THE ELEMENT WHOSE SW-CORNER IS IJ
C
      IP=0
      XMN=MIN(XC(IJ),XC(IJ+NJ),XC(IJ+NJ+1),XC(IJ+1))
      XMX=MAX(XC(IJ),XC(IJ+NJ),XC(IJ+NJ+1),XC(IJ+1))
      IF(XINT.GE.XMN.AND.XINT.LE.XMX) THEN
	CALL PROPX(IJ,IJ+NJ,IP,XINT)
	CALL PROPX(IJ+NJ,IJ+NJ+1,IP,XINT)
	IF(IP.NE.2) CALL PROPX(IJ+NJ+1,IJ+1,IP,XINT)
	IF(IP.NE.2) CALL PROPX(IJ+1,IJ,IP,XINT)
      ENDIF
      RETURN
      END
C
C#############################################################
      SUBROUTINE PROPX(IJ1,IJ2,IP,XINT)
C#############################################################
C     This routine finds the crossing point of the line X=XINT
C     with an element side defined by node indices at its ends,
C     IJ1 and IJ2. IP is incremented by one if the crossing
C     point is found, and the coordinates are stored in XP(IP)
C     and YP(IP).
C==============================================================
      PARAMETER (nx=300,NY=300,NXY=NX*NY)
      COMMON /IPAR/ NI,NJ,NIM,NJM,NIJ,LI(NX),NPRX,NPRY,IAR,
     *       JAR,IEPRX(10),IEPRY(10)
      COMMON /RPAR/ XMIN,YMIN,XMAX,YMAX,XTOT,YTOT,XBOX,YBOX,
     *       XPAGE,YPAGE,AROMAX,SCFG,SCFV,
     *       XPRO(10),YPRO(10),CVAL(128),FI1,FI2
      COMMON /GEO/ X(NXY),Y(NXY),XC(NXY),YC(NXY),FI(NXY),
     *       CVX(20),CVY(20)
      COMMON /PRO/ XP(2),YP(2)
C
C.....SEARCH FOR CROSSING POINT BETWEEN IJ1 AND IJ2 NODES
C
      IF(XINT.GE.MIN(XC(IJ1),XC(IJ2)).AND.
     *   XINT.LE.MAX(XC(IJ1),XC(IJ2))) THEN
	IP=IP+1
	FAC=(XINT-XC(IJ1))/(XC(IJ2)-XC(IJ1)+1.E-20)
	YP(IP)=YC(IJ1)+FAC*(YC(IJ2)-YC(IJ1))
	XP(IP)=FI(IJ1)+FAC*(FI(IJ2)-FI(IJ1))
      ENDIF
      RETURN
      END
C         
C
C##########################################################
      SUBROUTINE PROFY(IJ,IP,YINT)
C##########################################################
C     This routine is analogous to PROFX, only for Y=YINT.
C==========================================================
      PARAMETER (nx=300,NY=300,NXY=NX*NY)
      COMMON /IPAR/ NI,NJ,NIM,NJM,NIJ,LI(NX),NPRX,NPRY,IAR,
     *       JAR,IEPRX(10),IEPRY(10)
      COMMON /RPAR/ XMIN,YMIN,XMAX,YMAX,XTOT,YTOT,XBOX,YBOX,
     *       XPAGE,YPAGE,AROMAX,SCFG,SCFV,
     *       XPRO(10),YPRO(10),CVAL(128),FI1,FI2
      COMMON /GEO/ X(NXY),Y(NXY),XC(NXY),YC(NXY),FI(NXY),
     *       CVX(20),CVY(20)
      COMMON /PRO/ XP(2),YP(2)
C
C.....FIND IF YINT CROSSES THE CELL WHOSE SW-CORNER IS IJ
C
      IP=0
      YMN=MIN(YC(IJ),YC(IJ+NJ),YC(IJ+NJ+1),YC(IJ+1))
      YMX=MAX(YC(IJ),YC(IJ+NJ),YC(IJ+NJ+1),YC(IJ+1))
      IF(YINT.GE.YMN.AND.YINT.LE.YMX) THEN
	CALL PROPY(IJ,IJ+NJ,IP,YINT)
	CALL PROPY(IJ+NJ,IJ+NJ+1,IP,YINT)
	IF(IP.NE.2) CALL PROPY(IJ+NJ+1,IJ+1,IP,YINT)
	IF(IP.NE.2) CALL PROPY(IJ+1,IJ,IP,YINT)
      ENDIF
      RETURN
      END
C
C##########################################################
      SUBROUTINE PROPY(IJ1,IJ2,IP,YINT)
C##########################################################
C     This routine is analogous to PROPX, only for Y=YINT.
C==========================================================
      PARAMETER (nx=300,NY=300,NXY=NX*NY)
      COMMON /IPAR/ NI,NJ,NIM,NJM,NIJ,LI(NX),NPRX,NPRY,IAR,
     *       JAR,IEPRX(10),IEPRY(10)
      COMMON /RPAR/ XMIN,YMIN,XMAX,YMAX,XTOT,YTOT,XBOX,YBOX,
     *       XPAGE,YPAGE,AROMAX,SCFG,SCFV,
     *       XPRO(10),YPRO(10),CVAL(128),FI1,FI2
      COMMON /GEO/ X(NXY),Y(NXY),XC(NXY),YC(NXY),FI(NXY),
     *       CVX(20),CVY(20)
      COMMON /PRO/ XP(2),YP(2)
C
C.....SEARCH FOR CROSSING POINT BETWEEN IJ1 AND IJ2 NODES
C
      IF(YINT.GE.MIN(YC(IJ1),YC(IJ2)).AND.
     *   YINT.LE.MAX(YC(IJ1),YC(IJ2))) THEN
	IP=IP+1
	FAC=(YINT-YC(IJ1))/(YC(IJ2)-YC(IJ1)+1.E-20)
	XP(IP)=XC(IJ1)+FAC*(XC(IJ2)-XC(IJ1))
	YP(IP)=FI(IJ1)+FAC*(FI(IJ2)-FI(IJ1))
      ENDIF
      RETURN
      END
C
C
C###############################################################
      SUBROUTINE ARROW(XC1,YC1,X,Y)
C###############################################################
C     This routine draws the arrow representing velocity vector.
C     XC1 and YC1 are page coordinates of vector start, X and Y
C     are coordinates of vector end. The arrow is long 20% of the
C     vector length and wide 5% of the vector length.
C===============================================================
C
      VL=SQRT((X-XC1)**2+(Y-YC1)**2)
      IF(VL.GT.1.E-8) THEN
	WRITE(7,*) int(XC1),int(YC1),' m',int(X),int(Y),' l'
	DX=X-XC1
	DY=Y-YC1
	X1=X-0.2*DX
	Y1=Y-0.2*DY
	DA=0.025*VL
	SAL=DY/VL
	CAL=DX/VL
	DX=DA*SAL
	DY=DA*CAL
	X1=X1-DX
	Y1=Y1+DY
	X2=X1+2.*DX
	Y2=Y1-2.*DY
	WRITE(7,*) int(X1),int(Y1),' l',int(X2),int(Y2),' l',
     *             int(X),int(Y),' l s'
      ENDIF
      RETURN
      END
C
C
C###########################################################
      SUBROUTINE GRIDPL
C###########################################################
C     This routine plots the grid lines other than boundary
C     lines.
C===========================================================
      PARAMETER (nx=300,NY=300,NXY=NX*NY)
      COMMON /IPAR/ NI,NJ,NIM,NJM,NIJ,LI(NX),NPRX,NPRY,IAR,
     *       JAR,IEPRX(10),IEPRY(10)
      COMMON /RPAR/ XMIN,YMIN,XMAX,YMAX,XTOT,YTOT,XBOX,YBOX,
     *       XPAGE,YPAGE,AROMAX,SCFG,SCFV,
     *       XPRO(10),YPRO(10),CVAL(128),FI1,FI2
      COMMON /GEO/ X(NXY),Y(NXY),XC(NXY),YC(NXY),FI(NXY),
     *       CVX(20),CVY(20)
C
      WRITE(7,*) '20 w'
C
C.....PLOT I-LINES (J=CONST)
C
      DO J=2,NJM-1
	IJ=LI(1)+J
	WRITE(7,'(2I7,A3)') INT(X(IJ)),INT(Y(IJ)),' m '
C
	DO I=2,NIM
	  IJ=LI(I)+J
	  WRITE(7,'(2I7,A3)') INT(X(IJ)),INT(Y(IJ)),' l '
	END DO
	WRITE(7,*) 's'
      END DO
C
C.....PLOT  J - LINES (I=CONST)
C
      DO I=2,NIM-1
	IJ=LI(I)+1
	WRITE(7,'(2I7,A3)') int(X(IJ)),int(Y(IJ)),' m '
C
	DO J=2,NJM
	  IJ=LI(I)+J
	  WRITE(7,'(2I7,A3)') int(X(IJ)),int(Y(IJ)),' l '
	END DO
	WRITE(7,*) 's'
      END DO
C
      RETURN
      END
C
C
C##########################################################
      SUBROUTINE BPLOT(HEAD,L)
C##########################################################
C     This routine opens the postscript file with the name
C     specified by HEAD and L (e.g. isob1.ps if HEAD=isob,
C     and L=1), writes the postscript header to it and plots
C     the boundary grid lines with a thick line. This is
C     the first routine that has to be called for any plot.
C==========================================================
      PARAMETER (nx=300,NY=300,NXY=NX*NY)
      COMMON /IPAR/ NI,NJ,NIM,NJM,NIJ,LI(NX),NPRX,NPRY,IAR,
     *       JAR,IEPRX(10),IEPRY(10)
      COMMON /RPAR/ XMIN,YMIN,XMAX,YMAX,XTOT,YTOT,XBOX,YBOX,
     *       XPAGE,YPAGE,AROMAX,SCFG,SCFV,
     *       XPRO(10),YPRO(10),CVAL(128),FI1,FI2
      COMMON /GEO/ X(NXY),Y(NXY),XC(NXY),YC(NXY),FI(NXY),
     *       CVX(20),CVY(20)
      COMMON /RGB/ R(255),G(255),B(255)
      CHARACTER FILOUT*10,HEAD*4
C
C.....OPEN PLOT FILE, WRITE HEADER
C
      IF(L.LT.10) WRITE(FILOUT,'(a4,I1,3H.ps)') HEAD,L
      IF(L.GE.10.AND.L.LT.100) WRITE(FILOUT,'(a4,I2,3H.ps)') HEAD,L
      IF(L.GT.100) WRITE(FILOUT,'(a4,I3,3H.ps)') HEAD,L
C
      OPEN(UNIT=7,FILE=FILOUT)
      REWIND 7
      CALL PSHEAD(XMIN,XMAX,YMIN,YMAX)
      WRITE(7,*) '0. 0. 0. col'
C
C.....Move to south-west corner
C
      WRITE(7,*) '80 w'
      IJ=LI(1)+1
      WRITE(7,'(2I7,A3)') int(X(IJ)),int(Y(IJ)),' m '
C
C.....Draw west boundary
C
      DO J=2,NJM
	IJ=LI(1)+J
	WRITE(7,'(2I7,A3)') int(X(IJ)),int(Y(IJ)),' l '
      END DO
C
C.....Draw north boundary
C
      DO I=2,NIM
	IJ=LI(I)+NJM
	WRITE(7,'(2I7,A3)') int(X(IJ)),int(Y(IJ)),' l '
      END DO
C
C.....Draw east boundary
C
      DO J=NJM-1,1,-1
	IJ=LI(NIM)+J
	WRITE(7,'(2I7,A3)') int(X(IJ)),int(Y(IJ)),' l '
      END DO
C
C.....Draw south boundary
C
      DO I=NIM-1,1,-1
	IJ=LI(I)+1
	WRITE(7,'(2I7,A3)') int(X(IJ)),int(Y(IJ)),' l '
      END DO
C
      WRITE(7,*) 's'
C
      RETURN
      END
c
C############################################################
      subroutine cont(icon,ncon,icol,nib,njb,title)
C############################################################
C     This routine plots contour lines of a constant value of
C     the variable stored in the array FI(NXY). It operates on
C     elements defined by CV centers. Contour lines are
C     made of segments of straight lines connecting points at
C     element edges where the interpolated varible value equals
C     the contour level. Since these segments are small, the
C     lines apear smooth for grids with more than 20 nodes in
C     one direction.
C=============================================================
      PARAMETER (nx=300,NY=300,NXY=NX*NY)
      COMMON /IPAR/ NI,NJ,NIM,NJM,NIJ,LI(NX),NPRX,NPRY,IAR,
     *       JAR,IEPRX(10),IEPRY(10)
      COMMON /RPAR/ XMIN,YMIN,XMAX,YMAX,XTOT,YTOT,XBOX,YBOX,
     *       XPAGE,YPAGE,AROMAX,SCFG,SCFV,
     *       XPRO(10),YPRO(10),CVAL(128),FI1,FI2
      COMMON /GEO/ X(NXY),Y(NXY),XC(NXY),YC(NXY),FI(NXY),
     *       CVX(20),CVY(20)
      COMMON /RGB/ R(255),G(255),B(255)
      character title*15
c
c.... find extrema
c
      fimax=-1.e20
      fimin=1.e20
      do ij=1,nij
	fimax=max(fimax,fi(ij))
	fimin=min(fimin,fi(ij))
      end do
c
c.....set contour levels (if icon.ne.0; linear distribution)
c
      if(icon.ne.0) then
	dfi=(fimax-fimin)/real(ncon)
	cval(1)=fimin+0.5*dfi
	do nc=2,ncon
	  cval(nc)=cval(nc-1)+dfi
	end do
      endif
c
c.....set line thicknes and colors (black if ICOL=0)
c   
      WRITE(7,*) '40 w '
      if(icol.eq.0) then
	write(7,*) '0. 0. 0. col'
      else
	call setcol(ncon)
      endif
c
C=====================================================================
C.....Search each quadrilateral element (IJ node is south-west corner)
C=====================================================================
C     There are NIM elements in I and NJM elements in J direction
C     (boundary nodes are also used in defining the elements).
C     IJ is the south-west, IJE the south-east, IJNE the north-east
C     and IJN the north-west corner of the element. The variable
C     values are available at corners (these are CV centers). If the
C     contour level is within the minimum and maximum value at the
C     four vertices of the element, the four element edges are
C     checked to find out if the contour level falls between values
C     at ends (routine NEWC). If so, the location is found by linear
C     interpolation, the coordinates are stored in CVX and CVY arrays
C     and the counter IVC is increased. The lines between points are
C     then drawn. If more than two points are found, the line is
C     closed from last to first point.
C
      do k=1,ncon
	if(icol.gt.0) WRITE(7,*) R(K),G(K),B(K),' col'
C
      do i=1,nib
      do j=1,njb
	ij=li(i)+j
	ije=ij+nj
	ijn=ij+1
	ijne=ije+1
c
c.....Search for contour AND PLOT IT
c
	fi1=cval(k)
	fimn=min(fi(ij),fi(ije),fi(ijn),fi(ijne))
	fimx=max(fi(ij),fi(ije),fi(ijn),fi(ijne))
	if(.not.((fi1.lt.fimn).or.(fi1.gt.fimx))) then
	  ivc=0
	  call newc(ij,ije,ivc)
	  call newc(ije,ijne,ivc)
	  call newc(ijne,ijn,ivc)
	  call newc(ijn,ij,ivc)
	  if(ivc.gt.1) then
	    WRITE(7,*) int(cvx(1)),int(cvy(1)),' m'
	    do kk=2,ivc
	      WRITE(7,*) int(cvx(kk)),int(cvy(kk)),' l'
	    end do
	    if(ivc.gt.2) write(7,*) int(cvx(1)),int(cvy(1)),' l'
	    WRITE(7,*) 's'
	  endif
	endif
      end do
      end do
C
      end do
C
C.....PLOT THE BOX with contour levels and colour scale
C
      write(7,*) '0. 0. 0. col'
      call plbox(ncon,icol,title)
c
      return
      end
c
c############################################################
      subroutine newc(ij1,ij2,ivc)
c############################################################
C     This routine finds the contour point on one element
C     edge (it checks also if the corner value at IJ1 equals
C     the contour level value).
C============================================================
      PARAMETER (nx=300,NY=300,NXY=NX*NY)
      COMMON /IPAR/ NI,NJ,NIM,NJM,NIJ,LI(NX),NPRX,NPRY,IAR,
     *       JAR,IEPRX(10),IEPRY(10)
      COMMON /RPAR/ XMIN,YMIN,XMAX,YMAX,XTOT,YTOT,XBOX,YBOX,
     *       XPAGE,YPAGE,AROMAX,SCFG,SCFV,
     *       XPRO(10),YPRO(10),CVAL(128),FI1,FI2
      COMMON /GEO/ X(NXY),Y(NXY),XC(NXY),YC(NXY),FI(NXY),
     *       CVX(20),CVY(20)
c
c.....Check if value at IJ1 equals contour value
c
      if(fi(ij1).eq.fi1) then
      ivc=ivc+1
      cvx(ivc)=xc(ij1)
      cvy(ivc)=yc(ij1)
c
c.....Check if contur value FI1 lies between values at IJ1 and IJ2;
c.....if so, interpolate to find location between nodes IJ1 and IJ2
c
      elseif((fi1.ge.min(fi(ij1),fi(ij2))).and.
     *    (fi1.le.max(fi(ij1),fi(ij2)))) then
	ivc=ivc+1
	fac1=(fi1-fi(ij1))/(fi(ij2)-fi(ij1)+1.e-20)
	cvx(ivc)=xc(ij1)+fac1*(xc(ij2)-xc(ij1))
	cvy(ivc)=yc(ij1)+fac1*(yc(ij2)-yc(ij1))
      endif
c
      return
      end
c
c#############################################################
      subroutine plbox(ncon,icol,title)
c#############################################################
C     This routine plots the box with contour levels and color 
C     scale.
C=============================================================
      PARAMETER (nx=300,NY=300,NXY=NX*NY)
      COMMON /IPAR/ NI,NJ,NIM,NJM,NIJ,LI(NX),NPRX,NPRY,IAR,
     *       JAR,IEPRX(10),IEPRY(10)
      COMMON /RPAR/ XMIN,YMIN,XMAX,YMAX,XTOT,YTOT,XBOX,YBOX,
     *       XPAGE,YPAGE,AROMAX,SCFG,SCFV,
     *       XPRO(10),YPRO(10),CVAL(128),FI1,FI2
      COMMON /RGB/ R(255),G(255),B(255)
      character title*15,tt*9
C
C.....TOP LEFT CORNER
C
      x1=xbox
      y1=ybox+6600.
C
C.....PLOT INFO BOX TITLE
C
      write(7,*) '0. 0. 0. col'
      write(7,*) '/Helvetica findfont 500.00 scalefont setfont'
      write(7,*) int(x1),int(y1),' m (',title,') show'
      y1=y1-600.
      write(7,*) '/Helvetica findfont 400.00 scalefont setfont'
      write(7,*) int(x1),int(y1),' m (Contour levels:) show'
      write(7,*) '200 w'
      x2=x1+1400.
      y1=y1-520.
c
C.....PLOT COLORS AND CONTOUR LEVELS
C
      istep=(ncon+5)/10
c
      do n=1,ncon,istep
	if(icol.eq.1) write(7,*) r(n),g(n),b(n),' col'
	write(7,*) int(x1),int(y1),' m ',int(x2),int(y1),' l s' 
	write(tt,'(1pe9.2)') cval(n)
	write(7,*) int(x2+400.),int(y1-160.),' m ','(',tt,') show'
	y1=y1-500.
      end do
c
      return
      end
C
c
c#############################################################
      subroutine paint(ncon,nib,njb,title)
c#############################################################
C     This routine paints each element by filling one colour 
C     between two contour levels. It operates on the same
C     element as the contouring routine. Two contour levels
C     are considered, and the polygon is defined using contour
C     lines and element edges.
C=============================================================
      PARAMETER (nx=300,NY=300,NXY=NX*NY)
      COMMON /IPAR/ NI,NJ,NIM,NJM,NIJ,LI(NX),NPRX,NPRY,IAR,
     *       JAR,IEPRX(10),IEPRY(10)
      COMMON /RPAR/ XMIN,YMIN,XMAX,YMAX,XTOT,YTOT,XBOX,YBOX,
     *       XPAGE,YPAGE,AROMAX,SCFG,SCFV,
     *       XPRO(10),YPRO(10),CVAL(128),FI1,FI2
      COMMON /GEO/ X(NXY),Y(NXY),XC(NXY),YC(NXY),FI(NXY),
     *       CVX(20),CVY(20)
      COMMON /RGB/ R(255),G(255),B(255)
      character title*15
c      
c.....Find extrema, choose contour colours, plot the box
c
      fimax=-1.e20
      fimin=1.e20
      do ij=1,nij
	fimax=max(fimax,fi(ij))
	fimin=min(fimin,fi(ij))
      end do
      dfi=(fimax-fimin)/real(ncon)
c
      cval(1)=fimin+0.5*dfi
      do nc=2,ncon
	cval(nc)=cval(nc-1)+dfi
      end do
c
      call setcol(ncon)
c
C============================================================
c.....Paint each element (south-west corner is node IJ)
C============================================================
c     One fills first the colour between FIMIN and the first
C     contour level, then between contours, and finally between
C     the last contour level and PHIMAX.
C
      WRITE(7,*) '40 w '
      fi1=fimin
      do k=1,ncon
	WRITE(7,*) R(K),G(K),B(K),' col'
	fi2=fi1+dfi
	if(k.eq.ncon) fi2=fimax
C
	do i=1,nib
	do j=1,njb
	  ij=li(i)+j
	  ije=ij+nj
	  ijn=ij+1
	  ijne=ije+1
c
c.....Search for filling range between FI1 and FI2
c
	  fimn=min(fi(ij),fi(ije),fi(ijn),fi(ijne))
	  fimx=max(fi(ij),fi(ije),fi(ijn),fi(ijne))
	  IF(.not.(((fi1.lt.fimn).and.(fi2.lt.fimn)).or. 
     *            ((fi1.gt.fimx).and.(fi2.gt.fimx)))) then 
	    ivc=0
	    call newvc(ij,ije,ivc)
	    call newvc(ije,ijne,ivc)
	    call newvc(ijne,ijn,ivc)
	    call newvc(ijn,ij,ivc)
	    if(ivc.gt.2) then
	      write(7,*) 'n ',int(cvx(1)),int(cvy(1)),' m'
	      do l=2,ivc
		write(7,*) int(cvx(l)),int(cvy(l)),' l'
	      end do
	      write(7,*) int(cvx(1)),int(cvy(1)),' l cp f s'
	    endif
	  ENDIF
	END DO
	END DO
C
      fi1=fi2
      END DO
C
      icol=1
      call plbox(ncon,icol,title)
C
      return
      end
c
c#############################################################
      subroutine newvc(ij1,ij2,ivc)
c#############################################################
C     This routine defines and fills with colour a polygon
C     bounded by two contours (FI1 and FI2) and element edges.
C     If an element corner is within the range, it becomes a
C     vertex in the polygon. When points corresponding to both
C     FI1 and FI2 are found on one edge, they are sorted out so
C     that polygon edges define a closed surface (one searces
C     along edges of an element counterclockwise; on one edge,
C     from IJ1 node to IJ2 node).
C=============================================================
      PARAMETER (nx=300,NY=300,NXY=NX*NY)
      COMMON /IPAR/ NI,NJ,NIM,NJM,NIJ,LI(NX),NPRX,NPRY,IAR,
     *       JAR,IEPRX(10),IEPRY(10)
      COMMON /RPAR/ XMIN,YMIN,XMAX,YMAX,XTOT,YTOT,XBOX,YBOX,
     *       XPAGE,YPAGE,AROMAX,SCFG,SCFV,
     *       XPRO(10),YPRO(10),CVAL(128),FI1,FI2
      COMMON /GEO/ X(NXY),Y(NXY),XC(NXY),YC(NXY),FI(NXY),
     *       CVX(20),CVY(20)
c
c.....Check if node IJ1 is within painted range 
c
      if(fi(ij1).ge.fi1.and.fi(ij1).le.fi2) then
	ivc=ivc+1
	cvx(ivc)=xc(ij1)
	cvy(ivc)=yc(ij1)
      endif
c
c.....Value FI1 (lower bound) between nodes IJ1 and IJ2
c
      fac1=0.
      if((fi1.ge.min(fi(ij1),fi(ij2))).and.
     *   (fi1.le.max(fi(ij1),fi(ij2)))) then
	ivc=ivc+1
	fac1=(fi1-fi(ij1))/(fi(ij2)-fi(ij1)+1.e-20)
	cvx(ivc)=xc(ij1)+fac1*(xc(ij2)-xc(ij1))
	cvy(ivc)=yc(ij1)+fac1*(yc(ij2)-yc(ij1))
      endif
c
c....Value FI2 (upper bound) between nodes IJ1 and IJ2
c
      fac2=0.
      if((fi2.ge.min(fi(ij1),fi(ij2))).and.
     *   (fi2.le.max(fi(ij1),fi(ij2)))) then
	ivc=ivc+1
	fac2=(fi2-fi(ij1))/(fi(ij2)-fi(ij1)+1.e-20)
	cvx(ivc)=xc(ij1)+fac2*(xc(ij2)-xc(ij1))
	cvy(ivc)=yc(ij1)+fac2*(yc(ij2)-yc(ij1))
c
c.....if both points found, sort them out
c
	if(fac2.lt.fac1) then
	  x1=cvx(ivc-1)
	  y1=cvy(ivc-1)
	  cvx(ivc-1)=cvx(ivc)
	  cvy(ivc-1)=cvy(ivc)
	  cvx(ivc)=x1
	  cvy(ivc)=y1
	endif
      endif
C
      return
      end
C
C
C##########################################################
      SUBROUTINE PSHEAD(XMIN,XMAX,YMIN,YMAX)
C##########################################################
C     This routine writes postscript header to the plot
C     file. Bounding box coveres only the solution domain
C     boundary, not the contour information. 
C==========================================================
C
      X1=XMIN+100.
      Y1=YMIN+100.
      X2=XMAX+110.
      Y2=YMAX+110.
C
      WRITE(7,*) '%!PS-Adobe-2.0'
      WRITE(7,*) '%%Creator: PLOTP'
      WRITE(7,*) '%%BoundingBox: ',X1,Y1,X2,Y2
      WRITE(7,*) '%%EndComments'
      WRITE(7,*) '/c {currentpoint} def /f {fill} def '
      WRITE(7,*) '/gr {grestore} def /gs {gsave} def /l {lineto} def '
      WRITE(7,*) '/m {moveto} def /n {newpath} def /p {showpage} def '
      WRITE(7,*) '/s {stroke} def /sg {setgray} def '
      WRITE(7,*) '/w {setlinewidth} def /cp {closepath} def'
      WRITE(7,*) '/col {setrgbcolor} def'
      WRITE(7,*) '100 100 translate 0.03 0.03 scale '
      WRITE(7,*) '1 setlinecap 1 setlinejoin '
C
      RETURN
      END
