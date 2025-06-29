@echo off
@setlocal ENABLEDELAYEDEXPANSION
@setlocal enableextensions

REM ‘-a logfile’
REM ‘--append-output=logfile’
REM Append to logfile. This is the same as ‘-o’, only it appends to logfile instead of
REM overwriting the old log file. If logfile does not exist, a new file is created.
REM 
REM ‘-v’
REM ‘--verbose’
REM Turn on verbose output, with all the available data. The default output is verbose.
REM 
REM ‘-t number’
REM ‘--tries=number’
REM Set number of retries to number. Specify 0 or ‘inf’ for infinite retrying. The default
REM is to retry 20 times, with the exception of fatal errors like “connection refused” or
REM “not found” (404), which are not retried.
REM 
REM ‘-O file’
REM ‘--output-document=file’
REM The documents will not be written to the appropriate files, but all will be concatenated
REM together and written to file.
REM 
REM ‘--user=user’
REM ‘--password=password’
REM Specify the username user and password password for both ftp and http file retrieval. 
REM These parameters can be overridden using the ‘--ftp-user’ and ‘--ftp-password’ options 
REM for ftp connections and the ‘--http-user’ and ‘--http-password’ options for http connections.
REM 
REM ‘-nd’
REM ‘--no-directories’
REM Do not create a hierarchy of directories when retrieving recursively. With this option
REM turned on, all files will get saved to the current directory, without clobbering (if a
REM name shows up more than once, the filenames will get extensions ‘.n’).
REM 
REM ‘--no-cookies’
REM Disable the use of cookies.
REM 
REM ‘--ignore-length’
REM Unfortunately, some http servers (cgi programs, to be more precise) send out
REM bogus Content-Length headers, which makes Wget go wild, as it thinks not all the
REM document was retrieved. You can spot this syndrome if Wget retries getting the
REM same document again and again, each time claiming that the (otherwise normal)
REM connection has closed on the very same byte.
REM With this option, Wget will ignore the Content-Length header—as if it never existed.
REM 
REM ‘-np’
REM ‘--no-parent’
REM Do not ever ascend to the parent directory when retrieving recursively
REM 
REM ‘-nH’
REM ‘--no-host-directories’
REM Disable generation of host-prefixed directories. By default, invoking Wget with
REM ‘-r http://fly.srk.fer.hr/’ will create a structure of directories beginning with
REM ‘fly.srk.fer.hr/’. This option disables such behavior.
REM 

ECHO --- Started !date! !time!

G:
CD G:\HDTV\
REM set header to date and time and computer name
CALL :get_header_String "header"

SET logname=G:\HDTV\TVsched.batch.log.wget.!header!.log
SET dlname=G:\HDTV\TVsched.batch.log.result.!header!.log

REM echo Intended logfile    %logname%
REM echo Intended resultfile %dlname%

REM c:\software\wget\wget.exe -v -t 1 --server-response --timeout=360 --user=TVSCH --password=TVSCHpw9897 -nd -np -nH --no-cookies --append-output="%logname%" --output-document="%dlname%" "http://10.0.0.25:8420/servlet/EpgDataRes?action=14&reload=1&rescan=1" 
REM c:\software\wget\wget.exe -v -t 1 --server-response --timeout=360 --user=TVSCH --password=TVSCHpw9897 -nd -np -nH --no-cookies --append-output="%logname%" --output-document="%dlname%" "http://10.0.0.22:8420/servlet/EpgDataRes?action=14&reload=1&rescan=1" 
REM c:\software\wget\wget.exe -v -t 1 --server-response --timeout=360 --user=TVSCH --password=TVSCHpw9897 -nd -np -nH --no-cookies --append-output="%logname%" --output-document="%dlname%" "http://localhost:8420/servlet/EpgDataRes?action=14&reload=1&rescan=1" 

REM
c:\software\wget\wget.exe -v -t 1 --server-response --timeout=360 --user=TVSCH --password=TVSCHpw9897 -nd -np -nH --no-cookies --output-document="%dlname%" "http://localhost:8420/servlet/EpgDataRes?action=14&reload=1&rescan=1" 

REM call "C:\TV Scheduler Pro\EPG-grabbers\safexmltv-11.1\xmltv.bat"

ECHO --- Finished !date! !time!
goto :eof


:get_date_time_String
REM return a datetime string with spaces replaced by zeroes in format yyyy-mm-dd hh.mm.ss.hh
set "datetimestring_variable_name=%~1"
set "Datey=!DATE: =0!"
set "Timey=!TIME: =0!"
set "eval_datetime=!Datey:~10,4!-!Datey:~7,2!-!Datey:~4,2! !Timey:~0,2!.!Timey:~3,2!.!Timey:~6,2!.!Timey:~9,2!"
set "!datetimestring_variable_name!=!eval_datetime!"
goto :eof

:get_date_time_String_nospaces
REM return a datetime string with spaces replaced by zeroes and no spaces in format yyyy-mm-dd.hh.mm.ss.hh
set "ns_datetimestring_variable_name=%~1"
set "ns_eval_datetime="
CALL :get_date_time_String "ns_eval_datetime"
set "ns_eval_datetime=!ns_eval_datetime: =.!"
set "!ns_datetimestring_variable_name!=!ns_eval_datetime!"
goto :eof

:get_header_String
REM Create a Header
set "ghs_header_variable_name=%~1"
CALL :get_date_time_String_nospaces "ghs_date_time_String"
set "!ghs_header_variable_name!=!ghs_date_time_String!-!COMPUTERNAME!"
goto :eof