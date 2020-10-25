sudo yum install -y jq ansible
mkdir -p tmp
wget https://releases.hashicorp.com/terraform/0.13.5/terraform_0.13.5_linux_amd64.zip -P tmp/
sudo unzip tmp/terraform_0.13.5_linux_amd64.zip -d tmp/
sudo mv tmp/terraform /usr/local/bin/.