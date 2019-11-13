NAME
  checkdb.sql

DESCRIPTION
  This script check the DB and create reports.

SUPPORTED OS
  Linux, Aix, Hp-ux, Solaris, Windows

SUPPORTED ORACLE VERSION
  11g;10g;9i(partly)

USAGE
  Connect to db using sqlplus, run checkdb.sql:
  SQL> @checkdb

  Note 1: user privileges
  grant execute on DBMS_WORKLOAD_REPOSITORY to username;
  grant select any dictionary to username;
  Note 2: set NLS_LANG to show chinese report
  linux Shell       : export NLS_LANG=AMERICAN_AMERICA.ZHS16GBK
  windows CMD       : set NLS_LANG=AMERICAN_AMERICA.ZHS16GBK
  windows PowerShell: $env:NLS_LANG="AMERICAN_AMERICA.ZHS16GBK"

MODIFIED    (YYYY-MM-DD)
Li JinGuang  2018-08-31 - translate chinese to english
Li JinGuang  2018-01-27 - Adding "Top 5 Wait Event trends"
Li JinGuang  2018-01-25 - Upgrade KPI function, using chart.js verion 2.6
Li JinGuang  2017-07-22 - Adding KPI trend Chart: CPU Utilization, Time Model, SQL Execution Count
Li JinGuang  2017-02-13 - Adding KPI trend: DB time, CPU%
Li JinGuang  2017-01-16 - Adding Support Windows OS
Li JinGuang  2017-01-10 - Adding KPI trend: physical reads, physical writes
Li JinGuang  2017-01-06 - Adding alertlog report: checkdb_alertlog.sql
Li JinGuang  2016-12-05 - Created
