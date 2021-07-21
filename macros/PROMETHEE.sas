%macro prometheeII(input,weights,preferences,output=work.promethee_rankings);

*title 'PROMETHEE II Algorithm with Non-Negative Preference Function';
*title3 'View Input Data';

/*
proc print data=&input noobs;
run;
*/

proc iml;
	*Read into matrix;
	use &input;
	read all into indata;
	
	title 'Run IML Procedure';
	*print indata;
	*Set preference weights;
	use weights;
	read all into weights;
	weights = weights`;
	*print weights;

	*Set preferences;
	use preferences;
	read all into preferences;
	preferences = preferences`;
	*print preferences;

	*Normalize matrix;
	norm_indata=J(nrow(indata), ncol(indata), 0);
		
	nc=ncol(indata);
	
	Do i=1 TO nc;
		*Maximization Variables;

		if preferences[i]=1 then
			do;
				v_temp=indata[, i];
				max_v_temp=max(v_temp);
				min_v_temp=min(v_temp);
				v_norm=(v_temp - min_v_temp) / (max_v_temp - min_v_temp);
				norm_indata[, i]=v_norm;
			end;
		*Minimization Variables;
		else
			do;
				v_temp=indata[, i];
				max_v_temp=max(v_temp);
				min_v_temp=min(v_temp);
				v_norm=(max_v_temp - v_temp)/ (max_v_temp - min_v_temp);
				norm_indata[, i]=v_norm;
			end;
	end;
	*print norm_indata;

	*Transpose of normalised phone;
	t_norm_indata=norm_indata`;
	
	option_diffs=J(nrow(t_norm_indata), ncol(t_norm_indata) # ncol(t_norm_indata), 0);

	i=1;

	do j=1 to ncol(t_norm_indata);
		*print i;
		current_var=t_norm_indata[, j];

		do k=1 to ncol(t_norm_indata);
			comp_var=t_norm_indata[, k];
			option_diffs[, i]=current_var - comp_var;
			i=i+1;
		end;
	end;

	

*set any preference <0 to 0;
r=nrow(option_diffs);
c=ncol(option_diffs);
Do i=1 TO r;
	Do j=1 TO c;
	if option_diffs[i,j] < 0 then option_diffs[i,j] = 0;
end;
end;

*print option_diffs;

*Multiple vars by weights;
t_option_diffs = option_diffs`;

do i=1 to ncol(t_option_diffs);
t_option_diffs[,i] = t_option_diffs[,i] # weights[i];
end;

option_diffs = t_option_diffs`;
*print option_diffs;

*create vectors of option sum;
	sum_pref_funcs=J(1, ncol(option_diffs), 0);
do i=1 to ncol(option_diffs);
v_temp = option_diffs[,i];
v_temp_sum = sum(v_temp);
sum_pref_funcs[1,i]=v_temp_sum;
end;
*print sum_pref_funcs;

pref_mat = shape(sum_pref_funcs,sqrt(ncol(sum_pref_funcs)),sqrt(ncol(sum_pref_funcs)));
*print pref_mat;

*column-wise sum = negative flow;
negative_flow=J(ncol(pref_mat), 1, 0);
do i = 1 to ncol(pref_mat);
temp_var = pref_mat[,i];
negative_flow[i,1] = sum(temp_var)/((ncol(pref_mat)-1));
end;
*print negative_flow;

*row-wise sum = positive flow;
positive_flow=J(ncol(pref_mat), 1, 0);
do i = 1 to nrow(pref_mat);
temp_var = pref_mat[i,];
positive_flow[i,1] = sum(temp_var) / ((ncol(pref_mat)-1));
end;

*print positive_flow;

net_flow = positive_flow - negative_flow;

*print net_flow;
*create rank_score; 
*append from net_flow;
create &output from net_flow[colname={"rank_score"}];
append from net_flow;
close &output;
quit;

*Merge Datasets;
data promethee_rank;
merge &input &output;
run;

*title 'Merge IML Score with Source Data';
*proc print data=promethee_rank noobs;run;

*Apply ranking to dataset;
proc rank data=promethee_rank(keep=player rank_score) out=&output ties=low descending;
   var rank_score;
   ranks player_pref_rank;
run;

data &output;
set &output;
label player='Player Option' rank_score='Rank Score' player_pref_rank = 'Preference Ranking';
run;

*Sort data by rank;
proc sort data=&output;by player_pref_rank;run;

*Print results;
*title 'PROMETHEE II Preference Ranking Output';
/*
proc print data=&output noobs label; 
var player_pref_rank player ;
label player='Selected Option' player_pref_rank='Preference Ranking';
run;*/

%mend;


