#deploy containers and keepalived
resource "null_resource" "deploy" {
  depends_on = [
  module.lunch_instances
  ]
  for_each = toset(module.lunch_instances.instance_list)
  #connect to instances with ssh
  connection {
    type = "ssh"
    user = "ubuntu"
    timeout = "5m"
    private_key = "${file("~/.ssh/id_rsa")}"
    host = "${module.lunch_instances.Instances_floating_IP[each.value].floating_ip}"
    port = "22"
  }
  #Copy required files to destination hosts
  provisioner "file" {
    source = "Files/hosts"
    destination = "/home/ubuntu/hosts"
  }
  provisioner "file" {
    source = "Files/proxysql.cnf"
    destination = "/home/ubuntu/proxysql.cnf"
  }
  provisioner "file" {
    source = "Files/checkMySql.sh"
    destination = "/home/ubuntu/checkMySql.sh"
  }
  provisioner "file" {
    source = "Files/config_keepalived.sh"
    destination = "/home/ubuntu/config_keepalived.sh"
  }
  provisioner "file" {
    source = "Files/keepalived.conf"
    destination = "/home/ubuntu/keepalived.conf"
  }
  #run required commands in instances
  provisioner "remote-exec" {
      inline = [
        "sudo cp /home/ubuntu/hosts /etc/",
        "sudo apt update -qq -y && sudo apt install docker.io htop keepalived -y " ,
        "sudo cp /home/ubuntu/keepalived.conf /etc/keepalived/" ,
        "sudo chmod +x /home/ubuntu/config_keepalived.sh && sudo bash /home/ubuntu/config_keepalived.sh" ,
        "sudo systemctl restart keepalived.service" ,
        "sudo mkdir -p /mnt/data" ,
        "sudo docker run -d --name proxysql-${each.value} --hostname proxysql-${each.value} --publish 6033:6033 --publish 6032:6032 --publish 6080:6080 --restart=unless-stopped -v /home/ubuntu/proxysql.cnf:/etc/proxysql.cnf -v proxysql-volume:/var/lib/proxysql -v /home/ubuntu/hosts:/etc/hosts  repo.ficld.ir/proxysql/proxysql:2.4.4",
        "sudo docker run -it -d --name mariadb-${each.value} --hostname mariadb-${each.value} --network host --restart=unless-stopped -v /mnt/data:/var/lib/mysql -v /etc/hosts:/etc/hosts -e NODE_NAME=mariadb-${each.value} -e CLUSTER_ADDRESS=gcomm://%{~ for index , instance in module.lunch_instances.instance_list }${module.lunch_instances.instances[instance].access_ip_v4}%{ if index < length(module.lunch_instances.instance_list) - 1 },%{ endif }%{~ endfor } -e DB_ROOT_PASSWORD=${var.mysql_root_password} -e DB_MARIABACKUP_PASSWORD=${var.mysql_backup_password} %{ if each.value == "node1" } -e MYSQL_USER=${var.mysql_admin_user} -e MYSQL_PASSWORD=${var.mysql_admin_password} %{ endif } repo.ficld.ir/ustcweizhou/mariadb-cluster:ubuntu20-10.6.4"
      ]
  }
}

resource "time_sleep" "deploy" {
  depends_on = [null_resource.deploy]
  create_duration = "30s"
}

#add required users to database
resource "null_resource" "config_mon_user" {
  depends_on = [null_resource.deploy]
  #connect to instance-1 with ssh
  connection {
    type = "ssh"
    user = "ubuntu"
    timeout = "5m"
    private_key = "${file("~/.ssh/id_rsa")}"
    host = tostring(module.lunch_instances.Instances_floating_IP["${module.lunch_instances.instance_list[0]}"].floating_ip)
    port = "22"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo docker exec -it mariadb-${module.lunch_instances.instance_list[0]} mysql -h 127.0.0.1 -u root -p${var.mysql_root_password} -e \" INSERT INTO mysql.user (Host, User, Password) VALUES ('%', 'root', password('${var.mysql_root_password}')); \" " ,
      "sudo docker exec -it mariadb-${module.lunch_instances.instance_list[0]} mysql -h 127.0.0.1 -u root -p${var.mysql_root_password} -e \" CREATE USER '${var.proxysql_mon_user}'@'%' IDENTIFIED BY '${var.proxysql_mon_password}' \" " ,
      "sudo docker exec -it mariadb-${module.lunch_instances.instance_list[0]} mysql -h 127.0.0.1 -u root -p${var.mysql_root_password} -e \" GRANT SELECT ON sys.* TO '${var.proxysql_mon_user}'@'%'; \" " ,
      "sudo docker exec -it mariadb-${module.lunch_instances.instance_list[0]} mysql -h 127.0.0.1 -u root -p${var.mysql_root_password} -e \" GRANT ALL PRIVILEGES ON *.* TO '${var.mysql_admin_user}'@'%' IDENTIFIED BY '${var.mysql_admin_password}'; \" " ,
      "sudo docker exec -it mariadb-${module.lunch_instances.instance_list[0]} mysql -h 127.0.0.1 -u root -p${var.mysql_root_password} -e \" FLUSH PRIVILEGES; \" "
    ]

  }
}