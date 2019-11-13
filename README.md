-- DESCRIPTION
--   This script check the DB and create reports.

-- SUPPORTED OS
--   Linux, Aix, Hp-ux, Solaris, Windows
-- SUPPORTED ORACLE VERSION
--   11g;10g;9i(partly)

-- USAGE
--   Connect to db using sqlplus, run checkdb.sql:
--   SQL> @checkdb
--   Note 1: user privileges
--   grant execute on DBMS_WORKLOAD_REPOSITORY to username;
--   grant select any dictionary to username;
--   Note 2: set NLS_LANG to show chinese report
--   linux Shell       : export NLS_LANG=AMERICAN_AMERICA.ZHS16GBK
--   windows CMD       : set NLS_LANG=AMERICAN_AMERICA.ZHS16GBK
--   windows PowerShell: $env:NLS_LANG="AMERICAN_AMERICA.ZHS16GBK"
