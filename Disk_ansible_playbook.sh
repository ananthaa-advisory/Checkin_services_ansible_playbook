### ########################
# Script to Auto Truncate the disks via Ansible Playbook
################

Part 1:
####Playbook########

# cat disk.yml
---
-  hosts: "{{ hosts1 }}"
   tasks:
     - name: checking Audit logs and truncating
       script: /root/disk_truncate.sh
       become: yes
       become_user: root
       register: result
     - debug:
         var: result


####Audit Playbok ##########

# cat audit.yml

---
-  hosts: "{{ hosts1 }}"
   tasks:
     - name: checking Audit logs
       script: /root/audit.sh
       become: yes
       become_user: root
       register: result
     - debug:
         var: result

################
Part 2

# cat disk_truncate.sh

#!/bin/bash
a=`find / -xdev -type f -printf '%s %p\n'| sort -nr | head -1|awk '{print $2}'|xargs sudo ls -lhS`
file_size=`echo $a | awk '{print $5}' |sed "s/[^0-9]//g"`
file_name=`echo $a | awk '{print $9}'`
file_name_trunc=`echo $a | awk '{print $9}' | awk -F'/' '{print $NF}'` 
echo $size,$file,$file_name_trunc
if [[ $file_size -ge 100 ]] && [[ "$file_name_trunc" == "defaultthreaddump.log" ]]
then
truncate -s 0 $file_name
file_name_size=`ls -lh $file_name`
echo "$file_name_size after truncation"
else
echo "No files are greater than 100 GB in size"
fi

##########
#Part 3: -  #@@@@ Root script save as "disk_ansible.sh"
# This will add the IP address if the host is new in /etc/ansible/hosts file and run the respective playbacks
##############

#!/bin/bash
host=$1
if [[ $(grep -wc $host /etc/ansible/hosts) -eq "0" ]]; then
echo "***************Adding this to hostlist in /etc/ansible/hosts file , Please wait **********************************"
echo "$host ansible_connect=ssh ansible_ssh_pass='XXXXX' ansible_user=XXXXXX" ansible_python_interpreter=/usr/bin/python3 | tee -a /etc/ansible/hosts
ansible-playbook audit.yml --extra-vars "hosts1=$host"
ansible-playbook disk.yml --extra-vars "hosts1=$host"
else
ansible-playbook audit.yml --extra-vars "hosts1=$host"
ansible-playbook disk.yml --extra-vars "hosts1=$host"
fi


