# Dataverse

Uma alternativa de instalação do Dataverse para aula da ESR em uma máquina linux, usando git, docker e docker-compose

# Execução no Windows:

## Download a imagem do ubuntu
- [Download Ubuntu](https://mirror.uepg.br/ubuntu-releases/22.04.3/ubuntu-22.04.3-live-server-amd64.iso)

## Instalar VirtualBox
- [Download VirtualBox](https://download.virtualbox.org/virtualbox/7.0.12/VirtualBox-7.0.12-159484-Win.exe)
- [Manual do virtualBox](https://www.virtualbox.org/manual/ch01.html#intro-running)
- [Como instalar o virtualBox](https://www.youtube.com/watch?v=CIuJ6IzgXW0)

## Crie uma VM usando a imagem do Ubuntu

## Abra a nova VM e execute o script de instalação do dataverse


# Execução no Linux:

Estando na VM ou na própria máquina linux faça:
Ex:
- ./dataverse.sh -[u|d]
```
git clone git@github.com:douglasfernandes/dataverse.git
cd dataverse
./dataverse.sh -u
```
Obs : a opção '-u' inicia o container, '-d' fecha o container

## O serviço:
Após uns 5 a 10 minutos, abra a página: 

página: localhost:8080

login: dataverseAdmin

senha: admin1

Referência:
- https://github.com/IQSS/dataverse
- https://k8s-docs.gdcc.io/en/v4.20/quickstart/docker-compose.html
- https://ct.gdcc.io/
