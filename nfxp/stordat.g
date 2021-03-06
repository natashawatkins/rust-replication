proc (1)=stordat;

"STORDAT.GPR: creates bus data file BDT.DAT for use by NFXP.GPR";
"Version 8, October, 2000. By John Rust, Yale University";"";

"This program prepares bus data from the Madison Metro Bus Co";
"for estimation using the nested fixed point algorithm. The program";
"reads the raw bus data files (*.FMT) producing an output file BDT.DAT";
"with fixed point dimension `n' selected by the user. BDT.DAT consists";
"of either 3 or 4 columns of binary data, depending on the options";
"chosen below. The second column, dtx, is the state variable x(t)";
"which specifies a mileage range which contains the bus's true odometer";
"reading during month t. The first column, dtc, is the dependent";
"variable i(t) which equals 1 if the bus engine was replaced in month t";
"when the bus's state was x(t), and 0 otherwise. The third column, mil,";
"is the monthly mileage variable mil=[x(t)-x(t-1)] giving the change";
"in the bus odometer reading during month t. You also have the option";
"to include the lagged dependent variable i(t-1) in the data set. This";
"allows you to conduct a specification test of the assumption that un-";
"observed state variables are serially independent given {x(t)}."; "";

/* INITIALIZE VARIABLES

   key variables saved:

   n:      fixed point dimension (positive integer)
   omax:   positive real, upper bound on odometer reading on buses
   modnum: 8x1 vector whose components are
           modnum[1]: index of type of cost function used (see function.g)
	   modnum[2]: number of unknown parameters in cost function
	   modnum[3]: 1 for partial likelihood, 2 for full likelihood
	   modnum[4]: 0 if discount factor (bet) fixed, 1 if bet is estimated
	   modnum[5]: maximum discretized monthly mileage (computed in 
		      stordat.gpr). Since there is possibility of 0
		      mileage, the dimension of the probability vector p
		      giving monthly mileage is modnum[5]+1
           modnum[6]: currently unused 
	   modnum[7]: 1 to include lagged mileage in model, 0 otherwise

   ogrid:  nx1 vector defining discretization of odometer state on [0,omax]
   p:      modnum[5]+1 x 1 vector with discretizied mileage probabilities

		p{o_{t+1}=o_t+i|o_t}=p[i], i=0,...,modnum[5]   */


local lfe,rws,cstp,modnum,dt,ov1,ov2,nr,m,dtc,mil;
local strng,rt,nt,rc,nc,ll,loop,milecnt,dtx,npk,lp,g,f1,grf;

lfe=0; rws=0; cstp=0; modnum=zeros(7,1); 

format /m1,/rz,9,4;

strng=cdir("");
load path=^strng;

/* SELECT FIXED POINT DIMENSION AND SIZE OF MILEAGE CELLS  */

""; "enter desired fixed point dimension `n' ";; n=con(1,1);
""; "enter upper bound odometer value (recommend 450,000)";; omax=con(1,1);
"implied size of discrete mileage range";; omax/n;
"";

"include lagged replacement choice i(t-1) in data set? (1=yes, 0=no)";;
modnum[7]=con(1,1); "";

rt=zeros(n,1); nt=rt; rc=rt; nc=rt; ll=0;
loop=1; milecnt=zeros(n,1);

/* SELECT BUS GROUPS TO BE INCLUDED IN ESTIMATION SAMPLE */

"enter bus groups to be included in BDT.DAT (1=include, 0=leave out)";

start: 
"";

if loop == 1;
        loop=2;
       "Bus group 1: 1983 Grumman model 870 buses (15 buses total)";
       "    (1=include, 0=leave out)";; swj=con(1,1);
        if swj == 1; 
	   load dt[]=g870.asc; 
	   dt=reshape(dt,15,rows(dt)/15)';
	   goto dtstor;
        else; goto start; endif;

elseif loop == 2; loop=3;
       "Bus group 2: 1981 Chance RT-50 buses (4 buses total)";
       "    (1=include, 0=leave out)";; swj=con(1,1);
        if swj == 1; 
	   load dt[]=rt50.asc; 
	   dt=reshape(dt,4,rows(dt)/4)';
	   goto dtstor;
        else; goto start; endif;

elseif loop == 3; loop=4;
       "Bus group 3: 1979 GMC model t8h203 buses (48 buses total)";
       "    (1=include, 0=leave out)";; swj=con(1,1);
        if swj == 1; 
	   load dt[]=t8h203.asc;  
	   dt=reshape(dt,48,rows(dt)/48)';
	   goto dtstor;
        else; goto start; endif;

elseif loop == 4; loop=5;
       "Bus group 4: 1975 GMC model a5308 buses (37 buses total)";
       "    (1=include, 0=leave out)";; swj=con(1,1);
        if swj == 1; 
	   load dt[]=a530875.asc; 
	   dt=reshape(dt,37,rows(dt)/37)';
	   goto dtstor;
       else; goto start; endif;

elseif loop == 5; loop=6;
       "Bus group 5: 1972 GMC model a5308 buses (18 buses total)";
       "    (1=include, 0=leave out)";; swj=con(1,1);
        if swj == 1; 
	   load dt[]=a530872.asc; 
	   dt=reshape(dt,18,rows(dt)/18)';
	   goto dtstor;
        else; goto start; endif;

elseif loop == 6; loop=7;
       "Bus group 6: 1972 GMC model a4523 buses (18 buses total)";
       "    (1=include, 0=leave out)";; swj=con(1,1);
        if swj == 1; 
	   load dt[]=a452372.asc; 
	   dt=reshape(dt,18,rows(dt)/18)';
	   goto dtstor;
        else; goto start; endif;

elseif loop == 7; loop=8;
       "Bus group 7: 1974 GMC model a4523 buses (10 buses total)";
       "    (1=include, 0=leave out)";; swj=con(1,1);
        if swj == 1; 
	   load dt[]=a452374.asc; 
	   dt=reshape(dt,10,rows(dt)/10)';
	   goto dtstor;
        else; goto start; endif;

elseif loop == 8; loop=9;
       "Bus group 8: 1974 GMC model a5308 buses (12 buses total)";
       "    (1=include, 0=leave out)";; swj=con(1,1);
        if swj == 1; 
	   load dt[]=a530874.asc; 
	   dt=reshape(dt,12,rows(dt)/12)';
	   goto dtstor;
        else; goto start; endif;

else; goto fin; 

endif;

/* DISCRETIZE CONTINUOUS MILEAGE DATA */

dtstor:
        ov1=dt[6,.]; ov2=dt[9,.];
        nr=rows(dt); m=cols(dt);
        dtc=(dt[12:nr,.] .>= ov1 .and ov1 .> 0)+
            (dt[12:nr,.] .>= ov2 .and ov2 .> 0);
        mil=dt[13:nr,.]-dt[12:nr-1,.];
       "";
       "minimum, maximum, mean monthly mileage";;
        minc(minc(mil));; maxc(maxc(mil));; meanc(meanc(mil));
       "begin discretizing data ... ";;
        dtx=dt[12:nr,.]+ov1.*dtc.*(dtc-2)-.5*ov2.*dtc.*(dtc-1);
        dtx=ceil(n*dtx/omax);
        dtc=(dtc[2:nr-11,.]-dtc[1:nr-12,.])|zeros(1,m);
        mil=(dtx[2:nr-11,.]-dtx[1:nr-12,.])+
        dtx[1:nr-12,.].*dtc[1:nr-12,.];

/* COMPUTE NON-PARAMETRIC HAZARD ESTIMATE */

       i=1; do until i > n; dt=(dtx .== i); nc[i,1]=sumc(sumc(dt));
       rc[i,1]=sumc(sumc(dt.*dtc)); nt[i,1]=nc[i,1]+nt[i,1];
       rt[i,1]=rt[i,1]+rc[i,1]; i=i+1; endo;
       npk=rt./(nt-(nt .== 0)); lp=submat(1-npk,vec(dtx),0);
       ll=ll+sumc(ln(lp+(1-2*lp).*vec(dtc)));

/* DISPLAY ESTIMATED DISCRETIZED MULTINOMIAL MILEAGE DISTRIBUTION */

      "";
      "minimum, maximum discretized mileage";;
       minc(minc(mil));; g=maxc(maxc(mil)); g;
       if g > modnum[5]; modnum[5]=g; endif;
       p=zeros(modnum[5]+1,1);
       i=1; do until i > rows(p);
           p[i]=meanc(vec((mil .== i-1)));
       i=i+1; endo;

/* WRITE DISCRETIZED DATA TO GAUSS DATA FILE bdt.dat */

      if rws > 0; goto writerow; endif;

      if modnum[7] == 0;
            create f1=bdt with bdt, 3, 2;
      else;
	    create f1=bdt with bdt, 4, 2;
      endif;

writerow:

      if modnum[7] == 0;
        rws=writer(f1,(vec(dtc[2:nr-11,.])~vec(dtx[2:nr-11,.])~vec(mil[.,.]))); 
      else;
        rws=writer(f1,(dtc[2:nr-11,.]~dtx[2:nr-11,.]~mil[.,.]~dtc[1:nr-12,.])); 
      endif;
      lfe=lfe+rws;

/* PRINT SUMMARY OF ESTIMATED MULTINOMIAL MILEAGE DISTRIBUTION */

      milecnt[1:rows(p)]=milecnt[1:rows(p)]+(nr-12)*m*p;

     "current and cumulative estimates of discretized transition probabilities";
     "for monthly mileage of a bus";
     "Mileage range  current estimate cumulative estimate";
      seqa(0,1,modnum[5]+1)~p~milecnt[1:modnum[5]+1]/lfe;

     "total rows written, cumulative, current"$+ftos(lfe,"*.*lf",7,0);;
      ftos((nr-12)*m,"*.*lf",7,0);

      goto start;

fin:

      closeall; 
      
       p=milecnt[1:modnum[5]+1]/lfe;
       ogrid=seqa(0,1,n)*omax/(1000*n);

       save n,omax,ogrid,p,modnum;

     "";
     "STORDAT.GPR successfully created data file bdt";

/* GRAPH NON-PARAMETRIC HAZARD AND NUMBER OF OBSERVATIONS */

      "Graph non-parametric estimate of replacement hazard? (1=yes,0=no) ";;
      grf=con(1,1);

      if grf;

      library pgraph;
      pqgwin many;

      _pnotify=0; 
      _pbox=1; 
      _pltype=6|6|6;
      _pdate="";
      _pcolor=15|14|7;
      let _pmcolor[9,1]=15 15 14 14 12 14 14 14 0;
      _pxlabel="Miles Since Last Replacement (000)";

      _pylabel="Replacment Probability";
      _ptitle="Non-Parametric Hazard";
/*
#IFUNIX
      let v = 100 100 640 480 0 0 1 6 15 0 0 2 2;
      wxy = WinOpenPQG(v,"Non-Parametric Hazard","XY");
      call WinSetActive(wxy);
#ENDIF
*/
      xy(ogrid,npk);
/*
#IFUNIX
      call WinSetActive(1);
#ENDIF
*/

      _pylabel="Number of Observations";
      _ptitle="Replacement Observations";
/*
#IFUNIX
      let v = 100 100 640 480 0 0 1 6 15 0 0 2 2;
      wxy = WinOpenPQG(v,"Replacement Observations","XY");
      call WinSetActive(wxy);
#ENDIF
*/
      xy(ogrid,nt);
/*
#IFUNIX
      call WinSetActive(1);
#ENDIF
*/

      endif;

      save npk;

     "ready to run SETUP.GPR to set parameters for NFXP algorithm";


retp(modnum);

endp;
