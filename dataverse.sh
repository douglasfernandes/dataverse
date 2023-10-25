#!/bin/bash

[ -z ${DIR_PROJECT} ] && echo -e 'Informe o diretório do projeto. Ex:\n  export DIR_PROJECT="${HOME}/dev/evor"' && exit 1

#altere para o seu diretório de projeto
export DIR_PROJECT="${HOME}/douglas500/sti/desenvolvimento/repositorios/dataverse/dataverse"

YML="${DIR_PROJECT}/docker-compose-dev.yml"
OPTSTRING=":udbhi"
BUILD=false

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
  echo "  -b: executa o build"
  echo "  -i: Instala o docker"
  echo "  -h: help"  
}

ACTION=""
SILENT=""
RMVOLUME=""

while getopts ${OPTSTRING} ARG; do
  case ${ARG} in
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

# se o projeto não existir, baixa:
if [ ! -d "${DIR_PROJECT}" ]; then
 echo "Projeto dataverse ainda não existe. Baixando ..."
 git clone https://github.com/IQSS/dataverse.git ${DIR_PROJECT}
fi

source ${DIR_PROJECT}/.env

# docker image rm ${APP_IMAGE} -f

#Se a imagem da aplicação não existir então faça ao build
if [[ "$(docker images -q ${APP_IMAGE} 2> /dev/null)" == "" ]]; then
  echo "Definindo para aplicação executar o build"
  BUILD=true
fi

case ${ACTION} in
  "up")
    cd ${DIR_PROJECT}
    [ ${BUILD} ] && docker-compose -f ${YML} build
    docker-compose -f ${YML} up -d
    cd -
    ;;
  "down")
    cd ${DIR_PROJECT}
    docker-compose -f ${YML} down
    cd -
    ;;
  *) 
    usage
    exit 1
    ;;
esac

