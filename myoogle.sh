#RUN SCRIPT VIA SUDO
#TODO: Add Brave Sync Server: https://github.com/brave/go-sync
echo "This script must be run via sudo."
#TODO: Replace all occurrences of /home/whatever with a variable called homepath
username=$(whoami)
cd ~ #Switch to home directory and operate there for the rest of the script

echo "Generate, if you have not already, and enter your ssh public key: "
read sshKey

echo "Enter your Amazon/Wasabi/DigitalOcean S3-compatible object storage access key: "
read accessKey

echo "Enter your Amazon/Wasabi/DigitalOcean S3-compatible object storage secret key: "
read secretKey

echo "Enter the name of the bucket containing the videos you will\nhave on your Tube (Youtube alternative:
https://github.com/prologic/tube) instance: "
read tubeBucket

echo "Enter the name of the bucket containing the files you will store in Filestash,
\na lightweight Google Drive alternative & NextCloud alternative -
\nwww.filestash.app, https://github.com/mickael-kerjean/filestash):"
read filestashBucket

echo "Enter the name of the bucket that Searx will use to store files here:"
read searxBucket

echo "Enter your S3-compatible endpoint (e.g. https://s3.wasabisys.com)"
read endpoint

#Update and upgrade before doing anything else
apt-get update
apt-get upgrade

#Install prereqs for docker and docker compose (IS THIS STEP STILL NECESSARY??)
apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
    py-pip \
    python-dev \
    libffi-dev \
    openssl-dev \
    gcc \
    libc-dev \
    make

#Install docker via convenience script. IS DOCKER ENGINE INSTALLED? If not, Searx won't work
curl -fsSL https://get.docker.com -o get-docker.sh

#Install docker compose via script from docker
curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose


#Disable password ssh at /etc/ssh/sshd_config
#[INSERT COMMAND FOR THAT HERE]

#Add public key of user-provided ssh key
mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys
echo $sshKey >> authorized_keys

#Change permissions on files. Only the user can do anything with their .ssh folder and has r/w access to their authorized_keys file.
chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys

#User owns their .ssh directory
chown -R $username:$username ~/.ssh

#Add user to docker group just in case they aren't in it.
#PRECEDE THIS WITH SUDO IF THE SCRIPT DOESN'T WORK. Shouldn't have to since the script needs to be executed as sudo
usermod -aG docker $username

#remove fuse & prepare to install s3fs-fuse
apt-get update
apt-get remove fuse
apt-get install s3fs

#Make S3 fuse folders and connect it to S3 or any object storage service with an S3-compatible api.
mkdir /tmp/cache/ /s3_tube_folder
chmod 777 /tmp/cache/ /s3_tube_folder
mkdir /tmp/cache/ /s3_filestash_folder
chmod 777 /tmp/cache/ /s3_filestash_folder
mkdir /tmp/cache/ /s3_searx_folder
chmod 777 /tmp/cache/ /s3_searx_folder

echo $accessKey:$secretKey >> ~/.passwd-s3fs
chmod 600 ~/.passwd-s3fs #Make the file containing the access and secret keys read/write only to the user

#Mount the S3 fuse buckets
s3fs $tubeBucket /s3_tube_folder -o passwd_file=/etc/pwd-s3fs -o url=$endpoint #Adjust endpoint in accordance with service
s3fs $filestashBucket /s3_filestash_folder -o passwd_file=/etc/pwd-s3fs -o url=$endpoint #Adjust endpoint in accordance with service
s3fs $searxBucket /s3_searx_folder -o passwd_file=/etc/pwd-s3fs -o url=$endpoint #Adjust endpoint in accordance with service


