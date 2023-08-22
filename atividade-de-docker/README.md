# Atividade de Docker

- [x] Instalar e configurar Docker ou containerd no host EC2
    - [ ] Ponto adicional para o trabalho que utilizar a instalação via script de Start Instance (user_data.sh)
- [ ] Efetuar Deploy de uma aplicação WordPress com:
    - [ ] Container da aplicação
    - [ ] RDS database Mysql
- [ ] Configuração para utilização do serviço EFS AWS para estáticos do container de aplicação WordPress

- Pontos de atenção:
    - [ ] Não utilizar ip público para saída do serviço WP (Evitem publicar o serviço via IP Público)
    - [ ] Sugestão para o tráfego de internet sair pelo LB (Load Balancer Classic)
    - [ ] Pastas públicas e estáticos do WordPress sugestão utilizar o EFS (Elasic File System)
    - [ ] Fica à critério de cada integrante (ou dupla) usar o Dockerfile ou Dockercompose;
    - [ ] Necessário demonstrar a aplicação wordpress funcionando (tella de login)
    - [ ] Aplicação WordPress precisar estar rodando na porta 80 ou 8080
    - [ ] Utilizar repositório git para versionamento
    - [ ] Criar documentação


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

## Criando uma instância
- No serviço EC2, vá até a opção Launch Instances
    - No campo de Name and tags, adicione as seguintes tags:
        - Name: PB IFMT - UTFPR
        - CostCenter: C092000004
        - Project: PB IFMT - UTFPR
    - Na seção Application and OS Images, selecione o Amazon Linux 2
    - Em Instance Type, selecione t2.micro
    - Selecione sua Key pair para realizar o acesso via SSH
    - Em Network settings, selecione a opção Edit. Em seguida:
        - Selecione a VPC Criada anteriormente
        - Selecione a Subnet a ser utilizada (Neste caso, a public A)
        - Ative o Auto-assign public IP
        - Crie um novo Security Group:
            - Nomeie-o e adicione uma descrição
            - Em Inbound Security Group Rules, adicione as seguintes regras:
                - HTTP         |  80  | 0.0.0.0/0
                - HTTPS        | 443  | 0.0.0.0/0
                - SSH          |  22  | 0.0.0.0/0
                - MYSQL/Aurora | 3306 | 0.0.0.0/0
                - NFS          | 2049 | O próprio SG
    - Em Configure storage, deixo o padrão, 8GiB / gp3
    - Em Advanced details, expanda o menu
        - Vá até User data e adicione os seguintes comandos
            ```
            #!/bin/bash

            yum update -y
            yum install -y docker
            systemctl start docker.service
            systemctl enable docker.service
            usermod -aG docker ec2-user

            curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose

            chmod +x /usr/local/bin/docker-compose
            ```
    - Clique em Launch Instance
