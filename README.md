Esta documentação fornecerá instruções passo a passo para configurar o monitoramento automatizado do serviço Apache em uma instância EC2. O monitoramento é realizado por meio de um script que valida o status do serviço Apache, registra os logs em um diretório montado em um sistema de arquivos NFS e mantém apenas os últimos 5 arquivos de log, registrando o nome de todos os logs já criados em um único arquivo.

## Requisitos na AWS
 1. **Gerando uma chave pública para acesso ao ambiente:**
	- Acesse o Console de Gerenciamento da AWS (AWS Management Console).
	- Navegue até o serviço EC2.
	- No painel de navegação esquerdo, clique em "Key Pairs" (Pares de Chaves).
	- Crie um novo par de chaves, forneça um nome e faça o download do arquivo da chave privada (.pem).
	- Armazene em local seguro a chave privada, pois ela será necessária para acessar a instância EC2 via SSH.
2. **Criar uma instância EC2:**
	   - Acesse o Console de Gerenciamento da AWS.
	   - Navegue até o serviço EC2.
	   - Clique em Launch Instance para iniciar a criação da instância.
	   - Selecione as seguintes configuração para a instância EC2:
		   - Adicione três tags:
				   - Name: PB IFMT - UTFPR
				   - CostCenter: C092000004
				   - Project: PB IFMT - UTFPR
				   - As três tags devem ser adicionadas para **instâncias** e **volumes**.
		   - Imagem: **Amazon Linux 2.**
		   - Tipo:  **t2.micro.**
		   - Selecione a Key Pair Name gerada anteriormente.
		   - Nas configurações de rede, selecione a subnet pública na região **us-east-1a**.
		   - Selecione o atribuição automática de IP público.
		   - Crie um novo Grupo de Segurança contendo as permissões de acesso às portas:
			   - SSH (**22/TCP**) para acesso via SSH.
			   - NFS (**111/TCP e UDP**) para comunicação com o sistema de arquivos NFS.
			   - NFS (**2049/TCP e UDP**) para comunicação com o sistema de arquivos NFS.
			   - HTTP (**80/TCP**) para acesso ao servidor Apache.
			   - HTTPS (**443/TCP**) para acesso ao servidor Apache.
		   - Nas configurações de armazenamento, selecione o **SSD gp2** com **16 GB**.
		   - Inicie a instância.
3. **Gerando um Elastic IP e anexado à Instância EC2:**
	   - Acesse o Console de Gerenciamento da AWS.
	   - Navegue até o serviço EC2.
	   - No painel de navegação esquerdo, clique em "Elastic IPs".
	   - Clique em "Allocate Elastic IP address" para gerar um novo Elastic IP.
	   - Selecione o Elastic IP criado e clique em "Actions", depois em "Associate IP address" (Associar endereço IP).
	   - Associe o Elastic IP à instância EC2 criada anteriormente.

## **Requisitos no Linux:**
1. **Configurando o NFS:**
   - Conecte-se à instância EC2 via SSH usando a chave privada gerada no início.
	   - No terminal, digite o seguinte comando:
	      ```ssh -i nome_da_chave ec2-user@ip_da_instancia_ec2```
   - Atualize os repositórios de pacotes executando o seguinte comando:
	     ```sudo yum update -y```
   - Instale o pacote nfs-utils executando o seguinte comando:
     ```sudo yum install -y nfs-utils```
2. **Criando um sistema de arquivos EFS:**
	-  Acesse o Console de gerenciamento da AWS.
	- Navegue até o serviço EFS.
	- Clique em Create File System:
		- Adicione o nome para a unidade
		- Selecione a VPC
		- Crie a unidade
	- Após a criação do sistema de arquivos EFS, será possível visualizar o ID do mesmo, que será utilizado para a configuração no sistema NFS dentro da instância EC2.
3. **Criando um diretório dentro do sistema de arquivos NFS:**
   - Verifique o ID do sistema de arquivos EFS que será usado para o NFS.
   - Execute o seguinte comando para criar um diretório dentro do sistema de arquivos NFS:
     ```
     sudo mkdir /mnt/
     sudo mkdir /mnt/efs/
     sudo mkdir /mnt/efs/seu_nome
     ```

3. **Subindo um Apache no Servidor:**
   - Instale o servidor Apache executando o seguinte comando:
     ```
     sudo yum install -y httpd
     ```
   - Inicie o serviço Apache e o configure para iniciar automaticamente no boot:
     ```
     sudo systemctl start httpd
     sudo systemctl enable httpd
     ```

4. **Criando o script de validação e registro do status do serviço:**
   - Crie um arquivo chamado `apache_status.sh` utilizando o comando:
	   - `touch apache_status.sh`
   - Utilizando o comando `nano apache_status.sh` copie o conteúdo do script `apache_status.sh` fornecido no código fonte do projeto para o arquivo.
   - Com o comando `ctrl + x` salve e feche o arquivo.
   - Com o comando `chmod 700 apache_status.sh` dê permissão para o script se tornar um executável.

5. **Criando uma execução automatizada do script a cada 5 Minutos:**
   -  No terminal da instância EC2, execute o comando `crontab -e` para abrir o arquivo de cron jobs.
   - Adicione a seguinte linha ao arquivo para executar o script a cada 5 minutos:
     ```
     */5 * * * * /bin/bash /home/seu_usuario/apache_status.sh
     ```
     Caso necessário, substitua `/home/seu_usuario/apache_status.sh` pelo caminho correto onde você salvou o arquivo `apache_status.sh`.
   - Com o comando `:wq` salve e feche o arquivo.

7. **Verificando os arquivos de log:**
	- Utilizando o comando `cd /mnt/efs/seu_nome/`, verifique se os arquivos de logs e o arquivo `log_index.txt` estão sendo criados e atualizados dentro do diretório.