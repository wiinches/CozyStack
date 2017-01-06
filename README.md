# CozyStack Installation Guide.

```
   ____               ____  _             _    
  / ___|___ _____   _/ ___|| |_ __ _  ___| | __
 | |   / _ \_  / | | \___ \| __/ _` |/ __| |/ /
 | |__| (_) / /| |_| |___) | || (_| | (__|   < 
  \____\___/___|\__, |____/ \__\__,_|\___|_|\_\
                |___/                          
```

###### Disclaimer: CozyStack has been designed specifically for certain hardware sets. Meaning it was not meant to be a dynamic install, before you begin this installation please notice that within the provided scripts some  values will need to be assigned in order for this to work.

# Pre-Installation
Download RPM files needed to install needed services and dependencies.

Download Sensor and Application Server files: https://drive.google.com/open?id=0B2Oi1KHMHUVJTnRrejhTWHM2UWs

### Sensor files
After downloading sensor.tar.gz, place that file into the sensor/ folder.

### Application files
After downloading apps.tar.gz, place that file into the application/ folder.

# Sensor Server Install Guide

Copy "sensor" folder to target server /tmp directory.
```
scp -r sensor <username>@<serverIP>:/tmp/
```
ssh into target server
```
ssh <username>@<serverIP>
```
Change Directory to /tmp/sensor
```
cd /tmp/sensor
```
Run Sensor server installation script
```
sudo bash SensorServer_deploy.sh
```

# Application Server Install Guide

Copy "application" folder to target server /tmp directory.
```
scp -r application <username>@<serverIP>:/tmp/
```
ssh into target server.
```
ssh <username>@<serverIP>
```
Change Directory to /tmp/application
```
cd /tmp/application
```
Run Application server installation script
```
sudo bash ApplicationServer_deploy.sh
```

#### Post Installation

Verify docker images are running.
```
docker ps -a
```

## To-do
* Have script output IMPORTANT.TXT
* Prompt user for everything upfront `read -p`
* CozyStack ASCII banner in script
* Health script
* Logstash 5.1 with MQ (set heap size)
* Incorporate Stenoremote container
* Logstash processed folder (file tracking)