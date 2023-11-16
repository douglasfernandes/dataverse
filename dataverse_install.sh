#!/bin/bash
# Instala o dataverse em VM 

SOLR_VERSION="9.3.0"

# DOI obtido em aula
DIR_DOWNLOAD="/home/ubuntu/download"
cd /home/ubuntu
[ ! -f ${DIR_DOWNLOAD}/.env ] && touch ${DIR_DOWNLOAD}/.env && echo 'DOI_USERNAME="user_doi"
DOI_PASSWORD="password_doi"
POSTGRES_ADMIN_PASSWORD="postgres"
DATAVERSE_DB="dataverse"
DATAVERSE_DB_USER="dataverse"
DATAVERSE_DB_PASSWORD="dataverse"
ADMIN_EMAIL="email@webmail.br"
' > ${DIR_DOWNLOAD}/.env  && echo 'Altere o arquivo .env antes de iniciar a instalação!' && exit 1
source ${DIR_DOWNLOAD}/.env

apt-get update
apt-get -y install libc6-i386 libc6-x32 libxi6 libxtst6 unzip wget   
[ ! -f ${DIR_DOWNLOAD}/jdk-17_linux-x64_bin.deb ] && wget https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.deb -P ${DIR_DOWNLOAD}/
chown _apt /var/lib/update-notifier/package-data-downloads/partial/
apt-get -y install ${DIR_DOWNLOAD}/jdk-17_linux-x64_bin.deb 
apt-get -y install --reinstall jdk-17

# postgres

echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt-get update
apt-get -y install postgresql-13
pg_ctlcluster 13 main start
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
pg_ctlcluster 13 main restart
#service postgresql restart
pg_ctlcluster 13 main status
#service postgresql status
r=$(/usr/bin/psql -At -h 127.0.0.1 -p 5432 -U postgres -d postgres -c 'SELECT 1')
[ "$r"=="1" ] && echo "[INFO] Instalação do postgres OK !" || echo "[ERRO] Corriga a instalação do postgres !" 

# criando o usuário e db do dataverse . devem constar no .env
#sudo -u postgres psql -c "create database $DATAVERSE_DB;"
#sudo -u postgres psql -c "create user $DATAVERSE_DB_USER with encrypted password '$DATAVERSE_DB_PASSOWRD';"
#sudo -u postgres psql -c "grant all privileges on database $DATAVERSE_DB to $DATAVERSE_DB_USER;"

# solr

useradd -m solr
mkdir /usr/local/solr
[ ! -f ${DIR_DOWNLOAD}/solr-9.3.0.tgz ] && wget https://archive.apache.org/dist/solr/solr/9.3.0/solr-9.3.0.tgz -P ${DIR_DOWNLOAD}/
tar -xvzf ${DIR_DOWNLOAD}/solr-9.3.0.tgz -C /usr/local/solr
cp -r /usr/local/solr/solr-9.3.0/server/solr/configsets/_default /usr/local/solr/solr-9.3.0/server/solr/collection1
chown -R solr:solr /usr/local/solr
cd /usr/local/solr

sed -i 's;<Set name="requestHeaderSize"><Property name="solr.jetty.request.header.size" default="8192" /></Set>;<Set name="requestHeaderSize"><Property name="solr.jetty.request.header.size" default="102400" /></Set>;' /usr/local/solr/solr-9.3.0/server/etc/jetty.xml
sed -i '$a#Instalação dataverse' /etc/security/limits.conf
sed -i '$asolr soft nproc  65000' /etc/security/limits.conf
sed -i '$asolr hard nproc  65000' /etc/security/limits.conf
sed -i '$asolr soft nofile 65000' /etc/security/limits.conf
sed -i '$asolr hard nofile 65000' /etc/security/limits.conf 
sed -i '$aroot soft nproc  65000' /etc/security/limits.conf 
sed -i '$aroot hard nproc  65000' /etc/security/limits.conf 
sed -i '$aroot soft nofile 65000' /etc/security/limits.conf 
sed -i '$aroot hard nofile 65000' /etc/security/limits.conf
cd /usr/local/solr/solr-9.3.0
sudo -u solr bin/solr start
sudo -u solr bin/solr create_core -c collection1 -d server/solr/collection1/conf/

echo '[Unit]
Description = Apache Solr
After = syslog.target network.target remote-fs.target nss-lookup.target
[Service]
User = solr
Type = forking
WorkingDirectory = /usr/local/solr/solr-9.3.0
ExecStart = bash /usr/local/solr/solr-9.3.0/bin/solr start
ExecStop = bash /usr/local/solr/solr-9.3.0/bin/solr stop
ExecReload= bash /usr/local/solr/solr-9.3.0/bin/solr stop
LimitNOFILE=65000
LimitNPROC=65000
Restart=on-failure
[Install]
WantedBy = multi-user.target
' > /etc/systemd/system/solr.service
sudo -u solr bin/solr stop
systemctl daemon-reload
systemctl restart solr.service
systemctl enable solr.service
systemctl status solr.service

# Dataverse

apt-get -y install jq imagemagick curl libssl-dev libcurl4-openssl-dev
useradd -m dataverse
cd /home/dataverse
[ ! -f ${DIR_DOWNLOAD}/dvinstall.zip ] && wget https://github.com/IQSS/dataverse/releases/download/v6.0/dvinstall.zip -P ${DIR_DOWNLOAD}/
unzip ${DIR_DOWNLOAD}/dvinstall.zip -d /home/dataverse
chown -R dataverse:dataverse /home/dataverse
cp /home/dataverse/dvinstall/schema*.xml /usr/local/solr/solr-9.3.0/server/solr/collection1/conf
cp /home/dataverse/dvinstall/solrconfig.xml /usr/local/solr/solr-9.3.0/server/solr/collection1/conf
       
# Payara

useradd -m payara
# versão 6 
[ ! -f ${DIR_DOWNLOAD}/payara-6.2023.10.zip ] && wget https://nexus.payara.fish/repository/payara-community/fish/payara/distributions/payara/6.2023.10/payara-6.2023.10.zip -P ${DIR_DOWNLOAD}/
unzip ${DIR_DOWNLOAD}/payara-6.2023.10.zip -d /usr/local
sed -i 's;       <jvm-options>-Xbootclasspath/a:${com.sun.aas.installRoot}/lib/grizzly-npn-api.jar</jvm-options>;       <jvm-options>-Xbootclasspath/a:${com.sun.aas.installRoot}/lib/grizzly-npn-api.jar</jvm-options>\n        <jvm-options>-Ddataverse.path.imagemagick.convert=/opt/local/bin/convert</jvm-options>;' /usr/local/payara6/glassfish/domains/domain1/config/domain.xml
chown -R dataverse /usr/local/payara6
sudo -u dataverse /usr/local/payara6/glassfish/bin/asadmin start-domain
sudo -u dataverse /usr/local/payara6/bin/asadmin osgi lb
# deve aparecer Command osgi executed successfully.
r=$(curl -o /dev/null -s -w "%{http_code}\n" http://localhost:8080)
[ "$r"=="200" ] && echo "[INFO] Instalação do payara OK !" || echo "[ERRO] Corriga a instalação do payara !"
sudo -u dataverse /usr/local/payara6/glassfish/bin/asadmin stop-domain
echo '[Unit]
Description = Payara Server
After = syslog.target network.target
[Service]
User=dataverse
Type = forking
ExecStart = /usr/local/payara6/glassfish/bin/asadmin start-domain
ExecStop = /usr/local/payara6/glassfish/bin/asadmin stop-domain
ExecReload = /usr/local/payara6/glassfish/bin/asadmin restart-domain
TimeoutSec=900
[Install]
WantedBy = multi-user.target
' > /etc/systemd/system/payara.service
systemctl daemon-reload
systemctl enable payara.service
systemctl restart payara.service
systemctl status payara.service

# R

apt-get -y install --no-install-recommends software-properties-common dirmngr python3-pip
wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
add-apt-repository -y "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
apt update
apt-get install -y r-base r-base-core r-recommended r-base-dev
R -e 'install.packages("R2HTML", repos="https://cloud.r-project.org/", lib="/usr/lib/R/library" )' &
R -e 'install.packages("rjson", repos="https://cloud.r-project.org/", lib="/usr/lib/R/library" )' &
R -e 'install.packages("DescTools", repos="https://cloud.r-project.org/", lib="/usr/lib/R/library" )' &
R -e 'install.packages("Rserve", repos="https://cloud.r-project.org/", lib="/usr/lib/R/library" )' &
R -e 'install.packages("haven", repos="https://cloud.r-project.org/", lib="/usr/lib/R/library" )' &
wait

# Dataverse

CONFIG="/home/dataverse/dvinstall/default.config"
#GLASSFISH_DIRECTORY=/usr/local/payara6
sudo -u dataverse sed -i 's;GLASSFISH_DIRECTORY.*;GLASSFISH_DIRECTORY = /usr/local/payara6;' $CONFIG
sudo -u dataverse sed -i 's/DOI_USERNAME =.*/DOI_USERNAME = '$DOI_USERNAME'/' $CONFIG
sudo -u dataverse sed -i 's/DOI_PASSWORD =.*/DOI_PASSWORD = '$DOI_PASSWORD'/' $CONFIG
sudo -u dataverse sed -i 's/POSTGRES_DATABASE =.*/POSTGRES_DATABASE = '$DATAVERSE_DB'/' $CONFIG
sudo -u dataverse sed -i 's/POSTGRES_USER =.*/POSTGRES_USER = '$DATAVERSE_DB_USER'/' $CONFIG
sudo -u dataverse sed -i 's/POSTGRES_PASSWORD =.*/POSTGRES_PASSWORD = '$DATAVERSE_DB_PASSWORD'/' $CONFIG
sudo -u dataverse sed -i 's/POSTGRES_ADMIN_PASSWORD =.*/POSTGRES_ADMIN_PASSWORD = '$POSTGRES_ADMIN_PASSWORD'/' $CONFIG
sudo -u dataverse sed -i 's/ADMIN_EMAIL =.*/ADMIN_EMAIL = '$ADMIN_EMAIL'/' $CONFIG


pip3 install psycopg2-binary #psycopg2
cd /home/dataverse/dvinstall
python3 install.py -y

#Ativando o R server no dataverse
#RSERVE="/home/dataverse/dataverse-5.12.1/scripts/r/rserve/rserve-setup.sh"
#sed -i 's/chkconfig rserve on/update-rc.d rserve defaults/' ${RSERVE}
#sed -i '/^. \/etc\/rc.d\/init.d\/functions/s//#&/' ${RSERVE}
#${RSERVE}

#email

CONFIG_DOMAIN="/usr/local/payara6/glassfish/domains/domain1/config/domain.xml"

#alterar email
export EMAIL_FROM=""
export EMAIL_USER=""
export EMAIL_PASSWORD=""
sed -i 's;<mail-resource auth=.*;<mail-resource auth="false" host="smtp.gmail.com" from="${EMAIL_FROM}" user="${EMAIL_USER}" jndi-name="mail/notifyMailSession">
      <property name="mail.smtp.port" value="465"></property>
      <property name="mail.smtp.socketFactory.fallback" value="false"></property>
      <property name="mail.smtp.socketFactory.port" value="465"></property>
      <property name="mail.smtp.socketFactory.class" value="javax.net.ssl.SSLSocketFactory"></property>
      <property name="mail.smtp.auth" value="true"></property>
      <property name="mail.smtp.password" value="${EMAIL_PASSWORD}"></property>
    </mail-resource>
;' $CONFIG_DOMAIN
export DOMINIO="dadosabertos.br"
sed -i 's;<jvm-options>-Ddataverse.fqdn=dataverse</jvm-options>;<jvm-options>-Ddataverse.fqdn=${DOMINIO}</jvm-options>;' $CONFIG_DOMAIN
sed -i 's;<jvm-options>-Ddataverse.siteUrl=http://${dataverse.fqdn}:8080</jvm-options>;<jvm-options>-Ddataverse.siteUrl=http:/${DOMINIO}:8080</jvm-options>;' $CONFIG


#definir cabeçalho
curl -X PUT -d 'UFPB <dadosabertos@ufpb.br>' http://localhost:8080/api/admin/settings/:SystemEmail
curl -X PUT -d true http://localhost:8080/api/admin/settings/:SendNotificationOnDatasetCreation

