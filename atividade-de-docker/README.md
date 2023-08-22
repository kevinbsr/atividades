# Atividade de Docker

- [x] Instalar e configurar Docker ou containerd no host EC2
    - [x] Ponto adicional para o trabalho que utilizar a instalação via script de Start Instance (user_data.sh)
- [x] Efetuar Deploy de uma aplicação WordPress com:
    - [x] Container da aplicação
    - [x] RDS database Mysql
- [x] Configuração para utilização do serviço EFS AWS para estáticos do container de aplicação WordPress

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

## Criando um RDS
- No campo de busca, pesquise por RDS
- Na página inicial, clique em Create database
	- Em Choose a database creation method, selecione **Standard create**
	- Em Engine options, selecione **MYSQL**
	- No submenu **Engine Version**, selecione pelo menos, uma versão anterior à última
	- Em Templates, selecione o **Free tier**
	- Na seção Settings:
		- Adicione um nome para sua db em **DB instance identifier**
		- Em **Credentials Settings**, adicione um **Master username** e uma **Master password** para acesso e gerenciamento do banco de dados.
	- Em Instance configuration, selecione o tipo **db.t3.micro**
	- Em **Storage**, aloque **20 GiB** no tipo **gp2**
		- Desabilite o **Storage autoscaling**
	- Na seção **Connectivity** selecione as seguintes opções:
		- Compute resource: **Don't connect an EC2 compute resource**
		- Virtual Private Cloud (VPC): selecione a VPC criada anteriormente
		- DB subnet group: selecione as subnets criadas anteriormente
		- Em Public access, selecione **no**
		- Em VPC security group, selecione **Choose existing** e selecione o security group criado anteriormente.
	- Em Database authentication, selecione **Password authentication**
	- Em Additional configuration:
		- Dê um nome para o **Initial database name**
		- Desmarque a opção **Enable automated backups**
		- Desmarque a opção **Enable encryption**
	- Clique em Create database
## Criando uma Instância
- No serviço EC2, vá até a opção Launch Instances
    - No campo de Name and tags, adicione as seguintes tags:
        - Name: PB IFMT - UTFPR    | Instances, Volumes |
        - CostCenter: C092000004   | Instances, Volumes | 
        - Project: PB IFMT - UTFPR | Instances, Volumes |
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
                - HTTP    |  80  | 0.0.0.0/0
                - HTTPS    | 443  | 0.0.0.0/0
                - SSH    |  22  | 0.0.0.0/0
                - MYSQL/Aurora    | 3306 | 0.0.0.0/0
                - NFS    | 2049 | O próprio SG
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

## Criando o EFS
- No campo de busca, pesquise por EFS
- Na página inicial, clique em Create file system
	- Dê um nome para para o seu novo sistema de arquivos (Neste exemplo **EFS**)
	- Selecione a mesma VPC em que foram criadas as outras instâncias
	- Clique em **Create**
- Neste momento, será exibido o DNS name deste file system, copie-o e siga para o próximo passo
## Acessando a Instância
- Para testarmos se tudo está funcionando, vamos acessar a instância via SSH para fazer a verificação.
- Na seção Instances, selecione a instância criada para que seja possível visualizar o seu IP público.
- Copie o IP e acesse a instância com o seguinte comando através do seu terminal: ``ssh -i minha-chave.pem ec2-user@ip-da-instancia``

## Montando o EFS
- Dentro da instância:
	- Primeiramente, digite o comando ``docker ps`` para saber se o Docker já está funcionando.
	- Em seguida, vamos criar uma pasta para servir de mount point para o EFS, execute o seguinte comando: ``sudo mkdir /mnt/efs`` 
	- Agora, vamos fazer o mount da unidade EFS criada anteriormente:
		- Digite o seguinte comando na sua instância: ``sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-028553ba57c8f1212.efs.us-east-1.amazonaws.com:/ /mnt/efs/``
		- Digite o comando df -h e observe se o EFS foi montado corretamente em seu sistema
		- Após isto, vamos garantir que este sistema de arquivos seja iniciado sempre que a instância for iniciada:
			- Digite o comando ``sudo vim /etc/fstab`` 
			- Dentro do vim, tecle i para entrar em modo de edição e adicione uma nova linha com o seguinte comando: ``fs-028553ba57c8f1212.efs.us-east-1.amazonaws.com:/ /mnt/efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 0 0``
			- Tecle esc para garantir que voltou para o modo de comando e digite :wq para salvar o documento e sair do editor vim.
		- Para garantir que o usuário atual tenha total acesso ao file system, digite o seguinte comando: ``sudo chown ec2-user /mnt/efs/``

## Criando o arquivo docker-compose e configurando o WordPress
Ainda dentro da instância, vamos seguir os seguintes passos:
- Abra o diretório onde foi anexado o EFS, ``cd /mnt/efs``
- Dentro do diretório, digite o comando ``vim docker-compose.yml``
- Será exibido o editor vim novamente. Tecle i para entrar em modo de edição e digite o seguinte código:
```
version: "3.9"
services:
  wordpress:
    image: wordpress:latest
    volumes:
      - ./config/php.conf.uploads.ini:/usr/local/etc/php/conf.d/uploads.ini
      - ./wp-app:/var/www/html
    ports:
      - 80:80
    restart: always
    environment:
      - WORDPRESS_DB_HOST=endpoint
      - WORDPRESS_DB_USER=admin
      - WORDPRESS_DB_PASSWORD=wordpress
      - WORDPRESS_DB_NAME=wordpress-db
```
- Tecle esc e digite :wq para salvar e sair do arquivo
- Agora, para executar o arquivo criado, digite ``docker-compose up -d`` e tecle enter
- O docker-compose foi executado e o container foi criado. Digite o comando ``docker ps`` para verificar.
