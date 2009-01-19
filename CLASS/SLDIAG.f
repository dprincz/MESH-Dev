      SUBROUTINE SLDIAG(SU,SV,ST,SQ,CDM,CDH,UA,VA,TA,QA,T0,Q0,
     1                  Z0M,Z0E,F,ZA,ZU,ZT,ILG,IL1,IL2,JL)

C     * NOV 04/04 - D.VERSEGHY. ADD "IMPLICIT NONE" COMMAND.
C     * JUL 19/96 - Y. DELAGE.  

C     * CALCULATES NEAR SURFACE OUTPUT VARIABLES

c     * OUTPUT FIELDS ARE:
C     *   SU  : U COMPONENT OF THE WIND AT ZU
C     *   SV  : V COMPONENT OF THE WIND AT ZU
C     *   ST  : TEMPERATURE AT ZT
C     *   SQ  : SPECIFIC HUMIDITY AT ZT

C     * INPUT FIELDS ARE:
C     *   CDM : DRAG COEFFICIENT
C     *   CDH : TRASFER COEFFICIENT FOR HEAT AND MOISTURE
C     *   UA  : U COMPONENT OF THE WIND AT ZA
C     *   VA  : V COMPONENT OF THE WIND AT ZA
C     *   TA  : POTENTIAL TEMPERATURE AT ZA
c     *   T0  : TEMPERATURE AT BOTTOM OF SURFACE LAYER
C     *   Q0  : SPECIFIC HUMIDITY AT BOTTOM OF SURFACE LAYER
C     *   Z0M : ROUGHNESS LENGTH FOR MOMENTUM
C     *   Z0E : ROUGHNESS LENGTH FOR HEAT AND MOISTURE
C     *   F   : FRACTION OF GRID POINT AFFECTED BY PROCESS
C     *   ZA  : TOP OF SURFACE LAYER
C     *   ZU  : HEIGHT OF OUTPUT WIND
C     *   ZT  : HEIGHT OF OUTPUT TEMPERATURE AND HUMIDITY
C     *   ILG : NUMBER OF POINTS TO BE TREATED
C
      IMPLICIT NONE
c
      INTEGER ILG,IL1,IL2,JL,I
c
      REAL   SU(ILG),  SV(ILG),  ST(ILG),  SQ(ILG), CDM(ILG), CDH(ILG),
     1       UA(ILG),  VA(ILG),  TA(ILG),  QA(ILG), Z0M(ILG), Z0E(ILG),
     2       F(ILG),   T0(ILG),  Q0(ILG),  ZA(ILG), ZU(ILG),  ZT(ILG)
c 
      REAL PR,WSPD,CM,US,TS,QS,L,UVA,RATIO,UVU,TTA,CE
c
      REAL RGAS,RGASV,GRAV,SBC,VKC,CT,VMIN
c
      REAL PSM,PSE,Y,PIM,PIE,X
c
      COMMON /CLASS2/ RGAS,RGASV,GRAV,SBC,VKC,CT,VMIN
      
c     * STABILITY FUNCTIONS FOR THE STABLE CASE

      PSM(X)= -X -.667*(X-5/.35)*EXP(-.35*X)
      PSE(X)= -(1+.667*X)**1.5 -.667*(X-5/.35)*EXP(-.35*X)

c     * STABILITY FUNCTIONS FOR THE UNSTABLE CASE

      Y(X)=(1-16*X)**.25
      PIM(X)= LOG((1+X)**2*(1+X**2)) -2*ATAN(X)
      PIE(X)= 2*LOG(1+X**2)

      PR=1.0
      DO 100 I=IL1,IL2
      IF(F(I).GT.0.)                                                THEN

C     * CALCULATION OF SURFACE FLUXES AND MONIN-OBUKHOV LENGTH

        WSPD=MAX(VMIN,SQRT(UA(I)**2+VA(I)**2))
        CM=SQRT(CDM(I))
        US=CM*WSPD
        TS=CDH(I)*(TA(I)-T0(I))/CM
        QS=CDH(I)*(QA(I)-Q0(I))/CM
        L=TA(I)*US**2/(VKC*GRAV*(TS*(1+.61*QA(I))+.61*TA(I)*QS))
      
C     * CALCULATE CORRECTION FACTORS TO TAKE INTO ACCOUNT THE APPROXIMATIONS
C     * IN DRCOEF

        IF(L.GT.0.)                                                 THEN

C     * STABLE CASE

         UVA=US/VKC*(LOG(ZA(I)/Z0M(I))-PSM(ZA(I)/L)+PSM(Z0M(I)/L))
         RATIO=WSPD/UVA
         UVU=US/VKC*(LOG((ZU(I)+Z0M(I))/Z0M(I))-PSM((ZU(I)+Z0M(I))/L)
     1       +PSM(Z0M(I)/L))*RATIO
         SU(I)=SU(I)+F(I)*UVU*UA(I)/WSPD
         SV(I)=SV(I)+F(I)*UVU*VA(I)/WSPD

      TTA=T0(I)+TS/VKC*PR*(LOG(ZA(I)/Z0E(I))-PSE(ZA(I)/L)+PSE(Z0E(I)/L))
         RATIO=(TA(I)-T0(I))/SIGN(MAX(ABS(TTA-T0(I)),1.E-4),TTA-T0(I))
         CE=(LOG((ZT(I)+Z0M(I))/Z0E(I))-PSE((ZT(I)+Z0M(I))/L)
     1      +PSE(Z0E(I)/L))*RATIO*PR/VKC
         ST(I)=ST(I)+F(I)*T0(I)+TS*CE
         SQ(I)=SQ(I)+F(I)*Q0(I)+QS*CE
        ELSE

C     * UNSTABLE CASE

         UVA=US/VKC*(LOG(ZA(I)/Z0M(I))-PIM(Y(ZA(I)/L))+PIM(Y(Z0M(I)/L)))
         RATIO=WSPD/UVA
         UVU=US/VKC*(LOG((ZU(I)+Z0M(I))/Z0M(I))-PIM(Y((ZU(I)+Z0M(I))/L))
     1        +PIM(Y(Z0M(I)/L)))*RATIO
         SU(I)=SU(I)+F(I)*UVU*UA(I)/WSPD
         SV(I)=SV(I)+F(I)*UVU*VA(I)/WSPD
         TTA=T0(I)+TS/VKC*PR*(LOG(ZA(I)/Z0E(I))-PIE(Y(ZA(I)/L))+
     1          PIE(Y(Z0E(I)/L)))
         RATIO=(TA(I)-T0(I))/SIGN(MAX(ABS(TTA-T0(I)),1.E-4),TTA-T0(I))
         CE=(LOG((ZT(I)+Z0M(I))/Z0E(I))-PIE(Y((ZT(I)+Z0M(I))/L))
     1      +PIE(Y(Z0E(I)/L)))*RATIO*PR/VKC
         ST(I)=ST(I)+F(I)*T0(I)+TS*CE
         SQ(I)=SQ(I)+F(I)*Q0(I)+QS*CE
        ENDIF
      ENDIF
  100 CONTINUE

      RETURN
      END




