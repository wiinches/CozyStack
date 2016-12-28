################################################################################
# Configure Variables below to your hardware settings.                         #
################################################################################
# Name of your domain
DOMAIN=<domain name>

# First 3 octects of the Application server IP
IP=<first 3 octets of IP space (ex: 192.168.1)>

# Primary communication interface between the Sensor and Application Servers
# This may be a bonded interface.
INTERFACE=<NIC name (ex: eth0)>

# Heap Space Allocation for Elasticsearch
#ES_RAM=30g    # 30GiB Heap Space for Elasticsearch (For Servers)
ES_RAM=2g   # 2GiB Heap Space for Elasticsearch (For VMs)

# IP Schema
ES_IP=$IP.15
KIBANA_IP=$IP.16
RANCHER_IP=$IP.17
RANCHER_AGENT_IP=$IP.18
OWNCLOUD_IP=$IP.19
GOGS_IP=$IP.20
CHAT_IP=$IP.21
MATTER_IP=$IP.22
################################################################################
# END OF USER CONFIGURATION - EDIT BELOW AT YOUR OWN RISK                      #
################################################################################
tar xzvf apps.tar.gz

# Install docker (and other RPMs)
yum -y localinstall ./extras/*
yum -y localinstall ./docker/*

# Create Virtual interfaces for containers.
bash interface.sh $INTERFACE $IP
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
#docker load -i ./images/mattermost.docker
#docker load -i ./images/osticket.docker
#docker load -i ./images/mysql.docker

echo "net.ipv4.conf.all.forwarding=1" >> /usr/lib/sysctl.d/00-system.conf
echo "vm.max_map_count=1073741824" >> /usr/lib/sysctl.d/00-system.conf


################## INSTALL Elasticsearch ##################
mkdir -p /data/elasticsearch
chmod 755 /data/*
mkdir /tmp/es
chmod 755 /tmp/es
cp elasticsearch/elasticsearch.yml /data/elasticsearch
#cp elasticsearch/x-pack-5.1.1.zip /tmp/es
docker run --restart=always -itd --name es \
            -v /data/elasticsearch/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml \
            -v /tmp/es:/tmp/es:Z \
            -h es.$DOMAIN \
            -p $ES_IP:9200:9200 \
            -p $ES_IP:9300:9300 \
            -e ES_JAVA_OPTS="-Xms$ES_RAM -Xmx$ES_RAM" \
            elasticsearch
#docker exec -itu root es /usr/share/elasticsearch/bin/elasticsearch-plugin \
#            install file:///tmp/es/x-pack-5.1.1.zip

##################  INSTALL Kibana ##################
mkdir -p /data/kibana/etc
chmod 755 /data/*
cp kibana/kibana.yml /data/kibana/etc
#cp elasticsearch/x-pack-5.1.1.zip /tmp/es
docker run --restart=always -itd --name kibana \
            -v /data/kibana/etc/kibana.yml:/etc/kibana/kibana.yml \
            -v /tmp/es:/tmp/es:Z \
            -h kibana.$DOMAIN \
            -p $KIBANA_IP:80:5601 \
            kibana
#docker exec -itu root es /usr/share/kibana/bin/kibana-plugin \
#            install file:///tmp/es/x-pack-5.1.1.zip

##################  INSTALL Rancher ##################
docker run --restart=always -itd --name rancher \
            -h rancher.$DOMAIN \
            -p $RANCHER_IP:80:8080 \
            rancher/server

##################  INSTALL GOGS ##################
docker run --restart=always -itd --name gogs \
            -h gogs.$DOMAIN \
            -p $GOGS_IP:80:3000 \
            -p $GOGS_IP:1022:22 \
            gogs/gogs

##################  INSTALL OpenFire ##################
docker run --restart=always -itd --name chat \
            -h chat.$DOMAIN \
            -p $CHAT_IP:3478:3478/tcp \
            -p $CHAT_IP:3479:3479/tcp \
            -p $CHAT_IP:5222:5222/tcp \
            -p $CHAT_IP:5223:5223/tcp \
            -p $CHAT_IP:5229:5229/tcp \
            -p $CHAT_IP:7070:7070/tcp \
            -p $CHAT_IP:7443:7443/tcp \
            -p $CHAT_IP:7777:7777/tcp \
            -p $CHAT_IP:80:9090/tcp \
            -p $CHAT_IP:9091:9091/tcp \
            sameersbn/openfire

##################  Install OwnCloud ##################
docker run --restart=always -itd --name owncloud \
            -h owncloud.$DOMAIN \
            -p $OWNCLOUD_IP:80:80 \
            -p $OWNCLOUD_IP:443:443 \
            owncloud

##################  INSTALL mattermost ##################
#docker run --restart=always -itd --name mattermost \
#           -h mattermost.$DOMAIN \
#           -p $MATTER_IP:80:8065 \
#           mattermost/mattermost-preview

# Make Elasticsearch Green Again.
curl -XPUT 'http://$ES_IP:9200/_all/_settings?preserve_existing=false' \
     -d '{ "index.number_of_replicas" : "0" }'

# Reboot after install finishes
init 6
