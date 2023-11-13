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

# VM via Multipass:
## Download do multipass
- [Download multipass](https://multipass.run/install)

# Criação da VM 
Este é um script bash, deve-se verifcar com fazer no windows.
```
# sudo snap install multipass
export IP=$(hostname -I | cut -f1 -d" ")
export VM="dataverse"

# Exclui uma VM (opcional)
function delVm() {
  vm="$1"
  multipass stop $vm 
  multipass delete $vm
  multipass purge
}

# Cria a VM. -d: disco , -m: memória, -c qtd de cores
multipass launch --name $VM -d 50G -m 4G -c 4

# Exemplo de como piar um arquivo para a vm
multipass transfer arquivo.txt ${VM}:instalacao/arquivo.txt

# compartilhando uma pasta na VM
multipass mount $HOME/dataverse ${VM}:/dataverse

# Exemplo de execução de um comando
multipass exec ${VM} -- mkdir instalacao

# Exemplo de como compartilhar uma pasta local com a VM:
mkdir ${HOME}/dataverse/dados
multipass mount ${HOME}/dataverse/dados dataverse:/dados

# Exemplo de como acessar o shell da VM
multipass shell ${VM} 

# como excluir uma VM
multipass stop ${VM}
multipass delete ${VM}
multipass purge

```

# Instalação dataverse

```
VM="dataverse"
$ multipass launch --name $VM -d 50G -m 4G -c 4
$ multipass transfer install.sh ${VM}:install.sh
$ multipass transfer .env ${VM}:.env

# Acesse a VM via shell
$ multipass shell ${VM}
# ou
$ multipass exec ${VM} -- sudo ./install.sh

## Opção 1 : Execução na VM via instalação completa
Copie o install.sh do projeto e execute
```

#Para não executar o download durante a instalação
#wget https://github.com/IQSS/dataverse/releases/download/v5.12.1/dvinstall.zip
#wget https://github.com/IQSS/dataverse/archive/dataverse-5.12.1.tar.gz
#wget https://nexus.payara.fish/repository/payara-community/fish/payara/distributions/payara/6.2023.10/payara-6.2023.10.zip
#wget https://archive.apache.org/dist/lucene/solr/8.11.1/solr-8.11.1.tgz

cd download
wget http://150.165.250.2/~douglas/dataverse/dvinstall.zip
wget http://150.165.250.2/~douglas/dataverse/dataverse-5.12.1.tar.gz
wget http://150.165.250.2/~douglas/dataverse/payara-6.2023.10.zip
wget http://150.165.250.2/~douglas/dataverse/solr-8.11.1.tgz

F='dvinstall.zip'; multipass transfer $F ${VM}:$F
F='payara-6.2023.10.zip'; multipass transfer $F ${VM}:$F
F='payara-6.2023.10.zip'; multipass transfer $F ${VM}:$F
F='payara-6.2023.10.zip'; multipass transfer $F ${VM}:$F
cd -

multipass transfer install.sh ${VM}:install.sh
multipass transfer .env ${VM}:.env
multipass exec ${VM} -- sudo ./install.sh | tee log.txt

```
ou
```
multipass shell ${VM} 
sudo su -
./install.sh
```

## Opção 2 : Execução na VM via docker-compose:

Copie o arquivo dataverse.sh
```
multipass transfer dataverse.sh ${VM}:dataverse.sh
```
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
Aguarde a inicialização do serviço e abra a página: 

IP=$(multipass info $VM | grep IPv4  | cut -c 17-30)
página: curl http://${IP}:8080

login: dataverseAdmin

senha: admin1

Referência:
- https://github.com/IQSS/dataverse
- https://k8s-docs.gdcc.io/en/v4.20/quickstart/docker-compose.html
- https://ct.gdcc.io/
