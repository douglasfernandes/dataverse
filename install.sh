#!/bin/bash

YML="./dataverse/docker-compose-dev.yml"
OPTSTRING=":umdbhi"
BUILD=false
FORMA="d" #d=docker ; m=multipass

[ ! -f 'dataverse_install.sh' ] && echo 'Instalação não localizada "'$(PWD)'/dataverse_install.sh" não localizada!' && exit 1

#Instalando os apps necessários
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
  sudo snap install multipass
  echo "O Docker está Ok!
Reinicie a sua VM"
}

#Instala em container baseado em docker-compose
function installDocker() {
  echo "Install via docker"
  #Se a imagem da aplicação não existir então faça ao build
  if [[ "$(docker images -q ${APP_IMAGE} 2> /dev/null)" == "" ]]; then
    echo "Definindo o build da aplicação"
    BUILD=true
  fi
  # se o projeto não existir, baixa:
  if [ ! -d "./dataverse" ]; then
   echo "Projeto dataverse ainda não existe. Baixando ..."
   git clone https://github.com/IQSS/dataverse.git ./dataverse
  fi
  source ./dataverse/.env
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
  echo "del docker"
  docker-compose -f ${YML} down
}

#baixa se não existir
function download() {
  LINK="$1"
  FILE="$2"
  [ ! -f $FILE ] && wget $LINK -P $FILE
}

#instala em uma VM baseada no multipass
function installMultipass() {
  echo "Install via multipass"
  mkdir -p ./download
  #baixa os pacotes previamente
  download 'https://archive.apache.org/dist/solr/solr/9.3.0/solr-9.3.0.tgz' './download/solr-9.3.0.tgz'
  download 'https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.deb' './download/jdk-17_linux-x64_bin.deb'
  download 'https://github.com/IQSS/dataverse/releases/download/v6.0/dvinstall.zip' './download/dvinstall.zip'
  download 'https://nexus.payara.fish/repository/payara-community/fish/payara/distributions/payara/6.2023.10/payara-6.2023.10.zip' './download/payara-6.2023.10.zip'
  cp dataverse_install.sh download
  cp .env download
  VM="dataverse"
  echo "Criando a VM $VM"
  multipass launch --name $VM -d 50G -m 4G -c 4  
  multipass mount ./download ${VM}:download
  echo "Executando a instalação"
  multipass exec ${VM} -- sudo download/dataverse_install.sh | tee log.txt  
  IP=$(multipass info ${VM} | grep IPv4 | cut -c 17-30)
  echo "Abra a página via: http://${IP}:8080"
}

#Exclui as vms e os dados gerados
function delMultipass() {
  echo "del multipass"
  VM="dataverse"
  multipass stop ${VM} && multipass delete ${VM} && multipass purge
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

ACTION=""
SILENT=""
RMVOLUME=""

while getopts ${OPTSTRING} ARG; do
  case ${ARG} in
    m)
      FORMA="m"
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
    [ "$FORMA" == "d" ] && installDocker || installMultipass 
    ;;
  "down")
    [ "$FORMA" == "d" ] && delDocker || delMultipass 
    ;;
  *) 
    usage
    exit 1
    ;;
esac

