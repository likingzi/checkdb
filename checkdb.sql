-- NAME
--   checkdb.sql
--
-- DESCRIPTION
--   This script check the DB and create reports.
--
-- SUPPORTED OS
--   Linux, Aix, Hp-ux, Solaris, Windows
--
-- SUPPORTED ORACLE VERSION
--   11g;10g;9i(partly)
--
-- USAGE
--   Connect to db using sqlplus, run checkdb.sql:
--   SQL> @checkdb
--
--   Note 1: user privileges
--   grant execute on DBMS_WORKLOAD_REPOSITORY to username;
--   grant select any dictionary to username;
--   Note 2: set NLS_LANG to show chinese report
--   linux Shell       : export NLS_LANG=AMERICAN_AMERICA.ZHS16GBK
--   windows CMD       : set NLS_LANG=AMERICAN_AMERICA.ZHS16GBK
--   windows PowerShell: $env:NLS_LANG="AMERICAN_AMERICA.ZHS16GBK"
--
-- MODIFIED    (YYYY-MM-DD)
-- Li JinGuang  2018-08-31 - translate chinese to english
-- Li JinGuang  2018-01-27 - Adding "Top 5 Wait Event trends"
-- Li JinGuang  2018-01-25 - Upgrade KPI function, using chart.js verion 2.6
-- Li JinGuang  2017-07-22 - Adding KPI trend Chart: CPU Utilization, Time Model, SQL Execution Count
-- Li JinGuang  2017-02-13 - Adding KPI trend: DB time, CPU%
-- Li JinGuang  2017-01-16 - Adding Support Windows OS
-- Li JinGuang  2017-01-10 - Adding KPI trend: physical reads, physical writes
-- Li JinGuang  2017-01-06 - Adding alertlog report: checkdb_alertlog.sql
-- Li JinGuang  2016-12-05 - Created

prompt +------------------------------+
prompt + Oracle Database Check Report +
prompt +------------------------------+

set feedback off
set verify   off
set termout  off
prompt
prompt Current Instance
prompt ~~~~~~~~~~~~~~~~
COLUMN inst_num NEW_VALUE inst_num
select d.dbid            dbid
     , d.name            db_name
     , i.instance_number inst_num
     , i.instance_name   inst_name
  from v$database d,
       v$instance i;

set termout  on
set heading  on
set echo     off
prompt How Many Days for KPI Trend ? [Default: '8']
define days=8
set termout off
column days new_value days noprint;
select nvl('&&days','8') days from dual;
select 8 days from dual where '&days' < 0 or '&days' > 8;
set termout on
prompt Using days: &days

set linesize 100 pages 10000
--
-- Here Auto select snap id ...
column bid new_value bid;
select a.snap_id bid, to_char(a.end_interval_time,'yyyy-mm-dd hh24:mi:ss') snap_time from dba_hist_snapshot a
where a.instance_number=(select b.instance_number from v$instance b)
and to_char(a.end_interval_time,'yyyy-mm-dd hh24') = to_char(sysdate-&days,'yyyy-mm-dd hh24') and rownum=1;
column eid new_value eid;
select a.snap_id eid, to_char(a.end_interval_time,'yyyy-mm-dd hh24:mi:ss') snap_time from dba_hist_snapshot a
where a.instance_number=(select b.instance_number from v$instance b)
and to_char(a.end_interval_time,'yyyy-mm-dd hh24') = to_char(sysdate,'yyyy-mm-dd hh24') and rownum=1;

set termout  off
COLUMN iv NEW_VALUE _iv NOPRINT
select trunc(3600*24*(sysdate+snap_interval-sysdate)) iv from dba_hist_wr_control;
COLUMN dbname NEW_VALUE _dbname NOPRINT
select name dbname from v$database;
COLUMN cpucount NEW_VALUE _cpucount NOPRINT
select value cpucount from v$parameter where name ='cpu_count';

set termout  on
set heading  on
set echo     off
prompt Choose begin_snap_id:
set termout off
column bid new_value bid;
select nvl('&&bid','5') bid from dual;
set termout on
prompt Using begin_snap_id: &bid

set termout  on
set heading  on
set echo     off
prompt Choose end_snap_id: [Default: 'begin_snap_id + 24*8']
set termout off
column eid new_value eid;
-- select '&bid'+120 eid from dual;
select nvl('&&eid','&bid'+192) eid from dual;
select '&bid'+192 eid from dual where &eid < &bid;
set termout on
prompt Using end_snap_id: &eid

define inid=&inst_num
prompt
prompt Start to Health Check. Please wait ......

set echo          off
set heading       on
set long          2000000
set linesize      999 pages 0
set termout       off
set echo          off
set feedback      off
set heading       off
set verify        off
set wrap          on
set trimspool     on
set serveroutput  on size  unlimited
set escape        on
COLUMN vp NEW_VALUE _vp NOPRINT
SELECT case when &eid-&bid>500 then 6  when &eid-&bid>350 then 4 else 2 end vp FROM dual;
alter session set nls_date_format='yyyy-mm-dd hh24:mi:ss';

-- Define rpt_name
COLUMN rpt_name NEW_VALUE rpt_name NOPRINT
SELECT 'checkdb_'||host_name||'_'||instance_name||'_'||TO_CHAR(SYSDATE,'YYYYMMDD')||'_KPI_Trend_'||&bid||'_'||&eid||'.html' rpt_name FROM v$instance;

spool &rpt_name

prompt <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
prompt <html xmlns="http://www.w3.org/1999/xhtml">

prompt <head>
prompt <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
prompt <title>Oracle Database Check Report</title>

prompt <style type="text/css">
prompt body.awr   {font:bold 10pt Arial,Helvetica,Geneva,sans-serif;color:black; background:White;}
prompt pre.awr    {font:8pt Courier;color:black; background:White;}
prompt h1.awr     {font:bold 20pt Arial,Helvetica,Geneva,sans-serif;color:#336699;background-color:White;border-bottom:1px solid #cccc99;margin-top:0pt; margin-bottom:0pt;padding:0px 0px 0px 0px;}
prompt h2.awr     {font:bold 18pt Arial,Helvetica,Geneva,sans-serif;color:#336699;background-color:White;margin-top:4pt; margin-bottom:0pt;}
prompt h3.awr     {font:bold 16pt Arial,Helvetica,Geneva,sans-serif;color:#336699;background-color:White;margin-top:4pt; margin-bottom:0pt;}
prompt li.awr     {font: 8pt Arial,Helvetica,Geneva,sans-serif; color:black; background:White;}
prompt h4.awr     {font:bold 20pt Arial,Helvetica,Geneva,sans-serif;color:#ff0000;}
prompt th.awrnobg {font:bold 8pt Arial,Helvetica,Geneva,sans-serif; color:black; background:White;  padding-left:4px; padding-right:4px;padding-bottom:2px}
prompt th.awrbg   {font:bold 8pt Arial,Helvetica,Geneva,sans-serif; color:White; background:#0066CC;padding-left:4px; padding-right:4px;padding-bottom:2px}
prompt td.awrnc   {font:8pt Arial,Helvetica,Geneva,sans-serif;color:black;background:White;   vertical-align:top;}
prompt td.awrc    {font:8pt Arial,Helvetica,Geneva,sans-serif;color:black;background:#FFFFCC; vertical-align:top;}
prompt a.awr      {font:bold 8pt  Arial,Helvetica,sans-serif;color:#663300; vertical-align:top;margin-top:0pt; margin-bottom:0pt;}
prompt a1.awr     {font:bold 10pt Arial,Helvetica,sans-serif;color:#0000FF; vertical-align:top;margin-top:0pt; margin-bottom:0pt;}
prompt </style>

prompt <script src="http://liking.site/js/checkdb_chart21.js"></script>
-- prompt <script src="checkdb_chart21.js"></script>
prompt </head>

prompt <body class='awr'>
prompt <font size=+2 color=darkblue><b>Oracle Database Check Report for</b></font><hr>

prompt <TABLE BORDER=1 WIDTH=600>
prompt <tr><th class='awrbg'>DB Name</th><th class='awrbg'>DB Id</th><th class='awrbg'>Instance</th><th class='awrbg'>Inst num</th><th class='awrbg'>Release</th><th class='awrbg'>RAC</th><th class='awrbg'>Host</th><th class='awrbg'>Report Time</th></tr>
prompt <tr><TD class='awrnc'>
SELECT A.NAME||'</td><TD ALIGN=''right'' class=''awrnc''>'
||A.DBID||'</td><TD class=''awrnc''>'||(SELECT B.INSTANCE_NAME||'</td><TD ALIGN=''right'' class=''awrnc''>'||&inid||'</td><TD class=''awrnc''>'||B.VERSION || '</td><TD class=''awrnc''>'||(SELECT value FROM V$PARAMETER C WHERE C.NAME ='cluster_database')||'</td><TD class=''awrnc''>'||b.HOST_NAME||'</td><td class=''awrnc'' align=''center''>'||sysdate FROM V$INSTANCE B)
  FROM V$DATABASE A;
prompt </td></tr>
prompt </table>
prompt <p/>

prompt <table border="0" width=400><tr><td align="center"><h3 class='awr'>Index</h3></td></tr></table>
prompt <table border="1" width=400> -
<tr><th class='awrbg'>DB info</th></tr> -
<tr><td align="center"> -
<a href="#Version and Patch">Version and Patch</a><br> -
<a href="#Instance and Database">Instance and Database</a><br> -
<a href="#Non-default Parameter">Non-default Parameter</a><br> -
<a href="#Database size">Database size</a><br> -
<a href="#Segment size">Segment size</a><br> -
<a href="#Disk_file_tablespace">Disk_file_tablespace</a><br> -
</td></tr>
prompt <tr><th class='awrbg'>Health Check</th></tr> -
<tr><td align="center"> -
<a href="#Tablespace Usage">Tablespace Usage</a><br> -
<a href="#Session">Session</a><br> -
<a href="#Lock">Lock</a><br> -
<a href="#SYSTEM Tablespace Usage">SYSTEM Tablespace Usage</a><br> -
<a href="#FRA Usage">FRA Usage</a><br> -
<a href="#Invalid objects">Invalid objects</a><br> -
<a href="#dba_recyclebin">dba_recyclebin</a><br> -
<a href="#User expiry date">User expiry date</a><br> -
<a href="#Inactive Session">Inactive Session</a><br> -
<a href="#dba_scheduler_job_run_details">dba_scheduler_job_run_details Top10</a><br> -
<a href="#Memory Usage">Memory Usage</a><br> -
<a href="#Busy DAY">Busy DAY</a><br> -
<a href="#Busy HOUR">Busy HOUR</a><br> -
</td></tr>
prompt <tr><th class='awrbg'>KPI Trend</th></tr> -
<tr><td align="center"> -
<a href="#CPU Utilization">CPU Utilization</a><br> -
<a href="#Time model">Time model</a><br> -
<a href="#SQL Execution Count and Average Execution Time">SQL Execution Count and Average Execution Time</a><br> -
<a href="#Physical Read and Write">Physical Read and Write</a><br> -
<a href="#Physical Read Request and Write Request">Physical Read Request and Write Request</a><br> -
<a href="#User IO wait time">User IO wait time</a><br> -
<a href="#Average IO wait time">Average IO wait time</a><br> -
<a href="#IO wait times">IO wait times</a><br> -
<a href="#Connections">Connections</a><br> -
<a href="#User Logon">User Logon</a><br> -
<a href="#Latch Hit Point">Latch Hit Point</a><br> -
<a href="#Top 5 Wait Event">Top 5 Wait Event</a><br> -
<a href="#Top 5 Wait Event trends">Top 5 Wait Event trends</a><br> -
</td></tr>
prompt <tr><th class='awrbg'>Top10 within 15m</th></tr> -
<tr><td align="center"> -
<a href="#Top Wait Event">Top Wait Event</a><br> -
<a href="#Top SQL on CPU">Top SQL on CPU</a><br> -
<a href="#Top SQL on Resource">Top SQL on Resource</a><br> -
</td></tr> -
</table>
prompt <p/>
--<a href="#Latch:row cache objects">Latch:row cache objects</a><br> -
--<a href="#Latch:cache buffers chains">Latch:cache buffers chains</a><br> -

-- KPI Time
-----------------------------------------------------------------------
prompt <a name="KPI Time"><h3 class='awr'>KPI Time</h3></a>
prompt <TABLE BORDER=1 WIDTH=600>
prompt <tr><th class='awrnobg'></th><th class='awrbg'>Snap Id</th><th class='awrbg'>Snap Time</th></tr>
prompt <tr><TD class='awrnc'>Begin Snap:</td><TD ALIGN='right' class='awrnc'>&bid</td><TD ALIGN='center' class='awrnc'>
select
nvl((select to_char(a.end_interval_time,'yyyy-mm-dd hh24:mi:ss') from dba_hist_snapshot a where a.instance_number=&inid and a.snap_id=&bid),
'minimum snap time')
from dual;
prompt </td></tr>
prompt <tr><TD class='awrc'>End Snap:</td><TD ALIGN='right' class='awrc'>&eid</td><TD ALIGN='center' class='awrc'>
select
nvl((select to_char(a.end_interval_time,'yyyy-mm-dd hh24:mi:ss') from dba_hist_snapshot a where a.instance_number=&inid and a.snap_id=&eid),
'maximum snap time')
from dual;
prompt </td></tr>
prompt </table>
prompt <p/>
-----------------------------------------------------------------------

-- Version and Patch
prompt <a name="Version and Patch"><h3 class='awr'>Version and Patch</h3></a>
prompt <TABLE BORDER=1 WIDTH=600>
prompt <tr> -
<th class='awrbg'>BANNER</th> -
</tr>
select '<tr>'|| -
'<TD class=''awrnc''>'||BANNER||'</td>'
||'</tr>'
from v$version;
prompt </table>
prompt <p/>
prompt <TABLE BORDER=1 WIDTH=600>
prompt <tr> -
<th class='awrbg'>ACTION_TIME</th> -
<th class='awrbg'>ACTION</th> -
<th class='awrbg'>NAMESPACE</th> -
<th class='awrbg'>VERSION</th> -
<th class='awrbg'>ID</th> -
<th class='awrbg'>COMMENTS</th> -
</tr>
select '<tr>'|| -
'<TD class=''awrnc''>'||ACTION_TIME||'</td>',
'<TD class=''awrnc''>'||ACTION||'</td>',
'<TD class=''awrnc''>'||NAMESPACE||'</td>',
'<TD class=''awrnc''>'||VERSION||'</td>',
'<TD class=''awrnc''>'||ID||'</td>',
'<TD class=''awrnc''>'||COMMENTS||'</td>'
||'</tr>'
from dba_registry_history;
prompt </table>
prompt <p/>

-- Instance and Database
prompt <a name="Instance and Database"><h3 class='awr'>Instance and Database</h3></a>
prompt <TABLE BORDER=1 WIDTH=600>
prompt <tr> -
<th class='awrbg'>INSTANCE_NUMBER</th> -
<th class='awrbg'>INSTANCE_NAME</th> -
<th class='awrbg'>host_name</th> -
<th class='awrbg'>STATUS</th> -
<th class='awrbg'>STARTUP_TIME</th> -
<th class='awrbg'>THREAD#</th> -
</tr>
select '<tr>'|| -
'<TD class=''awrnc''>'||INSTANCE_NUMBER||'</td>',
'<TD class=''awrnc''>'||INSTANCE_NAME||'</td>',
'<TD class=''awrnc''>'||host_name||'</td>',
'<TD class=''awrnc''>'||STATUS||'</td>',
'<TD class=''awrnc''>'||STARTUP_TIME||'</td>',
'<TD class=''awrnc''>'||THREAD#||'</td>'
||'</tr>'
from gv$instance order by 1;
prompt </table>
prompt <p/>
prompt <TABLE BORDER=1 WIDTH=1000>
prompt <tr> -
<th class='awrbg'>open_mode</th> -
<th class='awrbg'>created</th> -
<th class='awrbg'>log_mode</th> -
<th class='awrbg'>checkpoint_change#</th> -
<th class='awrbg'>controlfile_type</th> -
<th class='awrbg'>controlfile_created</th> -
<th class='awrbg'>controlfile_change#</th> -
<th class='awrbg'>controlfile_time</th> -
<th class='awrbg'>resetlogs_change#</th> -
<th class='awrbg'>resetlogs_time</th> -
</tr>
select '<tr>'|| -
'<TD class=''awrnc''>'||open_mode||'</td>',
'<TD class=''awrnc''>'||created||'</td>',
'<TD class=''awrnc''>'||log_mode||'</td>',
'<TD class=''awrnc''>'||checkpoint_change#||'</td>',
'<TD class=''awrnc''>'||controlfile_type||'</td>',
'<TD class=''awrnc''>'||controlfile_created||'</td>',
'<TD class=''awrnc''>'||controlfile_change#||'</td>',
'<TD class=''awrnc''>'||controlfile_time||'</td>',
'<TD class=''awrnc''>'||resetlogs_change#||'</td>',
'<TD class=''awrnc''>'||resetlogs_time||'</td>'
||'</tr>'
from v$database;
prompt </table>
prompt <p/>

-- Non-default Parameter
prompt <a name="Non-default Parameter"><h3 class='awr'>Non-default Parameter</h3></a>
prompt <TABLE BORDER=1 WIDTH=45%>
prompt <tr> -
<th class='awrbg'>name</th> -
<th class='awrbg'>value</th> -
</tr>
select '<tr>'|| -
'<TD class=''awrnc''>'||p.name||'</td>',
'<TD class=''awrnc''>'||p.value||'</td>'
||'</tr>'
FROM
    v$parameter p
WHERE
    isdefault='FALSE'
ORDER BY p.name;
prompt </table>
prompt <p/>

-- Database size
prompt <a name="Database size"><h3 class='awr'>Database size</h3></a>
prompt <TABLE BORDER=1 WIDTH=30%>
prompt <tr> -
<th class='awrbg'>Type</th> -
<th class='awrbg'>Size GB</th> -
</tr>
select '<tr>'|| -
'<TD class=''awrnc''>'||'data_files_size'||'</td>',
'<TD class=''awrnc''>'||round(sum(bytes)/1024/1024/1024,2)||'</td>'
||'</tr>'
from dba_data_files;
select '<tr>'|| -
'<TD class=''awrnc''>'||'temp_files_size'||'</td>',
'<TD class=''awrnc''>'||round(sum(bytes)/1024/1024/1024,2)||'</td>'
||'</tr>'
from dba_temp_files;
select '<tr>'|| -
'<TD class=''awrnc''>'||'log_files_size'||'</td>',
'<TD class=''awrnc''>'||round(sum(bytes)/1024/1024/1024,2)||'</td>'
||'</tr>'
from v$log;
select '<tr>'|| -
'<TD class=''awrnc''>'||'segments_size'||'</td>',
'<TD class=''awrnc''>'||round(sum(bytes)/1024/1024/1024,2)||'</td>'
||'</tr>'
from dba_segments;
prompt </table>
prompt <p/>
prompt <TABLE BORDER=1 WIDTH=30%>
prompt <tr> -
<th class='awrbg'>owner</th> -
<th class='awrbg'>segments_GB</th> -
</tr>
select '<tr>'|| -
'<TD class=''awrnc''>'||owner||'</td>',
'<TD class=''awrnc''>'||round(sum(bytes)/1024/1024/1024,2)||'</td>'
||'</tr>'
from dba_segments where bytes>10000000 group by owner order by 2;
prompt </table>
prompt <p/>

-- Segment size
prompt <a name="Segment size"><h3 class='awr'>Segment size</h3></a>
prompt <TABLE BORDER=1 WIDTH=45%>
prompt <tr> -
<th class='awrbg'>segment_name</th> -
<th class='awrbg'>segment_type</th> -
<th class='awrbg'>MB</th> -
</tr>
-- select '<tr>'|| -
-- '<TD class=''awrnc''>'||segment_name||'</td>',
-- '<TD class=''awrnc''>'||segment_type||'</td>',
-- '<TD class=''awrnc''>'||MB||'</td>'
-- ||'</tr>'
-- FROM (SELECT segment_name,
--                segment_type,
--                trunc(SUM(bytes) / 1024 / 1024) MB
--           FROM dba_segments
--          WHERE segment_name NOT LIKE '%$%'
--          GROUP BY segment_name, segment_type
--          ORDER BY 3 DESC)
--  WHERE rownum <= 10;
prompt </table>
prompt <p/>

-- Disk_file_tablespace
prompt <a name="Disk_file_tablespace"><h3 class='awr'>Disk_file_tablespace</h3></a>
prompt <TABLE BORDER=1 WIDTH=45%>
prompt <tr> -
<th class='awrbg'>GROUP_NUMBER</th> -
<th class='awrbg'>NAME</th> -
<th class='awrbg'>STATE</th> -
<th class='awrbg'>TYPE</th> -
<th class='awrbg'>TOTAL_MB</th> -
<th class='awrbg'>FREE_MB</th> -
</tr>
select '<tr>'|| -
'<TD class=''awrnc''>'||GROUP_NUMBER||'</td>',
'<TD class=''awrnc''>'||NAME||'</td>',
'<TD class=''awrnc''>'||STATE||'</td>',
'<TD class=''awrnc''>'||TYPE||'</td>',
'<TD class=''awrnc''>'||TOTAL_MB||'</td>',
'<TD class=''awrnc''>'||FREE_MB||'</td>'
||'</tr>'
from v$asm_diskgroup order by GROUP_NUMBER;
prompt </table>
prompt <p/>
prompt <TABLE BORDER=1 WIDTH=45%>
prompt <tr> -
<th class='awrbg'>GROUP_NUMBER</th> -
<th class='awrbg'>DISK_NUMBER</th> -
<th class='awrbg'>TOTAL_MB</th> -
<th class='awrbg'>FREE_MB</th> -
<th class='awrbg'>NAME</th> -
<th class='awrbg'>PATH</th> -
</tr>
select '<tr>'|| -
'<TD class=''awrnc''>'||GROUP_NUMBER||'</td>',
'<TD class=''awrnc''>'||DISK_NUMBER||'</td>',
'<TD class=''awrnc''>'||TOTAL_MB||'</td>',
'<TD class=''awrnc''>'||FREE_MB||'</td>',
'<TD class=''awrnc''>'||NAME||'</td>',
'<TD class=''awrnc''>'||PATH||'</td>'
||'</tr>'
from v$asm_disk order by GROUP_NUMBER,DISK_NUMBER;
prompt </table>
prompt <p/>
prompt <TABLE BORDER=1 WIDTH=45%>
prompt <tr> -
<th class='awrbg'>tablespace_name</th> -
<th class='awrbg'>file_name</th> -
<th class='awrbg'>GB</th> -
<th class='awrbg'>autoextensible</th> -
<th class='awrbg'>increment_by</th> -
</tr>
select '<tr>'|| -
'<TD class=''awrnc''>'||tablespace_name||'</td>',
'<TD class=''awrnc''>'||file_name||'</td>',
'<TD class=''awrnc''>'||round(bytes/1024/1024/1024,0)||'</td>',
'<TD class=''awrnc''>'||autoextensible||'</td>',
'<TD class=''awrnc''>'||increment_by||'</td>'
||'</tr>'
from dba_data_files order by 1;
prompt </table>
prompt <p/>
prompt <TABLE BORDER=1 WIDTH=45%>
prompt <tr> -
<th class='awrbg'>tablespace_name</th> -
<th class='awrbg'>file_name</th> -
<th class='awrbg'>GB</th> -
<th class='awrbg'>autoextensible</th> -
<th class='awrbg'>increment_by</th> -
</tr>
select '<tr>'|| -
'<TD class=''awrnc''>'||tablespace_name||'</td>',
'<TD class=''awrnc''>'||file_name||'</td>',
'<TD class=''awrnc''>'||round(bytes/1024/1024/1024,0)||'</td>',
'<TD class=''awrnc''>'||autoextensible||'</td>',
'<TD class=''awrnc''>'||increment_by||'</td>'
||'</tr>'
from dba_temp_files order by 3;
prompt </table>
prompt <p/>

-- Tablespace Usage
prompt <a name="Tablespace Usage"><h3 class='awr'>Tablespace Usage</h3></a>
prompt <TABLE BORDER=1 WIDTH=500>
prompt <tr> -
<th class='awrbg'>TABLESPACE_NAME</th> -
<th class='awrbg'>TOTAL(G)</th> -
<th class='awrbg'>USED(G)</th> -
<th class='awrbg'>FREE(G)</th> -
<th class='awrbg'>USAGE(%)</th> -
</tr>
select '<tr>'|| -
'<TD class=''awrnc''>'||A.TABLESPACE_NAME||'</td>',
'<TD class=''awrnc''>'||ROUND(A.WLTOTAL / 1024 / 1024 / 1024, 2)||'</td>',
'<TD class=''awrnc''>'||ROUND((A.TOTAL - NVL(B.FREE, 0)) / 1024 / 1024 / 1024, 2)||'</td>',
'<TD class=''awrnc''>'||ROUND((A.WLTOTAL - (A.TOTAL - NVL(B.FREE, 0))) / 1024 / 1024 / 1024, 2)||'</td>',
'<TD class=''awrnc''>'||ROUND((A.TOTAL - NVL(B.FREE, 0)) / A.WLTOTAL, 4) * 100||'</td>'
||'</tr>'
  FROM (SELECT TABLESPACE_NAME,
               SUM(decode(autoextensible, 'YES', MAXBYTES, BYTES)) WLTOTAL,
               SUM(BYTES) TOTAL
          FROM DBA_DATA_FILES
         GROUP BY TABLESPACE_NAME) A,
       (SELECT TABLESPACE_NAME, SUM(BYTES) FREE
          FROM DBA_FREE_SPACE
         GROUP BY TABLESPACE_NAME) B
 WHERE A.TABLESPACE_NAME = B.TABLESPACE_NAME(+)
 ORDER BY ROUND((A.TOTAL - NVL(B.FREE, 0)) / 1024 / 1024 / 1024, 2) DESC;
prompt </table>
prompt <p/>

-- Session
prompt <a name="Session"><h3 class='awr'>Session</h3></a>
prompt <TABLE BORDER=1 WIDTH=800>
prompt <tr> -
<th class='awrbg'>inst_id</th> -
<th class='awrbg'>username</th> -
<th class='awrbg'>machine</th> -
<th class='awrbg'>osuser</th> -
<th class='awrbg'>program</th> -
<th class='awrbg'>status</th> -
<th class='awrbg'>count(*)</th> -
</tr>
select '<tr>'|| -
'<TD class=''awrnc''>'||s.inst_id||'</td>',
'<TD class=''awrnc''>'||s.username||'</td>',
'<TD class=''awrnc''>'||s.machine||'</td>',
'<TD class=''awrnc''>'||s.osuser||'</td>',
'<TD class=''awrnc''>'||s.program||'</td>',
'<TD class=''awrnc''>'||s.status||'</td>',
'<TD class=''awrnc''>'||count(*)||'</td>'
||'</tr>'
  from gv$session s
 where 1 = 1
   and s.username not in ('XXX')
 group by s.inst_id, s.username, s.machine, s.osuser, s.program, s.status
 order by 6 desc,7 desc;
prompt </table>
prompt <p/>

-- Lock
prompt <a name="Lock"><h3 class='awr'>Lock</h3></a>
prompt <TABLE BORDER=1 WIDTH=45%>
prompt <tr> -
<th class='awrbg'>object_name</th> -
<th class='awrbg'>machine</th> -
<th class='awrbg'>sid</th> -
<th class='awrbg'>serial#</th> -
<th class='awrbg'>status</th> -
</tr>
select '<tr>'|| -
'<TD class=''awrnc''>'||object_name||'</td>',
'<TD class=''awrnc''>'||machine||'</td>',
'<TD class=''awrnc''>'||s.sid||'</td>',
'<TD class=''awrnc''>'||s.serial#||'</td>',
'<TD class=''awrnc''>'||s.status||'</td>'
||'</tr>'
  from gv$locked_object l, dba_objects o, gv$session s
 where l.object_id = o.object_id
   and l.session_id = s.sid;
prompt </table>
prompt <p/>
prompt <TABLE BORDER=1 WIDTH=100%>
prompt <tr> -
<th class='awrbg'>username</th> -
<th class='awrbg'>object_name</th> -
<th class='awrbg'>owner</th> -
<th class='awrbg'>machine</th> -
<th class='awrbg'>program</th> -
<th class='awrbg'>ctime(s)</th> -
<th class='awrbg'>alter_system_kill_session...</th> -
<th class='awrbg'>kill_process</th> -
<th class='awrbg'>sql_text</th> -
</tr>
select '<tr>'|| -
'<TD class=''awrnc''>'||a.username||'</td>',
'<TD class=''awrnc''>'||c.object_name||'</td>',
'<TD class=''awrnc''>'||c.owner||'</td>',
'<TD class=''awrnc''>'||a.machine||'</td>',
'<TD class=''awrnc''>'||a.program||'</td>',
'<TD class=''awrnc''>'||b.ctime||'</td>',
'<TD class=''awrnc''>'||'alter system kill session ''' || a.sid || ',' || a.serial# || ''' immediate;'||'</td>',
'<TD class=''awrnc''>'||'kill -9 ' || d.spid||'</td>',
'<TD class=''awrnc''>'||g.sql_text||'</td>'
||'</tr>'
  FROM gv$session       a,
       gv$lock          b,
       gv$locked_object b1,
       dba_objects      c,
       gv$process       d,
       gv$instance      f,
       gv$sqlarea       g
 WHERE a.type <> 'BACKGROUND'
   AND a.sid = b.sid
   AND b.request = 0
   AND b.type <> 'AE'
   AND b.ctime > 300
   AND d.addr = a.paddr
   AND b1.session_id = a.sid
   AND b1.object_id = c.object_id
   AND f.status = 'OPEN'
   AND f.database_status = 'ACTIVE'
   AND a.sql_hash_value=g.hash_value
   AND a.username <> 'SYS'
 order by b.ctime desc;
prompt </table>
prompt <p/>

-- SYSTEM Tablespace Usage
prompt <a name="SYSTEM Tablespace Usage"><h3 class='awr'>SYSTEM Tablespace Usage</h3></a>
prompt <TABLE BORDER=1 WIDTH=45%>
prompt <tr> -
<th class='awrbg'>owner</th> -
<th class='awrbg'>table_name/index_name</th> -
<th class='awrbg'>tablespace_name</th> -
</tr>
select '<tr>'|| -
'<TD class=''awrnc''>'||owner||'</td>',
'<TD class=''awrnc''>'||table_name||'</td>',
'<TD class=''awrnc''>'||tablespace_name||'</td>'
||'</tr>'
from dba_tables where owner not in ('SYS','SYSTEM','OUTLN','MDSYS','OLAPSYS','ORDDATA','XDB') and tablespace_name ='SYSTEM' order by 1,2;
select '<tr>'|| -
'<TD class=''awrnc''>'||owner||'</td>',
'<TD class=''awrnc''>'||index_name||'</td>',
'<TD class=''awrnc''>'||tablespace_name||'</td>'
||'</tr>'
from dba_indexes where owner not in ('SYS','SYSTEM','OUTLN','MDSYS','OLAPSYS','ORDDATA','XDB') and tablespace_name ='SYSTEM' order by 1,2;
prompt </table>
prompt <p/>

-- FRA Usage
prompt <a name="FRA Usage"><h3 class='awr'>FRA Usage</h3></a>
prompt <TABLE BORDER=1 WIDTH=45%>
prompt <tr> -
<th class='awrbg'>space_limit GB</th> -
<th class='awrbg'>space_used GB</th> -
<th class='awrbg'>Used%</th> -
<th class='awrbg'>space_reclaimable</th> -
<th class='awrbg'>number_of_files</th> -
</tr>
select '<tr>'|| -
'<TD class=''awrnc''>'||round(space_limit/1024/1024/1024,2)||'</td>',
'<TD class=''awrnc''>'||round(space_used/1024/1024/1024,2)||'</td>',
'<TD class=''awrnc''>'||round(space_used/space_limit*100,2)||'</td>',
'<TD class=''awrnc''>'||space_reclaimable||'</td>',
'<TD class=''awrnc''>'||number_of_files||'</td>'
||'</tr>'
FROM v$recovery_file_dest;
prompt </table>
prompt <p/>
prompt <TABLE BORDER=1 WIDTH=45%>
prompt <tr> -
<th class='awrbg'>FILE_TYPE</th> -
<th class='awrbg'>PERCENT_SPACE_USED</th> -
<th class='awrbg'>PERCENT_SPACE_RECLAIMABLE</th> -
<th class='awrbg'>NUMBER_OF_FILES</th> -
</tr>
select '<tr>'|| -
'<TD class=''awrnc''>'||FILE_TYPE||'</td>',
'<TD class=''awrnc''>'||PERCENT_SPACE_USED||'</td>',
'<TD class=''awrnc''>'||PERCENT_SPACE_RECLAIMABLE||'</td>',
'<TD class=''awrnc''>'||NUMBER_OF_FILES||'</td>'
||'</tr>'
from V$FLASH_RECOVERY_AREA_USAGE;
prompt </table>
prompt <p/>

-- Invalid objects
prompt <a name="Invalid objects"><h3 class='awr'>Invalid objects</h3></a>
prompt <TABLE BORDER=1 WIDTH=80%>
prompt <tr> -
<th class='awrbg'>owner</th> -
<th class='awrbg'>object_type</th> -
<th class='awrbg'>object_name</th> -
<th class='awrbg'>todo</th> -
</tr>
select '<tr>'|| -
'<TD class=''awrnc''>'||owner||'</td>',
'<TD class=''awrnc''>'||object_type||'</td>',
'<TD class=''awrnc''>'||object_name||'</td>',
'<TD class=''awrnc''>'||'ALTER ' || OBJECT_TYPE || ' ' || OWNER || '.' || OBJECT_NAME || ' COMPILE;'||'</td>'
||'</tr>'
  from dba_objects
 where object_name not like '%$_%' and status = 'INVALID' order by 1,2,3;
prompt </table>
prompt <p/>

-- dba_recyclebin
prompt <a name="dba_recyclebin"><h3 class='awr'>dba_recyclebin</h3></a>
prompt <TABLE BORDER=1 WIDTH=45%>
prompt <tr> -
<th class='awrbg'>OWNER</th> -
<th class='awrbg'>count(*)</th> -
</tr>
select '<tr>'|| -
'<TD class=''awrnc''>'||OWNER||'</td>',
'<TD class=''awrnc''>'||count(*)||'</td>'
||'</tr>'
from DBA_RECYCLEBIN group by "OWNER";
select '<tr>'|| -
'<TD class=''awrnc''>'||'All users'||'</td>',
'<TD class=''awrnc''>'||count(*)||'</td>'
||'</tr>'
from DBA_RECYCLEBIN;
prompt </table>
prompt <p/>

-- User expiry date
prompt <a name="User expiry date"><h3 class='awr'>User expiry date</h3></a>
prompt <TABLE BORDER=1 WIDTH=45%>
prompt <tr> -
<th class='awrbg'>username</th> -
<th class='awrbg'>expiry_date</th> -
<th class='awrbg'>days</th> -
</tr>
select '<tr>'|| -
'<TD class=''awrnc''>'||username||'</td>',
'<TD class=''awrnc''>'||expiry_date||'</td>',
'<TD class=''awrnc''>'||trunc(expiry_date-sysdate)||'</td>'
||'</tr>'
from dba_users where username not like '%SYS%' order by expiry_date,username;
prompt </table>
prompt <p/>

-- Inactive Session
prompt <a name="Inactive Session"><h3 class='awr'>Inactive Session</h3></a>
prompt <TABLE BORDER=1 WIDTH=80%>
prompt <tr> -
<th class='awrbg'>username</th> -
<th class='awrbg'>machine</th> -
<th class='awrbg'>program</th> -
<th class='awrbg'>last_call_et</th> -
<th class='awrbg'>todo</th> -
</tr>
select '<tr>'|| -
'<TD class=''awrnc''>'||s.username||'</td>',
'<TD class=''awrnc''>'||s.machine||'</td>',
'<TD class=''awrnc''>'||s.program||'</td>',
'<TD class=''awrnc''>'||s.last_call_et||'</td>',
'<TD class=''awrnc''>'||'alter system kill session '''||s.sid||','||s.serial#||''' immediate;'||'</td>'
||'</tr>'
from gv$session s where status = 'INACTIVE' and s.last_call_et>2*60*60 and s.username not in('SYS') order by s.last_call_et desc;
prompt </table>
prompt <p/>

-- dba_scheduler_job_run_details
prompt <a name="dba_scheduler_job_run_details"><h3 class='awr'>dba_scheduler_job_run_details</h3></a>
prompt <TABLE BORDER=1 WIDTH=60%>
prompt <tr> -
<th class='awrbg'>owner</th> -
<th class='awrbg'>job_name</th> -
<th class='awrbg'>status</th> -
<th class='awrbg'>start_date</th> -
<th class='awrbg'>log_date</th> -
<th class='awrbg'>run_duration</th> -
</tr>
select '<tr>'|| -
'<TD class=''awrnc''>'||owner||'</td>',
'<TD class=''awrnc''>'||job_name||'</td>',
'<TD class=''awrnc''>'||status||'</td>',
'<TD class=''awrnc''>'||start_date||'</td>',
'<TD class=''awrnc''>'||log_date||'</td>',
'<TD class=''awrnc''>'||run_duration||'</td>'
||'</tr>'
  FROM (SELECT owner,
               job_name,
               status,
               to_char(actual_start_date, 'YYYY-MM-DD HH24:MI:SS') start_date,
               to_char(log_date, 'YYYY-MM-DD HH24:MI:SS') log_date,
               run_duration
          FROM dba_scheduler_job_run_details
         WHERE owner NOT IN ('SYS', 'ORACLE_OCM', 'EXFSYS')
         ORDER BY 6 DESC)
 WHERE rownum <= 10;
 prompt </table>
prompt <p/>

-- Memory Usage
prompt <a name="Memory Usage"><h3 class='awr'>Memory Usage</h3></a>
prompt <TABLE BORDER=1 WIDTH=80%>
prompt <tr> -
<th class='awrbg'>COMPONENT</th> -
<th class='awrbg'>CURRENT_SIZE</th> -
<th class='awrbg'>MIN_SIZE</th> -
<th class='awrbg'>MAX_SIZE</th> -
<th class='awrbg'>USER_SPECIFIED_SIZE</th> -
<th class='awrbg'>OPER_COUNT</th> -
<th class='awrbg'>LAST_OPER_TYPE</th> -
<th class='awrbg'>LAST_OPER_MODE</th> -
<th class='awrbg'>LAST_OPER_TIME</th> -
<th class='awrbg'>GRANULE_SIZE</th> -
</tr>
select '<tr>'|| -
'<TD class=''awrnc''>'||COMPONENT||'</td>',
'<TD class=''awrnc''>'||CURRENT_SIZE||'</td>',
'<TD class=''awrnc''>'||MIN_SIZE||'</td>',
'<TD class=''awrnc''>'||MAX_SIZE||'</td>',
'<TD class=''awrnc''>'||USER_SPECIFIED_SIZE||'</td>',
'<TD class=''awrnc''>'||OPER_COUNT||'</td>',
'<TD class=''awrnc''>'||LAST_OPER_TYPE||'</td>',
'<TD class=''awrnc''>'||LAST_OPER_MODE||'</td>',
'<TD class=''awrnc''>'||LAST_OPER_TIME||'</td>',
'<TD class=''awrnc''>'||GRANULE_SIZE||'</td>'
||'</tr>'
from v$memory_dynamic_components;
prompt </table>
prompt <p/>
prompt <TABLE BORDER=1 WIDTH=50%>
prompt <tr> -
<th class='awrbg'>SGA_SIZE</th> -
<th class='awrbg'>SGA_SIZE_FACTOR</th> -
<th class='awrbg'>ESTD_DB_TIME</th> -
<th class='awrbg'>ESTD_DB_TIME_FACTOR</th> -
<th class='awrbg'>ESTD_PHYSICAL_READS</th> -
</tr>
select '<tr>'|| -
'<TD class=''awrnc''>'||SGA_SIZE||'</td>',
'<TD class=''awrnc''>'||SGA_SIZE_FACTOR||'</td>',
'<TD class=''awrnc''>'||ESTD_DB_TIME||'</td>',
'<TD class=''awrnc''>'||ESTD_DB_TIME_FACTOR||'</td>',
'<TD class=''awrnc''>'||ESTD_PHYSICAL_READS||'</td>'
||'</tr>'
from v$sga_target_advice;
prompt </table>
prompt <p/>
prompt <TABLE BORDER=1 WIDTH=45%>
prompt <tr> -
<th class='awrbg'>NAME</th> -
<th class='awrbg'>VALUE</th> -
<th class='awrbg'>UNIT</th> -
</tr>
select '<tr>'|| -
'<TD class=''awrnc''>'||NAME||'</td>',
'<TD class=''awrnc''>'||VALUE||'</td>',
'<TD class=''awrnc''>'||UNIT||'</td>'
||'</tr>'
from v$pgastat;
prompt </table>
prompt <p/>
prompt <TABLE BORDER=1 WIDTH=45%>
-- ESTD_TIME only support 11g
-- <th class='awrbg'>ESTD_TIME</th> -
-- '<TD class=''awrnc''>'||ESTD_TIME||'</td>',
prompt <tr> -
<th class='awrbg'>PGA_TARGET_FOR_ESTIMATE</th> -
<th class='awrbg'>PGA_TARGET_FACTOR</th> -
<th class='awrbg'>ADVICE_STATUS</th> -
<th class='awrbg'>BYTES_PROCESSED</th> -
<th class='awrbg'>ESTD_EXTRA_BYTES_RW</th> -
<th class='awrbg'>ESTD_PGA_CACHE_HIT_PERCENTAGE</th> -
<th class='awrbg'>ESTD_OVERALLOC_COUNT</th> -
</tr>
select '<tr>'|| -
'<TD class=''awrnc''>'||PGA_TARGET_FOR_ESTIMATE||'</td>',
'<TD class=''awrnc''>'||PGA_TARGET_FACTOR||'</td>',
'<TD class=''awrnc''>'||ADVICE_STATUS||'</td>',
'<TD class=''awrnc''>'||BYTES_PROCESSED||'</td>',
'<TD class=''awrnc''>'||ESTD_EXTRA_BYTES_RW||'</td>',
'<TD class=''awrnc''>'||ESTD_PGA_CACHE_HIT_PERCENTAGE||'</td>',
'<TD class=''awrnc''>'||ESTD_OVERALLOC_COUNT||'</td>'
||'</tr>'
from v$pga_target_advice;
prompt </table>
prompt <p/>

-- Busy DAY
prompt <a name="Busy DAY"><h3 class='awr'>Busy DAY</h3></a>
prompt <TABLE BORDER=1 WIDTH=45%>
prompt <tr> -
<th class='awrbg'>day</th> -
<th class='awrbg'>logs</th> -
</tr>
select '<tr>'|| -
'<TD class=''awrnc''>'||day||'</td>',
'<TD class=''awrnc''>'||logs||'</td>'
||'</tr>'
from (select to_char(FIRST_TIME,'yyyy/mm/dd') day,count(*) logs from v$log_history group by to_char(FIRST_TIME,'yyyy/mm/dd') order by 2 desc) where rownum < 10;
prompt </table>
prompt <p/>

-- Busy HOUR
prompt <a name="Busy HOUR"><h3 class='awr'>Busy HOUR</h3></a>
prompt <TABLE BORDER=1 WIDTH=45%>
prompt <tr> -
<th class='awrbg'>hour</th> -
<th class='awrbg'>logs</th> -
</tr>
select '<tr>'|| -
'<TD class=''awrnc''>'||hour||'</td>',
'<TD class=''awrnc''>'||logs||'</td>'
||'</tr>'
from (select to_char(FIRST_TIME,'yyyy/mm/dd hh24') hour,count(*) logs from v$log_history group by to_char(FIRST_TIME,'yyyy/mm/dd hh24') order by 2 desc) where rownum < 10;
prompt </table>
prompt <p/>

spool off
set termout       on
prompt
prompt Start to Find Top 10. Please wait ......
set termout       off
spool &rpt_name append

-- Top Wait Event
prompt <a name="Top Wait Event"><h3 class='awr'>Top Wait Event</h3></a>
prompt <TABLE BORDER=1 WIDTH=500>
prompt <tr> -
<th class='awrbg'>event</th> -
<th class='awrbg'>total_wait_time</th> -
</tr>
SELECT '<tr>'|| -
'<TD class=''awrnc''>'||event||'</td>',
'<TD class=''awrnc''>'||total_wait_time||'</td>'
||'</tr>'
  FROM (SELECT event, SUM(wait_time + time_waited) total_wait_time
          FROM v$active_session_history
         WHERE sample_time BETWEEN SYSDATE - 15 / (24 * 60) AND SYSDATE
         GROUP BY event
         ORDER BY total_wait_time DESC)
 WHERE rownum <= 10;
prompt </table>
prompt <p/>

-- Top SQL on CPU
prompt <a name="Top SQL on CPU"><h3 class='awr'>Top SQL on CPU</h3></a>
prompt <TABLE BORDER=1 WIDTH=1000>
prompt <tr> -
<th class='awrbg'>sql_id</th> -
<th class='awrbg'>count</th> -
<th class='awrbg'>pctload</th> -
<th class='awrbg'>sql_text</th> -
</tr>
SELECT DISTINCT '<tr>'|| -
'<TD class=''awrnc''>'||a.sql_id||'</td>',
'<TD class=''awrnc''>'||a.count||'</td>',
'<TD class=''awrnc''>'||a.pctload||'</td>',
'<TD class=''awrnc''>'||b.sql_text||'</td>'
||'</tr>'
  FROM (SELECT *
          FROM (SELECT sql_id, COUNT(*) COUNT, round(COUNT(*) / SUM(COUNT(*)) over(), 3) * 100 || '%' pctload
                  FROM gv$active_session_history
                 WHERE sample_time > SYSDATE - 15 / (24 * 60) AND session_type <> 'BACKGROUND' AND
                       session_state = 'ON CPU'
                 GROUP BY sql_id
                 ORDER BY 2 DESC)
         WHERE rownum <= 10) a,
       gv$sql b
 WHERE a.sql_id = b.sql_id
 ORDER BY 2;
prompt </table>
prompt <p/>

-- Top SQL on Resource
prompt <a name="Top SQL on Resource"><h3 class='awr'>Top SQL on Resource</h3></a>
prompt <TABLE BORDER=1 WIDTH=1000>
prompt <tr> -
<th class='awrbg'>sql_id</th> -
<th class='awrbg'>CPU</th> -
<th class='awrbg'>WAIT</th> -
<th class='awrbg'>IO</th> -
<th class='awrbg'>TOTAL</th> -
<th class='awrbg'>sql_text</th> -
</tr>
SELECT DISTINCT '<tr>'|| -
'<TD class=''awrnc''>'||a.sql_id||'</td>',
'<TD class=''awrnc''>'||a.CPU||'</td>',
'<TD class=''awrnc''>'||a.WAIT||'</td>',
'<TD class=''awrnc''>'||a.IO||'</td>',
'<TD class=''awrnc''>'||a.TOTAL||'</td>',
'<TD class=''awrnc''>'||b.sql_text||'</td>'
||'</tr>'
  FROM (SELECT *
          FROM (SELECT ash.sql_id,
                       SUM(decode(ash.session_state, 'ON CPU', 1, 0)) "CPU",
                       SUM(decode(ash.session_state, 'WAITING', 1, 0)) -
                       SUM(decode(ash.session_state, 'WAITING', decode(en.wait_class, 'USER I/O', 1, 0), 0)) "WAIT",
                       SUM(decode(ash.session_state, 'WAITING', decode(en.wait_class, 'USER I/O', 1, 0), 0)) "IO",
                       SUM(decode(ash.session_state, 'ON CPU', 1, 1)) "TOTAL"
                  FROM v$active_session_history ash, v$event_name en
                 WHERE sql_id IS NOT NULL AND en.event# = ash.event# AND
                       ash.sample_time > SYSDATE - 15 / (24 * 60)
                 GROUP BY ash.sql_id
                 ORDER BY SUM(decode(ash.session_state, 'ON CPU', 1, 1)) DESC)
         WHERE rownum <= 10) a,
       gv$sql b
 WHERE a.sql_id = b.sql_id
 ORDER BY 5;
prompt </table>
prompt <p/>

spool off
set termout       on
prompt
prompt Start to Create KPI Trend Chart. Please wait ......
set termout       off
spool &rpt_name append

-- CPU Utilization
-----------------------------------------------------------------------
prompt <a class="awr" name="CPU Utilization"></a>
prompt <p><h3 class='awr'>CPU Utilization</h3></p>
prompt <a1 class="awr" href="#10">Comments: none</a1>
prompt  <div style="width:100%;">
prompt    <canvas width="1800" height="600" id="canvas_cpu"></canvas>
prompt  </div>
prompt  <a class="awr" href="#top">Back to Top</a>
-----------------------------------------------------------------------

-- Time model
-----------------------------------------------------------------------
prompt <a class="awr" name="Time model"></a>
prompt <p><h3 class='awr'>Time Model: DB TIME, DB CPU, SQL EXEC TIME</h3></p>
prompt <a1 class="awr" href="#10">Comments: snap sample interval &_iv seconds, cpu count &_cpucount</a1>
prompt  <div style="width:100%;">
prompt    <canvas width="1800" height="600" id="canvas_dbtime"></canvas>
prompt  </div>
prompt  <a class="awr" href="#top">Back to Top</a>
-----------------------------------------------------------------------

-- SQL Execution Count and Average Execution Time
-----------------------------------------------------------------------
prompt <a class="awr" name="SQL Execution Count and Average Execution Time"></a>
prompt <p><h3 class='awr'>SQL Execution Count and Average Execution Time</h3></p>
prompt <a1 class="awr" href="#10">Comments: Unit of Time is micro second</a1>
prompt <div style="width:100%;">
prompt <canvas width="1800" height="600" id="canvas_sql"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
-----------------------------------------------------------------------

-- Physical Read and Write
-----------------------------------------------------------------------
prompt <a class="awr" name="Physical Read and Write"></a>
prompt <p><h3 class='awr'>Physical Read and Write</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas width="1800" height="600" id="canvas_phy"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
-----------------------------------------------------------------------

-- Physical Read Request and Write Request
-----------------------------------------------------------------------
prompt <a class="awr" name="Physical Read Request and Write Request"></a>
prompt <p><h3 class='awr'>Physical Read Request and Write Request</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas width="1800" height="600" id="canvas_phyreq"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
-----------------------------------------------------------------------

-- User IO wait time
-----------------------------------------------------------------------
prompt <a class="awr" name="User IO wait time"></a>
prompt <p><h3 class='awr'>User IO wait time</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas width="1800" height="600" id="canvas_userio"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
-----------------------------------------------------------------------

-- Average IO wait time
-----------------------------------------------------------------------
prompt <a class="awr" name="Average IO wait time"></a>
prompt <p><h3 class='awr'>Average IO wait time</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas width="1800" height="600" id="canvas_avgio"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
-----------------------------------------------------------------------

-- IO wait times
-----------------------------------------------------------------------
prompt <a class="awr" name="IO wait times"></a>
prompt <p><h3 class='awr'>IO wait times</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:450%;">
prompt <canvas width="3000px" height="200px" id="canvas_iotimes"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
-----------------------------------------------------------------------

-- Connections
-----------------------------------------------------------------------
prompt <a class="awr" name="Connections"></a>
prompt <p><h3 class='awr'>Connections</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_conn"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
-----------------------------------------------------------------------

-- User Logon
-----------------------------------------------------------------------
prompt <a class="awr" name="User Logon"></a>
prompt <p><h3 class='awr'>User Logon</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_logon"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
-----------------------------------------------------------------------

-- Latch Hit Point
-----------------------------------------------------------------------
prompt <a class="awr" name="Latch Hit Point"></a>
prompt <p><h3 class='awr'>Latch Hit Point</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_latch"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
-----------------------------------------------------------------------

-- Latch:row cache objects
-----------------------------------------------------------------------
--prompt <a class="awr" name="Latch:row cache objects"></a>
--prompt <p><h3 class='awr'>Latch:row cache objects</h3></p>
--prompt <a1 class="awr" href="#10">Comments:</a1>
--prompt <div style="width:100%;">
--prompt <canvas  width="1800" height="600" id="canvas_latchrco"></canvas>
--prompt </div>
--prompt <a class="awr" href="#top">Back to Top</a>
-----------------------------------------------------------------------

-- Latch:cache buffers chains
-----------------------------------------------------------------------
--prompt <a class="awr" name="Latch:cache buffers chains"></a>
--prompt <p><h3 class='awr'>Latch:cache buffers chains</h3></p>
--prompt <a1 class="awr" href="#10">Comments:</a1>
--prompt <div style="width:100%;">
--prompt <canvas  width="1800" height="600" id="canvas_latchcbc"></canvas>
--prompt </div>
--prompt <a class="awr" href="#top">Back to Top</a>
-----------------------------------------------------------------------

-- Top 5 Wait Event
-----------------------------------------------------------------------
prompt <a class="awr" name="Top 5 Wait Event"></a>
prompt <p><h3 class='awr'>Top 5 Wait Event</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_event"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
-----------------------------------------------------------------------

-- Top 5 Wait Event trends
-----------------------------------------------------------------------
prompt <a class="awr" name="Top 5 Wait Event trends"></a>
prompt <p><h3 class='awr'>Top 5 Wait Event trends </h3></p>
prompt <div style="width:75%">
prompt <div>

declare
vevent varchar2(100);
vtime number;
vavgtime number;
vpctwt number;
vwaits number;
vwaitclass varchar2(100);
vbid number ;
veid number ;
vinid number:=&inid;
startid number:=&bid;
endid number:=&eid;
vstarttime varchar2(200);
vendtime varchar2(200);
cursor c1 is
SELECT EVENT,
       WAITS,
       trunc(TIME,2),
       trunc(DECODE(WAITS,
              NULL,
              TO_NUMBER(NULL),
              0,
              TO_NUMBER(NULL),
              TIME / WAITS * 1000),2) AVGWT,
       trunc(PCTWTT,2) ,
       WAIT_CLASS
  FROM (SELECT EVENT, WAITS, TIME, PCTWTT, WAIT_CLASS
          FROM (SELECT E.EVENT_NAME EVENT,
                       E.TOTAL_WAITS_FG - NVL(B.TOTAL_WAITS_FG, 0) WAITS,
                       (E.TIME_WAITED_MICRO_FG - NVL(B.TIME_WAITED_MICRO_FG, 0)) /
                       1000000 TIME,
                       100 *
                       (E.TIME_WAITED_MICRO_FG - NVL(B.TIME_WAITED_MICRO_FG, 0)) /
                       ((SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL e
                          WHERE e.SNAP_ID = veid
                            AND e.INSTANCE_NUMBER = vinid
                            AND e.STAT_NAME = 'DB time') -
                       (SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL b
                          WHERE b.SNAP_ID = vbid
                            AND b.INSTANCE_NUMBER = vinid
                            AND b.STAT_NAME = 'DB time')) PCTWTT,
                       E.WAIT_CLASS WAIT_CLASS
                  FROM DBA_HIST_SYSTEM_EVENT B, DBA_HIST_SYSTEM_EVENT E
                 WHERE B.SNAP_ID(+) = vbid
                   AND E.SNAP_ID = veid
                   AND B.INSTANCE_NUMBER(+) = vinid
                   AND E.INSTANCE_NUMBER = vinid
                   AND B.EVENT_ID(+) = E.EVENT_ID
                   AND E.TOTAL_WAITS > NVL(B.TOTAL_WAITS, 0)
                   AND E.WAIT_CLASS != 'Idle'
                UNION ALL
                SELECT 'CPU time' EVENT,
                       TO_NUMBER(NULL) WAITS,
                       ((SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL e
                          WHERE e.SNAP_ID = veid
                            AND e.INSTANCE_NUMBER = vinid
                            AND e.STAT_NAME = 'DB CPU') -
                       (SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL b
                          WHERE b.SNAP_ID = vbid
                            AND b.INSTANCE_NUMBER = vinid
                            AND b.STAT_NAME = 'DB CPU')) / 1000000 TIME,
                       100 * ((SELECT sum(value)
                                 FROM DBA_HIST_SYS_TIME_MODEL e
                                WHERE e.SNAP_ID = veid
                                  AND e.INSTANCE_NUMBER = vinid
                                  AND e.STAT_NAME = 'DB CPU') -
                       (SELECT sum(value)
                                 FROM DBA_HIST_SYS_TIME_MODEL b
                                WHERE b.SNAP_ID = vbid
                                  AND b.INSTANCE_NUMBER = vinid
                                  AND b.STAT_NAME = 'DB CPU')) /
                       ((SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL e
                          WHERE e.SNAP_ID = veid
                            AND e.INSTANCE_NUMBER = vinid
                            AND e.STAT_NAME = 'DB time') -
                       (SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL b
                          WHERE b.SNAP_ID = vbid
                            AND b.INSTANCE_NUMBER = vinid
                            AND b.STAT_NAME = 'DB time')) PCTWTT,
                       NULL WAIT_CLASS
                  from dual
                 WHERE ((SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL e
                          WHERE e.SNAP_ID = veid
                            AND e.INSTANCE_NUMBER = vinid
                            AND e.STAT_NAME = 'DB CPU') -
                       (SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL b
                          WHERE b.SNAP_ID = vbid
                            AND b.INSTANCE_NUMBER = vinid
                            AND b.STAT_NAME = 'DB CPU')) > 0)
         ORDER BY TIME DESC, WAITS DESC)
 WHERE ROWNUM <= 5;
begin
  for i in startid..endid-1 loop
    vbid:=i;
    veid:=i+1;
     select to_char(a.end_interval_time,'yyyy-mm-dd hh24:mi') into vstarttime from dba_hist_snapshot a where snap_id=vbid and instance_number=&inid;
     select to_char(a.end_interval_time,'yyyy-mm-dd hh24:mi') into vendtime from dba_hist_snapshot a where snap_id=veid and instance_number=&inid;
     dbms_output.put_line('<table border="1" width="50%" ><tr><th class="awrbg" scope="col" colspan="6">'||vstarttime||' to '||vendtime);
     dbms_output.put_line('</th></tr><tr><th class="awrbg" scope="col">Event</th><th class="awrbg" scope="col">Waits</th>');
     dbms_output.put_line('<th class="awrbg" scope="col">Time(s)</th><th class="awrbg" scope="col">Avg wait (ms)</th><th class="awrbg" scope="col">% DB time</th><th class="awrbg" scope="col">Wait Class</th></tr>');

  open c1;
  loop
  fetch c1 into vevent,vwaits,vtime,vavgtime,vpctwt,vwaitclass;
  exit when c1%notfound;

   dbms_output.put_line( '<tr>' );
  dbms_output.put_line('<td scope="row" class=''awrc''>'||vevent||'</td>' );
  dbms_output.put_line('<td align="right" class=''awrc''>'||vwaits||'</td>' );
  dbms_output.put_line('<td align="right" class=''awrc''>'||vtime||'</td>' );
  dbms_output.put_line('<td align="right" class=''awrc''>'||vavgtime||'</td>' );
  dbms_output.put_line('<td align="right" class=''awrc''>'||vpctwt||'</td>' );
   dbms_output.put_line('<td class=''awrc''>'||vwaitclass||'</td>' );
  dbms_output.put_line('</tr>' );
  end loop;
  close c1;
   dbms_output.put_line('</table><p />');
  end loop;
end;
/

prompt </div>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
-----------------------------------------------------------------------

prompt <script>
prompt

-- CPU Utilization
prompt
prompt
declare
TYPE ValueList IS TABLE OF varchar2(200);
backdbcpu ValueList;
servercpu ValueList;
dbcpu ValueList;
snaptime ValueList;
cpu_cur SYS_REFCURSOR;
v_backdb_cpu varchar2(200);
v_server_cpu varchar2(200);
v_db_cpu varchar2(200);
v_snap_time varchar2(200);
begin
  dbms_output.put_line('var cpudata = { type: "line", data: { labels: [' );
open cpu_cur for
select
       sum(case
   when e.metric_name = 'Background CPU Usage Per Sec' then
    e.pct
   else
    0
 end) backdb_cpu,
       sum(case
   when e.metric_name = 'Host CPU Utilization (%)' then
    e.pct
   else
    0
 end) server_cpu,
       sum(case
   when e.metric_name = 'CPU Usage Per Sec' then
    e.pct
   else
    0
 end) db_cpu,
 (select '"'||to_char(f.end_interval_time, 'mm-dd hh24:mi')||'"'
from dba_hist_snapshot f
         where f.snap_id = e.snap_id
 and f.instance_number = &inid) snap_time
  from (select a.snap_id,
     trunc(decode(a.METRIC_NAME,
        'Host CPU Utilization (%)',
        a.average,
        'CPU Usage Per Sec',
        a.average / 100 / (select value from v$parameter t where t.NAME = 'cpu_count' ) * 100,
        a.average / 100 / (select value from v$parameter t where t.NAME = 'cpu_count' ) * 100,
        a.average),
 2) pct,
     a.METRIC_NAME,
     a.METRIC_UNIT
from dba_hist_sysmetric_summary a
         where A.snap_id >= &bid and a.snap_id <=&eid
 and a.instance_number = &inid
 and a.METRIC_NAME in
     ('Host CPU Utilization (%)',
      'CPU Usage Per Sec',
      'Background CPU Usage Per Sec')
         order by 1, 3) e
 group by snap_id
 order by snap_id;
  FETCH cpu_cur BULK COLLECT INTO backdbcpu,servercpu,dbcpu,snaptime;
 close cpu_cur;
 ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 backdbcpu.extend;
 backdbcpu(1):='0';
 servercpu.extend;
 servercpu(1):=0;
 dbcpu.extend;
 dbcpu(1):=0;
 end if;
-----------------------------------------
FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('],datasets: [{');
DBMS_OUTPUT.PUT_LINE ('label: "Backup CPU",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE ('borderColor: "rgba(255, 255, 0, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: "rgba(128, 128, 0, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('data: [');
-----------------------------------------
FOR i IN backdbcpu.FIRST .. backdbcpu.LAST
LOOP
  if(i<backdbcpu.count) then
DBMS_OUTPUT.PUT_LINE (backdbcpu(i)||',');
elsif(i=backdbcpu.count) then
DBMS_OUTPUT.PUT_LINE (backdbcpu(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('], }, {');
DBMS_OUTPUT.PUT_LINE ('label: "Database CPU",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE ('borderColor: "rgba(0, 0, 0, 128)" ,');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: "rgba(0, 0, 255, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('data: [');
-----------------------------------------
FOR i IN dbcpu.FIRST .. dbcpu.LAST
LOOP
  if(i<dbcpu.count) then
DBMS_OUTPUT.PUT_LINE (dbcpu(i)||',');
elsif(i=dbcpu.count) then
DBMS_OUTPUT.PUT_LINE (dbcpu(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('],}, {');
DBMS_OUTPUT.PUT_LINE ('label: "Server CPU",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE ('borderColor: "rgba(0, 128, 0, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: "rgba(0, 255, 0, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('data: [');
-----------------------------------------
FOR i IN servercpu.FIRST .. servercpu.LAST
LOOP
  if(i<servercpu.count) then
DBMS_OUTPUT.PUT_LINE (servercpu(i)||',');
elsif(i=servercpu.count) then
DBMS_OUTPUT.PUT_LINE (servercpu(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE('],},]},');
DBMS_OUTPUT.PUT_LINE('      options: {');
DBMS_OUTPUT.PUT_LINE('        responsive: true,');
DBMS_OUTPUT.PUT_LINE('        title:{');
DBMS_OUTPUT.PUT_LINE('          display:true,');
DBMS_OUTPUT.PUT_LINE('          text:"CPU Utilization"');
DBMS_OUTPUT.PUT_LINE('        },');
DBMS_OUTPUT.PUT_LINE('        tooltips: {');
DBMS_OUTPUT.PUT_LINE('          mode: "index",');
DBMS_OUTPUT.PUT_LINE('        },');
DBMS_OUTPUT.PUT_LINE('        hover: {');
DBMS_OUTPUT.PUT_LINE('          mode: "index"');
DBMS_OUTPUT.PUT_LINE('        },');
DBMS_OUTPUT.PUT_LINE('        scales: {');
DBMS_OUTPUT.PUT_LINE('          xAxes: [{');
DBMS_OUTPUT.PUT_LINE('            scaleLabel: {');
DBMS_OUTPUT.PUT_LINE('              display: true,');
DBMS_OUTPUT.PUT_LINE('              labelString: "Snap Time"');
DBMS_OUTPUT.PUT_LINE('            }');
DBMS_OUTPUT.PUT_LINE('          }],');
DBMS_OUTPUT.PUT_LINE('          yAxes: [{');
DBMS_OUTPUT.PUT_LINE('           ticks: {min : 0,  max :100 },');
DBMS_OUTPUT.PUT_LINE('            stacked: false,');
DBMS_OUTPUT.PUT_LINE('            scaleLabel: {');
DBMS_OUTPUT.PUT_LINE('              display: true,');
DBMS_OUTPUT.PUT_LINE('              labelString: "Value"');
DBMS_OUTPUT.PUT_LINE('            }');
DBMS_OUTPUT.PUT_LINE('          }]');
DBMS_OUTPUT.PUT_LINE('        }');
DBMS_OUTPUT.PUT_LINE('      }');
DBMS_OUTPUT.PUT_LINE('    };');
  end;
  /

-- Time Model
declare
TYPE ValueList IS TABLE OF varchar2(200);
dbtime ValueList;
cputime ValueList;
sqltime ValueList;
dbcpu ValueList;
snaptime ValueList;
my_cur SYS_REFCURSOR;
v_backdb_cpu varchar2(200);
v_server_cpu varchar2(200);
v_db_cpu varchar2(200);
v_snap_time varchar2(200);
begin
dbms_output.put_line('var dbtimedata = { type: "line", data: { labels: [' );
open my_cur for
select
  snap_time, db_time, db_cpu,sql_exec_time
 from (
select  a1.snap_id,
trunc((a1.dbtime - lag(a1.dbtime, 1, a1.dbtime) over(order by a1.snap_id))/1000000) db_time,
trunc((a1.dbcpu - lag(a1.dbcpu, 1, a1.dbcpu) over(order by a1.snap_id))/1000000) db_cpu,
trunc((a1.sql_time - lag(a1.sql_time, 1, a1.sql_time) over(order by a1.snap_id))/1000000) sql_exec_time ,
(select '"'||to_char(f.end_interval_time, 'mm-dd hh24:mi')||'"'
          from dba_hist_snapshot f
         where f.snap_id = a1.snap_id
           and f.instance_number = &inid) snap_time
 from (
select a.snap_id,instance_number,
sum(case when a.stat_name='DB CPU' then  a.value else 0 end  )  dbcpu,
sum(case when a.stat_name='DB time' then  a.value else 0 end  )  dbtime,
sum(case when a.stat_name='hard parse elapsed time' then  a.value else 0 end  )  hardptime,
sum(case when a.stat_name='parse time elapsed' then  a.value else 0 end  )  ptime,
sum(case when a.stat_name='sql execute elapsed time' then  a.value else 0 end  )  sql_time,
(select b.value from DBA_HIST_SYSSTAT b where b.snap_id=a.snap_id and b.stat_name='execute count' and b.instance_number=&inid) exec_count
 from  dba_hist_sys_time_model a
where a.stat_name in (   'DB time','DB CPU','parse time elapsed','hard parse elapsed time','sql execute elapsed time')
and A.snap_id >= &bid and A.snap_id <= &eid and a.instance_number=&inid
group by a.snap_id,instance_number order by snap_id ) a1 ) a2
where a2.db_time>0 and a2.db_cpu>0 and a2.sql_exec_time>0;
  FETCH my_cur BULK COLLECT INTO snaptime,dbtime,cputime,sqltime;
 close my_cur;
---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 dbtime.extend;
 dbtime(1):='0';
 cputime.extend;
 cputime(1):=0;
 sqltime.extend;
 sqltime(1):=0;
 end if;
-----------------------------------------
FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('], datasets: [');
DBMS_OUTPUT.PUT_LINE ('{label: "CPU Time",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE ('borderColor: "rgba(0, 204, 102, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: "rgba(0, 255, 0, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('data: [');
-----------------------------------------
FOR i IN cputime.FIRST .. cputime.LAST
LOOP
  if(i<cputime.count) then
DBMS_OUTPUT.PUT_LINE (cputime(i)||',');
elsif(i=cputime.count) then
DBMS_OUTPUT.PUT_LINE (cputime(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('],}, {label: "SQL time",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE ('borderColor: "rgba(204, 102, 0, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: "rgba(255, 128, 0, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('data: [');
FOR i IN sqltime.FIRST .. sqltime.LAST
LOOP
  if(i<sqltime.count) then
DBMS_OUTPUT.PUT_LINE (sqltime(i)||',');
elsif(i=sqltime.count) then
DBMS_OUTPUT.PUT_LINE (sqltime(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('],}, {label: "DB time",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE ('borderColor: "rgba(0, 0, 255, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: "rgba(0, 128, 255, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('data: [');
-----------------------------------------
FOR i IN dbtime.FIRST .. dbtime.LAST
LOOP
  if(i<dbtime.count) then
DBMS_OUTPUT.PUT_LINE (dbtime(i)||',');
elsif(i=dbtime.count) then
DBMS_OUTPUT.PUT_LINE (dbtime(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('],},]},');
DBMS_OUTPUT.PUT_LINE ('     options: {');
DBMS_OUTPUT.PUT_LINE ('       responsive: true,');
DBMS_OUTPUT.PUT_LINE ('       title:{');
DBMS_OUTPUT.PUT_LINE ('         display:true,');
DBMS_OUTPUT.PUT_LINE ('         text:"DB time"');
DBMS_OUTPUT.PUT_LINE ('       },');
DBMS_OUTPUT.PUT_LINE ('       tooltips: {');
DBMS_OUTPUT.PUT_LINE ('         mode: "index",');
DBMS_OUTPUT.PUT_LINE ('       },');
DBMS_OUTPUT.PUT_LINE ('       hover: {');
DBMS_OUTPUT.PUT_LINE ('         mode: "index"');
DBMS_OUTPUT.PUT_LINE ('       },');
DBMS_OUTPUT.PUT_LINE ('       scales: {');
DBMS_OUTPUT.PUT_LINE ('         xAxes: [{');
DBMS_OUTPUT.PUT_LINE ('           scaleLabel: {');
DBMS_OUTPUT.PUT_LINE ('             display: true,');
DBMS_OUTPUT.PUT_LINE ('             labelString: "Snap Time"');
DBMS_OUTPUT.PUT_LINE ('           }');
DBMS_OUTPUT.PUT_LINE ('         }],');
DBMS_OUTPUT.PUT_LINE ('         yAxes: [{');
DBMS_OUTPUT.PUT_LINE ('           stacked: false,');
DBMS_OUTPUT.PUT_LINE ('           scaleLabel: {');
DBMS_OUTPUT.PUT_LINE ('             display: true,');
DBMS_OUTPUT.PUT_LINE ('             labelString: "Value"');
DBMS_OUTPUT.PUT_LINE ('           }}]}}}; ');
END;
/

-- SQL Execution Count and Average Execution Time
declare
  TYPE ValueList IS TABLE OF varchar2(200);
  snaptime ValueList;
  sqlcnt   ValueList;
  sqltime ValueList;
  sqlcnt_cur sys_refcursor;
begin
  dbms_output.put_line('var sqldata = {labels: [');
  open sqlcnt_cur for
    select snap_time,sql_exec_count,   trunc(sql_time/ sql_exec_count  )   avg_sql_time
      from (select
                   a1.snap_time,
                  trunc( (a1.exec_count - lag(a1.exec_count, 1, a1.exec_count) over(order by a1.snap_id))/&_iv) sql_exec_count,
                 trunc(( a1.sql_time - lag(a1.sql_time, 1, a1.sql_time) over(order by a1.snap_id))/&_iv) sql_time
              from (select a.snap_id,
                           sum(case
                                 when a.stat_name = 'sql execute elapsed time' then
                                  a.value
                                 else
                                  0
                               end) sql_time,
                           (select b.value
                              from DBA_HIST_SYSSTAT b
                             where b.snap_id = a.snap_id
                               and b.stat_name = 'execute count'
                               and b.instance_number = &inid) exec_count,
                           (select '"' || to_char(f.end_interval_time,
                                                     'mm-dd hh24:mi') || '"'
                                 from dba_hist_snapshot f
                                where f.snap_id = a.snap_id
                                  and f.instance_number = &inid) snap_time
                      from dba_hist_sys_time_model a
                     where a.stat_name in
                           ('DB time',
                            'DB CPU',
                            'parse time elapsed',
                            'hard parse elapsed time',
                            'sql execute elapsed time')
                       and A.snap_id >= &bid
                       and A.snap_id <= &eid
                       and a.instance_number = &inid
                     group by a.snap_id
                     order by snap_id) a1)
     where sql_exec_count > 0;
  FETCH sqlcnt_cur BULK COLLECT
    INTO  snaptime, sqlcnt,sqltime;
  close sqlcnt_cur;
---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 sqlcnt.extend;
 sqlcnt(1):='0';
 sqltime.extend;
 sqltime(1):='0';
 end if;
-----------------------------------------
  FOR i IN snaptime.FIRST .. snaptime.LAST LOOP
    if (i < snaptime.count) then
      DBMS_OUTPUT.PUT_LINE(snaptime(i) || ',');
    elsif (i = snaptime.count) then
      DBMS_OUTPUT.PUT_LINE(snaptime(i));
    end if;
  END LOOP;
  -----------------------------------------
dbms_output.put_line('],datasets: [{');
dbms_output.put_line('label: "SQL Execution Count",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
dbms_output.put_line('borderColor: window.awrColors.red1,');
dbms_output.put_line('backgroundColor: window.awrColors.red2,');
dbms_output.put_line('fill: false,');
dbms_output.put_line('data: [');
  -----------------------------------------
  FOR i IN sqlcnt.FIRST .. sqlcnt.LAST LOOP
    if (i < sqlcnt.count) then
      DBMS_OUTPUT.PUT_LINE(sqlcnt(i) || ',');
    elsif (i = sqlcnt.count) then
      DBMS_OUTPUT.PUT_LINE(sqlcnt(i));
    end if;
  END LOOP;
dbms_output.put_line('], yAxisID: "y-axis-1", }, {');
dbms_output.put_line('label: "SQL Execution Time",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
dbms_output.put_line('borderColor: window.awrColors.blue1,');
dbms_output.put_line('backgroundColor: window.awrColors.blue2,');
dbms_output.put_line('fill: true,');
dbms_output.put_line('data: [');
  -----------------------------------------
  FOR i IN sqltime.FIRST .. sqltime.LAST LOOP
    if (i < sqltime.count) then
      DBMS_OUTPUT.PUT_LINE(sqltime(i) || ',');
    elsif (i = sqltime.count) then
      DBMS_OUTPUT.PUT_LINE(sqltime(i));
    end if;
  END LOOP;
  -----------------------------------------
dbms_output.put_line('],');
dbms_output.put_line('yAxisID: "y-axis-2"');
dbms_output.put_line(' }]};');
end;
/

-- Physical Read and Write
declare
  TYPE ValueList IS TABLE OF varchar2(200);
  PR       ValueList; ---Physical Reads bytes
  PW       ValueList; ---physical write bytes
  prmax ValueList;
  pwmax ValueList;
  SNAPTIME ValueList;
  pw_cur sys_refcursor;
begin
  DBMS_OUTPUT.PUT_LINE('var phydata = { type: "line", data: { labels: [');
  open pw_cur for
   select    (select trunc(maxval/1024/1024) from dba_hist_sysmetric_summary b where b.METRIC_NAME='Physical Write Total Bytes Per Sec' and a2.snap_id=b.snap_id and b.INSTANCE_NUMBER=a2.instance_number) pwmax,
    (select trunc(maxval/1024/1024) from dba_hist_sysmetric_summary c where c.METRIC_NAME='Physical Read Total Bytes Per Sec' and a2.snap_id=c.snap_id and c.INSTANCE_NUMBER=a2.instance_number) prmax,
      trunc(  ( a2.pw - lag(a2.pw, 1, a2.pw) over(order by a2.snap_id))/&_iv/1024/1024) pw,
      trunc( ( a2.pr - lag(a2.pr, 1, a2.pr) over(order by a2.snap_id))/&_iv/1024/1024) pr,
            (select '"' || to_char(f.end_interval_time, 'mm-dd hh24:mi') || '"'
                 from dba_hist_snapshot f
                where f.snap_id = a2.snap_id
                  and f.instance_number = &inid) snap_time
      from (select a1.instance_number,a1.snap_id,
                   sum(case
                         when a1.stat_name = 'physical read total bytes' then
                          a1.value
                         else
                          0
                       end) pr,

                   sum(case
                         when a1.stat_name = 'physical write total bytes' then
                          a1.value
                         else
                          0
                       end) pw
              from (select a.snap_id, a.stat_name, a.value,a.instance_number
                      from dba_hist_sysstat a
                     where (
                           a.stat_name like 'physical write total bytes' or
                           a.stat_name = 'physical read total bytes' )
                       and snap_id >= &bid
                       and snap_id < &eid
                       and a.instance_number = &inid
                     order by a.snap_id, a.stat_name,a.instance_number) a1
             group by a1.snap_id,a1.instance_number
             order by a1.snap_id) a2;

  fetch pw_cur bulk collect into pwmax, prmax,  pw,  pr,    snaptime;
  close pw_cur;
 ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 pr.extend;
 pr(1):='0';
 pw.extend;
 pw(1):=0;
  prmax.extend;
 prmax(1):='0';
 pwmax.extend;
 pwmax(1):=0;
 end if;
-----------------------------------------
  FOR i IN snaptime.FIRST .. snaptime.LAST LOOP
    if (i < snaptime.count) then
      DBMS_OUTPUT.PUT_LINE(snaptime(i) || ',');
    elsif (i = snaptime.count) then
      DBMS_OUTPUT.PUT_LINE(snaptime(i));
    end if;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('  ],  datasets: [{');
  DBMS_OUTPUT.PUT_LINE(' label: "Physical read",');
  DBMS_OUTPUT.PUT_LINE(' fill: false,');
  DBMS_OUTPUT.PUT_LINE(' backgroundColor: window.awrColors.blue1,');
  DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
  DBMS_OUTPUT.PUT_LINE(' borderColor: window.awrColors.blue2,');
  DBMS_OUTPUT.PUT_LINE(' data: [');
  FOR i IN pr.FIRST .. pr.LAST LOOP
    if (i < pr.count) then
      DBMS_OUTPUT.PUT_LINE(pr(i) || ',');
    elsif (i = pr.count) then
      DBMS_OUTPUT.PUT_LINE(pr(i));
    end if;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('], }, {');
  DBMS_OUTPUT.PUT_LINE('label: "MAX Physical read",');
  DBMS_OUTPUT.PUT_LINE('fill: false,');
  DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.blue2,');
  DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
  DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.blue2,');
  DBMS_OUTPUT.PUT_LINE('borderDash: [5, 5],');
  DBMS_OUTPUT.PUT_LINE('data: [');
  FOR i IN prmax.FIRST .. prmax.LAST LOOP
    if (i < prmax.count) then
      DBMS_OUTPUT.PUT_LINE(prmax(i) || ',');
    elsif (i = prmax.count) then
      DBMS_OUTPUT.PUT_LINE(prmax(i));
    end if;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('], },{');
  DBMS_OUTPUT.PUT_LINE('label: "Physcial write",');
  DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.red1,');
  DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
  DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.red2,');
  DBMS_OUTPUT.PUT_LINE('data: [');
  FOR i IN pw.FIRST .. pw.LAST LOOP
    if (i < pw.count) then
      DBMS_OUTPUT.PUT_LINE(pw(i) || ',');
    elsif (i = pw.count) then
      DBMS_OUTPUT.PUT_LINE(pw(i));
    end if;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('],  fill: false,}, {');
  DBMS_OUTPUT.PUT_LINE('label: "Max Physical write",');
  DBMS_OUTPUT.PUT_LINE('fill: false,');
  DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.red2,');
  DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
  DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.red2,');
  DBMS_OUTPUT.PUT_LINE('borderDash: [5, 5],');
  DBMS_OUTPUT.PUT_LINE('data: [');
  FOR i IN pwmax.FIRST .. pwmax.LAST LOOP
    if (i < pwmax.count) then
      DBMS_OUTPUT.PUT_LINE(pwmax(i) || ',');
    elsif (i = pwmax.count) then
      DBMS_OUTPUT.PUT_LINE(pwmax(i));
    end if;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('     ], }]},');
DBMS_OUTPUT.PUT_LINE('options: {');
DBMS_OUTPUT.PUT_LINE('    responsive: true,');
DBMS_OUTPUT.PUT_LINE('    title:{');
DBMS_OUTPUT.PUT_LINE('        display:true,');
DBMS_OUTPUT.PUT_LINE('        text:"Physical R/W (MB) per Second"');
DBMS_OUTPUT.PUT_LINE('    },');
DBMS_OUTPUT.PUT_LINE('    tooltips: {');
DBMS_OUTPUT.PUT_LINE('        mode: "index",');
DBMS_OUTPUT.PUT_LINE('        intersect: false,');
DBMS_OUTPUT.PUT_LINE('    },');
DBMS_OUTPUT.PUT_LINE('    hover: {');
DBMS_OUTPUT.PUT_LINE('        mode: "nearest",');
DBMS_OUTPUT.PUT_LINE('        intersect: true');
DBMS_OUTPUT.PUT_LINE('    },');
DBMS_OUTPUT.PUT_LINE('    scales: {');
DBMS_OUTPUT.PUT_LINE(' xAxes: [{');
DBMS_OUTPUT.PUT_LINE('     display: true,');
DBMS_OUTPUT.PUT_LINE('     scaleLabel: {');
DBMS_OUTPUT.PUT_LINE('         display: true,');
DBMS_OUTPUT.PUT_LINE('         labelString: "Snap"');
DBMS_OUTPUT.PUT_LINE('     }');
DBMS_OUTPUT.PUT_LINE(' }],');
DBMS_OUTPUT.PUT_LINE(' yAxes: [{');
DBMS_OUTPUT.PUT_LINE('     display: true,');
DBMS_OUTPUT.PUT_LINE('     scaleLabel: {');
DBMS_OUTPUT.PUT_LINE('         display: true,');
DBMS_OUTPUT.PUT_LINE('         labelString: "Value"');
DBMS_OUTPUT.PUT_LINE('     } }] } } };');
END;
/

-- Physical Read Request and Write Request
declare
  TYPE ValueList IS TABLE OF varchar2(200);
  PR       ValueList; ---Physical Reads bytes
  PW       ValueList; ---physical write bytes
  prmax ValueList;
  pwmax ValueList;
  SNAPTIME ValueList;
  pw_cur sys_refcursor;
begin
  DBMS_OUTPUT.PUT_LINE('var phyreqdata = { type: "line", data: { labels: [');
  open pw_cur for
  select (select trunc(maxval ) from dba_hist_sysmetric_summary b where b.METRIC_NAME='Physical Write Total IO Requests Per Sec' and a2.snap_id=b.snap_id and b.INSTANCE_NUMBER=a2.instance_number) pwmax,
    (select trunc(maxval ) from dba_hist_sysmetric_summary c where c.METRIC_NAME='Physical Read Total IO Requests Per Sec' and a2.snap_id=c.snap_id and c.INSTANCE_NUMBER=a2.instance_number) prmax,
      trunc(  ( a2.pw - lag(a2.pw, 1, a2.pw) over(order by a2.snap_id))/&_iv ) pw,
      trunc( ( a2.pr - lag(a2.pr, 1, a2.pr) over(order by a2.snap_id))/&_iv ) pr,
            (select '"' || to_char(f.end_interval_time, 'mm-dd hh24:mi') || '"'
                 from dba_hist_snapshot f
                where f.snap_id = a2.snap_id
                  and f.instance_number = &inid) snap_time
      from (select a1.instance_number,a1.snap_id,
                   sum(case
                         when a1.stat_name = 'physical read total IO requests' then
                          a1.value
                         else
                          0
                       end) pr,

                   sum(case
                         when a1.stat_name = 'physical write total IO requests' then
                          a1.value
                         else
                          0
                       end) pw
              from (select a.snap_id, a.stat_name, a.value,a.instance_number
                      from dba_hist_sysstat a
                     where (
                           a.stat_name like 'physical read total IO requests' or
                           a.stat_name = 'physical write total IO requests' )
                       and snap_id >= &bid
                       and snap_id < &eid
                       and a.instance_number = &inid
                     order by a.snap_id, a.stat_name,a.instance_number) a1
             group by a1.snap_id,a1.instance_number
             order by a1.snap_id) a2;
  fetch pw_cur bulk collect into pwmax, prmax,  pw,  pr,    snaptime;
  close pw_cur;
 ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 pr.extend;
 pr(1):='0';
 pw.extend;
 pw(1):=0;
  prmax.extend;
 prmax(1):='0';
 pwmax.extend;
 pwmax(1):=0;
 end if;
-----------------------------------------
  FOR i IN snaptime.FIRST .. snaptime.LAST LOOP
    if (i < snaptime.count) then
      DBMS_OUTPUT.PUT_LINE(snaptime(i) || ',');
    elsif (i = snaptime.count) then
      DBMS_OUTPUT.PUT_LINE(snaptime(i));
    end if;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('  ],  datasets: [{');
  DBMS_OUTPUT.PUT_LINE(' label: "Physical read request",');
  DBMS_OUTPUT.PUT_LINE(' fill: false,');
  DBMS_OUTPUT.PUT_LINE(' backgroundColor: window.awrColors.blue1,');
  DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
  DBMS_OUTPUT.PUT_LINE(' borderColor: window.awrColors.blue2,');
  DBMS_OUTPUT.PUT_LINE(' data: [');
  FOR i IN pr.FIRST .. pr.LAST LOOP
    if (i < pr.count) then
      DBMS_OUTPUT.PUT_LINE(pr(i) || ',');
    elsif (i = pr.count) then
      DBMS_OUTPUT.PUT_LINE(pr(i));
    end if;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('], }, {');
  DBMS_OUTPUT.PUT_LINE('label: "MAX Physical read request",');
  DBMS_OUTPUT.PUT_LINE('fill: false,');
  DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.blue2,');
  DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
  DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.blue2,');
  DBMS_OUTPUT.PUT_LINE('borderDash: [5, 5],');
  DBMS_OUTPUT.PUT_LINE('data: [');
  FOR i IN prmax.FIRST .. prmax.LAST LOOP
    if (i < prmax.count) then
      DBMS_OUTPUT.PUT_LINE(prmax(i) || ',');
    elsif (i = prmax.count) then
      DBMS_OUTPUT.PUT_LINE(prmax(i));
    end if;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('], },{');
  DBMS_OUTPUT.PUT_LINE('label: "Physcial write request",');
  DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.red1,');
  DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
  DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.red2,');
  DBMS_OUTPUT.PUT_LINE('data: [');
  FOR i IN pw.FIRST .. pw.LAST LOOP
    if (i < pw.count) then
      DBMS_OUTPUT.PUT_LINE(pw(i) || ',');
    elsif (i = pw.count) then
      DBMS_OUTPUT.PUT_LINE(pw(i));
    end if;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('],  fill: false,}, {');
  DBMS_OUTPUT.PUT_LINE('label: "Max Physical write request",');
  DBMS_OUTPUT.PUT_LINE('fill: false,');
  DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.red2,');
  DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
  DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.red2,');
  DBMS_OUTPUT.PUT_LINE('borderDash: [5, 5],');
  DBMS_OUTPUT.PUT_LINE('data: [');
  FOR i IN pwmax.FIRST .. pwmax.LAST LOOP
    if (i < pwmax.count) then
      DBMS_OUTPUT.PUT_LINE(pwmax(i) || ',');
    elsif (i = pwmax.count) then
      DBMS_OUTPUT.PUT_LINE(pwmax(i));
    end if;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('     ], }]},');
DBMS_OUTPUT.PUT_LINE('options: {');
DBMS_OUTPUT.PUT_LINE('    responsive: true,');
DBMS_OUTPUT.PUT_LINE('    title:{');
DBMS_OUTPUT.PUT_LINE('        display:true,');
DBMS_OUTPUT.PUT_LINE('        text:"Physical R/W Request"');
DBMS_OUTPUT.PUT_LINE('    },');
DBMS_OUTPUT.PUT_LINE('    tooltips: {');
DBMS_OUTPUT.PUT_LINE('        mode: "index",');
DBMS_OUTPUT.PUT_LINE('        intersect: false,');
DBMS_OUTPUT.PUT_LINE('    },');
DBMS_OUTPUT.PUT_LINE('    hover: {');
DBMS_OUTPUT.PUT_LINE('        mode: "nearest",');
DBMS_OUTPUT.PUT_LINE('        intersect: true');
DBMS_OUTPUT.PUT_LINE('    },');
DBMS_OUTPUT.PUT_LINE('    scales: {');
DBMS_OUTPUT.PUT_LINE(' xAxes: [{');
DBMS_OUTPUT.PUT_LINE('     display: true,');
DBMS_OUTPUT.PUT_LINE('     scaleLabel: {');
DBMS_OUTPUT.PUT_LINE('         display: true,');
DBMS_OUTPUT.PUT_LINE('         labelString: "Snap"');
DBMS_OUTPUT.PUT_LINE('     }');
DBMS_OUTPUT.PUT_LINE(' }],');
DBMS_OUTPUT.PUT_LINE(' yAxes: [{');
DBMS_OUTPUT.PUT_LINE('     display: true,');
DBMS_OUTPUT.PUT_LINE('     scaleLabel: {');
DBMS_OUTPUT.PUT_LINE('         display: true,');
DBMS_OUTPUT.PUT_LINE('         labelString: "Value"');
DBMS_OUTPUT.PUT_LINE('     } }] } } };');
END;
/

-- User IO wait time
declare
TYPE ValueList IS TABLE OF varchar2(200);
snaptime ValueList;
iotimedata ValueList;
my_cur SYS_REFCURSOR;
begin
dbms_output.put_line('var useriodata = { type: "line", data: { labels: [');
open my_cur for
select
  trunc(iotime/&_iv) ,snap_time
 from (
select a2.snap_id  ,
a2.iotime - lag(a2.iotime, 1, a2.iotime) over(order by a2.snap_id) iotime,
(select '"'||to_char(f.end_interval_time, 'mm-dd hh24:mi')||'"'
          from dba_hist_snapshot f
         where f.snap_id =a2.snap_id
           and f.instance_number = &inid) snap_time
 from (
select a1.snap_id,
a1.value  iotime
from
(select a.snap_id,a.stat_name,a.value from dba_hist_sysstat a where    ( a.stat_name = 'user I/O wait time' )
and snap_id >=&bid and snap_id<=&eid and a.instance_number=&inid
 order by a.snap_id,a.stat_name) a1 order by a1.snap_id) a2 ) a3;
 FETCH my_cur BULK COLLECT INTO iotimedata,snaptime;
 close my_cur;
 ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 iotimedata.extend;
 iotimedata(1):='0';
 end if;
-----------------------------------------

  FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
  if i=1 then
   null;
  else
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
end if;
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
------------------------------------
dbms_output.put_line(' ], datasets: [{');
dbms_output.put_line('label: "IO wait time (Second)",');
dbms_output.put_line('backgroundColor: window.awrColors.grey1,');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
dbms_output.put_line('borderColor: window.awrColors.purple2,');
dbms_output.put_line('data: [');
------------------------------
 FOR i IN iotimedata.FIRST .. iotimedata.LAST
LOOP
  if(i<iotimedata.count) then
   if i=1 then
    null;
  else
DBMS_OUTPUT.PUT_LINE (iotimedata(i)||',');
end if;
elsif(i=iotimedata.count) then
DBMS_OUTPUT.PUT_LINE (iotimedata(i));
end if;
END LOOP;
dbms_output.put_line('        ], fill: true, } ] },');
dbms_output.put_line('options: {');
dbms_output.put_line('    responsive: true,');
dbms_output.put_line('    title:{');
dbms_output.put_line('        display:true,');
dbms_output.put_line('        text:"User IO Wait Time per Second"');
dbms_output.put_line('    },');
dbms_output.put_line('    tooltips: {');
dbms_output.put_line('        mode: "index",');
dbms_output.put_line('        intersect: false,');
dbms_output.put_line('    },');
dbms_output.put_line('    hover: {');
dbms_output.put_line('        mode: "nearest",');
dbms_output.put_line('        intersect: true');
dbms_output.put_line('    },');
dbms_output.put_line('    scales: {');
dbms_output.put_line('        xAxes: [{');
dbms_output.put_line('            display: true,');
dbms_output.put_line('            scaleLabel: {');
dbms_output.put_line('                display: true,');
dbms_output.put_line('                labelString: "Snap"');
dbms_output.put_line('            }');
dbms_output.put_line('        }],');
dbms_output.put_line('        yAxes: [{');
dbms_output.put_line('            display: true,');
dbms_output.put_line('            scaleLabel: {');
dbms_output.put_line('                display: true,');
dbms_output.put_line('                labelString: "Value"');
dbms_output.put_line('            }  }] }  } };');
end;
/

-- Average IO wait time
declare
TYPE ValueList IS TABLE OF varchar2(200);
snaptime ValueList;
control ValueList;
dbseq ValueList;
dbsca ValueList;
dbparaell ValueList;
logsync ValueList;
drtpath ValueList;
cpu_cur SYS_REFCURSOR;
v_control varchar2(200);
v_dbseq varchar2(200);
v_dbsca varchar2(200);
v_dbparaell varchar2(200);
v_logsync varchar2(200);
v_drtpath varchar2(200);
v_snap_time varchar2(200);
begin
dbms_output.put_line('var avgiodata = {type: "line", data: { labels: [' );
open cpu_cur for
select a3.snap_time,
decode(controlfilewaits,0,1 ,ceil(controlfilewaitstimes/controlfilewaits/1000)) controlfilewaits,
decode(dbfileseqwaits,0,1 ,ceil(dbfileseqtimes/dbfileseqwaits/1000)) dbfileseqwaits,
decode(dbfilesctwaits,0,1 ,ceil(dbfilescttimes/dbfilesctwaits/1000)) dbfilesctwaits,
decode(drtwaits,0,1 ,ceil(drttimes/drtwaits/1000)) drtwaits,
decode(logwaits,0,1 ,ceil(logtimes/logwaits/1000)) logwaits,
decode(dbparallelwaits,0,1 ,ceil(dbparalleltimes/dbparallelwaits/1000)) dbparallelwaits
 from (
select a2.snap_id,
          trunc(( a2.controlfilewaitstimes - lag(a2.controlfilewaitstimes, 1, a2.controlfilewaitstimes) over(order by a2.snap_id))) controlfilewaitstimes ,
            trunc(( a2.controlfilewaits - lag(a2.controlfilewaits, 1, a2.controlfilewaits) over(order by a2.snap_id)))  controlfilewaits,
              trunc(( a2.dbfileseqtimes - lag(a2.dbfileseqtimes, 1, a2.dbfileseqtimes) over(order by a2.snap_id))) dbfileseqtimes ,
            trunc(( a2.dbfileseqwaits - lag(a2.dbfileseqwaits, 1, a2.dbfileseqwaits) over(order by a2.snap_id)))  dbfileseqwaits,
              trunc(( a2.dbfilescttimes - lag(a2.dbfilescttimes, 1, a2.dbfilescttimes) over(order by a2.snap_id))) dbfilescttimes ,
            trunc(( a2.dbfilesctwaits - lag(a2.dbfilesctwaits, 1, a2.dbfilesctwaits) over(order by a2.snap_id)))  dbfilesctwaits,
              trunc(( a2.drttimes - lag(a2.drttimes, 1, a2.drttimes) over(order by a2.snap_id))) drttimes ,
            trunc(( a2.drtwaits - lag(a2.drtwaits, 1, a2.drtwaits) over(order by a2.snap_id)))  drtwaits,
              trunc(( a2.logtimes - lag(a2.logtimes, 1, a2.logtimes) over(order by a2.snap_id))) logtimes ,
            trunc(( a2.logwaits - lag(a2.logwaits, 1, a2.logwaits) over(order by a2.snap_id)))  logwaits,
              trunc(( a2.dbparalleltimes - lag(a2.dbparalleltimes, 1, a2.dbparalleltimes) over(order by a2.snap_id))) dbparalleltimes ,
            trunc(( a2.dbparallelwaits - lag(a2.dbparallelwaits, 1, a2.dbparallelwaits) over(order by a2.snap_id)))  dbparallelwaits,
           (select '"' || to_char(f.end_interval_time, 'mm-dd hh24:mi') || '"'
                 from dba_hist_snapshot f
                where f.snap_id = a2.snap_id
                  and f.instance_number = &inid) snap_time
           from (
select a1.snap_id,
       sum(case
             when a1.event_name = 'control file sequential read' then
              a1.total_waits_fg
             else
              0
           end) controlfilewaits,
       sum(case
             when a1.event_name = 'control file sequential read' then
              a1.time_waited_micro_fg
             else
              0
           end) controlfilewaitstimes,
       sum(case
             when a1.event_name = 'db file sequential read' then
              a1.total_waits_fg
             else
              0
           end) dbfileseqwaits,
       sum(case
             when a1.event_name = 'db file sequential read' then
              a1.time_waited_micro_fg
             else
              0
           end) dbfileseqtimes,
       sum(case
             when a1.event_name = 'db file scattered read' then
              a1.total_waits_fg
             else
              0
           end) dbfilesctwaits,
       sum(case
             when a1.event_name = 'db file scattered read' then
              a1.time_waited_micro_fg
             else
              0
           end) dbfilescttimes,
       sum(case
             when a1.event_name = 'direct path read' then
              a1.total_waits_fg
             else
              0
           end) drtwaits,
       sum(case
             when a1.event_name = 'direct path read' then
              a1.time_waited_micro_fg
             else
              0
           end) drttimes,
       sum(case
             when a1.event_name = 'log file sync' then
              a1.total_waits_fg
             else
              0
           end) logwaits,
       sum(case
             when a1.event_name = 'log file sync' then
              a1.time_waited_micro_fg
             else
              0
           end) logtimes,
       sum(case
             when a1.event_name = 'db file parallel read' then
              a1.total_waits_fg
             else
              0
           end) dbparallelwaits,
       sum(case
             when a1.event_name = 'db file parallel read' then
              a1.time_waited_micro_fg
             else
              0
           end) dbparalleltimes
  from (select a.snap_id,
               a.event_name,
               a.time_waited_micro_fg,
               a.total_waits_fg
          from dba_hist_system_event a
         where event_name in ('control file sequential read',
                              'log file sync',
                              'db file sequential read',
                              'db file scattered read',
                              'db file parallel read',
                              'direct path read')
           and A.snap_id >= &bid and a.snap_id <=&eid
 and a.instance_number = &inid) a1
 group by a1.snap_id
 order by a1.snap_id)a2)a3 order by snap_id;
   FETCH cpu_cur BULK COLLECT INTO snaptime,control,dbseq,dbsca,drtpath,logsync, dbparaell;
 close cpu_cur;
 ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 control.extend;
 control(1):='0';
 dbseq.extend;
 dbseq(1):=0;
 dbsca.extend;
 dbsca(1):=0;
  drtpath.extend;
 drtpath(1):=0;
  logsync.extend;
 logsync(1):=0;
  dbparaell.extend;
 dbparaell(1):=0;
 end if;
-----------------------------------------
FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
DBMS_OUTPUT.PUT_LINE('], datasets: [{');
DBMS_OUTPUT.PUT_LINE('label: "db file sequential read",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.blue1,');
DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.blue2,');
DBMS_OUTPUT.PUT_LINE('data: [');
-----------------------------------------
FOR i IN dbseq.FIRST .. dbseq.LAST
LOOP
  if(i<dbseq.count) then
DBMS_OUTPUT.PUT_LINE (dbseq(i)||',');
elsif(i=dbseq.count) then
DBMS_OUTPUT.PUT_LINE (dbseq(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE('], fill: false, }, {');
DBMS_OUTPUT.PUT_LINE('label: "direct path read",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE('fill: false,');
DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.pink1,');
DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.pink2,');
DBMS_OUTPUT.PUT_LINE('data: [');
-----------------------------------------
FOR i IN drtpath.FIRST .. drtpath.LAST
LOOP
  if(i<drtpath.count) then
DBMS_OUTPUT.PUT_LINE (drtpath(i)||',');
elsif(i=drtpath.count) then
DBMS_OUTPUT.PUT_LINE (drtpath(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE('], }, {');
DBMS_OUTPUT.PUT_LINE('label: "log file sync",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE('fill: false,');
DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.red1,');
DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.red2,');
DBMS_OUTPUT.PUT_LINE('data: [');
-----------------------------------------
FOR i IN logsync.FIRST .. logsync.LAST
LOOP
  if(i<logsync.count) then
DBMS_OUTPUT.PUT_LINE (logsync(i)||',');
elsif(i=logsync.count) then
DBMS_OUTPUT.PUT_LINE (logsync(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE('], }, {');
DBMS_OUTPUT.PUT_LINE('label: "db file parallel read",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE('fill: false,');
DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.orange1,');
DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.orange2,');
DBMS_OUTPUT.PUT_LINE('data: [');
-----------------------------------------
FOR i IN dbparaell.FIRST .. dbparaell.LAST
LOOP
  if(i<dbparaell.count) then
DBMS_OUTPUT.PUT_LINE (dbparaell(i)||',');
elsif(i=dbparaell.count) then
DBMS_OUTPUT.PUT_LINE (dbparaell(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE('], }, {');
DBMS_OUTPUT.PUT_LINE('label: "control file sequential read",');
DBMS_OUTPUT.PUT_LINE('fill: false,');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.purple1,');
DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.purple2,');
DBMS_OUTPUT.PUT_LINE('data: [');
-----------------------------------------
FOR i IN control.FIRST .. control.LAST
LOOP
  if(i<control.count) then
DBMS_OUTPUT.PUT_LINE (control(i)||',');
elsif(i=control.count) then
DBMS_OUTPUT.PUT_LINE (control(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE('], }, {');
DBMS_OUTPUT.PUT_LINE('label: "db file scatter read",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE('fill: false,');
DBMS_OUTPUT.PUT_LINE(' backgroundColor: window.awrColors.green1,');
DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.green2,');
DBMS_OUTPUT.PUT_LINE('data: [');
-----------------------------------------
FOR i IN dbsca.FIRST .. dbsca.LAST
LOOP
  if(i<dbsca.count) then
DBMS_OUTPUT.PUT_LINE (dbsca(i)||',');
elsif(i=dbsca.count) then
DBMS_OUTPUT.PUT_LINE (dbsca(i));
end if;
END LOOP;
-----------------------------------------
dbms_output.put_line('        ], }]  },');
dbms_output.put_line('options: {');
dbms_output.put_line('    responsive: true,');
dbms_output.put_line('    title:{');
dbms_output.put_line('        display:true,');
dbms_output.put_line('        text:"Average IO Wait Time (ms)"');
dbms_output.put_line('    },');
dbms_output.put_line('    tooltips: {');
dbms_output.put_line('        mode: "index",');
dbms_output.put_line('        intersect: false,');
dbms_output.put_line('    },');
dbms_output.put_line('    hover: {');
dbms_output.put_line('        mode: "nearest",');
dbms_output.put_line('        intersect: true');
dbms_output.put_line('    },');
dbms_output.put_line('    scales: {');
dbms_output.put_line('        xAxes: [{');
dbms_output.put_line('            display: true,');
dbms_output.put_line('            scaleLabel: {');
dbms_output.put_line('                display: true,');
dbms_output.put_line('                labelString: "Snap"');
dbms_output.put_line('            }');
dbms_output.put_line('        }],');
dbms_output.put_line('        yAxes: [{');
dbms_output.put_line('            display: true,');
dbms_output.put_line('            scaleLabel: {');
dbms_output.put_line('                display: true,');
dbms_output.put_line('                labelString: "Value"');
dbms_output.put_line('            } }] } } };');
END;
/

-- IO wait times
declare
TYPE ValueList IS TABLE OF varchar2(200);
snaptime ValueList;
control ValueList;
dbseq ValueList;
dbsca ValueList;
dbparaell ValueList;
logsync ValueList;
drtpath ValueList;
cpu_cur SYS_REFCURSOR;
v_control varchar2(200);
v_dbseq varchar2(200);
v_dbsca varchar2(200);
v_dbparaell varchar2(200);
v_logsync varchar2(200);
v_drtpath varchar2(200);
v_snap_time varchar2(200);
begin
dbms_output.put_line('var iotimesdata = {labels: [' );
open cpu_cur for
select    trunc(( a2.controlfilewaits - lag(a2.controlfilewaits, 1, a2.controlfilewaits) over(order by a2.snap_id)))  controlfilewaits,
            trunc(( a2.drtwaits - lag(a2.drtwaits, 1, a2.drtwaits) over(order by a2.snap_id)))  drtwaits,
            trunc(( a2.logwaits - lag(a2.logwaits, 1, a2.logwaits) over(order by a2.snap_id)))  logwaits,
            trunc(( a2.dbfileseqwaits - lag(a2.dbfileseqwaits, 1, a2.dbfileseqwaits) over(order by a2.snap_id)))  dbfileseqwaits,
            trunc(( a2.dbfilesctwaits - lag(a2.dbfilesctwaits, 1, a2.dbfilesctwaits) over(order by a2.snap_id)))  dbfilesctwaits,
            trunc(( a2.dbparallelwaits - lag(a2.dbparallelwaits, 1, a2.dbparallelwaits) over(order by a2.snap_id)))  dbparallelwaits,
            (select '"' || to_char(f.end_interval_time, 'mm-dd hh24:mi') || '"'
                 from dba_hist_snapshot f
                where f.snap_id = a2.snap_id
                  and f.instance_number = &inid) snap_time
           from (
select a1.snap_id,
       sum(case
             when a1.event_name = 'control file sequential read' then
              a1.total_waits_fg
             else
              0
           end) controlfilewaits,
       sum(case
             when a1.event_name = 'db file sequential read' then
              a1.total_waits_fg
             else
              0
           end) dbfileseqwaits,
       sum(case
             when a1.event_name = 'db file scattered read' then
              a1.total_waits_fg
             else
              0
           end) dbfilesctwaits,
       sum(case
             when a1.event_name = 'direct path read' then
              a1.total_waits_fg
             else
              0
           end) drtwaits,
       sum(case
             when a1.event_name = 'log file sync' then
              a1.total_waits_fg
             else
              0
           end) logwaits,
       sum(case
             when a1.event_name = 'db file parallel read' then
              a1.total_waits_fg
             else
              0
           end) dbparallelwaits
  from (select a.snap_id,
               a.event_name,
               a.total_waits_fg
          from dba_hist_system_event a
         where event_name in ('control file sequential read',
                              'log file sync',
                              'db file sequential read',
                              'db file scattered read',
                              'db file parallel read',
                              'direct path read')
           and A.snap_id >= &bid and a.snap_id <=&eid
 and a.instance_number = &inid) a1
 group by a1.snap_id
 order by a1.snap_id)a2  order by snap_id;
   FETCH cpu_cur BULK COLLECT INTO  control,drtpath,logsync,dbseq,dbsca,dbparaell,snaptime;
 close cpu_cur;
 ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 control.extend;
 control(1):='0';
 dbseq.extend;
 dbseq(1):=0;
 dbsca.extend;
 dbsca(1):=0;
 drtpath.extend;
 drtpath(1):=0;
 logsync.extend;
 logsync(1):=0;
 dbparaell.extend;
 dbparaell(1):=0;
 end if;
-----------------------------------------
FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('], datasets: [{');
DBMS_OUTPUT.PUT_LINE ('label: "db file sequential read",');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: window.awrColors.blue2,');
DBMS_OUTPUT.PUT_LINE ('data: [');
-----------------------------------------
FOR i IN dbseq.FIRST .. dbseq.LAST
LOOP
  if(i<dbseq.count) then
DBMS_OUTPUT.PUT_LINE (dbseq(i)||',');
elsif(i=dbseq.count) then
DBMS_OUTPUT.PUT_LINE (dbseq(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('] }, { label: "Direct path read",' );
DBMS_OUTPUT.PUT_LINE ('backgroundColor: window.awrColors.pink2,' );
DBMS_OUTPUT.PUT_LINE ('data: [' );
-----------------------------------------
FOR i IN drtpath.FIRST .. drtpath.LAST
LOOP
  if(i<drtpath.count) then
DBMS_OUTPUT.PUT_LINE (drtpath(i)||',');
elsif(i=drtpath.count) then
DBMS_OUTPUT.PUT_LINE (drtpath(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('] }, {');
DBMS_OUTPUT.PUT_LINE ('label: "Log file sync",');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: window.awrColors.red2,');
DBMS_OUTPUT.PUT_LINE ('data: [');
-----------------------------------------
FOR i IN logsync.FIRST .. logsync.LAST
LOOP
  if(i<logsync.count) then
DBMS_OUTPUT.PUT_LINE (logsync(i)||',');
elsif(i=logsync.count) then
DBMS_OUTPUT.PUT_LINE (logsync(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE (']}, {');
DBMS_OUTPUT.PUT_LINE ('label: "Db file parallel read",');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: window.awrColors.orange2,');
DBMS_OUTPUT.PUT_LINE ('data: [');
-----------------------------------------
FOR i IN dbparaell.FIRST .. dbparaell.LAST
LOOP
  if(i<dbparaell.count) then
DBMS_OUTPUT.PUT_LINE (dbparaell(i)||',');
elsif(i=dbparaell.count) then
DBMS_OUTPUT.PUT_LINE (dbparaell(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE (']}, {');
DBMS_OUTPUT.PUT_LINE ('label: "control file sequential read",');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: window.awrColors.purple2,');
DBMS_OUTPUT.PUT_LINE ('data: [');
-----------------------------------------
FOR i IN control.FIRST .. control.LAST
LOOP
  if(i<control.count) then
DBMS_OUTPUT.PUT_LINE (control(i)||',');
elsif(i=control.count) then
DBMS_OUTPUT.PUT_LINE (control(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE (']}, {');
DBMS_OUTPUT.PUT_LINE ('label: "Db file scatter read",');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: window.awrColors.green1,');
DBMS_OUTPUT.PUT_LINE ('data: [');
-----------------------------------------
FOR i IN dbsca.FIRST .. dbsca.LAST
LOOP
  if(i<dbsca.count) then
DBMS_OUTPUT.PUT_LINE (dbsca(i)||',');
elsif(i=dbsca.count) then
DBMS_OUTPUT.PUT_LINE (dbsca(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE (']}]};');
END;
/

-- Connections
declare
  TYPE ValueList IS TABLE OF varchar2(200);
  snap_id  ValueList;
  PROC     ValueList; ---Process
  SE       ValueList; ---Session
  SNAPTIME ValueList;
  se_cur   sys_refcursor;
begin
  DBMS_OUTPUT.PUT_LINE('var conndata = { type: "line", data: { labels: [');
  OPEN SE_CUR FOR
    select pr,
           se,
          (select '"' || to_char(f.end_interval_time, 'mm-dd hh24:mi') || '"'
                 from dba_hist_snapshot f
                where f.snap_id = a1.snap_id
                  and f.instance_number = &inid) snap_time,
           snap_id
      from (select snap_id,
                   sum(case
                         when a.resource_name = 'processes' then
                          a.current_utilization
                         else
                          0
                       end) pr,
                   sum(case
                         when a.resource_name = 'sessions' then
                          a.current_utilization
                         else
                          0
                       end) se
              from dba_hist_resource_limit a
             where a.snap_id >= &bid
               and a.snap_id <= &eid
               and a.instance_number = &inid
               and (a.resource_name = 'sessions' or
                   a.resource_name = 'processes')
             group by snap_id
             order by snap_id) a1;

  Fetch se_cur bulk collect
    into PROC, SE, SNAPTIME, SNAP_ID;
close se_cur;
  ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 proc.extend;
 proc(1):='0';
 SE.extend;
 SE(1):='0';
end if;
-----------------------------------------
  FOR i IN snaptime.FIRST .. snaptime.LAST LOOP
    if (i < snaptime.count) then
      DBMS_OUTPUT.PUT_LINE(snaptime(i) || ',');
    elsif (i = snaptime.count) then
      DBMS_OUTPUT.PUT_LINE(snaptime(i));
    end if;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('  ], datasets: [{');
  DBMS_OUTPUT.PUT_LINE('label: "Processes",');
  DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
  DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.blue2,');
  DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.blue2,');
  DBMS_OUTPUT.PUT_LINE('data: [ ');
  FOR i IN proc.FIRST .. proc.LAST LOOP
    if (i < proc.count) then
      DBMS_OUTPUT.PUT_LINE(proc(i) || ',');
    elsif (i = proc.count) then
      DBMS_OUTPUT.PUT_LINE(proc(i));
    end if;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('], fill: false, }, {');
  DBMS_OUTPUT.PUT_LINE('label: "Sessions",');
  DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
  DBMS_OUTPUT.PUT_LINE('fill: false,');
  DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.green1,');
  DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.green1,');
  DBMS_OUTPUT.PUT_LINE('data: [');
  FOR i IN SE.FIRST .. SE.LAST LOOP
    if (i < SE.count) then
      DBMS_OUTPUT.PUT_LINE(SE(i) || ',');
    elsif (i = SE.count) then
      DBMS_OUTPUT.PUT_LINE(SE(i));
    end if;
  END LOOP;
dbms_output.put_line(' ], }] },             ');
dbms_output.put_line('options: {            ');
dbms_output.put_line('responsive: true,     ');
dbms_output.put_line('title:{               ');
dbms_output.put_line('display:true,         ');
dbms_output.put_line('text:"Connections"    ');
dbms_output.put_line('},                    ');
dbms_output.put_line('tooltips: {           ');
dbms_output.put_line('mode: "index",        ');
dbms_output.put_line('intersect: false,     ');
dbms_output.put_line('},                    ');
dbms_output.put_line('hover: {              ');
dbms_output.put_line('mode: "nearest",      ');
dbms_output.put_line('intersect: true       ');
dbms_output.put_line('},                    ');
dbms_output.put_line('scales: {             ');
dbms_output.put_line('xAxes: [{             ');
dbms_output.put_line('display: true,        ');
dbms_output.put_line('scaleLabel: {         ');
dbms_output.put_line('display: true,        ');
dbms_output.put_line('labelString: "Snap"   ');
dbms_output.put_line('}                     ');
dbms_output.put_line('}],                   ');
dbms_output.put_line('yAxes: [{             ');
dbms_output.put_line('display: true,        ');
dbms_output.put_line('scaleLabel: {         ');
dbms_output.put_line('display: true,        ');
dbms_output.put_line('labelString:  "Value" ');
dbms_output.put_line('} }] } } };           ');
END;
/

-- User Logon
declare
  TYPE ValueList IS TABLE OF varchar2(200);
  SNAPTIME ValueList;
  max_logon ValueList; ---max logon
  avg_logon ValueList;
  cr_cur sys_refcursor;
BEGIN
  DBMS_OUTPUT.PUT_LINE('var logondata = { type: "line", data: { labels: [');
  OPEN CR_CUR FOR
select sum(a1.maxlogon),sum(a1.avglogon),
        (select '"' || to_char(f.end_interval_time, 'mm-dd hh24:mi') || '"'
             from dba_hist_snapshot f
            where f.snap_id = a1.snap_id
              and f.instance_number = &inid) snap_time
  from (select a.snap_id,
               case
                 when metric_name = 'Logons Per Sec' then
                   trunc(a.maxval)
                 else
                  0
               end maxlogon,
               case
                 when metric_name = 'Logons Per Sec' then
                   trunc(a.average)
                 else
                  0
               end avglogon
          from dba_hist_sysmetric_summary a
         where A.snap_id >= &bid
           and a.snap_id <= &eid
           and a.instance_number = &inid
         and a.metric_name in
               ('Logons Per Sec'
                )) a1
 group by a1.snap_id;
    FETCH CR_CUR     BULK COLLECT    INTO max_logon,avg_logon,SNAPTIME;
    close CR_CUR;
  ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 max_logon.extend;
 max_logon(1):='0';
 avg_logon.extend;
 avg_logon(1):='0';
end if;
-----------------------------------------
    FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
  if i=1 then
   null;
  else
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
end if;
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
------------------------------------
dbms_output.put_line('], datasets: [{');
dbms_output.put_line('label: "Max Logon",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
dbms_output.put_line('backgroundColor: window.awrColors.red1,');
dbms_output.put_line('borderColor: window.awrColors.red2,');
dbms_output.put_line('data: [');
------------------------------
 FOR i IN max_logon.FIRST .. max_logon.LAST
LOOP
  if(i<max_logon.count) then
   if i=1 then
    null;
  else
DBMS_OUTPUT.PUT_LINE (max_logon(i)||',');
end if;
elsif(i=max_logon.count) then
DBMS_OUTPUT.PUT_LINE (max_logon(i));
end if;
END LOOP;
dbms_output.put_line('], fill: false, }, {');
dbms_output.put_line('label: "Average logon",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
dbms_output.put_line('fill: false,');
dbms_output.put_line('borderDash: [5, 5],');
dbms_output.put_line('backgroundColor: window.awrColors.blue1,');
dbms_output.put_line('borderColor: window.awrColors.blue2,');
dbms_output.put_line('data: [');
 FOR i IN avg_logon.FIRST .. avg_logon.LAST
LOOP
  if(i<avg_logon.count) then
   if i=1 then
    null;
  else
DBMS_OUTPUT.PUT_LINE (avg_logon(i)||',');
end if;
elsif(i=avg_logon.count) then
DBMS_OUTPUT.PUT_LINE (avg_logon(i));
end if;
END LOOP;
dbms_output.put_line('], }] },                    ');
dbms_output.put_line('options: {                  ');
dbms_output.put_line('responsive: true,           ');
dbms_output.put_line('title:{                     ');
dbms_output.put_line('display:true,               ');
dbms_output.put_line('text:"User logon per Second"');
dbms_output.put_line('},                          ');
dbms_output.put_line('tooltips: {                 ');
dbms_output.put_line('mode: "index",              ');
dbms_output.put_line('intersect: false,           ');
dbms_output.put_line('},                          ');
dbms_output.put_line('hover: {                    ');
dbms_output.put_line('mode: "nearest",            ');
dbms_output.put_line('intersect: true             ');
dbms_output.put_line('},                          ');
dbms_output.put_line('scales: {                   ');
dbms_output.put_line('xAxes: [{                   ');
dbms_output.put_line('display: true,              ');
dbms_output.put_line('scaleLabel: {               ');
dbms_output.put_line('display: true,              ');
dbms_output.put_line('labelString: "Snap"         ');
dbms_output.put_line('}                           ');
dbms_output.put_line('}],                         ');
dbms_output.put_line('yAxes: [{                   ');
dbms_output.put_line('display: true,              ');
dbms_output.put_line('scaleLabel: {               ');
dbms_output.put_line('display: true,              ');
dbms_output.put_line('labelString:  "Value"       ');
dbms_output.put_line('} }] } } };                 ');
end;
/

-- Latch Hit Point
declare
  TYPE ValueList IS TABLE OF varchar2(200);
  SNAPTIME         ValueList;
  LATCH_HIT          ValueList; --- Latch hit %
  LATCH_CUR           sys_refcursor;
BEGIN
  DBMS_OUTPUT.PUT_LINE('var latchdata = { type: "line", data: { labels: [');
  OPEN LATCH_CUR FOR
      select trunc(100 - (misses / gets * 100), 2) Get_rate,---change Miss_rate from Get_rate on 2016-12-30 by MaXuefeng
              (select '"' || to_char(f.end_interval_time, 'mm-dd hh24:mi') || '"'
                   from dba_hist_snapshot f
                  where f.snap_id = a2.snap_id
                    and f.instance_number = &inid) snap_time
        from (select a1.snap_id,
                     a1.gets - lag(a1.gets, 1, a1.gets) over(order by a1.snap_id) gets,
                     a1.misses - lag(a1.misses, 1, a1.misses) over(order by a1.snap_id) misses
                from (select a.snap_id, sum(a.gets) gets, sum(a.misses) misses
                        from dba_hist_latch a
                       where a.instance_number = &inid
                         and a.snap_id >= &bid
                         and a.snap_id <= &eid
                       group by a.snap_id
                       order by a.snap_id) a1) a2
       where gets > 0;
   FETCH LATCH_CUR BULK COLLECT INTO LATCH_HIT,SNAPTIME;
   CLOSE LATCH_CUR;
    ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 LATCH_HIT.extend;
 LATCH_HIT(1):='0';
end if;
-----------------------------------------
   FOR i IN snaptime.FIRST .. snaptime.LAST LOOP
        if (i < snaptime.count) then
          DBMS_OUTPUT.PUT_LINE(snaptime(i) || ',');
        elsif (i = snaptime.count) then
          DBMS_OUTPUT.PUT_LINE(snaptime(i));
        end if;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('], datasets: [{');
    DBMS_OUTPUT.PUT_LINE('label: "Latch hit point",');
    DBMS_OUTPUT.PUT_LINE('lineTension :0,');
    DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.green1,');
    DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.green2,');
    DBMS_OUTPUT.PUT_LINE('data: [');
    FOR i IN LATCH_HIT.FIRST .. LATCH_HIT.LAST LOOP
        if (i < LATCH_HIT.count) then
          DBMS_OUTPUT.PUT_LINE(LATCH_HIT(i) || ',');
        elsif (i = LATCH_HIT.count) then
          DBMS_OUTPUT.PUT_LINE(LATCH_HIT(i));
        end if;
    END LOOP;
dbms_output.put_line('], fill: true, } ] },                  ');
dbms_output.put_line('options: {                             ');
dbms_output.put_line('responsive: true,                      ');
dbms_output.put_line('title:{                                ');
dbms_output.put_line('display:true,                          ');
dbms_output.put_line('text:""');
dbms_output.put_line('},                                     ');
dbms_output.put_line('tooltips: {                            ');
dbms_output.put_line('mode: "index",                         ');
dbms_output.put_line('intersect: false,                      ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('hover: {                               ');
dbms_output.put_line('mode: "nearest",                       ');
dbms_output.put_line('intersect: true                        ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('scales: {                              ');
dbms_output.put_line('xAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Snap"                    ');
dbms_output.put_line('}                                      ');
dbms_output.put_line('}],                                    ');
dbms_output.put_line('yAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "%"                   ');
dbms_output.put_line('}  }] }  } };                          ');
END;
/

-- Latch:row cache objects
declare
TYPE ValueList IS TABLE OF varchar2(200);
snaptime ValueList;
rowco ValueList;
my_cur SYS_REFCURSOR;
begin
dbms_output.put_line('var latchrcodata = { type: "line", data: { labels: [');
open my_cur for
select
sum(case when a2.latch_name='row cache objects' then  a2.miss_rate else 0 end  ) row_co,
 (select '"'||to_char(f.end_interval_time, 'mm-dd hh24:mi')||'"'
          from dba_hist_snapshot f
         where f.snap_id =a2.snap_id
           and f.instance_number = &inid)  snap_time
 from (
select a1.snap_id, a1.latch_name, trunc(a1.miss / a1.get * 10000 ) miss_rate
  from (select a.snap_id,
               a.latch_name,
               a.gets,
               a.misses,
               a.gets - lag(a.gets, 1, a.gets) over(partition by a.latch_name order by a.snap_id, a.latch_name) get,
               a.misses - lag(a.misses, 1, a.misses) over(partition by a.latch_name order by a.snap_id, a.latch_name) miss
          from dba_hist_latch a
         where latch_name in ('row cache objects') and a.instance_number=&inid and
                              a.snap_id >=&bid and a.snap_id <=&eid
         order by snap_id, latch_name) a1
 where a1.get > 0
  order by snap_id, latch_name )a2
group by a2.snap_id order by a2.snap_id ;
 FETCH my_cur BULK COLLECT INTO rowco,snaptime;
 close my_cur;
    ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 rowco.extend;
 rowco(1):='0';
end if;
-----------------------------------------
 FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
------------------------------------
dbms_output.put_line('], datasets: [{');
dbms_output.put_line('label: "Latch:row cache objects - MISSES RATE N/10000 ",');
dbms_output.put_line('lineTension :0,');
dbms_output.put_line('backgroundColor: window.awrColors.orange1,');
dbms_output.put_line('borderColor: window.awrColors.orange2,');
dbms_output.put_line('data: [');
------------------------------
 FOR i IN rowco.FIRST .. rowco.LAST
LOOP
  if(i<rowco.count) then
DBMS_OUTPUT.PUT_LINE (rowco(i)||',');
elsif(i=rowco.count) then
DBMS_OUTPUT.PUT_LINE (rowco(i));
end if;
END LOOP;
dbms_output.put_line('], fill: true, } ] },                  ');
dbms_output.put_line('options: {                             ');
dbms_output.put_line('responsive: true,                      ');
dbms_output.put_line('title:{                                ');
dbms_output.put_line('display:true,                          ');
dbms_output.put_line('text:""');
dbms_output.put_line('},                                     ');
dbms_output.put_line('tooltips: {                            ');
dbms_output.put_line('mode: "index",                         ');
dbms_output.put_line('intersect: false,                      ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('hover: {                               ');
dbms_output.put_line('mode: "nearest",                       ');
dbms_output.put_line('intersect: true                        ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('scales: {                              ');
dbms_output.put_line('xAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Snap"                    ');
dbms_output.put_line('}                                      ');
dbms_output.put_line('}],                                    ');
dbms_output.put_line('yAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "%"                   ');
dbms_output.put_line('}  }] }  } };                          ');
end;
/

-- Latch:cache buffers chains
declare
TYPE ValueList IS TABLE OF varchar2(200);
snaptime ValueList;
latch_cbc ValueList;
my_cur SYS_REFCURSOR;
begin
dbms_output.put_line('var latchcbcdata = { type: "line", data: { labels: [');
open my_cur for
select
 cache_bc,snap_time
  from (
select
a2.snap_id,
sum(case when a2.latch_name='cache buffers chains' then  a2.miss_rate else 0 end  ) cache_bc,
 (select '"'||to_char(f.end_interval_time, 'mm-dd hh24:mi')||'"'
          from dba_hist_snapshot f
         where f.snap_id =a2.snap_id
           and f.instance_number = &inid) snap_time
 from (
select a1.snap_id, a1.latch_name, trunc(a1.miss / a1.get * 10000 ) miss_rate
  from (select a.snap_id,
               a.latch_name,
               a.gets,
               a.misses,
               a.gets - lag(a.gets, 1, a.gets) over(partition by a.latch_name order by a.snap_id, a.latch_name) get,
               a.misses - lag(a.misses, 1, a.misses) over(partition by a.latch_name order by a.snap_id, a.latch_name) miss
          from dba_hist_latch a
         where latch_name in (
                              'cache buffers chains'
                             ) and a.instance_number=&inid and
                              a.snap_id >=&bid and a.snap_id <=&eid
         order by snap_id, latch_name) a1
 where a1.get > 0
  order by snap_id, latch_name )a2
group by a2.snap_id order by a2.snap_id )a3;
 FETCH my_cur BULK COLLECT INTO latch_cbc,snaptime;
 close my_cur;
    ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 latch_cbc.extend;
 latch_cbc(1):='0';
end if;
-----------------------------------------
  FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
------------------------------------
dbms_output.put_line('], datasets: [{');
dbms_output.put_line('label: "Latch:cache buffers chains - MISSES RATE N/10000  ",');
dbms_output.put_line('lineTension :0,');
dbms_output.put_line('backgroundColor: window.awrColors.green0,');
dbms_output.put_line('borderColor: window.awrColors.green2,');
dbms_output.put_line('data: [');
------------------------------
 FOR i IN latch_cbc.FIRST .. latch_cbc.LAST
LOOP
  if(i<latch_cbc.count) then
DBMS_OUTPUT.PUT_LINE (latch_cbc(i)||',');
elsif(i=latch_cbc.count) then
DBMS_OUTPUT.PUT_LINE (latch_cbc(i));
end if;
END LOOP;
dbms_output.put_line('], fill: true, } ] },                  ');
dbms_output.put_line('options: {                             ');
dbms_output.put_line('responsive: true,                      ');
dbms_output.put_line('title:{                                ');
dbms_output.put_line('display:true,                          ');
dbms_output.put_line('text:""');
dbms_output.put_line('},                                     ');
dbms_output.put_line('tooltips: {                            ');
dbms_output.put_line('mode: "index",                         ');
dbms_output.put_line('intersect: false,                      ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('hover: {                               ');
dbms_output.put_line('mode: "nearest",                       ');
dbms_output.put_line('intersect: true                        ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('scales: {                              ');
dbms_output.put_line('xAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Snap"                    ');
dbms_output.put_line('}                                      ');
dbms_output.put_line('}],                                    ');
dbms_output.put_line('yAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "%"                   ');
dbms_output.put_line('}  }] }  } };                          ');
end;
/

-- Top 5 Wait Event
declare
TYPE ValueList IS TABLE OF varchar2(200);
pct ValueList;
event ValueList;
my_cur SYS_REFCURSOR;
begin
dbms_output.put_line('var eventdata = { data: { datasets: [{ data: [');
open my_cur for
select
pct,event
 from
(
SELECT
        trunc(PCTWTT,2) pct , EVENT, rownum rn
  FROM (SELECT EVENT, WAITS, TIME, PCTWTT, WAIT_CLASS
          FROM (SELECT E.EVENT_NAME EVENT,
                       E.TOTAL_WAITS_FG - NVL(B.TOTAL_WAITS_FG, 0) WAITS,
                       (E.TIME_WAITED_MICRO_FG - NVL(B.TIME_WAITED_MICRO_FG, 0)) /
                       1000000 TIME,
                       100 *
                       (E.TIME_WAITED_MICRO_FG - NVL(B.TIME_WAITED_MICRO_FG, 0)) /
                       ((SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL e
                          WHERE e.SNAP_ID = &eid
                            AND e.INSTANCE_NUMBER = &inid
                            AND e.STAT_NAME = 'DB time') -
                       (SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL b
                          WHERE b.SNAP_ID = &bid
                            AND b.INSTANCE_NUMBER = &inid
                            AND b.STAT_NAME = 'DB time')) PCTWTT,
                       E.WAIT_CLASS WAIT_CLASS
                  FROM DBA_HIST_SYSTEM_EVENT B, DBA_HIST_SYSTEM_EVENT E
                 WHERE B.SNAP_ID(+) = &bid
                   AND E.SNAP_ID = &eid
                   AND B.INSTANCE_NUMBER(+) = &inid
                   AND E.INSTANCE_NUMBER = &inid
                   AND B.EVENT_ID(+) = E.EVENT_ID
                   AND E.TOTAL_WAITS > NVL(B.TOTAL_WAITS, 0)
                   AND E.WAIT_CLASS != 'Idle'
                UNION ALL
                SELECT 'CPU time' EVENT,
                       TO_NUMBER(NULL) WAITS,
                       ((SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL e
                          WHERE e.SNAP_ID = &eid
                            AND e.INSTANCE_NUMBER = &inid
                            AND e.STAT_NAME = 'DB CPU') -
                       (SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL b
                          WHERE b.SNAP_ID = &bid
                            AND b.INSTANCE_NUMBER = &inid
                            AND b.STAT_NAME = 'DB CPU')) / 1000000 TIME,
                       100 * ((SELECT sum(value)
                                 FROM DBA_HIST_SYS_TIME_MODEL e
                                WHERE e.SNAP_ID = &eid
                                  AND e.INSTANCE_NUMBER = &inid
                                  AND e.STAT_NAME = 'DB CPU') -
                       (SELECT sum(value)
                                 FROM DBA_HIST_SYS_TIME_MODEL b
                                WHERE b.SNAP_ID = &bid
                                  AND b.INSTANCE_NUMBER = &inid
                                  AND b.STAT_NAME = 'DB CPU')) /
                       ((SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL e
                          WHERE e.SNAP_ID = &eid
                            AND e.INSTANCE_NUMBER = &inid
                            AND e.STAT_NAME = 'DB time') -
                       (SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL b
                          WHERE b.SNAP_ID = &bid
                            AND b.INSTANCE_NUMBER = &inid
                            AND b.STAT_NAME = 'DB time')) PCTWTT,
                       NULL WAIT_CLASS
                  from dual
                 WHERE ((SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL e
                          WHERE e.SNAP_ID = &eid
                            AND e.INSTANCE_NUMBER = &inid
                            AND e.STAT_NAME = 'DB CPU') -
                       (SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL b
                          WHERE b.SNAP_ID = &bid
                            AND b.INSTANCE_NUMBER = &inid
                            AND b.STAT_NAME = 'DB CPU'))> 0)
         ORDER BY TIME DESC, WAITS DESC)
 WHERE ROWNUM <= 5) a1 order by rn;
 FETCH my_cur BULK COLLECT INTO pct,event;
 close my_cur;
 FOR i IN pct.FIRST .. pct.LAST
LOOP
  if(i<pct.count) then
DBMS_OUTPUT.PUT_LINE (pct(i)||',');
elsif(i=pct.count) then
DBMS_OUTPUT.PUT_LINE (pct(i));
end if;
END LOOP;
dbms_output.put_line('], backgroundColor: [');
dbms_output.put_line('window.awrColors.red2,');
dbms_output.put_line('window.awrColors.blue2,');
dbms_output.put_line('window.awrColors.green1,');
dbms_output.put_line('window.awrColors.yellow1,');
dbms_output.put_line('window.awrColors.orange1');
dbms_output.put_line('], label: "Event" }],');
dbms_output.put_line('labels: [');
FOR i IN event.FIRST .. event.LAST
LOOP
  if(i<event.count) then
DBMS_OUTPUT.PUT_LINE ('"'||event(i)||'",');
elsif(i=event.count) then
DBMS_OUTPUT.PUT_LINE ('"'||event(i)||'"');
end if;
END LOOP;
dbms_output.put_line('   ] },');
dbms_output.put_line('  options: {');
dbms_output.put_line('     responsive: true,');
dbms_output.put_line('   legend: {');
dbms_output.put_line('    position: "right",');
dbms_output.put_line(' },');
dbms_output.put_line(' title: {');
dbms_output.put_line('   display: true,');
dbms_output.put_line('  text: "event"');
dbms_output.put_line(' },');
dbms_output.put_line(' scale: {');
dbms_output.put_line(' ticks: {');
dbms_output.put_line(' beginAtZero: true');
dbms_output.put_line(' },');
dbms_output.put_line(' reverse: false');
dbms_output.put_line(' },');
dbms_output.put_line(' animation: {');
dbms_output.put_line(' animateRotate: false,');
dbms_output.put_line(' animateScale: true');
dbms_output.put_line('} } };');
end;
/


prompt
prompt   window.onload = function(){

-- CPU Utilization
prompt var ctx = document.getElementById("canvas_cpu").getContext("2d");
prompt window.myLine = new Chart(ctx, cpudata);

-- Time Model
prompt var ctx2 = document.getElementById("canvas_dbtime").getContext("2d");
prompt window.myLine = new Chart(ctx2, dbtimedata);

-- SQL Execution Count and Average Execution Time
prompt var ctx3 = document.getElementById("canvas_sql").getContext("2d");
prompt window.myLine = Chart.Line(ctx3, {
prompt     data: sqldata,
prompt  options: {
prompt      responsive: true,
prompt      hoverMode: "index",
prompt      stacked: false,
prompt      title:{
prompt          display: true,
prompt          text:"SQL exe time and count"
prompt      },
prompt      scales: {
prompt  yAxes: [{
prompt      type: "linear", // only linear but allow scale type registration. This allows extensions to exist solely for log scale for instance
prompt      display: true,
prompt      position: "left",
prompt      id: "y-axis-1",
prompt  }, {
prompt      type: "linear", // only linear but allow scale type registration. This allows extensions to exist solely for log scale for instance
prompt      display: true,
prompt      position: "right",
prompt      id: "y-axis-2",
prompt      // grid line settings
prompt      gridLines: {
prompt          drawOnChartArea: false, // only want the grid lines for one axis to show up
prompt      }, }], }} });

-- Physical Read and Write
prompt var ctxphy = document.getElementById("canvas_phy").getContext("2d");
prompt window.myLine = new Chart(ctxphy, phydata);

-- Physical Read Request and Write Request
prompt var ctxphy2 = document.getElementById("canvas_phyreq").getContext("2d");
prompt window.myLine = new Chart(ctxphy2, phyreqdata);

-- User IO wait time
prompt var ctxuserio = document.getElementById("canvas_userio").getContext("2d");
prompt window.myLine = new Chart(ctxuserio, useriodata);

-- Average IO wait time
prompt var ctxavgio = document.getElementById("canvas_avgio").getContext("2d");
prompt window.myLine = new Chart(ctxavgio, avgiodata);

-- IO wait times
prompt var ctxiotimes = document.getElementById("canvas_iotimes").getContext("2d");
prompt window.myBar = new Chart(ctxiotimes, {
prompt     type: "bar",
prompt     data: iotimesdata,
prompt     options: {
prompt  title:{
prompt      display:true,
prompt      text:"Chart.js Bar Chart - Stacked"
prompt  },
prompt  tooltips: {
prompt      mode: "index",
prompt      intersect: false
prompt  },
prompt  responsive: true,
prompt  scales: {
prompt      xAxes: [{
prompt          stacked: true,
prompt      }],
prompt      yAxes: [{
prompt          stacked: true
prompt      }]
prompt         }
prompt     }
prompt });

-- Connections
prompt var ctxconn = document.getElementById("canvas_conn").getContext("2d");
prompt window.myLine = new Chart(ctxconn, conndata);

-- User Logon
prompt var ctxlogon = document.getElementById("canvas_logon").getContext("2d");
prompt window.myLine = new Chart(ctxlogon, logondata);

-- Latch Hit Point
prompt var ctxlatch = document.getElementById("canvas_latch").getContext("2d");
prompt window.myLine = new Chart(ctxlatch, latchdata);

-- Latch:row cache objects
--prompt var ctxlatchrco = document.getElementById("canvas_latchrco").getContext("2d");
--prompt window.myLine = new Chart(ctxlatchrco, latchrcodata);

-- Latch:cache buffers chains
--prompt var ctxlatchcbc = document.getElementById("canvas_latchcbc").getContext("2d");
--prompt window.myLine = new Chart(ctxlatchcbc, latchcbcdata);

-- Top 5 Wait Event
prompt var ctxevent = document.getElementById("canvas_event");
prompt window.myPolarArea = Chart.PolarArea(ctxevent, eventdata);

prompt   };
prompt </script>

prompt <hr>
prompt <div align='center' class="awr" name="liking">Checkdb Version 1.1; Author: Li JinGuang; Email: ljg@inspur.com; QQ: 1229420</div>

prompt </body>
prompt </html>
spool off

set termout       on
prompt
prompt Report name: &rpt_name
prompt
prompt Completed!
prompt

undefine rpt_name
undefine days
undefine inst_num
undefine bid
undefine eid