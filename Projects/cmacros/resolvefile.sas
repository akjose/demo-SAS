/* ******************************************************
* macro resolvefile.sas resolve the file name and type
* *******************************************************/
%macro resolvefile() /minoperator;
	%if %superq(oriname) eq %then %let fullname=%qsysfunc(dread(&pid, &i));  
	%else %let fullname=&oriname;

	%let position=%sysfunc(find(&fullname, . ,-99));
	%let type=%upcase(%scan(&fullname, -1, .));            
	%let name=%qsubstr(&fullname, 1 , &position-1); 
	%let name=%sysfunc(prxchange(s![^a-z_0-9]!_!i, -1, &name)); 

	%if &position > 33 %then %do;
		%let name=%substr(&name, 1 , 32);
		%put NOTES- The length of the file name is over 32 and has been truncated to 32;
	%end;  

	%if %superq(ext) ne and %superq(oriname) eq %then  %do;
		/*if combined with above statement, %eval() will evaluate all condition. 
		if the ext is empty, the %eval() will eject an error in log*/
		%if not (&type  in &ext) %then  %let type=; 
	%end;
%mend resolvefile;
