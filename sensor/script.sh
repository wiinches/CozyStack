# For setting up collection interface
INTERFACE=<name of collection interface (like eth0)>
# app server
ES_IP=<full ip of your elasticsearch server>
DOMAIN=<domain name>
REVERSE_ZONE=<reverse domain zone (like 1.168.192.in-addr.arpa.)> ### Network portion of the subnet backwards with '.in-addr.arpa.' on the end.

################################################################################
# EDIT BELOW AT YOUR OWN RISK                                                  #
################################################################################

# Install IPA
yum -y localinstall rpm/freeipa/*.rpm
ipa-server-install -U -r $DOMAIN -n $DOMAIN -p toortoor -a toortoor --mkhomedir --setup-dns --no-forwarders --reverse-zone=$REVERSE_ZONE
systemctl enavle ipa
systemctl start ipa

# Install Bro
yum -y localinstall rpm/base/*.rpm
yum -y localinstall rpm/bro/*.rpm
tar xzvf bro.tar.gz
cd bro/bro-2.5
./configure && make && make install
cd ../..
# Install AF_Packet for Bro
cd bro/bro-plugins/af_packet
./configure --bro-dist=../../bro-2.5/ --with-kernel=/usr/include && make && make install
cd ../../..
# Move configuration files into Bro folders
cp bro/etc/node.cfg /usr/local/bro/etc/node.cfg
sed -i "s/INTERFACE/$INTERFACE/g" /usr/local/bro/etc/node.cfg
cp bro/etc/broctl.cfg /usr/local/bro/etc/broctl.cfg
cp bro/etc/local.bro /usr/local/bro/share/bro/site/local.bro

# Use BroCTL to finish Bro install and deploy
mkdir -p /data/bro
mkdir -p /data/bro/spool
/usr/local/bro/bin/broctl install
/usr/local/bro/bin/broctl deploy

#### BRO DOES NOT START ON BOOT. '/usr/local/bro/bin/broctl start'

# Install suricata
tar xzvf suricata.tar.gz
cd suricata/suricata-3.2
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --enable-nfqueue --enable-lua

# Do stuff to fix errors... not sure what it really does.
autoreconf -isvf
ldconfig /usr/local/lib
make && make install-full
cd ../..
cp suricata/etc/suricata.yaml /etc/suricata/suricata.yaml
sed -i "s/DEVICENAME/$INTERFACE/g" /etc/suricata/suricata.yaml

# More error fixing... not sure what it does...
ethtool -K $INTERFACE lro off
ethtool -K $INTERFACE gro off
ldconfig /usr/local/lib
suricata --af-packet=$INTERFACE -D

#### SURICATA DOES NOT START ON BOOT. Use above command.

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
sed -i "s/ES_HOST/$ES_IP/g" /etc/filebeat/filebeat.yml

# Install Metricbeat
yum -y localinstall rpm/metricbeat/*.rpm
systemctl enable metricbeat
systemctl start metricbeat
cp metricbeat/metricbeat.yml /etc/metricbeat/metricbeat.yml
sed -i "s/ES_HOST/$ES_IP/g" /etc/metricbeat/metricbeat.yml

# Install Logstash
yum -y localinstall rpm/logstash/*.rpm
mkdir -p /usr/share/GeoIP
cp logstash/GeoLite2-City.mmdb /usr/share/GeoIP
systemctl enable logstash
systemctl start logstash
cp logstash/logstash.conf /etc/logstash/conf.d/logstash.conf
sed -i "s/ES_HOST/$ES_IP/g" /etc/logstash/conf.d/logstash.conf
cp logstash/logstash.yml /etc/logstash/logstash.yml
