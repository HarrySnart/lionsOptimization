%macro weightVariables(in_data,weight,out_data);
data &out_data;
 set &in_data;
 array areverse {28} MP T TA C P DG M CA MK BH PM O BTS KON TM MT DT TW TT TC HE PC OPC SPC LW LS YC RC;
 do i=1 to 28;
 areverse[i]=areverse[i]*&weight.;
 end;
drop i;
run;
%mend;
