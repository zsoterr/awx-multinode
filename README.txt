--------------------------------
AWX v9 multi node enviroment
--------------------------------

This project contains an optimized deployment-plan for AWX v9, based on multi node environment.

----------------
I. INSTALLATION:
----------------

Some words about the installation's history and environment:
This deployment has been created based on this git repository: https://github.com/sujiar37/AWX-HA-InstanceGroup/releases/tag/V9.1.1
I need to fix some issue in original code(s) - for example: rabbitmq server - and I extended the deplyoment some useful parts like https support,newer ansible version,pynetbox,TimeZone support,etc.

I don't use docker swarm instead of that I'm going to use official docker community edition (named docker-ce), on all nodes. 
I've validated evrything using Centos v7.
If you use one more docker-node you have to ensure if all nodes are able to communicate with each other.


I. PREPARATION:
- update the /etc/hosts file on all docker nodes and ensure if the nodes are able to reach each other, using hostname via ssh protocol.
- using sed command to replace the "pre-defined user" to you user account, which will be used to run the deployment! : for example, you can run this (or similar to this) command, within the downloaded repository's directory:
$pwd
.../git/my/awx/docker/work-temp/awx-multinode
 grep -rl defaultuser ./deployment/playbooks/ | xargs sed -i 's/defaultuser/DesiredUserName/g'
- if you use the default ansible configuration (like inventory) you have to edit/update the file (/etc/ansible/hosts) with "planned roles" of awx-nodes.
We will refer these "roles" in our yml files...
In my case, for example, last section of my /etc/ansible/hosts file:
...##due to awx deployment
[dbservers]
dock-awx-db1:2222

[awxnodes]
dock-awx-node1:2222
dock-awx-node2:2222

[allnodes]
dock-awx-db1:2222
dock-awx-node1:2222
dock-awx-node2:2222

- run these commands: 
These commands will run the preparation on nodes- based on the /etc/hosts and /etc/ansible/hosts file - :
-/deployment/oneliners/ping-test.sh : ping test, every node is reachable?,
./deployment/oneliners/date-check.sh: check the date on nodes,
./deployment/oneliners/df-check.sh:  check whether you have enough space on nodes,
./deployment/oneliners/PREP-dock-all.sh: node(s)' preparation (for example: install packages,docker,etc.)
./deployment/oneliners/PREP-users-all.sh: create the necessary user(s),group(s),etc.
./deployment/oneliners/PREP-db-node.sh: database node(s)'s preparation,
./deployment/oneliners/PREP-awx-nodes.sh: awx node(s)'s preparation (for web/task containers)
In my case I changed the default SSH port from 22 to 2222: that means, if you use different ssh port (as 2222) you have to update the scripts, where I referred to this port number! 


DATABASE:
- if you want you can prepare it by yourself,
or
- you can use my prepared deployment which will use a compose file to create a postfresql instance on database node and set it to master-role. Later, if you want you can add a slave postgresql database instance.
You can use a separated node (preferred, especially within production-ready environment)  for this purpose or you can put it on one of awx nodes (within only test environment)
My database instance has been created based on this repository:  https://github.com/zsoterr/database-clustering.git
If you want to use this repository meanwhile the deployment you have to edit the .env file - before the deployment: you can find here: ...deployment/playbooks/files/db/.env
Basically - following this readme's steps we will use this repository to set up the database instance, during deployment.


CONTAINER IMAGES:
The images will be built using the "official ansible awx" images.
 Web and task container: based on v9.1.1 images.
 Memccached: also, but if you would like to add unique timezone support you need to build a new image:
ps: the deplyoment works without any changes (regarding imamgs) but - if you want - you can ensure if the timestamp is correct -regarding memcached container- you should follow these steps:
- download the memcached images and run the memcached container,
- add the following changes to container:
You can change Europe/Budapest based on your requirement.
docker exec -u root -i build_image_memcached_1 /bin/sh -c "apk add tzdata"
docker exec -u root -i build_image_memcached_1 /bin/sh -c "cp /usr/share/zoneinfo/Europe/Budapest /etc/localtime"
docker exec -u root -i build_image_memcached_1 /bin/sh -c "echo 'Europe/Budapest' >  /etc/timezone"
docker exec -u root -i build_image_memcached_1 /bin/sh -c "apk del tzdata"
docker stop build_image_memcached_1
docker commit build_image_memcached_1 $NameOfImageNewMemcachedContainer
- and you have to reference this new imagei, in docker compose files! That means you have to edit compose files, before the deployment!

You can use these "pre-created" Dockerfile(s) or you cand edit the necessary configuration file and change the necessary parameters (like TimeZone). Don't forget to refer the new image(s) - in configuration file - if you build another/unique image for your goals: in this case you must check the  Dockerfile(s) and compose file(s).

We will install a newer ansible version within awx containers using a pre-downloaded offical ansible rpm package.
Why? 
Well, the published ansible packages always change, and we can't guarantee if the current ansible packages (when I created this deployment) will be available that time, when you start the deployment. Yes, we can check and use the "actual ansible version" - realtime,meanwhile the deployment -but please think about that the fact if you shouldn't use any un-validated component(s) - in our case: ansible version- within your environment. 
You must pre-check and validate the newer ansible version - too - before you publish/use that within you deployment/environment, especially: production-ready environment. 


DOCKER NODE:
You can use a prepared docker image - as docker-node, with pre-installed necessary packages -  or, you can use different image/different server for this purpose.
Note: keep in your mind if I validated everything on Centos v7. I've already mentioned this fact, but it's a really important thing/fact.
Firewall: Basically, you don't have to stop and disable firewalld but sometimes useful.
SeLinux: I've validated this awx deployment using "enforced" SELINUX policy but, - if you want - you can disable selinux, via configuraton file:  /etc/selinux/config and restart the docker node before you start the deployment.
User account:
I've created a dedicated user for me - on all affected docker-node(s) - and I've published my ssh public key on docker-node(s). You can do this also. It's very convinient due to the fact if you don't have to type our passwords,regularly....
The deplyoment will create a technical user (sshawx user) on all nodes. The public key of sshawx user will be deployed on docker-node(s),too. 
Meanwhile the deployment we will change your sshd configuration: this parameter will be set to "yes":  PubkeyAuthentication, here: /etc/ssh/sshd_config - on affected docker-node(s).
SSHAWX user: if you want to use this technical user, you must generate and place the user public key, here: .../deployment/playbooks/files/userskeys/


DEDICATED network for docker daemon:
There is a chance if you will have a conflict - regarding exist networks - within your infrastructure so if you would like to avoid this, you haveto set a dedicated network for docker daemon - before the deployment: you can control this, using a docker configuration file:  have a look a prepared configuration file - which will be deployed! -, here: .../deployment/playbooks/files/docker/daemon.json
 
 
II. INSTALL:
ENSURE if:
- you (your user account) is able to reach every nodes, using ssh key, without typing user passwords. Not mandatory, but useful.
- edit the /etc/hosts file (on all docker-node) and ensure if all nodes are able to communicate with each other, using ssh protocol.
- download this git repositry, jump to directory and edit these files based on your expectations:
 inventory/hosts: you can use hostname,
 inventory/group_vars/all.yml: set IP address of db node
- if you use the default ansible configuration (like inventory) you have to edit/update the file (/etc/ansible/hosts) with "roles" of awx-nodes.
In my case, for example:
...##due to awx deployment
[dbservers]
dock-awx-db1:2222

[awxnodes]
dock-awx-node1:2222
dock-awx-node2:2222

[allnodes]
dock-awx-db1:2222
dock-awx-node1:2222
dock-awx-node2:2222

- update docker-compose.yml.j2 -if needed, for example: proxies, dns servers, memcached image's name,etc.
You can find the file within this directory: .../roles/awx_ha/templates/

- run the deployment as your account (or you can become to sshawx user, if you want.) :
  ansible-playbook -i inventory/hosts awx_ha.yml --verbose -K

You can use this oneliner to check whether web ui is available or not: echo "Waiting for awx web"&&while ! httping -qc1 https://$IP_or_NAME_of_webserverHOST ; do sleep 1 ; done&&links2 -ssl.certificates 0 https://$IP_or_NAME_of_webserverHOST

If everything went well you will get similar to this:
On docker-node, where the web server is running:
$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                  NAMES
390684a5d5d6        awx_task_ha:9.2.0   "/tini -- /bin/sh -c…"   25 minutes ago      Up 25 minutes       8052/tcp               build_image_task_1
b1fae0cfd2d8        awx_web_ha:9.2.0    "/tini -- /bin/sh -c…"   25 minutes ago      Up 25 minutes       0.0.0.0:80->8052/tcp   build_image_web_1
c221cdfe693a        memcached:alpine    "docker-entrypoint.s…"   25 minutes ago      Up 25 minutes       11211/tcp              build_image_memcached_1

Instance group: You can find the details on the web interface (UI), under "Instance Group".
Sometimes the node's status is "unavailable" or you don't see the desired node-name,rarely. In this case you have to restart the containers on the affected node and the node will be available for instance group.


--------------------------------------------
II. BEFORE the deployment! 
--------------------------------------------

--------------------
PROXIES, DNS servers
--------------------
As I mentioned, - if needed - add proxy/proxies to dokcer-compose configuration file(s). You can find here:  .../roles/awx_ha/templates/

--------------
HTTPS support:
--------------
The deployment will create a self-signed certificate for awx web server. If you dont't want to use this, please update/edit the playbook, before the deployment: .../deployment/plabooks/prep-awx-nodes.yml
After you ran the referred playbook you should get similar to this on docker node:
/srv/awx/pass2awx/certs/
awxweb.crt
awxweb.csr
awxweb.key

NGINX CONFIGURATION: 
You can edit/update (for example: server name, chiper method,etc.) before the deployment. You can find the nginx configuration file within this directory: ..../deployment/playbooks/files/configs/nginx.conf  and will be copied to nodes, using this path:  /srv/awx/pass2awx/configs/nginx.conf


--------------
VAULT file:
--------------
Maybe you can use/reference a vault file,regularly. In this case you can add vault file to deployment.
Pass VAULT file to containers.
- edit the necessary file before the deployment: ..../deployment/playbooks/files/configs/ansible_vault_pw
- will be published on nodes,in the next path: /srv/awx/pass2awx/configs/ansible_vault_pw


------------------
CORKSCREW support:
------------------
If you want to use corkscrew  (for example: to reach a git repositories - through a proxy- you can use corkscrew, for example.
This will be deployed automatically, if you don't want edit/update the configuration files before the deployment.
Source: .../deployment/playbooks/files/configs/corkscrew/
 - configuration file (update before you start to use,before the deployment): /srv/awx/pass2awx/configs/corkscrew/config
Destination: /srv/awx/pass2awx/configs/corkscrew/


------------------
LDAP support:
------------------
If you need addtional ldap support (like certificate):
- update the pem file wiht right certificate, before the deployment, you can find here: .../deployment/playbooks/files/awx/Internal_Root_CA_1.pem

