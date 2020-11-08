sudo yum install -y jq ansible moretutils ts
mkdir -p tmp

wget https://releases.hashicorp.com/terraform/0.13.5/terraform_0.13.5_linux_amd64.zip -P tmp/ # Get terraform
sudo unzip tmp/terraform_0.13.5_linux_amd64.zip -d tmp/
sudo mv tmp/terraform /usr/local/bin/.

wget https://releases.hashicorp.com/packer/1.6.4/packer_1.6.4_linux_amd64.zip -P tmp/ # Get Packer
sudo unzip tmp/packer_1.6.4_linux_amd64.zip -d tmp/
sudo mv tmp/packer /usr/local/bin/.

mkdir -p "$HOME/.ssh/tls" # The directory to store the TLS certificates in.
