#implement host file for all servers
resource "local_file" "hosts" {
  depends_on = [module.lunch_instances.instances]
  filename = "Files/hosts"
  content = <<-EOF
127.0.0.1 localhosts
%{ for index , instance in module.lunch_instances.instances }
${instance.access_ip_v4} ${instance.name} proxysql-${index} ${index} mariadb-${index}
%{ endfor }
  EOF
}

#script for config keepalived configs
resource "local_file" "config_keepalived" {
  filename = "Files/config_keepalived.sh"
  content = <<-EOF
#!/bin/bash
export IPADDR=`hostname -I | awk '{print $1}'`
export INTERFACE_NAME=$(ip -br a | grep "$IPADDR" | awk '{print $1}'| sed "s/ //g")
sed -i "s/INTERFACE_NAME/"$INTERFACE_NAME"/g" /etc/keepalived/keepalived.conf
if [[ $IPADDR == "${module.lunch_instances.instances[module.lunch_instances.instance_list[0]].access_ip_v4}" ]]
then
  sed -i "s/STATE/MASTER/g" /etc/keepalived/keepalived.conf
  sed -i "s/PRIORITY/100/g" /etc/keepalived/keepalived.conf
else
  sed -i "s/STATE/BACKUP/g" /etc/keepalived/keepalived.conf
  sed -i "s/PRIORITY/90/g" /etc/keepalived/keepalived.conf
fi
  EOF
}

#implement keepalived.conf file
resource "local_file" "keepalived_conf_file" {
  filename = "Files/keepalived.conf"
  content = <<-EOF
vrrp_instance VI1SL {
        state STATE   # (optional) initial state for this server
        interface INTERFACE_NAME # interface where VRRP traffic will exist
        advert_int 5   # interval between sync
        virtual_router_id 71 # unique identifier per VRRP instance (same across all servers on the instance)
        priority PRIORITY   # server priority - higher number == higher priority

        # authentication for VRRP messages
        authentication {
                auth_type AH    # good authentication
                auth_pass ${var.keepalived_AH_Password} # password
        }
        virtual_ipaddress {
                ${module.lunch_instances.VIP_address}/24 dev INTERFACE_NAME # Virtual IP address and interface assignment
        }
        track_script {
                check_mysqld # tracking script
        }
}
vrrp_script check_mysqld {
        script "/home/ubuntu/checkMySql.sh"
        interval 2 # 2s per check
        fall 2 # 2 fails - 4s
        rise 3 # 2 OKs - 6s
        timeout 3 # wait up to 3 seconds for script before assuming fail
}
  EOF
}

#Script for check sql container health
resource "local_file" "checkMySql_health" {
  filename = "Files/checkMySql.sh"
  content = <<-EOF
#!/bin/bash
ProcID=`/usr/bin/pgrep mysqld`
if [ -z $ProcIP ]
then
  exit 1
else
  exit 0
fi
  EOF
}

#implement proxysql.conf file
resource "local_file" "proxysqlconfig" {
  filename = "Files/proxysql.cnf"
  content = <<EOF
datadir="/var/lib/proxysql"
admin_variables=
{
    admin_credentials="${var.proxysql_admin_user}:${var.proxysql_admin_password};${var.proxysql_cluster_admin_user}:${var.proxysql_cluster_admin_password}"
    mysql_ifaces="0.0.0.0:6032"
    refresh_interval=2000
    cluster_username="${var.proxysql_cluster_admin_user}"
    cluster_password="${var.proxysql_cluster_admin_password}"
    cluster_check_interval_ms=200
    cluster_check_status_frequency=100
    cluster_mysql_query_rules_save_to_disk=true
    cluster_mysql_servers_save_to_disk=true
    cluster_mysql_users_save_to_disk=true
    cluster_proxysql_servers_save_to_disk=true
    cluster_mysql_query_rules_diffs_before_sync=3
    cluster_mysql_servers_diffs_before_sync=3
    cluster_mysql_users_diffs_before_sync=3
    cluster_proxysql_servers_diffs_before_sync=3
}

mysql_variables=
{
    threads=8
    max_connections=2048
    default_query_delay=0
    default_query_timeout=36000000
    have_compress=true
    poll_timeout=2000
    interfaces="0.0.0.0:6033;/tmp/proxysql.sock"
    default_schema="information_schema"
    stacksize=1048576
    server_version="5.1.30"
    connect_timeout_server=10000
    monitor_history=60000
    monitor_connect_interval=200000
    monitor_ping_interval=200000
    ping_interval_server_msec=10000
    ping_timeout_server=200
    commands_stats=true
    sessions_sort=true
    monitor_username="${var.proxysql_mon_user}"
    monitor_password="${var.proxysql_mon_password}"
    monitor_galera_healthcheck_interval=2000
    monitor_galera_healthcheck_timeout=800
}

mysql_galera_hostgroups =
(
    {
        writer_hostgroup=10
        backup_writer_hostgroup=20
        reader_hostgroup=30
        offline_hostgroup=9999
        max_writers=1
        writer_is_also_reader=1
        max_transactions_behind=30
        active=1
    }
)

mysql_servers =
(
%{ for index , proxy in var.proxysql~}
    { address="${split(":",var.proxysql[index])[0]}" , port=3306 , hostgroup=%{ if split(":",var.proxysql[index])[1] == "write" }10%{ endif }%{ if split(":",var.proxysql[index])[1] == "backup" }20%{ endif }%{ if split(":",var.proxysql[index])[1] == "read" }30%{ endif }  , max_connections=100 }%{ if index < length(var.proxysql) - 1 },%{ endif }
%{ endfor ~}
)

mysql_query_rules =
(
    {
        rule_id=100
        active=1
        match_pattern="^SELECT .* FOR UPDATE"
        destination_hostgroup=10
        apply=1
    },
    {
        rule_id=200
        active=1
        match_pattern="^SELECT .*"
        destination_hostgroup=30
        apply=1
    }
)

mysql_users =
(
    { username = "root", password = "${var.mysql_root_password}", default_hostgroup = 10, transaction_persistent = 0, active = 1 },
    { username = "${var.mysql_admin_user}", password = "${var.mysql_admin_password}", default_hostgroup = 10, transaction_persistent = 0, active = 1 }
)

proxysql_servers =
(
%{ for index , proxy in var.proxysql ~}
      { hostname = "proxysql-${split(":",var.proxysql[index])[0]}", port = 6032, weight = 1 }%{ if index < length(var.proxysql) - 1 },%{ endif }
%{ endfor ~}
)
  EOF
}