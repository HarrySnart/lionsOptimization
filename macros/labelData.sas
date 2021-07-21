
%macro label_data(data_set, library, ds_labels, column_name, column_label);

* create distinct macro variables for each variable name and label; 
data _null_; 
     set &ds_labels; 
     call symput('var' || trim(left(_N_)), trim(left(&column_name))); 
     call symput('label' || trim(left(_N_)), trim(left(&column_label))); 
     call symput('nobs', trim(left(_N_))); 
run;


* use PROC DATASETS to change the labels;
proc datasets 
     library = &library 
          memtype = data
          nolist; 
     modify &data_set; 
     label 
          %do i = 1 %to &nobs; 
               &&var&i = &&label&i 
          %end; 
     ; 
     quit; 
run; 

%mend;