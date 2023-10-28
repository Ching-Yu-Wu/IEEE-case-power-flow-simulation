% This program is to solve power flow of a 5-bus power system (Steven's book)

% 

	format long e;
	clear;

%      1. Load parameters

	NB = 9; 			% number of buses
   	NPV = 2; 			% number of PV bus
   	NX = 2*NB-NPV-2;    % number of unknown variables of V and beta 
   	BMVA = 100.0;	    % base MVA
   	EPS = 1.0e-6;   	% error tolerance
    RTOD = 180.0/pi;	% radian to degree conversion
    i = sqrt(-1);		% define j or i 
      
    for NI = 1:NB
        for NJ = 1:NB
            CHVA(NI, NJ) = 0.0; % clear charging VA, line impedances, and [Ybus]
            ZL(NI, NJ) = 0.0 + i*0.0;
            YB(NI, NJ) = 0.0 + i*0.0;
        end
    end
      
 %     2. load charging VA between buses
      
     CHVA(4,5) = 0.088; CHVA(4,6) = 0.079; CHVA(5,7) = 0.153; CHVA(6,9) = 0.179; CHVA(7,8) = 0.0745; CHVA(8,9) = 0.1045;
     
 %     3. load line impedances
     
     ZL(1,4) = i*0.0576;       ZL(2,7) = i*0.0625;         ZL(3,9) = i*0.0568;
     ZL(4,5) = 0.01 + i*0.085; ZL(4,6) = 0.017 + i*0.092;  ZL(5,7) = 0.032 + i*0.161;
     ZL(6,9) = 0.039 + i*0.17; ZL(7,8) = 0.0085 + i*0.072; ZL(8,9) = 0.0119 + i*0.1008;

%      4. load bus type: 1 for swing bus, 2 for PV bus , 3 for PQ bus(Load bus)
        
     BT(1)= 1; BT(2) = 2; BT(3) = 2;  BT(4) = 3;  BT(5) = 3; BT(6)= 3; BT(7) = 3; BT(8) = 3;  BT(9) = 3; 
        
%     5. load each bus's PG, QG, PL, QL, V, ANG
 

     PG(1) = 0.0;  PG(2) = 163.0;  PG(3) = 85.0;  PG(4) = 0.0;  PG(5) = 0.0;   PG(6) = 0.0;  PG(7) = 0.0;  PG(8) = 0.0;   PG(9) = 0.0;

     QG(1) = 0.0;  QG(2) = 0.0;    QG(3) = 0.0;   QG(4) = 0.0;  QG(5) = 0.0;   QG(6) = 0.0;  QG(7) = 0.0;  QG(8) = 0.0;   QG(9) = 0.0;
 
     PL(1) = 0.0;  PL(2) = 0.0;    PL(3) = 0.0;   PL(4) = 0.0;  PL(5) = 125.0; PL(6) = 90.0; PL(7) = 0.0;  PL(8) = 100.0; PL(9) = 0.0;

     QL(1) = 0.0;  QL(2) = 0.0;    QL(3) = 0.0;   QL(4) = 0.0;  QL(5) = 50.0;  QL(6) = 30.0; QL(7) = 0.0;  QL(8) = 35.0;  QL(9) = 0.0;

     V(1) = 1.04;  V(2) = 1.025;   V(3) = 1.025;  V(4) = 1.0;   V(5) = 1.0;    V(6) = 1.0;   V(7) = 1.0;   V(8) = 1.0;    V(9) = 1.0;

     ANG(1) = 0.0; ANG(2) = 0.0;   ANG(3) = 0.0;  ANG(4)=0.0;   ANG(5) = 0.0;  ANG(6) = 0.0; ANG(7) = 0.0; ANG(8) = 0.0;  ANG(9) = 0.0;
                
%     6. formulate [Ybus]

        for NI = 1:NB
          for NJ = 1:NB

            if ZL(NI,NJ) ~= 0.0 + i*0.0 
                YB(NI,NI)=YB(NI,NI) + 1.0/ZL(NI,NJ);
                YB(NJ,NJ)=YB(NJ,NJ) + 1.0/ZL(NI,NJ);
                YB(NI,NJ)= -1.0/ZL(NI,NJ);
                YB(NJ,NI)=YB(NI,NJ);
            end
           
           
            if CHVA(NI,NJ) ~= 0.0 
        	    YB(NI,NI) = YB(NI,NI) + i*CHVA(NI,NJ);
        	    YB(NJ,NJ) = YB(NJ,NJ) + i*CHVA(NI,NJ);
%               YB(NI,NI) = YB(NI,NI) + i*CHVA(NI,NJ)/(2.0*BMVA);
%         	    YB(NJ,NJ) = YB(NJ,NJ) + i*CHVA(NI,NJ)/(2.0*BMVA);
            end

          end
        end

%      7. PREPARE X VECTOR

        NA = 0;   % initial NO. OF ANGLE VARIABLES
        NV = 0;   % initial NO. OF VOLTAGE VARIABLES

        for  NI = 1:NB
          if BT(NI) == 2 % PV bus: only beta is unknown
                NA = NA+1;  NXA(NA) = NI;
          end
          
          if BT(NI) == 3  % load bus: |V| and beta are unknows 
                NA = NA + 1;   NXA(NA) = NI; NV = NV + 1;  NXV(NV) = NI;
          end
        end

%      8.  SAVE X WITH INITIAL VALUES

        for NI = 1:NA;  XX(NI) = ANG(NXA(NI));  end

        for NI = 1:NV;  XX(NA+NI) = V(NXV(NI)); end

        NITER = 0; % clear no. of iteration

%      9. NEWTON-RAPHSON's LOOP is HERE

   FLAG = 1;
        
   while FLAG == 1 % FLAG = 0 denotes all errors are less than EPS

          for NI=1:NA;  ANG(NXA(NI)) = XX(NI); end % load angle variables

          for NI=1:NV; V(NXV(NI)) = XX(NA+NI); end % load |V| variables

%      10. FIND BUS P AND Q

        for NI=1:NB
          P(NI)=0.0;   Q(NI)= 0.0;
          for NJ=1:NB
             
             P(NI) = P(NI) + V(NI)*V(NJ)*(real(YB(NI,NJ))*cos((ANG(NI)-ANG(NJ))/RTOD) ...
                                                               + imag(YB(NI,NJ))*sin((ANG(NI)-ANG(NJ))/RTOD));
             
             Q(NI) = Q(NI) + V(NI)*V(NJ)*(real(YB(NI,NJ))*sin((ANG(NI)-ANG(NJ))/RTOD)...
                                                           - imag(YB(NI,NJ))*cos((ANG(NI)-ANG(NJ))/RTOD));
          end
        end
       
%      11. check errors of buses' P and Q
       
        for NI= 1:NA; FX(NI) = (PG(NXA(NI)) - PL(NXA(NI)))/BMVA - P(NXA(NI));  end

        for NI = 1:NV; FX(NA+NI) = (QG(NXV(NI))-QL(NXV(NI)))/BMVA - Q(NXV(NI));  end

         NI = 1;
         FLAG = 0;      
         
         while NI < NX 
            if abs(FX(NI)) >  EPS; FLAG = 1; NI = NX;  end
            NI = NI +1;
         end
            
%      12. JACOBIAN MATRIX CREATION
% [J11]

if FLAG ==1
   
      for NI=1:NA
        for NJ=1:NA

        NII = NXA(NI);  NJJ=NXA(NJ);

        if NII ~= NJJ   % PARTIAL P-I/PARTIAL THETA-J
           J(NI,NJ) = V(NII)*V(NJJ)*(real(YB(NII,NJJ))*sin((ANG(NII)-ANG(NJJ))/RTOD)...
              					        - imag(YB(NII,NJJ))*cos((ANG(NII)-ANG(NJJ))/RTOD));
        else                     % PARTIAL P-I/PARTIAL THETA-I
           
           J(NI,NJ) = 0.0;
           for NK=1:NB
              if NK ~= NII 
                  J(NI,NJ) = J(NI,NJ) + V(NII)*V(NK)*(-real(YB(NII,NK))*sin((ANG(NII)-ANG(NK))/RTOD)...
               									  + imag(YB(NII,NK))*cos((ANG(NII)-ANG(NK))/RTOD));
              end
           end
        end

        end
      end

% [J12]

    for NI=1:NA
        for NJ=1:NV

        NII = NXA(NI);   NJJ=NXV(NJ);

        if NII == NJJ				%PARTIAL P-I/PARTIAL V-I
                J(NI,NA+NJ) = 0.0;
            for NK=1:NB
               if NII ~= NK 
                J(NI,NA+NJ) = J(NI,NA+NJ) + V(NK)*(real(YB(NII,NK))*cos((ANG(NII)-ANG(NK))/RTOD)...
                                         + imag(YB(NII,NK))*sin((ANG(NII)-ANG(NK))/RTOD));
               end
            end
                J(NI,NA+NJ) = J(NI,NA+NJ) + 2.0*V(NII)*real(YB(NII,NII));
       else                            %PARTIAL P-I/PARTIAL V-J
                J(NI,NA+NJ) = V(NII)*(real(YB(NII,NJJ))*cos((ANG(NII)-ANG(NJJ))/RTOD)...
                       					+ imag(YB(NII,NJJ))*sin((ANG(NII)-ANG(NJJ))/RTOD));
        end

        end
    end

% [J21]

        for NI=1:NV
           for NJ=1:NA

        NII =NXV(NI);   NJJ=NXA(NJ);

        if NII == NJJ    			%	PARTIAL Q-I/PARTIAL THETA-I
                J(NA+NI,NJ) = 0.0;
            for NK=1:NB
              if NII ~= NK 
                J(NA+NI,NJ) = J(NA+NI,NJ) + V(NII)*V(NK)*(real(YB(NII,NK))*cos((ANG(NII)-ANG(NK))/RTOD)...
                       + imag(YB(NII,NK))*sin((ANG(NII)-ANG(NK))/RTOD));
              end
            end
        else                            		%PARTIAL Q-I/PARTIAL THETA-J
                J(NA+NI,NJ) = -V(NII)*V(NJJ)*(real(YB(NII,NJJ))*cos((ANG(NII)-ANG(NJJ))/RTOD)...
                       							+ imag(YB(NII,NJJ))*sin((ANG(NII)-ANG(NJJ))/RTOD));
        end

           end
        end

% [J22]

        for NI=1:NV
        	for NJ=1:NV

                NII = NXV(NI);  NJJ=NXV(NJ);
    
                if NII ~= NJJ   %PARTIAL Q-I/PARTIAL THETA-J
                    J(NA+NI,NA+NJ) = V(NJJ)*(real(YB(NII,NJJ))*sin((ANG(NII)-ANG(NJJ))/RTOD)...
     						                       -imag(YB(NII,NJJ))*cos((ANG(NII)-ANG(NJJ))/RTOD));
                else                    %  PARTIAL Q-I/PARTIAL V-I
                    J(NA+NI,NA+NJ) = 0.0;
                    for NK=1:NB
                          if NK ~= NII
                               J(NA+NI,NA+NJ) = J(NA+NI,NA+NJ)+V(NK)*(real(YB(NII,NK))*sin((ANG(NII)-ANG(NK))/RTOD)...
                  										            - imag(YB(NII,NK))*cos((ANG(NII)-ANG(NK))/RTOD));
                          end
                    end
                    J(NA+NI,NA+NJ) = J(NA+NI,NA+NJ) - 2.0*V(NII)*imag(YB(NII,NII));
                end
    
            end
        end

        INVJ = inv(J);

        for NI=1:NX
            DX(NI) = 0.0;
            for NJ=1:NX
                DX(NI) = DX(NI) + INVJ(NI,NJ)*FX(NJ);
            end
        end
        
        DX
        
        for NI = 1:NX;   XX(NI) = XX(NI) + DX(NI);   end
	NITER = NITER + 1;
   
end  % if
   end % while
     
   for NI=1:NB
      if BT(NI) == 1 
                PG(NI) = P(NI)*BMVA + PL(NI);     QG(NI) = Q(NI)*BMVA + QL(NI);
      end
             
          if BT(NI) == 2, QG(NI) = Q(NI)*BMVA + QL(NI); end    
   end

          % disp(' BUS NAME TYPE  VOLTAGE ANGLE PG  QG  PL QL  ')

       for NI=1:NB
          %disp('NI', NI)
          %disp('V(NI)') 
          %ANG(NI)-*RTOD
          V(NI)
          ANG(NI)
          PG(NI) 
          QG(NI)
          PL(NI) 
          QL(NI)
          SUM = [V' ANG' PG' QG' PL' QL'];
       end
     