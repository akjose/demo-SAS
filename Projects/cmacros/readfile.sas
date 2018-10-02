%macro readfile() /minoperator;     
	%local i;   
	%if &type in(TXT CSV DAT)  %then %do;
		%if %length(%superq(struc))=0   %then %do;
			%if &type = TXT or &type=DAT %then %let type=tab;
			proc import datafile = "&path\&fullname"
			out=&lib..&name
			dbms=&type
			replace; 
			getnames=yes;
			guessingrows=max; %*a large number will take some time, but it is faster than semi-automatic;
			run;
			%end;
		%else %do;
			data &lib..&name;
				infile "&path\&fullname" truncover %if &ext=csv %then dsd;%str(;)
				input &struc;
				run
			%end;
	%end;
	%else %if &type eq SAS7BDAT %then %do;
		libname templb "&path";
		proc datasets noprint;
			copy in=templb out=&pname memtype=data;
			select &name;
		run; quit;
		libname templb clear;
	%end;
	%else %if &type eq XPT %then %do;
		libname templb XPORT "&path\&fullname";
		proc copy in=templb out=&pname memtype=data;
		run;
		libname templb clear;
	%end;
	%else %if &type in (XLS XLSB XLSM XLSX) %then %do;
		libname templb excel "&path\&fullname";
		proc sql noprint; 
			create table work.temp as
			select tranwrd(trim(compress(memname, ,"p")), " " , "_") as setname, 
						case when substr(memname, 1,1)= "'" then memname else "'"||trim(memname)||"'" end as tname 
			from sashelp.vtable
			where libname= "TEMPLB" and substr(memname, length(memname), 1) in ("'" "$");

			select count(distinct setname) into :number
			from work.temp; 
			select tname, setname
						into :table1- :table%sysfunc(left(&number)), 
								 :sname1-:sname%sysfunc(left(&number))
			from work.temp;
		quit;
		%do i=1 %to &number;
		        proc import datafile= "&path\&fullname" 
		        out=&lib..&&sname&i 
		        dbms=excel 
				replace;
		        sheet= &&table&i;
		        getnames=yes;
	%*	        mixed=yes;
		        run;
		%end; 
		libname templb clear; 
	%end;
	%else  %if &type in (MDB ACCDB) %then %do;
		libname templb access "&path\&fullname";
		proc sql noprint; 
			create table work.temp as
				select tranwrd(trim(memname)," " ,"_") as setname, "'"||trim(memname)||"'" as tname,  name as vname, 
							'max(length('||trim(name)||'))' as qlist, . as len
					from dictionary.columns
					where  libname= "TEMPLB" and type = "char"
					order by setname, tname;
			select count(distinct tname) into :number
				from work.temp; 
			select distinct tname, setname
				into :table1- :table%sysfunc(left(&number)), 
						 :sname1-:sname%sysfunc(left(&number))
				from work.temp;
		quit;
		%do i=1 %to &number;
			proc import 
				DATATABLE=&&table&i
				out=&lib..&&sname&i 
				dbms=access
				replace;
				database= "&path\&fullname";
			run;
		%end;
		data work.temp;
			set work.temp;
			by setname;
			length modifylist $ 32767;
			retain modifylist;
			len = get_vars_length("&lib",setname,qlist);
			if first.setname then modifylist="";
			mdf=trim(vname)||" char("||trim(left(len))||") format=$"||trim(left(len))||
					". informat=$"||trim(left(len))||".";
			modifylist = catx(",", modifylist, mdf) ;
			if last.setname then call symputx(trim(setname)||"modifylist", modifylist);
		run;
		proc sql noprint;		
			%do i=1 %to &number;
				%let setname=&&sname&i;
				alter table &lib..&&sname&i
					modify &&&setname.modifylist;
			%end;
		quit;
		libname templb clear %str(;);
	%end;
%mend readfile;
