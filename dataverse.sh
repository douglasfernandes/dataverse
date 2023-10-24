#!/bin/bash

# [ -z ${DIR_PROJECT} ] && echo -e 'Informe o diretório do projeto. Ex:\n  export DIR_PROJECT="${HOME}/dev/evor"' && exit 1

export DIR_PROJECT="${HOME}/douglas500/sti/desenvolvimento/repositorios/dv/dataverse"

YML="${DIR_PROJECT}/docker-compose-dev.yml"
OPTSTRING=":udbxh"
BUILD=false

echo "Criando o diretorio de volumes"
#mkdir -p docker-dev-volumes/app/data
#mkdir -p docker-dev-volumes/app/secrets
#mkdir -p docker-dev-volumes/postgresql/data
#mkdir -p docker-dev-volumes/solr/data
#mkdir -p docker-dev-volumes/solr/conf 
#mkdir -p conf/keycloak
#touch conf/keycloak/test-realm.json

# Docker exemplo
# https://github.com/docker/awesome-compose/tree/master/official-documentation-samples/django/

function usage {
  echo "./$(basename $0) [${OPTSTRING}]"
  echo "  -u: up dataverse"
  echo "  -d: down dataverse"
  echo "  -b: executa o build"
  echo "  -x: remove os volumes no down"
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
    x)
      RMVOLUME="rm" 
      ;;
    b) 
      BUILD=true
      ;;
    h | *) 
      usage
      exit 1
      ;;
  esac
done

# se o projeto não existir, baixa:
if [ ! -d "${DIR_PROJECT}" ]; then
 echo "Projeto não existe. Baixando ..."
 git clone https://github.com/IQSS/dataverse.git ${DIR_PROJECT}
fi

source ${DIR_PROJECT}/.env

# docker image rm ${APP_IMAGE} -f

#Se a imagem da aplicação não existir então faça ao build
if [[ "$(docker images -q ${APP_IMAGE} 2> /dev/null)" == "" ]]; then
  echo "Definindo para aplicação executar o build"
  BUILD=true
fi

exit 0

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

