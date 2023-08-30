# Atividade de Docker
A documentação a seguir lhe dará um passo-a-passo de como executar a seguinte estrutura para uma aplicação WordPress:
![Untitled](assets/Untitled.png)
---

## Criando um nova VPC

- Vá até o serviço de VPC
    - Clique no botão no **Create VPC**
        
        ![Untitled](assets/Untitled%201.png)
        
    - **Atenção: todos os parâmetros que não forem citados a baixo, devem ser deixados como padrão.**
    - Para criar esta VPC, utilizaremos a seguinte configuração:
        - Selecione a opção **VPC and more**
        - Nomeie sua nova VPC e deixe a opção Name tag auto-generation habilitada
            
            ![Untitled](assets/Untitled%202.png)
            
        - Selecione o número de Availability Zones
            - Utilizaremos 2 AZs
        - Selecione o número de subnets públicas
            - Utilizaremos 2 subnets
        - Selecione o número de subnets privadas
            - Utilizaremos 2 subnetes
            
            ![Untitled](assets/Untitled%203.png)
            
        - Selecione o NAT Gateway para 1 AZ
        - Selecione o VPC endpoint como S3 Gateway
        
        ![Untitled](assets/Untitled%204.png)
        
        - Clique em **Create VPC** para criar o seguinte esquema:
        
        ![Untitled](assets/Untitled%205.png)
        

## Criando um novo Security Group

- Vá até o serviço de EC2
- No menu lateral, procure por **Security Groups**, dentro da seção **Networks & Security**
- Clique no botão **Create security group**
- Nomeie e adicione uma descrição o novo SG
    
    ![Untitled](assets/Untitled%206.png)
    
- Adicione os seguintes **Inbound rules**:
    
    
    | Type | Port range | Source |
    | --- | --- | --- |
    | HTTP | 80 | 0.0.0.0/0 |
    | HTTPS | 443 | 0.0.0.0/0 |
    | SSH | 22 | 0.0.0.0/0 |
    | MYSQL/Aurora | 3306 | O próprio Security Group |
    | NFS | 2049 | O próprio Security Group |
    
    ![Untitled](assets/Untitled%207.png)
    
- Clique em **Create security group**

## Criando um RDS

- No campo de busca, pesquise por RDS
- Na página inicial, clique em Create database
    - Em Choose a database creation method, selecione **Standard create**
        
        ![Untitled](assets/Untitled%208.png)
        
    - Em Engine options, selecione **MYSQL**
        
        ![Untitled](assets/Untitled%209.png)
        
    - No submenu **Engine Version**, selecione pelo menos, uma versão anterior à última
        
        ![Untitled](assets/Untitled%2010.png)
        
    - Em Templates, selecione o **Free tier**
        
        ![Untitled](assets/Untitled%2011.png)
        
    - Na seção Settings:
        - Adicione um nome para sua db em **DB instance identifier**
            
            ![Untitled](assets/Untitled%2012.png)
            
        - Em **Credentials Settings**, adicione um **Master username** e uma **Master password** para acesso e gerenciamento do banco de dados.
            
            ![Untitled](assets/Untitled%2013.png)
            
    - Em Instance configuration, selecione o tipo **db.t3.micro**
        
        ![Untitled](assets/Untitled%2014.png)
        
    - Em **Storage**, aloque **20 GiB** no tipo **gp2**
        - Desabilite o **Storage autoscaling**
            
            ![Untitled](assets/Untitled%2015.png)
            
    - Na seção **Connectivity** selecione as seguintes opções:
        - Compute resource: **Don't connect an EC2 compute resource**
        - Virtual Private Cloud (VPC): selecione a VPC criada anteriormente
        - Em Public access, selecione **No**
        - Em VPC security group, selecione **Choose existing** e selecione o security group criado anteriormente.
            
            ![Untitled](assets/Untitled%2016.png)
            
    - Em Database authentication, selecione **Password authentication**
    - Em Additional configuration:
        - Dê um nome para o **Initial database name**
        - Desmarque a opção **Enable automated backups**
        - Desmarque a opção **Enable encryption**
            
            ![Untitled](assets/Untitled%2017.png)
            
    - Clique em **Create database**

## Criando o EFS

- No campo de busca, pesquise por EFS
- Na página inicial, clique em Create file system
    - Dê um nome para para o seu novo sistema de arquivos (Neste exemplo **wordpress EFS**)
    - Selecione a mesma VPC em que foram criadas as outras instâncias
        
        ![Untitled](assets/Untitled%2018.png)
        
    - Clique em **Create**
- Clique sobre o nome do FS, na nova tela, será exibido o **DNS name** deste file system, copie-o e siga para o próximo passo.

## Configurando o [user_data.sh](./user_data.sh)

- abra o seu editor de texto e digite os seguintes comandos:
    
    ```
    #!/bin/bash
    
    # estes comandos instalarão e habilitarão o Docker
    yum update -y
    yum install docker -y
    systemctl start docker.service && systemctl enable docker.service
    usermod -aG docker ec2-user
    
    # estes comandos instalarão o Docker Compose
    curl -L "<https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$>(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # estes comando montarão o EFS
    yum install -y amazon-efs-utils
    mkdir /mnt/efs
    efs_mount_target="fs-00c69a321c7e11584.efs.us-east-1.amazonaws.com:/" # cole o DNS do seu EFS nesta linha
    echo "$efs_mount_target /mnt/efs efs defaults,_netdev 0 0" >> /etc/fstab
    mount -a -t efs,nfs4 defaults
    
    # estes comando criarão o docker-compose.yml
    cat <<EOF > /mnt/efs/docker-compose.yml
    version: '3'
    services:
      wordpress:
        image: wordpress
        restart: always
        ports:
          - 80:80
        environment:
          WORDPRESS_DB_HOST: wordpress-db.ctl3b1vgbby2.us-east-1.rds.amazonaws.com # cole o endpoint da sua db nesta linha
          WORDPRESS_DB_NAME: wordpress
          WORDPRESS_DB_USER: admin
          WORDPRESS_DB_PASSWORD: wordpress
    EOF
    
    # estes comando iniciarão o Docker Compose
    cd /mnt/efs
    docker-compose up -d
    ```
    

## Criando uma Instância

- No serviço EC2, vá até a opção **Launch Instances**
    - No campo de Name and tags, adicione as seguintes tags:
        
        
        | Key | Value | Resource types |
        | --- | --- | --- |
        | Name | PB IFMT - UTFPR | Instances, Volumes |
        | CostCenter | C092000004 | Instances, Volumes |
        | Project | PB IFMT - UTFPR | Instances, Volumes |
        
        ![Untitled](assets/Untitled%2019.png)
        
    - Na seção Application and OS Images, selecione o **Amazon Linux 2**
        
        ![Untitled](assets/Untitled%2020.png)
        
    - Em Instance Type, selecione t2.micro
    - Selecione sua Key pair para realizar a autenticação de acesso
        
        ![Untitled](assets/Untitled%2021.png)
        
    - Em Network settings, selecione a opção Edit. Em seguida:
        - Selecione a VPC criada anteriormente
        - Selecione a Subnet a ser utilizada (Neste caso, a **public A**)
        - Ative o Auto-assign public IP
        - Em Firewall (security groups), selecione o SG criado anteriormente:
        
        ![Untitled](assets/Untitled%2022.png)
        
    - Em Configure storage, deixo o padrão, 8GiB / gp2
        
        ![Untitled](assets/Untitled%2023.png)
        
    - Em Advanced details, expanda o menu
        - Vá até User data e adicione os comandos do **[user_data.sh](https://www.notion.so/kevinbenevides/user_data.sh)** criados anteriormente.
            
            ![Untitled](assets/Untitled%2024.png)
            
    - Clique em **Launch Instance**

## Acessando a Instância

- Para testarmos se tudo está funcionando, vamos acessar a instância via SSH para fazer a verificação.
- Na seção Instances, selecione a instância criada para que seja possível visualizar o seu IP público.
- Copie o IP e acesse a instância com o seguinte comando através do seu terminal: `ssh -i minha-chave.pem ec2-user@ip-da-instancia`
    
    ![Untitled](assets/Untitled%2025.png)
    
- Digitando o comando `docker ps` será possível observar que o container do WordPress já foi criado e iniciado.
    
    ![Untitled](assets/Untitled%2026.png)
    
- Após isto, podemos encerrar a conexão com a nossa instância.

## Criando um template

- Navegue até a seção Instances
- Na instância criada, clique com o botão direito do mouse, vá em **Image and templates > Create template from instance**
- Nomeie e adicione uma descrição ao template
- Selecione a opção **Auto Scaling guidance**
- Em **Template tags** adicione as seguintes:
    
    
    | Key | Value |
    | --- | --- |
    | Name | PB IFMT - UTFPR |
    | CostCenter | C092000004 |
    | Project | PB IFMT - UTFPR |
    
    ![Untitled](assets/Untitled%2027.png)
    
- Em **Application and OS Images**, deixe o padrão
    
    ![Untitled](assets/Untitled%2028.png)
    
- Em **Instance type**, deixe o padrão
    
    ![Untitled](assets/Untitled%2029.png)
    
- Selecione a sua **Key pair**
- Em **Network settings**:
    - Selecione **Don't include in launch template** na opção de Subnet
    - Em **Common security groups**, selecione o SG criado anteriormente
    - Em **Advanced network configuration**, marque como Don't include in launch template o **Auto-assign public IP**
        
        ![Untitled](assets/Untitled%2030.png)
        
- Em **Resource tags**, adicione as tags:
    
    
    | Key | Value | Resource type |
    | --- | --- | --- |
    | Name | PB IFMT - UTFPR | Instances, Volumes |
    | CostCenter | C092000004 | Instances, Volumes |
    | Project | PB IFMT - UTFPR | Instances, Volumes |
    
    ![Untitled](assets/Untitled%2031.png)
    
- Em **Advanced details**, desative o **Shutdown behavior** e o **Stop - Hibernate behavior**
    
    ![Untitled](assets/Untitled%2032.png)
    
- Clique em **Create launch template**

## Criando o Target Group

- Navegue até a seção de **Load Balancing**
- Vá até **Target Groups**
- Clique em **Create target group**
    - Em **Choose a target type**, selecione **Instances**
        
        ![Untitled](assets/Untitled%2033.png)
        
    - Nomeie seu target group em **Target group name**
    - Selecione a VPC criada anteriormente
        
        ![Untitled](assets/Untitled%2034.png)
        
    - Em **Health checks**, adicione **`/`** em **Health check path**
    - Na próxima página, clique em **Create target group**

## Criando o Load Balancer

- Agora, vá até **Load Balancers**, na mesma seção do Target Group
- Clique em **Create load balancer**
    - Selecione o **Application Load Balancer** clicando em create
    - Adicione um nome para o Load Balancer
        
        ![Untitled](assets/Untitled%2035.png)
        
    - Em **Network mapping**, vamos selecionar a nossa VPC e selecionar as **subnets públicas**
        
        ![Untitled](assets/Untitled%2036.png)
        
    - Em **Security groups**, vamos selecionar a que criamos anteriormente
        
        ![Untitled](assets/Untitled%2037.png)
        
    - Em **Listeners and routing**, vamos marcar o **target group** que criamos no passo anterior
        
        ![Untitled](assets/Untitled%2038.png)
        
    - Clique em **Create load balancer**

## Criando o Auto Scaling Group

- Na seção Auto Scaling, navegue até **Auto Scaling Groups**
- Clique em **Create Auto Scaling group**
    - Nomeie seu Auto Scaling Group
        
        ![Untitled](assets/Untitled%2039.png)
        
    - Selecione o **Launch Template** criado anteriormente
        
        ![Untitled](assets/Untitled%2040.png)
        
    - Em **Network**, selecione a VPC criada anteriormente e em **Availability Zones and Subnets**, selecione apenas as **subnets privadas**
        
        ![Untitled](assets/Untitled%2041.png)
        
    - Na página seguinte, em **Load balancing**, selecione **Attach to an existing load balancer**
    - Em **Attach to an existing load balancer**, selecione **Choose from your load balancer target groups** e selecione o target group criado anteriormente
        
        ![Untitled](assets/Untitled%2042.png)
        
    - Na próxima página, em **Group size**, vamos selecionar o seguinte:
        
        
        | Desired capacity | Minimum capacity | Maximum capacity |
        | --- | --- | --- |
        | 2 | 1 | 3 |
    - Agora podemos passar as próximas páginas e clicar em **Create Auto Scaling group**

## Configurando o WordPress

Agora, vamos configurar o WordPress para finalizar o nosso objetivo.

- Vá até **Load balancers** e copie o **DNS name** do seu load balancer
- Copie-o e cole-o no barra de pesquisa do seu navegador
    
    ![Untitled](assets/Untitled%2043.png)
    
- Ao carregar a página, será possível ver o setup de instalação do WordPress, na primeira tela vamos selecionar o **English (United States)** e clicar em continue
    
    ![Untitled](assets/Untitled%2044.png)
    
    - Na próxima tela vamos:
        - Adicionar um título para o site
        - Adicionar um nome de usuário para administrar o site
        - Adicionar uma senha de acesso
        - Adicionar o endereço de e-mail
        
        ![Untitled](assets/Untitled%2045.png)
        
    - Agora podemos clicar em **Install WordPress**
    - Após isto, aparecerá uma tela de instalação concluída, podemos clicar em **Log in**
        
        ![Untitled](assets/Untitled%2046.png)
        
    - Aparecerá uma tela para adicionarmos o nome de usuário/email e senha
        
        ![Untitled](assets/Untitled%2047.png)
        
    - Após isso, o processo está completamente concluído e temos acesso ao painel administrativo do WordPress.
        
        ![Untitled](assets/Untitled%2048.png)
