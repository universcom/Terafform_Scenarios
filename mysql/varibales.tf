#Define Database and keepalived Usernames/Passwords
variable "mysql_root_password" {default = "rootpass"}
variable "mysql_backup_password" {default = "backuppass"}
variable "proxysql_admin_user" {default = "proxysql-admin"}
variable "proxysql_admin_password" {default = "admin"}
variable "proxysql_cluster_admin_user" {default = "cluster-admin"}
variable "proxysql_cluster_admin_password" {default = "admin"}
variable "proxysql_mon_user" {default = "mon"}
variable "proxysql_mon_password" {default = "admin"}
variable "mysql_admin_user" {default = "mysql-admin"}
variable "mysql_admin_password" {default = "admin"}
variable "proxysql" {default = ["node1:write" , "node2:backup" , "node3:read"] }
variable "keepalived_AH_Password" {default = "admin"}