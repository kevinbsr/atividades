# Atividade de Docker

- [] Instalar e configurar Docker ou containerd no host EC2
    - [] Ponto adicional para o trabalho que utilizar a instalação via script de Start Instance (user_data.sh)
- [] Efetuar Deploy de uma aplicação WordPress com:
    - [] Container da aplicação
    - [] RDS database Mysql
- [] Configuração para utiliação do serviço EFS AWS para estáticos do container de aplicação WordPress

- Pontos de atenção:
    - [] Não utilizar ip público para saída do serviço WP (Evitem publicar o serviço via IP Público)
    - [] Sugestão para o tráfego de internet sair pelo LB (Load Balancer Classic)
    - [] Pastas públicas e estáticos do WordPress sugestão utilizar o EFS (Elasic File System)
    - [] Fica à critério de cada integrante (ou dupla) usar o Dockerfile ou Dockercompose;
    - [] Necessário demonstrar a aplicação wordpress funcionando (tella de login)
    - [] Aplicação WordPress precisar estar rodando na porta 80 ou 8080
    - [] Utilizar repositório git para versionamento
    - [] Criar documentação


## Criando um nova VPC
- Vá até o serviço de VPC
- Clique no botão no Create VPC
    - Selecione a opção VPC and more
    - Nomeie sua nova VPC
    - Selecione um bloco CIDR para o IPV4
        - Neste exemplo, utilizaremos um bloco /24
    - Selecione o número de Availability Zones
        - Neste exemplo, utilizaremos 2 AZs
    - Selecione o número de subnetes públicas
        - Neste exemplo, utilizaremos 2 subnetes
    - Selecione o número de subnetes privadas
        - Neste exemplo, utilizaremos 2 subnetes
    - Selecione o VPC endpoint como S3 Gateway
    - Em DNS options, selecione os campos:
        - Enable DNS hostnames
        - Enable DNS resolution
    - Clique em Criar VPC
