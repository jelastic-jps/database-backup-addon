#!/bin/bash

DBUSER=$1
DBPASSWD=$2
ACTION=$3

PITR_CONF='/etc/mysql/conf.d/pitr.cnf'
SUCCESS_CODE=0
ERROR_CODE=99
PITR_ERROR_CODE=701

source /etc/jelastic/metainf.conf
COMPUTE_TYPE_FULL_VERSION_FORMATTED=$(echo "$COMPUTE_TYPE_FULL_VERSION" | sed 's/\.//')
if [[ ("$COMPUTE_TYPE" == "mysql" || "$COMPUTE_TYPE" == "percona") && "$COMPUTE_TYPE_FULL_VERSION_FORMATTED" -ge "81" ]]; then
  BINLOG_EXPIRE_SETTING="binlog_expire_logs_seconds"
  EXPIRY_SETTING="604800"
elif [[ "$COMPUTE_TYPE" == "mariadb" ]]; then
  BINLOG_EXPIRE_SETTING="expire_logs_days"
  EXPIRY_SETTING="7"
else
  echo "{result:$ERROR_CODE, out:'Fail detect DB server'}"
  exit 0
fi
  
check_pitr() {
  LOG_BIN=$(mysql -u"$DBUSER" -p"$DBPASSWD" -se "SHOW VARIABLES LIKE 'log_bin';" | grep "ON")
  EXPIRE_LOGS=$(mysql -u"$DBUSER" -p"$DBPASSWD" -se "SHOW VARIABLES LIKE '$BINLOG_EXPIRE_SETTING';" | awk '{ print $2 }')

  if [[ -n "$LOG_BIN" && "$EXPIRE_LOGS" == "$EXPIRY_SETTING" ]]; then
    echo "{result:$SUCCESS_CODE}"
  else
    echo "{result:$PITR_ERROR_CODE}"
  fi
}

setup_pitr() {
  CONFIG="
[mysqld]
log-bin=mysql-bin
$BINLOG_EXPIRE_SETTING=$EXPIRY_SETTING
"
  echo "$CONFIG" > "$PITR_CONF"
}

case $ACTION in
  checkPitr)
    check_pitr
    ;;
  setupPitr)
    setup_pitr
    ;;
esac
