      subroutine watrof(isfc,THLIQ,THICE,ZPOND,TPOND,OVRFLW,TOVRFL,
     1                  SUBFLW,TSUBFL,BASFLW,TBASFL,RUNOFF,TRUNOF,FI,
     2                  ZPLIM,XSLOPE,XDRAIN,MANNING_N,DDEN,GRKSAT,TBARW,
     3                  DELZW,THPOR,THLMIN,BI,DODRN,DOVER,DIDRN,
     4                  ISAND,IWF,IG,ILG,IL1,IL2,BULKFC,
     5                  NA,NTYPE,ILMOS,JLMOS)
      USE FLAGS
      IMPLICIT NONE                         

ctest diary 
c22may15 - ric       
c  v2: 1000.0*smax
c  v2: bcof: 2*b+2 replaced by 2*b+3
c  v2: ratio = 1.0      
************************************************************************************************************
*     WATROF2 *** DRAFT VERSION 2.0 *** 01.JUNE.2015 *** Ric Soulis *** Mateusz Tinel                      *
************************************************************************************************************
c
c     This routine calculates the outflow from a tilted landscape element (TILE). This code is a replacement
c     for WATDRN and WATROF.
      
c     In WATROF2 the shape of typical recession curve is postulated to be a consequence of the decline in
c     in conductivity with degree of saturation. Starting from saturation, the flow continues at maximum
c     value Qmax until the largest pores stop flowing due to suction. Flow continues at near saturation
c     rate, while the saturation curvature changes from negative to positive curvature . This produces a 
c     recession curve pattern shown below. The curve can be conveniently represented 
c     by Q = qmax*min(1.0, seffective^Qcof). Baseflow is based on the average saturation of the element, 
c     represented by bmax*effective^bcof.
      
c     In contrast, WATDRN and WATROF are based on decline in conductivity with depth 
      
c     WATROF2 computes overland flow, interflow, and baseflow.
c     It relies on CLASSW and its various routines to compute for vertical flow.
c     Normally, DRNROW is set to zero so all baseflow is generated by WATROF2.

c                    SATURATION A FUNCTION OF TIME
      
c     |*                                                          | - asat saturation 1.0
c     |+*                                                         |
c     |+ *                                                        |
c     |+  *                                                       |
c     | +  *                                                      |
c  S  | +   *                                                     |
c  A  | +    *                                                    |
c  T  |  +    *                                                   |
c  U  |  +     *                                                  | - asat saturation sta, s saturation 1.0
c  R  |   +     **                                                |
c  A  |    +      **                                              |
c  T  |     +       **                                            |
c  I  |      +        **                                          |
c  O  |       +         **                                        |
c  N  |        ++         ***                                     |
c     |          ++          ***                                  |
c     |            +++          ***                               |
c     |               +++++        *****                          |
c     |                    ++++++       *****                     |
c     |                          +++++++++++ *******              | - asat saturation sfc, s saturatoin 0.0
c     |                                                           |
c     |__________________________________________________________ |
c      |               |                                           
c      time 0.0        time ta, s curve time 0.0                                           
c                                TIME 
      
c     Saturated flow is calculated using by a straight line: 
c         asat(t) = 1 - ((1 - sta)/ta)*t 
c     Time t1 at begining of time step can be calculated using this equation. When saturated flow ends at 
c     time = ta, unsaturated flow begins, that is calculated using by: 
c         s(t) = ((B - 1) * (Bmax * t + (1/(B - 1))))**(1/(1 - B))
c     For the curve, at time t = 0 saturation s = 1 everywhere, therefore the time must be corrected for 
c     the time spent on saturated flow which lasted for length of time = ta (so t = t2 - ta), if initial 
c     saturation asat1 happens during saturated flow. If asat1 happens during unsaturated flow then t1 can 
c     be determined using the initial saturation s1. asat can be connected to s using:
c         s = (asat - sfc)/(sta - sfc) since; 
c     if time = ta then asat = sta and the equation gives s = 1, when flow ends then asat = sfc and the 
c     equation gives s = 0. 
      
      
***** COMMON BLOCK PARAMETERS ******************************************************************************
      
      REAL DELT,TFREZ,delksat
      
      COMMON /CLASS1/ DELT,TFREZ 
      
***** INTERNAL SCALARS AND VECTORS *************************************************************************
      REAL*8  qflowij , bflowij            !interflow and base flow accumulator
      REAL*8  asat1ij , asat2ij , asat3ij  !initial, and final interflow and baseflow soil saturation
      REAL*8  bsat1ij , bsat2ij , bsat3ij  !initial, and final interflow and baseflow soil saturation
      REAL*8  stc     , sta                !soil saturation at end of pure and apparent saturated flow
      REAL*8  sfc                          !lowest soil saturation possible due to drainage
      REAL*8  satmin  , satice             !minimal soil saturation and soil saturation with ice
      REAL*8  t1      , t2      , tb1, tb2 !initial, and final interflow and baseflow time
      REAL*8  tc      , ta                 !time at end of pure saturated and apparent saturated flow
      REAL*8  s1,sb1  , s2,sb2  , s3,sb3   !initial, intermediate and final soil saturation
      REAL*8  qmax    , bmax    , smax     !max flow for interflow, baseflow and overland flow
      REAL*8  qcof    , bcof    , scof     !coefficient for interflow, baseflow and overland flow
      REAL*8  xlengthi, xbasei  , xheighti !geometric properties of the tile
      REAL*8  h       , sslopei            !soil depth and slope
      REAL*8  avlflw  , potflw  , actadj   !available and potential flow, and actual flow correction
      REAL*8  dover1  , dover2             !initial and final overlanf flow level
      
***** INTERNAL AND INPUT INTEGERS **************************************************************************
      INTEGER IWF, IWD, IG, ILG, IL1, IL2, NA, NTYPE 
      INTEGER ILMOS (ILG), JLMOS (ILG)
      INTEGER ISAND  (ILG, IG), isandij    !SAND PERCENT 0-100
      INTEGER CLAY   (ILG, IG), clayij     !CLAY PERCENT 0-100
      INTEGER i, j, isfc, op1, op2
      
***** INPUT ARRAYS AND VECTORS ******************************************************************************
      REAL    BI     (ILG, IG), biij
      REAL    BULKFC (ILG, IG), bulkfcij
      REAL    DELZW  (ILG, IG), delzwij
      REAL    DIDRN  (ILG, IG)
      REAL    GRKSAT (ILG, IG), grksatij , grksatij0, grksatij1 !is mean cross-sectional velocity (m/s) 
      REAL    PSISAT (ILG, IG), psisatij   !soil section TODO - NEED UNITS
      REAL    THICE  (ILG, IG), thiceij
      REAL    THLIQ  (ILG, IG), thliqij
      REAL    THLMIN (ILG, IG), thlminij
      REAL    THPOR  (ILG, IG), thporij    !porosity
      REAL    DDEN       (ILG), ddeni      !drainage density (m/m^2)
      REAL    DODRN      (ILG)
      REAL    DOVER      (ILG)
      REAL    FI         (ILG), fii
      REAL    MANNING_N  (ILG), manning_ni
      REAL    TPOND      (ILG), tpondi
      REAL    XDRAIN     (ILG), xdraini    !vertical lateral flow ratio
      REAL    XSLOPE     (ILG), xslopei    !valley slope
      REAL    ZPLIM      (ILG), zplimi
      REAL    ZPOND      (ILG), zpondi
      REAL    RATIO      (ILG), ratioi
      REAL    SDEPTH (NTYPE, IG)
      
***** OUTPUT ARRAYS ****************************************************************************************
      REAL    OVRFLW (ILG), ovrflwi        !overland flow
      REAL    SUBFLW (ILG), subflwi        !interflow
      REAL    BASFLW (ILG), basflwi        !baseflow
      REAL    RUNOFF (ILG)                 !runoff
      
***** UNUSED VARIABLES *************************************************************************************
      REAL    TBARW (ILG, IG)
      REAL    TOVRFL    (ILG),tovrfli
      REAL    TSUBFL    (ILG),tsubfli
      REAL    TBASFL    (ILG),tbasfli
      REAL    TRUNOF    (ILG),trunofi
      
C----------------------------------------------------------------------C
C     USE FLAGS IWF AND IWD                                            C
C----------------------------------------------------------------------C
!>    * IF IWF = 0, ONLY OVERLAND FLOW AND BASEFLOW ARE MODELLED, AND
!>    * THE GROUND SURFACE SLOPE IS NOT MODELLED.
!>    * IF IWF = 1, THE MODIFIED CALCULATIONS OF OVERLAND
!>    * FLOW AND INTERFLOW ARE PERFORMED.
!>    * IF IWF = 2, SAME AS IWF = 0 EXCEPT THAT OVERLAND FLOW IS
!>    * MODELLED AS FILL AND SPILL PROCESS FROM A SERIES OF POTHOLES.
!>    * DEFAULT VALUE IS 1.

ctest  force iwf to 1 
c      if (IWF.NE.1) then
c          pause "WARNING: WATROF2 is not used, setting flag IWF to 1"
c          iwf = 1
          !return
c     endif

************************************************************************************************************
      do i = il1,il2
      
C--------------------------------------------------------------------  C
C     clear accumulators                                               C
C----------------------------------------------------------------------C
      ovrflwi = 0.0
      subflwi = 0.0
      basflwi = 0.0
      
      fii = FI(i)
      
      if (fii .gt. 0.0) then
      
C----------------------------------------------------------------------C
C     GEOMETRY OF TILE                                                 C
C----------------------------------------------------------------------C
      ddeni    = DDEN(i)
      xlengthi = 1.0/(2*ddeni)
      xslopei  = xslope(i)
      sslopei  = atan(xslopei)
      xbasei   = xlengthi * cos(sslopei)
      xheighti = xlengthi * sin(sslopei)
      xdraini  = xdrain(i)
      
C----------------------------------------------------------------------C
C     RATIO Q                                                          C
C----------------------------------------------------------------------C
      ratioi   = 1.0    
      
C----------------------------------------------------------------------C
C     OVERLAND FLOW PARAMETERS                                         C
C----------------------------------------------------------------------C
      zpondi     = ZPOND(i)      
      zplimi     = ZPLIM(i)
      manning_ni = MANNING_N(i)
      tpondi     = tpond(i)

      
************************************************************************************************************
        do j = 1,IG
            
C----------------------------------------------------------------------C
C     CLEAR ACCUMULATORS                                               C
C----------------------------------------------------------------------C
        qflowij = 0.0
        bflowij = 0.0

C----------------------------------------------------------------------C
C     GET LAYER THICKNESS                                              C
C----------------------------------------------------------------------C
        h = DELZW(i,j)
        biij = bi(i,j)

C----------------------------------------------------------------------C
C       STATE VARIABLES - VALUES AT BEGINNING OF TIME STEP             C
C----------------------------------------------------------------------C
        thlminij   = THLMIN(i,j)
        thliqij    = THLIQ(i,j)
        thporij    = THPOR(i,j)
        thiceij    = THICE(i,j)
        isandij    = isand(i,j)
        
C----------------------------------------------------------------------C
C      CHECK CONDIRIONS AT BEGINNING OF TIME STEP                      C
C----------------------------------------------------------------------C
       if(xslopei>0.0.and.isand(i,j)>=0.and.biij>0.0)then

C----------------------------------------------------------------------C
C     soil texture and pedotransfer functions  - isand : 0..100)       C                          C
C----------------------------------------------------------------------C
       bulkfcij = bulkfc(i,j)
       psisatij = 0.01*(10.0**(-0.0131*isandij+1.88))
       grksatij = (1.0*3600./39.37)*(10.0**(0.0153*isandij-0.884))

c----------------------------------------------------------------------c
c     future: adjust hydraulic conductivity for temperature
c     conventional decrease in viscosity is about 30% over 100k
c----------------------------------------------------------------------c     
c      delksat = 0.3/100.0
c      grksatij0 = (1.0*3600./39.37)*(10.0**(0.0153*isandij-0.884))
c      grksatij = grksatij0*(1.0+(tsubfl(i)-tfrez)*delksat*0)
c      if (tsubfl(i).ne.0.0)then
c        print*,i,j,grksatij0,grksatij,isandij,tsubfl(i)
c      endif
************************************************************************************************************
C----------------------------------------------------------------------------------------------------------C
C     FIND POTENTIAL LATERAL FLOW - assume ice freezes uniformly as soil freeze                                                                         C
C----------------------------------------------------------------------------------------------------------C
      if (thliqij+thiceij.gt.bulkfcij.and.biij.gt.0.0) then
         
c         SECONDARY TILE PROPERTIES
         
c         qcof/bcof exponent for recession curve (B), (dimensionless, 4 for 0% clay, 6 for 30% clay)
c         qmax/bmax maximum flux (Bmax)
c         asat      is the actual saturation of the soil (asat1ij, asat2ij)
c         s         is the saturation of soil used for the curve (s1, s2)
c         t1        is the time at beginning of the time step
c         t2        is the time at the end of time step
c         tc        end time of pure saturation flow, beginng of a mixture unsaturated flow
c         ta        end of apparent saturation flow, beginning of sustantial unsaturated flow
c         stc       is bulk saturation when pure saturation flow ceases
c         sta       is bulk saturation when apparent saturation flow ceases
c         sfc/bfc   is the lowest possible bulk saturation, as time goes to infinity
c         satice    is the saturation with ice
c         satmin    is the minimum saturation
 
          qmax    = ratioi*grksatij*xslopei/xlengthi
c          qcof    = 4.0*(biij+2.0)/5.0
          qcof    = (biij + 2.0)/2.0
          sfc     = bulkfcij/thporij
          
          stc     = 1.0 - (2.0*biij + 5.0)/6.0
          tc      = (1.0 - stc)/qmax
          
          sta     = max(sfc,1.0 - 2.0/biij)
          ta      = (1.0 - sta)/qmax
          
          asat1ij = thliqij/thporij
          satice  = thiceij/thporij
          satmin  = thlminij/thporij
          
          s1 = min(1.0,max(0.0,(asat1ij - sfc)/(sta-sfc)))

C----------------------------------------------------------------------C
C     beginning of step - find starting storage
C     determine how much flux can exit this time step- units (kg/m**2/s)==mm/s
C----------------------------------------------------------------------C
C----------------------------------------------------------------------C
C     CASE (SAT - *) - PRIMARY SATURATED FLOW AT THE END OF TIME STEP  C
C----------------------------------------------------------------------C
          if (asat1ij .ge. sta) then
            t1 = ta*(1.0-asat1ij)/(1.0-sta)
            t2 = t1 + delt
            tb1 = t1
            tb2 = tb1 + delt
            
C----------------------------------------------------------------------C
C     case (sat-sat) - saturated flow at start and end of time step    C
C----------------------------------------------------------------------C
            if (t2 .le. ta) then
              asat2ij = 1.0-((1.0-sta)/ta)*t2
              
C----------------------------------------------------------------------C
C     case (sat-unsat) - unsaturated flow at end of time step          C
C----------------------------------------------------------------------C
            else
              s2 = ((qcof-1.0)*qmax*(t2-ta)+1.0)**(1.0/(1.0-qcof))
              asat2ij = s2*(sta-sfc)+sfc
            endif

C----------------------------------------------------------------------C
C    case (unsat-unsat) - unsaturated flow at both ends of the timestep
C----------------------------------------------------------------------C
          else 
            t1 = (s1**(1.0-qcof)-1.0)/((qcof-1.0)*(qmax))
            t2 = t1 + delt
            tb1 = t1 + ta
            tb2 = tb1 + delt
            s2 = ((qcof-1.0)*qmax*t2+1.0)**(1.0/(1.0-qcof))
            asat2ij = s2*(sta-sfc)+sfc
          endif
          
          asat2ij  = min(asat1ij, max(asat2ij, satmin))
          
C----------------------------------------------------------------------C
C     FIND POTENTIAL BASEFLOW (draw from bottom layer only)            C
C----------------------------------------------------------------------C
          if (j.lt.ig) then
            
            bflowij = 0.0
            bsat1ij = asat1ij
            bsat3ij = bsat1ij
            
C----------------------------------------------------------------------C
C     only case is: (u-u) - unsaturated at start and end of time step  C
C----------------------------------------------------------------------C
         else 
            
            bmax = grksatij
            bcof = (2.0*biij+3.0)
            
            sb1 = ((bcof-1.0)*bmax*t1+1.0)**(1.0/(1.0-bcof))
            sb2 = ((bcof-1.0)*bmax*t2+1.0)**(1.0/(1.0-bcof))
            
            bsat1ij = sb1*(1.0-sfc)+sfc
            bsat1ij  = min(1.0,max(bsat1ij, sfc))
            
            bsat3ij = sb2*(1.0-sfc)+sfc
            bsat3ij  = max(sfc,min(1.0,bsat1ij, bsat3ij))
            
c           alternate formula for interflow
c            bflowij = bmax/2*(bsat1ij**(bcof)+bsat3ij**(bcof))
c            bflowij = bflowij*delt
           bflowij = bsat1ij-bsat3ij
          endif
          
C----------------------------------------------------------------------C
C         determine how much flux can exit this time step              C
C         - units (kg/m**2/s)==mm/s                                    C
C----------------------------------------------------------------------C
          
C----------------------------------------------------------------------C
C         available liquid water                                       C
C----------------------------------------------------------------------C
          avlflw = asat1ij - max(satmin,sfc,satice)
          avlflw = min(max(avlflw,0.0),1.0)
      
C----------------------------------------------------------------------C
C         max possible outflow given physics of viscous flow           C
C----------------------------------------------------------------------C
          qflowij = max(0.0,min(1.0,(asat1ij-asat2ij)))

          
c          bflowij = max(0.0,min(1.0,(bsat1ij-bsat3ij)))*thporij
          potflw  = qflowij + bflowij
          asat1ij = asat1ij
          
         if (potflw .le. 0.0) then
           qflowij = 0.0
           bflowij = 0.0
           asat3ij = asat1ij

         elseif (avlflw .le. potflw) then
           actadj  = avlflw/potflw 
           qflowij = actadj*qflowij
           bflowij = actadj*bflowij
           asat3ij = asat1ij - qflowij - bflowij  
        
         else
           qflowij = qflowij
           bflowij = bflowij
           asat3ij = asat1ij - qflowij - bflowij  

         endif
                        
C----------------------------------------------------------------------C
C        collect and add totals to master silos                        C
C----------------------------------------------------------------------C
         subflwi = subflwi + qflowij * thporij *h
         basflwi = basflwi + bflowij * thporij *h
         thliq(i,j) = asat3ij * thporij

      endif
      endif
      

************************************************************************************************************
      enddo
************************************************************************************************************
      
C----------------------------------------------------------------------C
C     calculate the depth of overland flow                             C
C----------------------------------------------------------------------C
      ovrflwi = 0.0
      if (zpondi.gt.zplimi .and. zplimi.ge. 0.0  
     1    .and. manning_ni .gt. 0.0) then
        dover1    = zpondi-zplimi
        scof      = -2.0/3.0
        smax      = 1.0e3*(2.0*ddeni/manning_ni)*(xslopei**0.5)
        dover2    = (dover1**scof - scof*smax*delt)**(1.0/scof)
        dover2    = max(0.0, min(dover1, dover2))

        zpond(i)  = dover2 + zplimi
        ovrflwi   = (dover1 - dover2)
      else
        ovrflwi = 0.0
      endif
      
C----------------------------------------------------------------------C
C     revise flux totals - code to maintain temperature is included         C
C----------------------------------------------------------------------C
      
c     tovrfl(i) = tpond(i)
      ovrflw(i) = ovrflwi

c     trunof(i) = runoff(i)*trunof(i)  +ovrflwi*tpond(i) 
c    1          + subflwi*tsubfl(i) + basflwi*tbasfl(i)
      runoff(i) = runoff(i) + ovrflwi + subflwi + basflwi
c     if(runoff(i).gt.0.0)trunof(i)  = trunof(i)/runoff(i)
      
c     tsubfl(i) = subflw(i)*tsubfl(i) + subflwi*tovrfl(i)
      subflw(i) = subflw(i) + subflwi 
c     if(subflw(i).gt.0.0)tsubfl(i)  = tsubfl(i)/subflw(i)
c     tsubfl(i) = tsubfl(i)/subflw(i)
      
c     tbasfl(i) = tbasfl(i)*basflw(i) + basflwi*tsubfl(i)
      basflw(i) = basflw(i) + basflwi
c     print*, tovrfl(i),trunof(i),tsubfl(i),tbasfl(i)
      
      endif
      enddo
c     pause
************************************************************************************************************
      
      RETURN
      end