################################################################################
# Configure Variables below to your hardware settings.                         #
################################################################################
# For setting up collection interface (ex: eth0)
INTERFACE=<name of collection interface>

# IP Address to elasticsearch (ex: 192.168.1.1)
ES_IP=<full ip of your elasticsearch server>

# The name of the domain (ex: test.lan)
DOMAIN=<domain name>

################################################################################
# EDIT BELOW AT YOUR OWN RISK                                                  #
################################################################################
tar xzvf sensor.tar.gz

echo -e $ES_IP\\telasticsearch >> /etc/hosts
# Install IPA
yum -y localinstall rpm/freeipa/*.rpm
ipa-server-install -U \
  -r $DOMAIN \
  -n $DOMAIN \
  -p toortoor \
  -a toortoor \
  --mkhomedir \
  --setup-dns \
  --no-forwarders \
  --reverse-zone=$(echo $ES_IP | awk -F. '{print $3"."$2"."$1".in-addr.arpa"}')
systemctl enavle ipa
systemctl start ipa

# Install Bro
yum -y localinstall rpm/base/*.rpm
yum -y localinstall rpm/bro/*.rpm
tar xzvf bro.tar.gz
cd bro/bro-2.5
./configure
make
make install
cd ../..
cd bro/bro-plugins/af_packet
./configure --bro-dist=../../bro-2.5/ --with-kernel=/usr/include
make
make install
cd ../../..
cp bro/etc/node.cfg /usr/local/bro/etc/node.cfg
sed -i "s/INTERFACE/$INTERFACE/g" /usr/local/bro/etc/node.cfg
cp bro/etc/broctl.cfg /usr/local/bro/etc/broctl.cfg
cp bro/etc/local.bro /usr/local/bro/share/bro/site/local.bro

# Use BroCTL to finish Bro install and deploy
mkdir -p /data/bro
mkdir -p /data/bro/spool
/usr/local/bro/bin/broctl install
/usr/local/bro/bin/broctl deploy
/usr/local/bro/bin/broctl stop
cp bro/etc/bro.service /etc/systemd/system
systemctl enable bro
systemctl start bro

# Install suricata
tar xzvf suricata.tar.gz
cd suricata/suricata-3.2
./configure --prefix=/usr \
  --sysconfdir=/etc \
  --localstatedir=/var \
  --enable-nfqueue \
  --enable-lua
autoreconf -isvf
ldconfig /usr/local/lib
make
make install-full
cd ../..
cp suricata/etc/suricata.yaml /etc/suricata/suricata.yaml
sed -i "s/DEVICENAME/$INTERFACE/g" /etc/suricata/suricata.yaml
ethtool -K $INTERFACE lro off
ethtool -K $INTERFACE gro off
ldconfig /usr/local/lib
cp suricata/etc/suricata.service /etc/systemd/system
sed -i "s/DEVICENAME/$INTERFACE/g" /etc/systemd/system/suricata.service
systemctl enable suricata
systemctl start suricata

#### Extract ET Rules
#### to /etc/suricata/rules

# Install stenographer
yum -y localinstall rpm/stenographer/*.rpm
mkdir -p /data/index
chown stenographer:stenographer /data/index
mkdir -p /data/packets
chown stenographer:stenographer /data/packets
cp stenographer/etc/config /etc/stenographer/config
sed -i "s/placeholder/$INTERFACE/g" /etc/stenographer/config
chmod 755 /etc/stenographer
chown stenographer:stenographer /etc/stenographer/certs
chmod 750 /etc/stenographer/certs
systemctl enable stenographer
systemctl start stenographer

# Install filebeat
yum -y localinstall rpm/filebeat/*.rpm
systemctl enable filebeat
systemctl start filebeat
cp filebeat/filebeat.yml /etc/filebeat/filebeat.yml

# Install Metricbeat
yum -y localinstall rpm/metricbeat/*.rpm
systemctl enable metricbeat
systemctl start metricbeat
cp metricbeat/metricbeat.yml /etc/metricbeat/metricbeat.yml

# Install Logstash
yum -y localinstall rpm/logstash/*.rpm
mkdir -p /usr/share/GeoIP
cp logstash/GeoLite2-City.mmdb /usr/share/GeoIP
systemctl enable logstash
systemctl start logstash
cp logstash/logstash.conf /etc/logstash/conf.d/logstash.conf
cp logstash/logstash.yml /etc/logstash/logstash.yml
mkdir /data/logstash
chmod 755 /data/logstash

# Restart
init 6
