      SUBROUTINE GRDRAN(IVEG,THLIQ,THICE,TBARW,FDT,TFDT,BASFLW,TBASFL,
     1                  RUNOFF,TRUNOF,QFG,WLOST,FI,EVAP,R,ZPOND,DT,
     2                  WEXCES,THLMAX,THTEST,THPOR,THLRET,THLMIN,
     3                  BI,PSISAT,GRKSAT,THFC,DELZW,XDRAIN,ISAND,
     4                  IGRN,IGRD,IG,IGP1,IGP2,ILG,IL1,IL2,JL  )
C
C     * MAR 27/08 - D.VERSEGHY. MOVE VISCOSITY ADJUSTMENT TO WPREP.
C     * OCT 31/06 - R.SOULIS.   ADJUST GRKSAT FOR VISCOSITY OF
C     *                         WATER AND PRESENCE OF ICE; ADJUST
C     *                         THPOR FOR PRESENCE OF ICE.
C     * JUN 06/06 - F.SEGLENIEKS. CHANGE CALCULATION OF GRSBND
C     *                           TO USE HARMONIC MEAN INSTEAD OF
C     *                           GEOMETRIC MEAN.
C     * MAY 17/06 - D.VERSEGHY. MODIFY CALCULATION OF THLMAX TO
C     *                         ALLOW FOR OVERSATURATED CONDITIONS.
C     * MAR 21/06 - D.VERSEGHY. PROTECT CALCULATIONS OF TBASFL AND
C     *                         TRUNOF AGAINST DIVISION BY ZERO.
C     * MAR 23/05 - R.SOULIS/D.VERSEGHY. CALCULATE GRKSAT AND
C     *                         PSISAT AT LAYER BOUNDARIES USING 
C     *                         GEOMETRIC MEAN; SET BASEFLOW TO
C     *                         GRKSAT IF THLIQ > THFC; ADD
C     *                         CALCULATION OF RUNOFF TEMPERATURE.
C     * MAR 16/05 - D.VERSEGHY. TREAT FROZEN SOIL WATER AS ICE
C     *                         VOLUME RATHER THAN AS EQUIVALENT
C     *                         LIQUID WATER VOLUME.
C     * SEP 24/04 - D.VERSEGHY. ADD "IMPLICIT NONE" COMMAND.
C     * JUL 27/04 - D.VERSEGHY,Y.DELAGE. PROTECT SENSITIVE 
C     *                         CALCULATIONS AGAINST ROUNDOFF ERRORS.
C     * DEC 03/03 - D.VERSEGHY. IMPROVE HANDLING OF CAPILLARY RISE
C     *                         VS. GRAVITY DRAINAGE (ESPECIALLY
C     *                         FOR ORGANIC SOILS).
C     * JUL 31/03 - D.VERSEGHY. ALWAYS CALCULATE THLMAX IN 100 LOOP.
C     * OCT 23/02 - D.VERSEGHY. REFINEMENT OF TEST IN 400 LOOP.
C     * JUN 21/02 - D.VERSEGHY. BUGFIX IN CALCULATION OF FDT'S IN
C     *                         400 LOOP; UPDATE SUBROUTINE CALL;
C     *                         SHORTENED CLASS4 COMMON BLOCK.
C     * MAY 21/02 - D.VERSEGHY. STREAMLINE CALCULATIONS FOR ORGANIC
C     *                         SOILS AND MODIFY CHECK ON EVAPORATION
C     *                         RATE.
C     * DEC 12/01 - D.VERSEGHY. ADD SEPARATE CALCULATION OF BASEFLOW
C     *                         AT BOTTOM OF SOIL COLUMN.
C     * SEP 28/00 - P.BARTLETT/D.VERSEGHY. BUG FIX IN CALCULATION
C     *                                    OF PSI IN LOOP 200.
C     * FEB 08/00 - D.VERSEGHY/L.SPACEK. MINOR BUG FIX IN LOOP 600
C     *                                  RE. ADDRESSING OF THLIQ.
C     * JUN 20/97 - D.VERSEGHY. CLASS - VERSION 2.7.
C     *                         MODIFICATIONS TO ALLOW FOR VARIABLE
C     *                         SOIL PERMEABLE DEPTH.
C     * DEC 30/96 - D.VERSEGHY. CLASS - VERSION 2.6.
C     *                         BUGFIX IN CALCULATION OF QFG.
C     * AUG 30/95 - D.VERSEGHY. CLASS - VERSION 2.4.
C     *                         ADDITIONAL DIAGNOSTIC CALCULATIONS.
C     * AUG 18/95 - D.VERSEGHY. REVISIONS TO ALLOW FOR INHOMOGENEITY
C     *                         BETWEEN SOIL LAYERS.
C     * APR 24/92 - D.VERSEGHY/M.LAZARE. CLASS - VERSION 2.1.
C     *                                  REVISED AND VECTORIZED CODE
C     *                                  FOR MODEL VERSION GCM7.
C     * AUG 12/91 - D.VERSEGHY. CODE FOR MODEL VERSION GCM7U -
C     *                         CLASS VERSION 2.0 (WITH CANOPY).
C     * APR 11/89 - D.VERSEGHY. UPDATE SOIL LAYER TEMPERATURES AND
C     *                         LIQUID MOISTURE CONTENTS FOR
C     *                         NON-INFILTRATING CONDITIONS (I.E.
C     *                         NO PONDED WATER AND NO RAINFALL 
C     *                         OCCURRING WITHIN CURRENT TIMESTEP).
C
      IMPLICIT NONE
C
C     * INTEGER CONSTANTS.
C
      INTEGER IVEG,IG,IGP1,IGP2,ILG,IL1,IL2,JL,I,J,K,IPTBAD 
C
C     * INPUT/OUTPUT FIELDS.
C
      REAL THLIQ (ILG,IG),  THICE (ILG,IG),  TBARW (ILG,IG),  
     1     FDT  (ILG,IGP1), TFDT  (ILG,IGP1)
C                        
      REAL BASFLW(ILG),    TBASFL (ILG),     RUNOFF(ILG),    
     1     TRUNOF (ILG),   QFG    (ILG),     WLOST (ILG)
C
C     * INPUT FIELDS.
C
      REAL FI    (ILG),    EVAP  (ILG),    R     (ILG),    
     1     ZPOND (ILG),    DT    (ILG)
C
      INTEGER              IGRN  (ILG)
C
C     * WORK FIELDS.
C
      REAL WEXCES(ILG),    THLMAX(ILG,IG), THTEST(ILG,IG),
     1     GRKSATF(ILG,IG),THPORF(ILG,IG) 
C
      INTEGER              IGRD  (ILG)
C
C     * SOIL INFORMATION ARRAYS.
C
      REAL THPOR (ILG,IG), THLRET(ILG,IG), THLMIN(ILG,IG), 
     1     BI    (ILG,IG), PSISAT(ILG,IG), GRKSAT(ILG,IG), 
     2     THFC  (ILG,IG), DELZW (ILG,IG), XDRAIN(ILG)    
C  
      INTEGER              ISAND (ILG,IG)
C
C     * TEMPORARY VARIABLES.
C
      REAL THPBND,THLBND,DTHLDZ,DTHPDZ,BBND,GRSBND,PSSBND,GRK,PSI,
     1     WLIMIT,THSUBL,THLTHR
C
C     * COMMON BLOCK PARAMETERS.
C
      REAL DELT,TFREZ,HCPW,HCPICE,HCPSOL,HCPOM,HCPSND,HCPCLY,SPHW,
     1     SPHICE,SPHVEG,SPHAIR,RHOW,RHOICE,TCGLAC,CLHMLT,CLHVAP
C
      COMMON /CLASS1/ DELT,TFREZ
      COMMON /CLASS4/ HCPW,HCPICE,HCPSOL,HCPOM,HCPSND,HCPCLY,
     1                SPHW,SPHICE,SPHVEG,SPHAIR,RHOW,RHOICE,
     2                TCGLAC,CLHMLT,CLHVAP
C-----------------------------------------------------------------------
C     * DETERMINE POINTS WHICH SATISFY CONDITIONS FOR THESE CALCULATIONS
C     * AND STORE THEM AS HAVING NON-ZERO VALUES FOR WORK ARRAY "IGRD".
C     * NOTE THAT POINTS WHICH GO THROUGH THE ROUTINE "GRINFL" SHOULD
C     * NOT GO THROUGH THIS ROUTINE WHEN IT IS CALLED FROM CLASSW.
C     * THE INPUT ARRAY "IGRN" HANDLES THIS CONDITION (PASSED AS
C     * "IZERO" ARRAY WHEN CALLED FROM "WEND" OR THE END OF "GRINFL"). 
C
      DO 50 I=IL1,IL2
          IF(FI (I).GT.0. .AND. 
     1       ISAND(I,1).GT.-4 .AND.DT(I).GT.0. .AND.IGRN(I).EQ.0 .AND.
     2       (R(I).LT.1.0E-12 .AND. ZPOND(I).LT.1.0E-12))           THEN
              IGRD(I)=1
          ELSE
              IGRD(I)=0
          ENDIF
   50 CONTINUE
C
C     * CALCULATE MAXIMUM LIQUID WATER CONTENT OF EACH SOIL LAYER;
C     * ADJUST GRKSAT FOR VISCOSITY OF WATER AND PRESENCE OF ICE;
C     * ADJUST THPOR FOR PRESENCE OF ICE.
C
      DO 100 J=1,IG
      DO 100 I=IL1,IL2
          IF(IGRD(I).GT.0. .AND. ISAND(I,J).GT.-3)             THEN
              THLMAX(I,J)=MAX((THPOR(I,J)-THICE(I,J)-0.00001),
     1            THLIQ(I,J),THLMIN(I,J))                
              GRKSATF(I,J)=GRKSAT(I,J)*(1.0-MAX(0.0,MIN(1.0,THICE(I,J)/
     1            THPOR(I,J))))**2
              THPORF(I,J)=THLMAX(I,J)
          ELSE
              THLMAX(I,J)=0.0
              GRKSATF(I,J)=0.0
              THPORF(I,J)=0.0
          ENDIF
  100 CONTINUE
C
C     * CALCULATE THEORETICAL FLOW RATES AT BOTTOM OF SOIL COLUMN AND
C     * BETWEEN SOIL LAYERS.

      DO 150 I=IL1,IL2
          IF(IGRD(I).GT.0)                                          THEN
             FDT(I,1)=-EVAP(I)*DT(I)                                                           
             IF(DELZW(I,IG).GT.0.0001)                            THEN
                 IF(THLIQ(I,IG).GT.THLRET(I,IG))              THEN
                     FDT(I,IG+1)=GRKSATF(I,IG)*DT(I)*XDRAIN(I)*
     1                   ((THLIQ(I,IG)/THPORF(I,IG))**(2.*BI(I,IG)+3.))
                 ELSE                                                                        
                     FDT(I,IG+1)=0.0                                                           
                 ENDIF
             ELSE                                                                        
                FDT(I,IG+1)=0.0                                                           
             ENDIF                                                                       
          ENDIF
  150 CONTINUE
C
      DO 200 J=1,IG-1                                                             
      DO 200 I=IL1,IL2
          IF(IGRD(I).GT.0)                                          THEN
              IF(THPOR(I,J).GT.0.0.AND.THPOR(I,J+1).GT.0.0.AND.
     1                  ISAND(I,J+1).GT.-3)            THEN
                  IF(DELZW(I,J+1).GT.DELZW(I,J)) THEN
                      THPBND=(THPORF(I,J)+THPORF(I,J+1))/2.0
                      THLBND=(THLIQ(I,J)+THLIQ(I,J+1))/2.0                                        
                      DTHLDZ=(THLIQ(I,J+1)-THLBND)/DELZW(I,J+1)+
     1                       (THLBND-THLIQ(I,J))/DELZW(I,J)
                  ELSE
                      DTHLDZ=2.0*(THLIQ(I,J+1)-THLIQ(I,J))/
     1                       (DELZW(I,J+1)+DELZW(I,J))
                      THLBND=THLIQ(I,J)+0.5*DTHLDZ*DELZW(I,J)
                      DTHPDZ=2.0*(THPORF(I,J+1)-THPORF(I,J))/
     1                       (DELZW(I,J+1)+DELZW(I,J))
                      THPBND=THPORF(I,J)+0.5*DTHPDZ*DELZW(I,J)
                  ENDIF
                  BBND=(BI(I,J)+BI(I,J+1))/2.0
C                  GRSBND=GRKSAT(I,J)**(DELZW(I,J)/(DELZW(I,J)+
C     1                DELZW(I,J+1)))*GRKSAT(I,J+1)**(DELZW(I,J+1)/
C     2                (DELZW(I,J)+DELZW(I,J+1)))
                  GRSBND=GRKSATF(I,J)*GRKSATF(I,J+1)*(DELZW(I,J)+
     1                DELZW(I,J+1))/(GRKSATF(I,J)*DELZW(I,J+1)+
     2                GRKSATF(I,J+1)*DELZW(I,J))
                  PSSBND=PSISAT(I,J)**(DELZW(I,J)/(DELZW(I,J)+
     1                DELZW(I,J+1)))*PSISAT(I,J+1)**(DELZW(I,J+1)/
     2                (DELZW(I,J)+DELZW(I,J+1)))
                  GRK=MIN(GRSBND*(THLBND/THPBND)**(2.*BBND+3.),
     1                   GRSBND)                     
                  PSI=MAX(PSSBND*(THLBND/THPBND)**(-BBND),PSSBND)                          
                  FDT(I,J+1)=GRK*DT(I)*((-BBND*PSI*DTHLDZ/THLBND)+1.)
              ELSE
                  FDT(I,J+1)=0.0
              ENDIF
          ENDIF
  200 CONTINUE 
C                               
C     * CHECK FOR SUSTAINABLE EVAPORATION RATE FROM TOP SOIL LAYER; IF
C     * LIQUID WATER SUPPLY IS INSUFFICIENT, TRY TO REMOVE WATER FROM 
C     * FROZEN SOIL MOISTURE.
C
      IPTBAD=0                                        
      DO 250 J=1,IG                                                               
      DO 250 I=IL1,IL2
          IF(IGRD(I).GT.0 .AND. J.EQ.1 .AND. FDT(I,J).LT.0. .AND.
     1                          DELZW(I,J).GT.0.0)             THEN 
              THTEST(I,J)=THLIQ(I,J)+FDT(I,J)/DELZW(I,J)
              IF(THTEST(I,J).LT.THLMIN(I,J))             THEN
                  FDT(I,J)=FDT(I,J)+(THLIQ(I,J)-THLMIN(I,J))*
     1                DELZW(I,J)
                  THLIQ(I,J)=THLMIN(I,J)
                  WEXCES(I)=-FDT(I,J)                                                  
                  FDT(I,J)=0.0                                                      
                  THSUBL=WEXCES(I)*RHOW/(RHOICE*DELZW(I,J))
                  IF(THLIQ(I,J).GT.0.0)                 THEN
                      TBARW(I,J)=TBARW(I,J)-(CLHMLT*RHOICE*THSUBL)/ 
     1                           (HCPW*THLIQ(I,J)) 
                  ENDIF
                  IF(THSUBL.LE.THICE(I,J))              THEN
                      THICE(I,J)=THICE(I,J)-THSUBL
                  ELSE
                      THSUBL=THSUBL-THICE(I,J)
                      THICE(I,J)=0.0
                      QFG(I)=QFG(I)-FI(I)*THSUBL*RHOICE*DELZW(I,J)/
     1                       DELT
                      WLOST(I)=WLOST(I)+THSUBL*RHOICE*DELZW(I,J)
                  ENDIF
              ENDIF
              IF(THICE(I,J).LT.0.) IPTBAD=I
          ENDIF
C                                                    
C     * ENSURE THAT CALCULATED WATER FLOWS BETWEEN SOIL LAYERS DO NOT
C     * CAUSE LIQUID MOISTURE CONTENT OF ANY LAYER TO FALL BELOW THE
C     * RESIDUAL VALUE OR TO EXCEED THE CALCULATED MAXIMUM.
C
          IF(IGRD(I).GT.0 .AND. THLIQ(I,J).LE.(THLMIN(I,J)+0.00001)) 
     1                                                            THEN 
              IF(FDT(I,J).LE.0. .AND. FDT(I,J+1).GE.0.)      THEN                          
                  FDT(I,J)=0.0    
                  FDT(I,J+1)=0.0   
              ELSE IF(FDT(I,J).GE.0. .AND. FDT(I,J+1).GT.0.) THEN                      
                  FDT(I,J+1)=0.0 
              ELSE IF(FDT(I,J).LT.0. .AND. FDT(I,J+1).LE.0.) THEN                      
                  FDT(I,J)=0.0    
              ENDIF
          ENDIF   
          IF(IGRD(I).GT.0. .AND. ISAND(I,J).EQ.-2 .AND. 
     1                           THLIQ(I,J).LE.THLRET(I,J))    THEN
              IF(FDT(I,J+1).GT.0.0) FDT(I,J+1)=0.0
          ENDIF
  250 CONTINUE    
C
      IF(IPTBAD.NE.0)                                           THEN
          WRITE(6,6500) IPTBAD,JL,IVEG,THICE(IPTBAD,1)
 6500     FORMAT('0AT (I,J)=(',I3,',',I3,'), IVEG=',I2,' THICE(1)= ',
     1            E13.5)
          CALL XIT('GRDRAN',-1)
      ENDIF
C
      DO 300 J=IG,1,-1                                                            
      DO 300 I=IL1,IL2
          IF(IGRD(I).GT.0 .AND. THLIQ(I,J).GE.(THLMAX(I,J)-0.00001)) 
     1                                                            THEN 
              IF(FDT(I,J).GE.0. .AND. FDT(I,J+1).LE.0.)      THEN                          
                  FDT(I,J)=0.0                                                      
                  FDT(I,J+1)=0.0                                                    
              ELSE IF(FDT(I,J).GT.0. .AND. FDT(I,J+1).GE.0.) THEN                      
                  IF(FDT(I,J).GT.FDT(I,J+1)) FDT(I,J)=FDT(I,J+1)                          
              ELSE IF(FDT(I,J).LE.0. .AND. FDT(I,J+1).LT.0.) THEN                      
                  IF(FDT(I,J+1).LT.FDT(I,J)) FDT(I,J+1)=FDT(I,J)                          
              ENDIF                                                               
          ENDIF                                                                   
  300 CONTINUE
C
      DO 400 J=1,IG                                                               
      DO 400 I=IL1,IL2
          IF(IGRD(I).GT.0.AND.ISAND(I,J).NE.-3)                     THEN
              THTEST(I,J)=THLIQ(I,J)+(FDT(I,J)-FDT(I,J+1))/DELZW(I,J) 
              IF(ISAND(I,J) .EQ. -2 .AND. J .NE. 1)        THEN
                  THLTHR=MIN(THLRET(I,J),THLIQ(I,J))
              ELSE
                  THLTHR=THLMIN(I,J)
              ENDIF
              IF(THTEST(I,J).LT.THLTHR)                             THEN
                  IF(FDT(I,J+1).GT.0.) THEN                      
                      FDT(I,J+1)=FDT(I,J)+(THLIQ(I,J)-THLTHR)*
     1                    DELZW(I,J)  
                  ELSE 
                      FDT(I,J)=FDT(I,J+1)-(THLIQ(I,J)-THLTHR)*
     1                    DELZW(I,J)  
                  ENDIF
                  THTEST(I,J)=THLTHR
                  IF(J.LT.IG) THEN
                      IF(DELZW(I,J+1).GT.0.0) THTEST(I,J+1)=THLIQ(I,J+1)
     1                    +(FDT(I,J+1)-FDT(I,J+2))/DELZW(I,J+1)
                  ENDIF
                  IF(J.GT.1) THEN
                      IF(DELZW(I,J-1).GT.0.0) THTEST(I,J-1)=THLIQ(I,J-1)
     1                    +(FDT(I,J-1)-FDT(I,J))/DELZW(I,J-1)
                  ENDIF
              ENDIF                                                                   
          ELSE
              THTEST(I,J)=0.0
          ENDIF
  400 CONTINUE               
C
      DO 500 J=IG,1,-1                                                            
      DO 500 I=IL1,IL2
          IF(IGRD(I).GT.0 .AND. THTEST(I,J).GT.THLMAX(I,J))         THEN
             WLIMIT=MAX((THLMAX(I,J)-THLIQ(I,J)),0.0)*DELZW(I,J)                      
             WEXCES(I)=(THTEST(I,J)-THLMAX(I,J))*DELZW(I,J)                                
             IF(FDT(I,J).GE.0. .AND. FDT(I,J+1).LE.0.)        THEN                          
                IF(FDT(I,J).GE.WLIMIT)             THEN                                       
                   FDT(I,J)=WLIMIT                                               
                   FDT(I,J+1)=0.0                                                
                ELSE                                                            
                   FDT(I,J+1)=FDT(I,J)-WLIMIT                                      
                ENDIF                                                           
             ELSE IF(FDT(I,J).GT.0. .AND. FDT(I,J+1).GE.0.)   THEN                      
                FDT(I,J)=FDT(I,J)-WEXCES(I)                                            
             ELSE IF(FDT(I,J).LE.0. .AND. FDT(I,J+1).LT.0.)   THEN                      
                FDT(I,J+1)=FDT(I,J+1)+WEXCES(I)                                        
             ENDIF                                                               
             DO 450 K=1,IG
                 IF(DELZW(I,K).GT.0.0)                            THEN
                     THTEST(I,K)=THLIQ(I,K)+(FDT(I,K)-FDT(I,K+1))/
     1                           DELZW(I,K)                    
                 ENDIF
  450        CONTINUE
         ENDIF                                                                   
  500 CONTINUE
C
      IPTBAD=0
      DO 600 I=IL1,IL2
          IF(IGRD(I).GT.0)                                        THEN
              IF(FDT(I,IG+1).LT.0.)                         THEN
                  WEXCES(I)=-FDT(I,IG+1)
                  DO 550 J=1,IG+1
                      FDT(I,J)=FDT(I,J)+WEXCES(I)
  550             CONTINUE
                  THSUBL=WEXCES(I)*RHOW/(RHOICE*DELZW(I,1))                                     
                  IF(THLIQ(I,1).GT.0.0)               THEN
                      TBARW(I,1)=TBARW(I,1)-(CLHMLT*RHOICE*THSUBL)/
     1                           (HCPW*THLIQ(I,1))                
                  ENDIF
                  IF(THSUBL.LE.THICE(I,1))            THEN
                      THICE(I,1)=THICE(I,1)-THSUBL                                        
                  ELSE
                      THSUBL=THSUBL-THICE(I,1)
                      THICE(I,1)=0.0
                      QFG(I)=QFG(I)-FI(I)*THSUBL*RHOICE*DELZW(I,1)/
     1                       DELT
                      WLOST(I)=WLOST(I)+THSUBL*RHOICE*DELZW(I,1)
                  ENDIF
                  IF(THICE(I,1).LT.0.0) IPTBAD=I
              ENDIF                                                                       
C
C     * CALCULATE DRAINAGE FROM BOTTOM OF SOIL COLUMN AND RE-EVALUATE
C     * SOIL LAYER TEMPERATURES AND LIQUID MOISTURE CONTENTS AFTER
C     * WATER MOVEMENT.
C
              TFDT(I,1)=TBARW(I,1) 
              TFDT(I,IG+1)=TBARW(I,IG)
              IF(FDT(I,IG+1).GT.0.0) THEN
                  IF((BASFLW(I)+FI(I)*FDT(I,IG+1)).GT.0.0) 
     1              TBASFL(I)=(TBASFL(I)*BASFLW(I)+(TFDT(I,IG+1)+TFREZ)*
     2                FI(I)*FDT(I,IG+1))/(BASFLW(I)+FI(I)*FDT(I,IG+1))
                  BASFLW(I)=BASFLW(I)+FI(I)*FDT(I,IG+1)
                  IF((RUNOFF(I)+FDT(I,IG+1)).GT.0.0) 
     1              TRUNOF(I)=(TRUNOF(I)*RUNOFF(I)+(TFDT(I,IG+1)+TFREZ)*
     2                FDT(I,IG+1))/(RUNOFF(I)+FDT(I,IG+1))
                  RUNOFF(I)=RUNOFF(I)+FDT(I,IG+1)
              ENDIF
          ENDIF
  600 CONTINUE
C
      IF(IPTBAD.NE.0)                                           THEN
          WRITE(6,6500) IPTBAD,JL,IVEG,THICE(IPTBAD,1)
          CALL XIT('GRDRAN',-3)
      ENDIF
C                                                      
      DO 700 J=1,IG
      DO 700 I=IL1,IL2
          IF(IGRD(I).GT.0)                                          THEN
             IF(J.LT.IG)                               THEN
                IF(FDT(I,J+1).GT.0.)          THEN                                                
                   TFDT(I,J+1)=TBARW(I,J)                                                  
                ELSE                                                                    
                   TFDT(I,J+1)=TBARW(I,J+1)                                                
                ENDIF                                                                   
             ENDIF
             IF(THTEST(I,J).GT.0.0 .AND. DELZW(I,J).GT.0.0)    THEN
                 TBARW(I,J)=(THLIQ(I,J)*TBARW(I,J)+(FDT(I,J)*TFDT(I,J)-
     1                      FDT(I,J+1)*TFDT(I,J+1))/DELZW(I,J))/
     2                      THTEST(I,J)                                       
             ENDIF
             THLIQ(I,J)=THTEST(I,J)
          ENDIF                                                      
  700 CONTINUE                                                                    
C                                                                                  
      RETURN                                                                      
      END        
