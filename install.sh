#!/bin/bash 
# Instalação 
# multipass ls
# multipass launch --name dataverse -d 50G -m 4G -c 4
# multipass transfer install.sh ${VM}:install.sh
# multipass shell dataverse ou
# mutipass exec ${VM} -- sudo ./install.sh

add-apt-repository -y "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
apt-get update
apt-get -y install unzip openjdk-11-jdk wget   

# postgres

echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt-get update
apt-get -y install postgresql-13
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*' #libera para todas as conexões/" /etc/postgresql/13/main/postgresql.conf
#Comenta todas as linhas
sed -i '/^#/! s/.*/#&/g' /etc/postgresql/13/main/pg_hba.conf
#Adiciona
sed -i '$a\
# Dataverse \
local   all             postgres                                trust \
host    all             all             127.0.0.1/32            trust \
host    all             all             ::1/128                 trust \
host    all             all             0.0.0.0/0               trust' /etc/postgresql/13/main/pg_hba.conf
service postgresql restart
service postgresql status
r=$(/usr/bin/psql -At -h 127.0.0.1 -p 5432 -U postgres -d postgres -c 'SELECT 1')
[ "$r"=="1" ] && echo "[INFO] Instalação do postgres OK !" || echo "[ERRO] Corriga a instalação do postgres !"

# solr

useradd -m solr
mkdir /usr/local/solr
chown solr:solr /usr/local/solr
cd /usr/local/solr
wget https://archive.apache.org/dist/lucene/solr/8.11.1/solr-8.11.1.tgz
tar xvzf solr-8.11.1.tgz
cp -r solr-8.11.1/server/solr/configsets/_default solr-8.11.1/server/solr/collection1
chown -R solr:solr solr-8.11.1

sed -i 's;<Set name="requestHeaderSize"><Property name="solr.jetty.request.header.size" default="8192" /></Set>;<Set name="requestHeaderSize"><Property name="solr.jetty.request.header.size" default="102400" /></Set>;' /usr/local/solr/solr-8.11.1/server/etc/jetty.xml
sed -i '$a#Instalação dataverse' /etc/security/limits.conf
sed -i '$asolr soft nproc  65000' /etc/security/limits.conf
sed -i '$asolr hard nproc  65000' /etc/security/limits.conf
sed -i '$asolr soft nofile 65000' /etc/security/limits.conf
sed -i '$asolr hard nofile 65000' /etc/security/limits.conf 
sed -i '$aroot soft nproc  65000' /etc/security/limits.conf 
sed -i '$aroot hard nproc  65000' /etc/security/limits.conf 
sed -i '$aroot soft nofile 65000' /etc/security/limits.conf 
sed -i '$aroot hard nofile 65000' /etc/security/limits.conf
#su solr #solr
cd /usr/local/solr/solr-8.11.1
sudo -u solr bin/solr start
sudo -u solr bin/solr create_core -c collection1 -d server/solr/collection1/conf/

# Dataverse

apt-get -y install jq imagemagick curl libssl-dev libcurl4-openssl-dev
useradd -m dataverse
cd /home/dataverse
wget https://github.com/IQSS/dataverse/releases/download/v5.12.1/dvinstall.zip
wget https://github.com/IQSS/dataverse/archive/v5.12.1.tar.gz
unzip dvinstall.zip
rm dvinstall.zip
tar -vzxf v5.12.1.tar.gz
rm v5.12.1.tar.gz
chown -R dataverse:dataverse /home/dataverse
cp /home/dataverse/dvinstall/schema.xml /usr/local/solr/solr-8.11.1/server/solr/collection1/conf
cp /home/dataverse/dvinstall/solrconfig.xml /usr/local/solr/solr-8.11.1/server/solr/collection1/conf

# Payara

useradd -m payara
cd /home/payara
#correção: https://s3-eu-west-1.amazonaws.com/payara.fish/Payara+Downloads/5.2022.3/payara-5.2022.3.zip
wget https://nexus.payara.fish/repository/payara-community/fish/payara/distributions/payara/5.2022.3/payara-5.2022.3.zip
unzip payara-5.2022.3.zip
rm payara-5.2022.3.zip 
chown -R payara:payara /home/payara
mv payara5 /usr/local/.
chown -R root:root /usr/local/payara5
chown dataverse /usr/local/payara5/glassfish/lib
chown -R dataverse:dataverse /usr/local/payara5/glassfish/domains/domain1
sed -i 's;<jvm-options>-client</jvm-options>;<jvm-options>-server</jvm-options>;g' /usr/local/payara5/glassfish/domains/domain1/config/domain.xml
sudo -u dataverse /usr/local/payara5/glassfish/bin/asadmin start-domain
sudo -u dataverse /usr/local/payara5/bin/asadmin osgi lb | grep 'Weld OSGi Bundle'
r=$(curl -o /dev/null -s -w "%{http_code}\n" http://localhost:8080)
[ "$r"=="200" ] && echo "[INFO] Instalação do payara OK !" || echo "[ERRO] Corriga a instalação do payara !"

# R

echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
apt-get -y install --no-install-recommends software-properties-common dirmngr
wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
add-apt-repository -y "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
apt-get install -y r-base r-base-core r-recommended r-base-dev
R -e 'install.packages("R2HTML", repos="https://cloud.r-project.org/", lib="/usr/lib/R/library" )'
R -e 'install.packages("rjson", repos="https://cloud.r-project.org/", lib="/usr/lib/R/library" )'
R -e 'install.packages("DescTools", repos="https://cloud.r-project.org/", lib="/usr/lib/R/library" )'
R -e 'install.packages("Rserve", repos="https://cloud.r-project.org/", lib="/usr/lib/R/library" )'
R -e 'install.packages("haven", repos="https://cloud.r-project.org/", lib="/usr/lib/R/library" )'

echo "Instalação do módulo III concluída!"
