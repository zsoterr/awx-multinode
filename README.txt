# This repository is archived and not actively maintained. The content may still be useful as a reference

--------------------------------
# AWX v9 multi node enviroment
--------------------------------

This project contains every fundamental deployment-plans for AWX v9 -based on multi node environment.

----------------
I. INSTALLATION:
----------------
This deployment has been created based on this git repository: https://github.com/sujiar37/AWX-HA-InstanceGroup/releases/tag/V9.1.1
I need to fix some issue in original code(s) - like rabbitmq server - and I extended the deplyoment some useful stuffs like https support,newer ansible,pynetbox,TimeZone support,etc.

We will not use docker swarm,  we use docker-ce on all nodes. 
All nodes are able to communicate with each other.


I. PREPARATION:
- create the necessary paths under /srv/ : /srv/awx/build_image and /srv/awx/projects and /srv/awx/configs
- update the /etc/hosts file with right data of awx server(s) on all docker nodes

DATABASE:
- you have to prepare it by yourself,
- you can use this simple compose file for this purpose: .../examples/postgresql/docker-compose.yml
 In this case create the necessary path before the deplyoment : /srv/awx/pgdocker
if you want to prepare the database for clustering, please check this repository: https://github.com/zsoterr/database-clustering.git

CONTAINER IMAGES:
The images will be built based on the "official ansible awx" images.
 Web and task container: based on v9.1.1 images.
 Memccached: also, but if you would like to add unique timezone support you need to build a new image:
ps: the deplyoment works without any changes (on image's side) but if you would like to ensure if the timestamps are correct -regarding all containers- you should follow these steps:
- download the memcached images and run the memcached container,
- add the following changes to container:
You can change Europe/Budapest based on your requirement.
docker exec -u root -i build_image_memcached_1 /bin/sh -c "apk add tzdata"
docker exec -u root -i build_image_memcached_1 /bin/sh -c "cp /usr/share/zoneinfo/Europe/Budapest /etc/localtime"
docker exec -u root -i build_image_memcached_1 /bin/sh -c "echo 'Europe/Budapest' >  /etc/timezone"
docker exec -u root -i build_image_memcached_1 /bin/sh -c "apk del tzdata"
docker stop build_image_memcached_1
docker commit build_image_memcached_1 $NameOfImageNewMemcachedContainer
- and you have to reference this new image in docker compose files!
You can use these "preferred" images, or you can build the container images (by yourself)- using Dockerfile(s) and edit the necessary configuration file which refers the images: in this case check our Dockerfile as example

DOCKER NODE:
- you can use a prepared node image as docker-node or, you can use different image/different server for this purpose:
Note: keep in your mind if I validated everything on Centos v7.
 Prepare your server for docker by yourself (for example: install docker, necessary packages,etc.)
 Don't have to stop and disable firewalld, but maybe useful if you disable selinux via configuraton file:  /etc/selinux/config and restart the docker node before you start the deployment.
 - create a technical user - due to ssh connection - on affected node(s) and create ssh key (without keypass):
 - set the right permission on .ssh folder and on key-files - for example:
  chmod 700 /home/$username/.ssh
  chmod 600 /home/$username/.ssh/authorized_keys
 Create the sshawx user on all nodes.
 Copy the public key of sshawx user to affected nodes (you can use ssh-copy-id command)
 Ensure if this parameter is correct ( 'yes' ): grep  PubkeyAuthentication /etc/ssh/sshd_config on affected node(s) on all nodes,
 Ensure if the ssh connection works (between the affected nodes) , for example:  ssh -i /home/sshawx/.ssh/id_dsa sshawx@$IP_ADDRESS

DEDICATED network for docker daemon:
There is a chance if you will have conflict - regarding exist networks - within your infrastructure so if you would like to avoid this, you have to set a pre-defined network for docker daemon, you can do it:
- via docker configuration file, have a look an example here: ../examples/daemon.json
 
 
II. INSTALL:
- edit these files based on your expectations:
inventory/hosts
inventory/group_vars/all.yml

-update docker-compose.yml.j2 -if needed, for example: proxies, dns servers, memcached image's name
You can find the file here: .../AWX-HA-InstanceGroup/roles/awx_ha/templates

- run the deployment as sshawx (or user that you created for ssh connection) : ansible-playbook -i inventory/hosts awx_ha.yml --verbose -K

If everything went well you will get similar to this:
$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                  NAMES
390684a5d5d6        awx_task_ha:9.2.0   "/tini -- /bin/sh -c…"   25 minutes ago      Up 25 minutes       8052/tcp               build_image_task_1
b1fae0cfd2d8        awx_web_ha:9.2.0    "/tini -- /bin/sh -c…"   25 minutes ago      Up 25 minutes       0.0.0.0:80->8052/tcp   build_image_web_1
c221cdfe693a        memcached:alpine    "docker-entrypoint.s…"   25 minutes ago      Up 25 minutes       11211/tcp              build_image_memcached_1


--------------------------------------------
II. TO-DO -before you start the deployment.
--------------------------------------------

--------------------
PROXIES, DNS servers
--------------------
If needed add proxy/proxies to dokcer-compose configuration file(s). You can find here:  .../roles/awx_ha/templates/

--------------
HTTPS support:
--------------
1. Create the necessary paths under /srv/ and copy the necessary files to right paths:
- create a certificate for webserver and drop those to certs directory: /srv/awx/pass2awx/certs/
For example:
 openssl genrsa -out awxweb.key 2048
 openssl req -sha256 -new -key awxweb.key -out awxweb.csr -subj '/CN=awxweb'
 openssl x509 -req -sha256 -days 365 -in awxweb.csr -signkey awxweb.key -out awxweb.crt
- copy  nginx.conf (from examples directory) to /srv/awx/pass2awx/configs/ path

You should get similar to this:
/srv/awx/pass2awx/certs/
awxweb.crt
awxweb.csr
awxweb.key
AND
/srv/awx/pass2awx/configs/nginx.conf

2. Update nginx.conf (if you want) (under /srv/... ) with right server name, name of certificate file, chiper method,etc


--------------
VAULT file:
--------------
Maybe you can use/reference vault file,regularly. In this case you can add vault file to deployment.
Pass VAULT file to containers.
- edit the necessary file before the deployment. You have to put it to next path: /srv/awx/pass2awx/configs/ansible_vault_pw


------------------
CORKSCREW support:
------------------
If you want to use corkscrew  (for example: to reach a git repositories - through a proxy- you have to copy the files from .../examples/corkscrew/ to destination path and edit the "config" file:
- destination path: /srv/awx/pass2awx/configs/corkscrew/
- configuration file: /srv/awx/pass2awx/configs/corkscrew/config


------------------
LDAP support:
------------------
If you need addtional ldap support (like certificate):
- update the pem file wiht right certificate, you can find here: .../examples/ldap-config/Internal_Root_CA_1.pem
