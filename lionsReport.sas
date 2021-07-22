%let path=<your path>;

proc template;
   define style styles.mystyle;
      parent = styles.powerpointlight;
      class SystemTitle /
         fontsize=25pt;
   end;
run;

options nodate  nonumber;
ods graphics / reset=all noborder scale=on /*width=4.5in height=3.5in*/;
ods escapechar="^";  
ods powerpoint file="&path/reports/lionsReport.pptx" options(backgroundimage="&path/lionsReport.png") startpage=no /*layout=titleslide*/;

ods layout gridded x=40pct y=45pct;
 ods region;


*ods powerpoint layout=titleslide;
proc odstext; p 'Lions Team Selection' /style=PresentationTitle /*style=[color=red fontsize=30pt]*/;run;
proc odstext; p 'Harry Snart' /style=PresentationTitle2 /*style=[color=black fontsize=20pt]*/;run;
ods layout end;

ods powerpoint startpage=now style=styles.mystyle options(backgroundimage="&path/lionsReport2.png");

options number;
/*
proc print data=sixn.STATS2020(obs=15) noobs;
	title 'Sample of Six Nations Player Stats';
run;

proc print data=premstats(obs=10) label;
	title 'Premiership League Stats';
run;

proc print data=pro14stats_clean(obs=10) label;
	title 'Pro 14 League Stats';
run;*/

proc sort data=profiles.sheet1 out=profiles_prnt; by player club;run;

proc print data=profiles_prnt label noobs style(head data)={fontsize=9pt};
	var player club main_position;
	title 'Tour Selected Players and Position Options' height=11pt;
	label player = 'Player' club = 'Club' main_position='Preferred Position';
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

data selected_team_prnt;
set selected_team;
pos = input(position,2.);
run;

proc print data=work.selected_team_prnt label noobs style(head data)={fontsize=9pt};
where pos lt 16;
var position player standardized_rank_score player_pref_rank;
	title 'SAS Algorithmically Selected Starting Team'; label player="Player" position="Position";
run;
ods powerpoint startpage=now style=styles.mystyle options(backgroundimage="&path/lionsReport2.png");

proc print data=work.selected_team_prnt label noobs style(head data)={fontsize=9pt};
where pos gt 16;
var position player standardized_rank_score player_pref_rank;
	title 'SAS Algorithmically Selected Bench'; label player="Player" position="Position";
run;
ods powerpoint close;