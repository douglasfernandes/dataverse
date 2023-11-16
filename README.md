# Dataverse

Uma alternativa de instalação do Dataverse para aula da ESR em uma máquina linux, usando git, docker e docker-compose


# VM via Multipass (VM):

O Multipass se demonstra uma opção mais simples para o desenvolvedor.
 
## Download do multipass
- [Download multipass](https://multipass.run/install)

# Instalação
Este é um script bash
```
#instalação via docker
$ ./dataverse.sh -ud 
#ou
#instalação via multipass(VM)
$ ./dataverse.sh -um
 
#desinstalação via docker
$ ./dataverse.sh -dd 
#ou
#desinstalação via multipass(VM)
$ ./dataverse.sh -dm

login: dataverseAdmin
senha: admin1

Referência:
- https://github.com/IQSS/dataverse
- https://k8s-docs.gdcc.io/en/v4.20/quickstart/docker-compose.html
- https://ct.gdcc.io/
- https://guides.dataverse.org/en/latest/installation/installation-main.html
- https://guides.dataverse.org/en/6.0/installation/index.html
