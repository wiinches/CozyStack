################################################################################
# Configure Variables below to your hardware settings.
################################################################################

# Base directory where the logs and pcap should be stored.
HOME_DIR=<your data directory>

# Domain to be used for Cozy Stack installation.
DOMAIN=<Your Domain>
IP=<Your IP(example 192.168.1)>
ES_IP=$IP.15
KIBANA_IP=$IP.16
RANCHER_IP=$IP.17
RANCHER_AGENT_IP=$IP.18
OWNCLOUD_IP=$IP.19
GOGS_IP=$IP.20
CHAT_IP=$IP.21
MATTER_IP=$IP.22

################################################################################
# END OF USER CONFIGURATION - EDIT BELOW AT YOUR OWN RISK
################################################################################
service firewalld stop
# Install docker (and other RPMs)
yum localinstall ./extras/*
yum localinstall ./docker/*

# Create Virtual interfaces for containers.
bash interface.sh
systemctl restart network

# Start docker service
systemctl enable docker
systemctl start docker
docker load -i ./images/rancher-agentv1.1.0.docker
docker load -i ./images/elasticsearch.docker
docker load -i ./images/kibana.docker
docker load -i ./images/rancher.docker
docker load -i ./images/Gogs.docker
docker load -i ./images/openfire.docker
docker load -i ./images/owncloud.docker
docker load -i ./images/mattermost.docker
docker load -i ./images/osticket.docker
docker load -i ./images/mysql.docker
mkdir -p $HOME_DIR

echo "net.ipv4.conf.all.forwarding=1" >> /etc/systctl.conf
echo "vm.max_map_count=1073741824" >> /etc/systctl.conf


################## INSTALL Elasticsearch ##################
#This Docker image is set to run with 30GiB heap size so if you are running on a VM decrease size to -Xms2g -Xmx2g
ddocker run --restart=always -itd --name es -h es.$DOMAIN -p $ES_IP:9200:9200 -p $ES_IP:9300:9300 -e ES_JAVA_OPTS="-Xms30g -Xmx30g" elasticsearch

##################  INSTALL Kibana ##################
docker run --restart=always -it --name kibana -h kibana.$DOMAIN --link es:elasticsearch -p $KIBANA_IP:80:5601 -d kibana

##################  INSTALL Rancher ##################
docker run --restart=always -it -d --name rancher -h rancher.$DOMAIN -p $RANCHER_IP:80:8080 rancher/server

##################  INSTALL GOGS ##################
docker run --name gogs -h gogs.$DOMAIN -it -d --restart=always -p $GOGS_IP:80:3000 -p $GOGS_IP:1022:22 gogs/gogs

##################  INSTALL OpenFire ##################
docker run -it -d --restart=always --name=chat -h chat.$DOMAIN -p 3478:3478/tcp -p $CHAT_IP:3479:3479/tcp -p $CHAT_IP:5222:5222/tcp -p $CHAT_IP:5223:5223/tcp -p $CHAT_IP:5229:5229/tcp -p $CHAT_IP:7070:7070/tcp -p $CHAT_IP:7443:7443/tcp -p $CHAT_IP:7777:7777/tcp -p $CHAT_IP:80:9090/tcp -p $CHAT_IP:9091:9091/tcp sameersbn/openfire

##################  Install OwnCloud ##################
docker run --name owncloud -h owncloud.$DOMAIN --restart=always -it -d -p $OWNCLOUD_IP:80:80 -p $OWNCLOUD_IP:443:443 owncloud

##################  INSTALL mattermost ##################
docker run --restart=always -it -d --name mattermost -h mattermost.$DOMAIN -p $MATTER_IP:80:8065 mattermost/mattermost-preview
