#!/bin/bash

#altere para o seu diretório de projeto
export DIR_PROJECT="${HOME}/douglas500/sti/desenvolvimento/repositorios/dataverse"
[ -z ${DIR_PROJECT} ] && echo -e 'Informe o diretório do projeto. Ex:\n  export DIR_PROJECT="${HOME}/dev/evor"' && exit 1

YML="${DIR_PROJECT}/dataverse/docker-compose-dev.yml"
OPTSTRING=":umdbhi"
BUILD=false
FORMA="d" #d=docker ; m=multipass

# Docker exemplo
# https://github.com/docker/awesome-compose/tree/master/official-documentation-samples/django/

# instalando o docker na vm 
function installApps() {
  echo "informe a senha do usuário: "
  sudo apt-get update -y
  sudo apt-get install ca-certificates curl gnupg lsb-release -y
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -y
  sudo apt-get install docker-ce docker-ce-cli containerd.io -y
  # docker run hello-world 
  sudo usermod -aG docker $USER  
  echo "O Docker está Ok!
Reinicie a sua VM"
}

function usage {
  echo "./$(basename $0) [${OPTSTRING}]"
  echo "  -u: up dataverse"
  echo "  -d: down dataverse"
  echo "  -m: instala via multipas e não via docker"
  echo "  -b: executa o build"
  echo "  -i: Instala o docker"
  echo "  -h: help"  
}

#Instala em container baseado em docker-compose
function installDocker() {
  #Se a imagem da aplicação não existir então faça ao build
  if [[ "$(docker images -q ${APP_IMAGE} 2> /dev/null)" == "" ]]; then
    echo "Definindo o build da aplicação"
    BUILD=true
  fi
  # se o projeto não existir, baixa:
  if [ ! -d "${DIR_PROJECT}" ]; then
   echo "Projeto dataverse ainda não existe. Baixando ..."
   git clone https://github.com/IQSS/dataverse.git ${DIR_PROJECT}
  fi
  cd ${DIR_PROJECT}
  source ${DIR_PROJECT}/dataverse/.env
  #build do app
  [ ${BUILD} ] && docker-compose -f ${YML} build
  #Levanta os containers via docker em segundo plano
  docker-compose -f ${YML} up -d
  IP=$(hostname -I | cut -f1 -d ' ')
  echo "Abra a página via: http://${IP}:8080"
  cd -  
}

#Encerra os serviços
function delDocker() {
  cd ${DIR_PROJECT}/dataverse
  docker-compose -f ${YML} down
  cd -
}

#instala em uma VM baseada no multipass
function installMultipass() {
  mkdir -p ${DIR_PROJECT}/download
  cd ${DIR_PROJECT}/download
  #baixa os pacotes previamente
  [ ! -f solr-9.3.0.tgz ] && wget https://archive.apache.org/dist/solr/solr/9.3.0/solr-9.3.0.tgz
  [ ! -f jdk-17_linux-x64_bin.deb ] && wget https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.deb
  [ ! -f dvinstall.zip ] && wget https://github.com/IQSS/dataverse/releases/download/v6.0/dvinstall.zip
  [ ! -f payara-6.2023.10.zip ] && wget https://nexus.payara.fish/repository/payara-community/fish/payara/distributions/payara/6.2023.10/payara-6.2023.10.zip
  VM="dataverse"
  multipass launch --name $VM -d 50G -m 4G -c 4
  F='install.sh'; multipass transfer $F ${VM}:$F
  F='.env'; multipass transfer $F ${VM}:$F
  F='dvinstall.zip'; multipass transfer $F ${VM}:$F
  F='payara-6.2023.10.zip'; multipass transfer $F ${VM}:$F
  F='solr-8.11.1.tgz'; multipass transfer $F ${VM}:$F
  F='jdk-17_linux-x64_bin.deb'; multipass transfer $F ${VM}:$F
  multipass exec ${VM} -- sudo ./install.sh | tee log.txt  
  IP=$(multipass info ${VM} | grep IPv4  | cut -c 17-30)
  echo "Abra a página via: http://${IP}:8080"
  cd -
}

#Exclui as vms e os dados gerados
function delMultipass() {
  VM="dataverse"
  multipass stop ${VM} && multipass delete ${VM} && multipass purge
}

ACTION=""
SILENT=""
RMVOLUME=""

while getopts ${OPTSTRING} ARG; do
  case ${ARG} in
    m)
      FORMA="${OPTSTRING}"
      ;;
    u)
      ACTION="up" 
      ;;
    d)
      ACTION="down" 
      ;;
    b) 
      BUILD=true
      ;;
    i) 
      installApps
      exit 0
      ;;
    h | *) 
      usage
      exit 1
      ;;
  esac
done

case ${ACTION} in
  "up")
    [ "$FORMA"=="d" ] && installDocker || installMultipass 
    ;;
  "down")
    [ "$FORMA"=="d" ] && delDocker || delMultipass 
    ;;
  *) 
    usage
    exit 1
    ;;
esac

