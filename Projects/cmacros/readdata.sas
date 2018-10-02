/* ****************************************************************************
* macro readdata.sas: read the data stored in local external files
* option minoperator: make the in() operator is available in macro, 
* parameters
* path: the folder where the data is stored. default is the data folder.
* lib: the library where the dataset would be stored.default is ori.
* ext: specify the file type(extention name) in which the data would be input.
		default is empty which means all types.
* oriname: specify the file name in which the data would be input.
		default is empty which means all file.
* struc: specify the data structure if it is available, for input statement。
* *****************************************************************************************************/
%macro readdata(path=&pdir.data, lib=ori, ext=, oriname=, struc= ) /minoperator ;
options nosource;
	%local filrf rc pid  position fullname type name i;    
 
	%if %superq(oriname)=  %then %do;
		%let rc=%sysfunc(filename(filrf,&path));      
		%let pid=%sysfunc(dopen(&filrf));          
		%if &pid eq 0 %then %do; 
			%put Directory &path cannot be open or does not exist;
			%return;
		%end;
		%let ext=%upcase(&ext); 

		%do i = 1 %to %sysfunc(dnum(&pid)); 
			%resolvefile();
			%if &type ne  %then %do;
				%readfile();
			%end;
		%end;

		proc datasets library=&lib  memtype=data ;
			contents data=_all_  short ;
		run;quit;
	%end;
	%else %do;
		%resolvefile();
		%readfile();
	%end;
options source;
%mend readdata;
