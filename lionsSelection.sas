/****************************/
/* 							*/
/* 		Lions Selection		*/
/* 							*/
/****************************/
ods noproctitle;
%let path=<your path>;

/****************************/
/* 							*/
/* 		Load Macros			*/
/* 							*/
/****************************/

%include "&path/macros/PROMETHEE.sas";
%include "&path/macros/labelData.sas";
%include "&path/macros/weightVariables.sas";
*Unused but useful if you want to weight performance over time;

/****************************/
/* 							*/
/* 		Load Datasets		*/
/* 							*/
/****************************/
libname sixn xlsx "&path/data/sixNationsData.xlsx";

proc copy in=sixn out=work;
run;

libname lions xlsx "&path/data/playerOptionsMatrix.xlsx";

data work.playerOptions;
	set lions.Sheet1;
run;

*Tidy Column Labels;

data metadata;
	set metadata;
	name=propcase(name);
run;

libname prem xlsx "&path/data/premStats.xlsx";
libname pro14 xlsx "&path/data/pro14Stats2021.xlsx";
libname profiles xlsx "&path/data/playerBios.xlsx";

data bios;
	set profiles.sheet1;
run;

proc sql noprint;
	select mean(age) into :meanAge from bios;
quit;

data bios_in;
	set bios;
	drop club weight height;
	age_absdev=abs(&meanAge. - age);
	caps_age_ratio=log(sum(premier_club_caps, nation_caps, lion_caps)) / log(age);
run;

/****************************/
/* 							*/
/* 		Data Preparation	*/
/* 							*/
/****************************/


%label_data(STATS2021, work, metadata, code, name);
%label_data(STATS2020, work, metadata, code, name);
%label_data(STATS2019, work, metadata, code, name);
*Prepare Data to Plot Number of Possible Players by Position;

data test;
	set playeroptions(rename=(player=playersrc));
	player=scan(playersrc, 1, '(');
	nation=scan(scan(playersrc, 2, '('), 1, ')');
	drop playersrc;
run;

proc transpose data=test out=pos_available;
run;

data pos_available;
	set pos_available(rename=(_NAME_=Position) drop=_LABEL_);
	Cover_Options=sum(of COL1-COL37);
	keep position cover_options;
run;

*Reshape player options into lookup table;

proc sort data=WORK.PLAYEROPTIONS;
	by Player;
run;

proc transpose data=WORK.PLAYEROPTIONS out=work.PlayerOptionsLong prefix=Column;
	var Number_1 Number_2 Number_3 Number_4 Number_5 Number_6 Number_7 Number_8 
		Number_9 Number_10 Number_11 Number_12 Number_13 Number_14 Number_15;
	by Player;
run;

data playeroptionslong;
	set playeroptionslong;
	_LABEL_=scan(_LABEL_, 2, '_');
run;

proc sql noprint;
	create table selectionoptions as select scan(Player, 1, '(') as Player, 
		_LABEL_ as Position from work.PlayerOptionsLong where Column1=1;
quit;

*Re-shape data;

proc sort data=PREM.PREMSTATS out=WORK.sort;
	by Player;
run;

data work.lbl;
	set work.sort;
	code=tranwrd(trim(stat), " ", "_");
	keep code stat;
run;

data work.sort;
	set work.sort;
	stat=tranwrd(trim(stat), " ", "_");
run;

proc transpose data=WORK.sort out=work.transpose;
	var Metric;
	id Stat;
	by Player;
run;

data work.premstats;
	set work.transpose;
	drop _NAME_ _LABEL_;
run;

*Label Datasets;
%label_data(premstats, work, lbl, code, stat);
* Pro 14 Data;
*Re-shape data;

proc sort data=pro14.leaguestats out=WORK.sort;
	by Player;
run;

data work.lbl;
	set work.sort;
	code=tranwrd(tranwrd(tranwrd(tranwrd(trim(stat), " ", "_"), "%", 
		"Percentage"), "/", "or"), "Conversions", "Con");
	keep code stat;
run;

data work.sort;
	set work.sort;
	stat=tranwrd(tranwrd(tranwrd(tranwrd(trim(stat), " ", "_"), "%", 
		"Percentage"), "/", "or"), "Conversions", "Con");
run;

proc transpose data=WORK.sort out=work.transpose;
	var Metric;
	id Stat;
	by Player;
run;

data work.pro14stats;
	set work.transpose;
	drop _NAME_ _LABEL_;
run;

*Label Datasets;
%label_data(pro14stats, work, lbl, code, stat);

data pro14stats_clean;
	set pro14stats(rename=(Carries=Carries_C Clean_Breaks=Clean_Breaks_C 
		Defenders_Beaten=Defenders_Beaten_C Kicking_Success=Kicking_Success_C 
		Kickmetres=Kickmetres_C Kicks_in_Play=Kicks_in_Play_C 
		Leading_Points_Scorer=Leading_Points_Scorer_C 
		Leading_Try_Scorer=Leading_Try_Scorer_C Lineout_Offences=Lineout_Offences_C 
		Lineouts_Won=Lineouts_Won_C Metres_Gained=Metres_Gained_C Offloads=Offloads_C 
		Penalties_Conceded=Penalties_Conceded_C Red_Cards=Red_Cards_C 
		Successful_Carries=Successful_Carries_C 
		Tackle_Success_Percentage=Tackle_Success_Percentage_C 
		Tackles_Made=Tackles_Made_C Tries_from_Kicks=Tries_from_Kicks_C 
		Try_Assists=Try_Assists_C Turnovers_Lost=Turnovers_Lost_C 
		Turnovers_Won=Turnovers_Won_C Yellow_Cards=Yellow_Cards_C));
	Carries=input(Carries_C, 10.);
	Clean_Breaks=input(Clean_Breaks_C, 10.);
	Defenders_Beaten=input(Defenders_Beaten_C, 10.);
	Kicking_Success=input(Kicking_Success_C, 10.2);
	Kickmetres=input(Kickmetres_C, 10.);
	Kicks_in_Play=input(Kicks_in_Play_C, 10.);
	Leading_Points_Scorer=input(Leading_Points_Scorer_C, 10.);
	Leading_Try_Scorer=input(Leading_Try_Scorer_C, 10.);
	Lineout_Offences=input(Lineout_Offences_C, 10.);
	Lineouts_Won=input(Lineouts_Won_C, 10.);
	Metres_Gained=input(Metres_Gained_C, 10.);
	Offloads=input(Offloads_C, 10.);
	Penalties_Conceded=input(Penalties_Conceded_C, 10.);
	Red_Cards=input(Red_Cards_C, 10.);
	Successful_Carries=input(Successful_Carries_C, 10.);
	Tackle_Success_Percentage=input(Tackle_Success_Percentage_C, 10.2);
	Tackles_Made=input(Tackles_Made_C, 10.);
	Tries_from_Kicks=input(Tries_from_Kicks_C, 10.);
	Try_Assists=input(Try_Assists_C, 10.);
	Turnovers_Lost=input(Turnovers_Lost_C, 10.);
	Turnovers_Won=input(Turnovers_Won_C, 10.);
	Yellow_Cards=input(Yellow_Cards_C, 10.);
	Penalties_Scored=input(scan(Penalties_ScoredorMissed, 1, "//"), 10.);
	Penalties_Missed=input(scan(Penalties_ScoredorMissed, 2, "//"), 10.);
	Con_Scored=input(scan(Con_ScoredorMissed, 1, "//"), 10.);
	Con_Missed=input(scan(Con_ScoredorMissed, 2, "//"), 10.);
	Drop_Goals_Scored=input(scan(Drop_Goals_ScoredorMissed, 1, "//"), 10.);
	Drop_Goals_Missed=input(scan(Drop_Goals_ScoredorMissed, 2, "//"), 10.);
	drop Penalties_ScoredorMissed Con_ScoredorMissed Drop_Goals_ScoredorMissed 
		Carries_C Clean_Breaks_C Defenders_Beaten_C Kicking_Success_C Kickmetres_C 
		Kicks_in_Play_C Leading_Points_Scorer_C Leading_Try_Scorer_C 
		Lineout_Offences_C Lineouts_Won_C Metres_Gained_C Offloads_C 
		Penalties_Conceded_C Red_Cards_C Successful_Carries_C 
		Tackle_Success_Percentage_C Tackles_Made_C Tries_from_Kicks_C Try_Assists_C 
		Turnovers_Lost_C Turnovers_Won_C Yellow_Cards_C;
	label Penalties_Scored='Penalties Scored' Penalties_Missed='Penalties Missed' 
		Con_Scored='Conversions Scored' Con_Missed='Conversions Missed' 
		Drop_Goals_Scored='Drop Goals Scored' Drop_Goals_Missed='Drop Goals Missed';
	format Tackle_Success_Percentage Kicking_Success percent10.;
run;

%label_data(pro14stats_clean, work, lbl, code, stat);

/****************************/
/* 							*/
/* 		Maths Derivations	*/
/* 							*/
/****************************/
* League Maths Derivation;

data premstats_in;
	set premstats;
	keep Player Most_Tries Turnovers_Won Most_Points Metres_Gained Clean_Breaks 
		Most_Tackles Defenders_Beaten;
run;

proc rank data=premstats_in out=premstats_ranks descending ties=dense;
	var Most_Tries Turnovers_Won Most_Points Metres_Gained Clean_Breaks 
		Most_Tackles Defenders_Beaten;
	ranks Most_Tries_R Turnovers_Won_R Most_Points_R Metres_Gained_R 
		Clean_Breaks_R Most_Tackles_R Defenders_Beaten_R;
run;

data premstats_maths;
	set premstats_ranks;
	*Binary flag for appearing in top 10;

	if Most_Tries ne . then
		Most_Tries_F=1;
	else
		Most_Tries_F=0;

	if Turnovers_Won ne . then
		Turnovers_Won_F=1;
	else
		Turnovers_Won_F=0;

	if Most_Points ne . then
		Most_Points_F=1;
	else
		Most_Points_F=0;

	if Metres_Gained ne . then
		Metres_Gained_F=1;
	else
		Metres_Gained_F=0;

	if Clean_Breaks ne . then
		Clean_Breaks_F=1;
	else
		Clean_Breaks_F=0;

	if Most_Tackles ne . then
		Most_Tackles_F=1;
	else
		Most_Tackles_F=0;

	if Defenders_Beaten ne . then
		Defenders_Beaten_F=1;
	else
		Defenders_Beaten_F=0;
	* inverse rank in top 10;

	if Most_Tries_R ne . then
		Most_Tries_M=1/Most_Tries_R;
	else
		Most_Tries_M=0;

	if Turnovers_Won_R ne . then
		Turnovers_Won_M=1/Turnovers_Won_R;
	else
		Turnovers_Won_M=0;

	if Most_Points_R ne . then
		Most_Points_M=1/Most_Points_R;
	else
		Most_Points_M=0;

	if Metres_Gained_R ne . then
		Metres_Gained_M=1/Metres_Gained_R;
	else
		Metres_Gained_M=0;

	if Clean_Breaks_R ne . then
		Clean_Breaks_M=1/Clean_Breaks_R;
	else
		Clean_Breaks_M=0;

	if Most_Tackles_R ne . then
		Most_Tackles_M=1/Most_Tackles_R;
	else
		Most_Tackles_M=0;

	if Defenders_Beaten_R ne . then
		Defenders_Beaten_M=1/Defenders_Beaten_R;
	else
		Defenders_Beaten_M=0;
	*Derive sum inverse rank metric for top 10 of league.;
	league_perf=sum(Most_Tries_M, Turnovers_Won_M, Most_Points_M, Metres_Gained_M, 
		Clean_Breaks_M, Most_Tackles_M, Defenders_Beaten_M);
	keep player league_perf;
run;

data pro14stats_in;
	set pro14stats_clean(rename=(Leading_Points_Scorer=Most_Points 
		Leading_Try_Scorer=Most_Tries Tackles_Made=Most_Tackles));
	keep Player Most_Tries Turnovers_Won Most_Points Metres_Gained Clean_Breaks 
		Most_Tackles Defenders_Beaten;
run;

proc rank data=pro14stats_in out=pro14stats_ranks descending ties=dense;
	var Most_Tries Turnovers_Won Most_Points Metres_Gained Clean_Breaks 
		Most_Tackles Defenders_Beaten;
	ranks Most_Tries_R Turnovers_Won_R Most_Points_R Metres_Gained_R 
		Clean_Breaks_R Most_Tackles_R Defenders_Beaten_R;
run;

data pro14stats_maths;
	set pro14stats_ranks;
	* inverse rank in top 10;

	if Most_Tries_R ne . and Most_Tries_R le 10 then
		Most_Tries_M=1/Most_Tries_R;
	else
		Most_Tries_M=0;

	if Turnovers_Won_R ne . and Turnovers_Won_R le 10 then
		Turnovers_Won_M=1/Turnovers_Won_R;
	else
		Turnovers_Won_M=0;

	if Most_Points_R ne . and Most_Points_R le 10 then
		Most_Points_M=1/Most_Points_R;
	else
		Most_Points_M=0;

	if Metres_Gained_R ne . and Metres_Gained_R le 10 then
		Metres_Gained_M=1/Metres_Gained_R;
	else
		Metres_Gained_M=0;

	if Clean_Breaks_R ne . and Clean_Breaks_R le 10 then
		Clean_Breaks_M=1/Clean_Breaks_R;
	else
		Clean_Breaks_M=0;

	if Most_Tackles_R ne . and Most_Tackles_R le 10 then
		Most_Tackles_M=1/Most_Tackles_R;
	else
		Most_Tackles_M=0;

	if Defenders_Beaten_R ne . and Defenders_Beaten_R le 10 then
		Defenders_Beaten_M=1/Defenders_Beaten_R;
	else
		Defenders_Beaten_M=0;
	*Derive sum inverse rank metric for top 10 of league.;
	league_perf=sum(Most_Tries_M, Turnovers_Won_M, Most_Points_M, Metres_Gained_M, 
		Clean_Breaks_M, Most_Tackles_M, Defenders_Beaten_M);
	keep player league_perf;
run;

data league_perf;
	set pro14stats_maths premstats_maths;
run;

* Six Nations Maths Derivation;
*Cleanse Web Data - remove unbreakable space character;

data stats2021;
	set stats2021;
	player=compress(player, 'C2A0'x);
run;

data stats2020;
	set stats2020;
	player=compress(player, 'C2A0'x);
run;

data stats2019;
	set stats2019;
	player=compress(player, 'C2A0'x);
run;

data stats_all;
	set stats2021 stats2020 stats2019;
run;

proc sql noprint;
	create table playerTournaments as select player, count(player) as tournaments 
		from stats_all where player in ('Alun Wyn Jones', 'Tadhg Beirne', 
		'Jack Conan', 'Luke Cowan-Dickie', 'Tom Curry', 'Zander Fagerson', 
		'Taulupe Faletau', 'Tadhg Furlong', 'Jamie George', 'Iain Henderson', 
		'Jonny Hill', 'Maro Itoje', 'Wyn Jones', 'Courtney Lawes', 'Ken Owens', 
		'Andrew Porter', 'Sam Simmonds', 'Rory Sutherland', 'Justin Tipuric', 
		'Mako Vunipola', 'Hamish Watson', 'Josh Adams', 'Bundee Aki', 'Dan Biggar', 
		'Elliot Daly', 'Gareth Davies', 'Owen Farrell', 'Chris Harris', 
		'Robbie Henshaw', 'Stuart Hogg', 'Conor Murray', 'Ali Price', 
		'Louis Rees-Zammit', 'Finn Russell', 'Duhan van der Merwe', 'Anthony Watson', 
		'Liam Williams') group by player;
quit;

proc freq data=playertournaments;
	tables tournaments;
run;

*only 7 / 36 don't feature in all 3. not an exact science just use mean;

proc sql noprint;
	create table sixn_stats as select player, mean(MP) as MP, mean(T) as T , 
		mean(TA) as TA , mean(C) as C , mean(P) as P , mean(DG) as DG , mean(M) as 
		M , mean(CA) as CA , mean(MK) as MK , mean(BH) as BH , mean(PM) as PM , 
		mean(O) as O , mean(BTS) as BTS , mean(KON) as KON , mean(TM) as TM , 
		mean(MT) as MT , mean(DT) as DT , mean(TW) as TW , mean(TT) as TT , mean(TC) 
		as TC , mean(HE) as HE , mean(PC) as PC , mean(OPC) as OPC , mean(SPC) as 
		SPC , mean(LW) as LW , mean(LS) as LS , mean(YC) as YC , mean(RC) as RC from 
		stats_all where player in ('Alun Wyn Jones', 'Tadhg Beirne', 'Jack Conan', 
		'Luke Cowan-Dickie', 'Tom Curry', 'Zander Fagerson', 'Taulupe Faletau', 
		'Tadhg Furlong', 'Jamie George', 'Iain Henderson', 'Jonny Hill', 
		'Maro Itoje', 'Wyn Jones', 'Courtney Lawes', 'Ken Owens', 'Andrew Porter', 
		'Sam Simmonds', 'Rory Sutherland', 'Justin Tipuric', 'Mako Vunipola', 
		'Hamish Watson', 'Josh Adams', 'Bundee Aki', 'Dan Biggar', 'Elliot Daly', 
		'Gareth Davies', 'Owen Farrell', 'Chris Harris', 'Robbie Henshaw', 
		'Stuart Hogg', 'Conor Murray', 'Ali Price', 'Louis Rees-Zammit', 
		'Finn Russell', 'Duhan van der Merwe', 'Anthony Watson', 'Liam Williams') 
		group by player;
quit;

%label_data(sixn_stats, work, metadata, code, name);

/****************************/
/* 							*/
/* 		Merge Tables 		*/
/* 							*/
/****************************/
data league_perf;
	set league_perf;
	player=propcase(player);
run;

/*
proc print data=sixn_stats(obs=5);run;
proc print data=bios_in(obs=5);run;
proc print data=league_perf(obs=5);run;
*/
proc sql noprint;
	create table playerposoptions as select scan(player, 1, "(") as player 
		label='Player', sum(column1) as num_pos_covered 
		label='Number of Positions Covered' from playeroptionslong where column1=1 
		group by player;
quit;

/*
proc print data=playerposoptions label;run;
*/
proc sort data=sixn_stats;
	by player;
run;

proc sort data=bios_in;
	by player;
run;

proc sort data=league_perf;
	by player;
run;

proc sort data=playerposoptions;
	by player;
run;

data player_perf_metrics;
	merge sixn_stats bios_in league_perf playerposoptions;
	by player;

	if player in:('Alun Wyn Jones', 'Tadhg Beirne', 'Jack Conan', 
		'Luke Cowan-Dickie', 'Tom Curry', 'Zander Fagerson', 'Taulupe Faletau', 
		'Tadhg Furlong', 'Jamie George', 'Iain Henderson', 'Jonny Hill', 
		'Maro Itoje', 'Wyn Jones', 'Courtney Lawes', 'Ken Owens', 'Andrew Porter', 
		'Sam Simmonds', 'Rory Sutherland', 'Justin Tipuric', 'Mako Vunipola', 
		'Hamish Watson', 'Josh Adams', 'Bundee Aki', 'Dan Biggar', 'Elliot Daly', 
		'Gareth Davies', 'Owen Farrell', 'Chris Harris', 'Robbie Henshaw', 
		'Stuart Hogg', 'Conor Murray', 'Ali Price', 'Louis Rees-Zammit', 
		'Finn Russell', 'Duhan van der Merwe', 'Anthony Watson', 'Liam Williams');

	/* IML Fix addition */
	if league_perf=. then
		league_perf=0;
	drop age main_position;
run;

/*
proc print data=player_perf_metrics(obs=5) label ; run;
*/

/****************************/
/* 							*/
/* 		Load Pref Matrix	*/
/* 							*/
/****************************/

proc import datafile="&path/data/prefWeightMtx.csv" 
		out=posprefmat replace;
run;

%label_data(posprefmat, work, metadata, code, name);

data posprefmat;
	set posprefmat;
	label age_absdev="Age Deviation from Mean" 
		caps_age_ratio="Adjusted Ratio of Caps to Age" 
		league_perf="Current Season League Performance" 
		num_pos_covered="Number of Positions Can Cover";
	drop VAR32;
run;

proc print data=posprefmat label;
run;

*Create Objective Functions;
*Set Preferences Table;

data preferences;
	input MP T TA C P DG M CA PM O BTS KON TM MT DT TW TT TC HE PC OPC SPC LW LS 
		YC RC age_absdev caps_age_ratio league_perf num_pos_covered;
	datalines;
1 1 1 1 1 1 1 1 1 1 1 0 1 0 1 1 1 0 0 0 0 0 1 1 0 0 0 1 1 0
;
	*Apply Business Format to Preferences;

proc format;
	value prefmt 0='Min' 1='Max';
	%label_data(preferences, work, metadata, code, name);

data preferences;
	set preferences;
	format MP T TA C P DG M CA PM O BTS KON TM MT DT TW TT TC HE PC OPC SPC LW LS 
		YC RC age_absdev caps_age_ratio league_perf num_pos_covered prefmt.;
	label age_absdev="Age Deviation from Mean" 
		caps_age_ratio="Adjusted Ratio of Caps to Age" 
		league_perf="Current Season League Performance" 
		num_pos_covered="Number of Positions Can Cover";
run;

proc print data=preferences label;
run;


/****************************/
/* 							*/
/* 	  Pos 1-15 PROMETHEE    */
/* 							*/
/****************************/

*pos 1;

proc sql;
	create table weights (drop=position) as select * from posprefmat where 
		position=1;
quit;

proc sql;
	create table player_in (drop=Age Main_Position Lion_Caps Nation_Caps 
		Premier_Club_Caps BH PM) as select * from player_perf_metrics where player 
		in (select player from selectionoptions where position="1");
quit;

%prometheeII(player_in, weights, preferences, output=prometheeII_output1);
*pos 2;

proc sql;
	create table weights (drop=position) as select * from posprefmat where 
		position=2;
quit;

proc sql;
	create table player_in (drop=Age Main_Position Lion_Caps Nation_Caps 
		Premier_Club_Caps BH PM) as select * from player_perf_metrics where player 
		in (select player from selectionoptions where position="2");
quit;

%prometheeII(player_in, weights, preferences, output=prometheeII_output2);
*pos 3;

proc sql;
	create table weights (drop=position) as select * from posprefmat where 
		position=3;
quit;

proc sql;
	create table player_in (drop=Age Main_Position Lion_Caps Nation_Caps 
		Premier_Club_Caps BH PM) as select * from player_perf_metrics where player 
		in (select player from selectionoptions where position="3");
quit;

%prometheeII(player_in, weights, preferences, output=prometheeII_output3);
*pos 4;

proc sql;
	create table weights (drop=position) as select * from posprefmat where 
		position=4;
quit;

proc sql;
	create table player_in (drop=Age Main_Position Lion_Caps Nation_Caps 
		Premier_Club_Caps BH PM) as select * from player_perf_metrics where player 
		in (select player from selectionoptions where position="4");
quit;

%prometheeII(player_in, weights, preferences, output=prometheeII_output4);
*pos 5;

proc sql;
	create table weights (drop=position) as select * from posprefmat where 
		position=5;
quit;

proc sql;
	create table player_in (drop=Age Main_Position Lion_Caps Nation_Caps 
		Premier_Club_Caps BH PM) as select * from player_perf_metrics where player 
		in (select player from selectionoptions where position="5");
quit;

%prometheeII(player_in, weights, preferences, output=prometheeII_output5);
*pos 6;

proc sql;
	create table weights (drop=position) as select * from posprefmat where 
		position=6;
quit;

proc sql;
	create table player_in (drop=Age Main_Position Lion_Caps Nation_Caps 
		Premier_Club_Caps BH PM) as select * from player_perf_metrics where player 
		in (select player from selectionoptions where position="6");
quit;

%prometheeII(player_in, weights, preferences, output=prometheeII_output6);
*pos 7;

proc sql;
	create table weights (drop=position) as select * from posprefmat where 
		position=7;
quit;

proc sql;
	create table player_in (drop=Age Main_Position Lion_Caps Nation_Caps 
		Premier_Club_Caps BH PM) as select * from player_perf_metrics where player 
		in (select player from selectionoptions where position="7");
quit;

%prometheeII(player_in, weights, preferences, output=prometheeII_output7);
*pos 8;

proc sql;
	create table weights (drop=position) as select * from posprefmat where 
		position=8;
quit;

proc sql;
	create table player_in (drop=Age Main_Position Lion_Caps Nation_Caps 
		Premier_Club_Caps BH PM) as select * from player_perf_metrics where player 
		in (select player from selectionoptions where position="8");
quit;

%prometheeII(player_in, weights, preferences, output=prometheeII_output8);
*pos 9;

proc sql;
	create table weights (drop=position) as select * from posprefmat where 
		position=9;
quit;

proc sql;
	create table player_in (drop=Age Main_Position Lion_Caps Nation_Caps 
		Premier_Club_Caps BH PM) as select * from player_perf_metrics where player 
		in (select player from selectionoptions where position="9");
quit;

%prometheeII(player_in, weights, preferences, output=prometheeII_output9);
*pos 10;

proc sql;
	create table weights (drop=position) as select * from posprefmat where 
		position=10;
quit;

proc sql;
	create table player_in (drop=Age Main_Position Lion_Caps Nation_Caps 
		Premier_Club_Caps BH PM) as select * from player_perf_metrics where player 
		in (select player from selectionoptions where position="10");
quit;

%prometheeII(player_in, weights, preferences, output=prometheeII_output10);
*pos 11;

proc sql;
	create table weights (drop=position) as select * from posprefmat where 
		position=11;
quit;

proc sql;
	create table player_in (drop=Age Main_Position Lion_Caps Nation_Caps 
		Premier_Club_Caps BH PM) as select * from player_perf_metrics where player 
		in (select player from selectionoptions where position="11");
quit;

%prometheeII(player_in, weights, preferences, output=prometheeII_output11);
*pos 12;

proc sql;
	create table weights (drop=position) as select * from posprefmat where 
		position=12;
quit;

proc sql;
	create table player_in (drop=Age Main_Position Lion_Caps Nation_Caps 
		Premier_Club_Caps BH PM) as select * from player_perf_metrics where player 
		in (select player from selectionoptions where position="12");
quit;

%prometheeII(player_in, weights, preferences, output=prometheeII_output12);
*pos 13;

proc sql;
	create table weights (drop=position) as select * from posprefmat where 
		position=13;
quit;

proc sql;
	create table player_in (drop=Age Main_Position Lion_Caps Nation_Caps 
		Premier_Club_Caps BH PM) as select * from player_perf_metrics where player 
		in (select player from selectionoptions where position="13");
quit;

%prometheeII(player_in, weights, preferences, output=prometheeII_output13);
*pos 14;

proc sql;
	create table weights (drop=position) as select * from posprefmat where 
		position=14;
quit;

proc sql;
	create table player_in (drop=Age Main_Position Lion_Caps Nation_Caps 
		Premier_Club_Caps BH PM) as select * from player_perf_metrics where player 
		in (select player from selectionoptions where position="14");
quit;

%prometheeII(player_in, weights, preferences, output=prometheeII_output14);
*pos 15;

proc sql;
	create table weights (drop=position) as select * from posprefmat where 
		position=15;
quit;

proc sql;
	create table player_in (drop=Age Main_Position Lion_Caps Nation_Caps 
		Premier_Club_Caps BH PM) as select * from player_perf_metrics where player 
		in (select player from selectionoptions where position="15");
quit;

%prometheeII(player_in, weights, preferences, output=prometheeII_output15);

data prometheeII_output1;
	set prometheeII_output1;
	position=1;
run;

data prometheeII_output2;
	set prometheeII_output2;
	position=2;
run;

data prometheeII_output3;
	set prometheeII_output3;
	position=3;
run;

data prometheeII_output4;
	set prometheeII_output4;
	position=4;
run;

data prometheeII_output5;
	set prometheeII_output5;
	position=5;
run;

data prometheeII_output6;
	set prometheeII_output6;
	position=6;
run;

data prometheeII_output7;
	set prometheeII_output7;
	position=7;
run;

data prometheeII_output8;
	set prometheeII_output8;
	position=8;
run;

data prometheeII_output9;
	set prometheeII_output9;
	position=9;
run;

data prometheeII_output10;
	set prometheeII_output10;
	position=10;
run;

data prometheeII_output11;
	set prometheeII_output11;
	position=11;
run;

data prometheeII_output12;
	set prometheeII_output12;
	position=12;
run;

data prometheeII_output13;
	set prometheeII_output13;
	position=13;
run;

data prometheeII_output14;
	set prometheeII_output14;
	position=14;
run;

data prometheeII_output15;
	set prometheeII_output15;
	position=15;
run;

data selections;
	set prometheeII_output1-prometheeII_output15;
run;


/****************************/
/* 							*/
/* 		Normalize Ranks		*/
/* 							*/
/****************************/

proc print data=selections;
run;

data selections_std;
	set selections(rename=(position=pos_in));
	position=put(pos_in, 2.);
	drop pos_in;
run;

proc sort data=SELECTIONS_STD;
	by position;
run;

proc stdize data=SELECTIONS_STD method=range nomiss out=work.Stdize oprefix 
		sprefix=Standardized_ mult=-1;
	var rank_score;
	by position;
run;

proc print data=stdize;
run;


/****************************/
/* 							*/
/* 		OPTNET Starting XV	*/
/* 							*/
/****************************/
data selections_in;
	set stdize;
	drop pos_in rank_score;
run;

proc optnet graph_direction=directed data_links=selections_in;
	data_links_var from=player to=position weight=Standardized_rank_score;
	linear_assignment out=startingxv;
run;

/*
 *proc sql; create table startingxv as select a.*,b.player_pref_rank from selections_in as b, startingxv as a where a.player =b.player;quit ;
 */
proc sort data=startingxv;
	by position;
run;

proc print data=startingxv;
	title 'Mathematically Selected Starting XV';
run;

proc sort data=startingxv;
	by player;
run;

proc sort data=selections_in;
	by player;
run;

proc print data=selections_in;
run;

proc print data=startingxv;
run;

proc sql;
	create table startingxv as select a.position, a.player, 
		a.standardized_rank_score, b.player_pref_rank from startingxv as a, 
		selections_in as b where a.player=b.player and a.position=b.position order by 
		position asc;
quit;


/****************************/
/* 							*/
/* 			Select Subs		*/
/* 							*/
/****************************/

/*
rugby has set roles for bench numbers, generally:
16=hooker
17=prop
18=prop
19=lock
20=wing forward
21=scrumhalf
22=flyhalf
23=utility back
*/
*Set Preferences Table;

data preferences;
	input MP T TA C P DG M CA PM O BTS KON TM MT DT TW TT TC HE PC OPC SPC LW LS 
		YC RC age_absdev caps_age_ratio league_perf num_pos_covered;
	datalines;
1 1 1 1 1 1 1 1 1 1 1 0 1 0 1 1 1 0 0 0 0 0 1 1 0 0 0 1 1 1
;
	*Apply Business Format to Preferences;

proc format;
	value prefmt 0='Min' 1='Max';
	%label_data(preferences, work, metadata, code, name);

data preferences;
	set preferences;
	format MP T TA C P DG M CA PM O BTS KON TM MT DT TW TT TC HE PC OPC SPC LW LS 
		YC RC age_absdev caps_age_ratio league_perf num_pos_covered prefmt.;
	label age_absdev="Age Deviation from Mean" 
		caps_age_ratio="Adjusted Ratio of Caps to Age" 
		league_perf="Current Season League Performance" 
		num_pos_covered="Number of Positions Can Cover";
run;

proc print data=preferences label;
run;

*Pos 16 - hooker;

proc sql;
	create table weights (drop=position) as select * from posprefmat where 
		position=2;
quit;

proc sql;
	create table player_in (drop=Age Main_Position Lion_Caps Nation_Caps 
		Premier_Club_Caps BH PM) as select * from player_perf_metrics where player 
		in (select player from selectionoptions where position="2" and player not 
		in (select player from startingxv));
quit;

%prometheeII(player_in, weights, preferences, output=prometheeII_output16);
*Pos 17 - loosehead prop;

proc sql;
	create table weights (drop=position) as select * from posprefmat where 
		position=1;
quit;

proc sql;
	create table player_in (drop=Age Main_Position Lion_Caps Nation_Caps 
		Premier_Club_Caps BH PM) as select * from player_perf_metrics where player 
		in (select player from selectionoptions where position="1" and player not 
		in (select player from startingxv));
quit;

%prometheeII(player_in, weights, preferences, output=prometheeII_output17);
*Pos 18 - tighthead prop;

proc sql;
	create table weights (drop=position) as select * from posprefmat where 
		position=3;
quit;

proc sql;
	create table player_in (drop=Age Main_Position Lion_Caps Nation_Caps 
		Premier_Club_Caps BH PM) as select * from player_perf_metrics where player 
		in (select player from selectionoptions where position="3" and player not 
		in (select player from startingxv));
quit;

%prometheeII(player_in, weights, preferences, output=prometheeII_output18);
*Pos 19 - lock;

proc sql;
	create table weights (drop=position) as select * from posprefmat where 
		position gt 3 and position lt 6;
quit;

proc sql;
	create table player_in (drop=Age Main_Position Lion_Caps Nation_Caps 
		Premier_Club_Caps BH PM) as select * from player_perf_metrics where player 
		in (select player from selectionoptions where position in ("5", "4") and 
		player not in (select player from startingxv));
quit;

%prometheeII(player_in, weights, preferences, output=prometheeII_output19);
*Pos 20 - wing forward;

proc sql;
	create table weights (drop=position) as select * from posprefmat where 
		position gt 5 and position lt 9;
quit;

proc sql;
	create table player_in (drop=Age Main_Position Lion_Caps Nation_Caps 
		Premier_Club_Caps BH PM) as select * from player_perf_metrics where player 
		in (select player from selectionoptions where position in ("6", "7", "8") and 
		player not in (select player from startingxv));
quit;

%prometheeII(player_in, weights, preferences, output=prometheeII_output20);
*Pos 21 - scrumhalf;

proc sql;
	create table weights (drop=position) as select * from posprefmat where 
		position=9;
quit;

proc sql;
	create table player_in (drop=Age Main_Position Lion_Caps Nation_Caps 
		Premier_Club_Caps BH PM) as select * from player_perf_metrics where player 
		in (select player from selectionoptions where position="9" and player not 
		in (select player from startingxv));
quit;

%prometheeII(player_in, weights, preferences, output=prometheeII_output21);
*Pos 22 - flyhalf;

proc sql;
	create table weights (drop=position) as select * from posprefmat where 
		position gt 9;
quit;

proc sql;
	create table player_in (drop=Age Main_Position Lion_Caps Nation_Caps 
		Premier_Club_Caps BH PM) as select * from player_perf_metrics where player 
		in (select player from selectionoptions where position in ("10", "11", "12", 
		"13", "14", "15") and player not in (select player from startingxv));
quit;

%prometheeII(player_in, weights, preferences, output=prometheeII_output22);
*Pos 23 - utility back;

proc sql;
	create table weights (drop=position) as select * from posprefmat where 
		position gt 10;
quit;

proc sql;
	create table player_in (drop=Age Main_Position Lion_Caps Nation_Caps 
		Premier_Club_Caps BH PM) as select * from player_perf_metrics where player 
		in (select player from selectionoptions where position in ("11", "12", "13", 
		"14", "15") and player not in (select player from startingxv));
quit;

%prometheeII(player_in, weights, preferences, output=prometheeII_output23);

data prometheeII_output16;
	set prometheeII_output16;
	position=16;
run;

data prometheeII_output17;
	set prometheeII_output17;
	position=17;
run;

data prometheeII_output18;
	set prometheeII_output18;
	position=18;
run;

data prometheeII_output19;
	set prometheeII_output19;
	position=19;
run;

data prometheeII_output20;
	set prometheeII_output20;
	position=20;
run;

data prometheeII_output21;
	set prometheeII_output21;
	position=21;
run;

data prometheeII_output22;
	set prometheeII_output22;
	position=22;
run;

data prometheeII_output23;
	set prometheeII_output23;
	position=23;
run;

data selections_subs;
	set prometheeII_output16-prometheeII_output23;
run;

proc print data=selections_subs;
	title 'Sub Selection Options';
run;

data selections_subs_std;
	set selections_subs(rename=(position=pos_in));
	position=put(pos_in, 2.);
	drop pos_in;
run;

proc sort data=SELECTIONS_SUBS_STD;
	by position;
run;

proc stdize data=SELECTIONS_SUBS_STD method=range nomiss out=work.Stdize_sub 
		oprefix sprefix=Standardized_ mult=-1;
	var rank_score;
	by position;
run;

proc print data=stdize_sub;
run;

data selections_subs_in;
	set stdize_sub;
	drop pos_in rank_score;
run;

proc optnet graph_direction=directed data_links=selections_subs_in;
	data_links_var from=player to=position weight=Standardized_rank_score;
	linear_assignment out=selected_subs;
run;

proc sort data=selected_subs;
	by position;
run;

proc print data=selected_subs;
	title 'Mathematically Selected Subs';
run;

proc sort data=selected_subs;
	by player;
run;

proc sort data=selections_subs_in;
	by player;
run;

proc sql;
	create table selected_subs as select a.position, a.player, 
		a.standardized_rank_score, b.player_pref_rank from selected_subs as a, 
		selections_subs_in as b where a.player=b.player and a.position=b.position 
		order by position asc;
quit;

proc print data=selected_subs;
run;

data selected_team;
	set startingxv selected_subs;
run;

proc print data=selected_team noobs label;
	title 'SAS Algorithmically Selected Lions XV';
	label position="Position" PLAYER="Player" 
		standardized_rank_score="Standardized Rank Score" 
		player_pref_rank="Player Rank Within Position";
run;


/****************************/
/* 							*/
/* 	Load Spatial Points		*/
/* 							*/
/****************************/

proc import datafile="&path/data/points_map.csv" dbms=csv 
		out=points_map;
run;

data points_map;
	set points_map(rename=(position=pos));
	position=put(pos, 2.);
	drop pos;
run;

proc print data=points_map;
run;

proc sql;
	create table lionsxv_viz as select selected_team.*, points_map.x, points_map.y 
		from selected_team , points_map where 
		selected_team.position=points_map.position;
quit;

libname casuser cas;

data casuser.lionsxv_viz(replace=yes);
	set lionsxv_viz;
	label position="Position" player="Player";
run;

/****************************/
/* 							*/
/* 		ODS Report			*/
/* 							*/
/****************************/

proc datasets lib=sixn;
	title 'Available Six Nations Tournament Datasets';
quit;

proc print data=sixn.STATS2020(obs=15) noobs;
	title 'Sample of Six Nations Player Stats';
run;

proc print data=premstats(obs=10) label;
	title 'Premiership League Stats';
run;

proc print data=pro14stats_clean(obs=10) label;
	title 'Pro 14 League Stats';
run;

proc print data=lions.Sheet1;
	title 'Tour Selected Players and Position Options';
run;

proc sgplot data=pos_available;
	scatter x=position y=cover_options;
	xaxis label='Field Position';
	yaxis label='Number of Players Able to Cover';
	titile 'Selections by Position Cover';
run;

*Plot Representation by Country;

proc sgplot data=test;
	hbar nation / datalabel;
	xaxis label='Number of Players';
	yaxis label='Home Nation';
	title 'Player Representation by Country';
run;

proc sgplot data=bios;
	hbar club / stat=freq categoryorder=respdesc datalabel;
	title 'Selection by Club';
run;

proc sgplot data=bios;
	hbar main_position / stat=freq categoryorder=respdesc datalabel;
	title 'Selection by Main Position';
run;

proc sgplot data=bios;
	histogram height;
	title 'Player Height Distribution';
run;

proc sgplot data=bios;
	histogram Weight;
	title 'Player Weight Distribution';
run;

proc sgplot data=bios;
	histogram age;
	title 'Player Age Distribution';
run;

proc sgplot data=bios;
	histogram lion_caps;
	title 'Player Lion Caps Distribution';
run;

proc sgplot data=bios;
	histogram nation_caps;
	title 'Player National Caps Distribution';
run;

proc sgplot data=bios;
	histogram premier_club_caps;
	title 'Player Premier League Caps Distribution';
run;

/*
 *proc sgscatter data=bios; plot weight*height / group=main_position filledoutlinedmarkers MARKERATTRS=filled ;run;
 */
proc sgplot data=bios noautolegend;
	styleattrs datasymbols=(circlefilled);
	scatter x=weight y=height / group=main_position filledoutlinedmarkers 
		datalabel=main_position;
	title 'Player Attribute Map';
run;

proc print data=work.selected_team label;
	title 'SAS Algorithmically Selected Team';
run;