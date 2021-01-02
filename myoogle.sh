#RUN SCRIPT VIA SUDO
#TODO: Replace all occurrences of /home/whatever with a variable called homepath
username=$(whoami)

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

#Install docker compose via 
curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

#Disable password ssh at /etc/ssh/sshd_config
#[INSERT COMMAND FOR THAT HERE]

#Add public key of user-provided ssh key
mkdir -p /home/$username/.ssh && touch /home/$username/.ssh/authorized_keys
echo $sshKey >> authorized_keys

#Change permissions on files. Only the user can do anything with their .ssh folder and has r/w access to their authorized_keys file.
chmod 700 /home/$username/.ssh && chmod 600 /home/$username/.ssh/authorized_keys

#User owns their .ssh directory
chown -R $username:$username /home/$username/.ssh

#Add user to docker group just in case they aren't in it.
#PRECEDE THIS WITH SUDO IF THE SCRIPT DOESN'T WORK. Shouldn't have to since the script needs to be executed as sudo
usermod -aG docker $username

#remove fuse & prepare to install s3fs-fuse
apt-get update
apt-get remove fuse
apt-get install s3fs

#Make S3 fuse folders and connect it to S3 or any object storage service with an S3-compatible api.
mkdir /home/$username/s3_tube_folder
chmod 777 /home/$username/s3_tube_folder
mkdir /home/$username/s3_filestash_folder
chmod 777 /home/$username/s3_filestash_folder
mkdir /home/$username/s3_searx_folder
chmod 777 /home/$username/s3_searx_folder

echo $accessKey:$secretKey >> /home/$username/.passwd-s3fs
chmod 600 /home/$username/.passwd-s3fs #Make the file containing the access and secret keys read/write only to the user

#Mount the S3 fuse bucket
s3fs -o use_cache=/home/$username/s3_fuse_folder mybucket /s3mnt -o passwd_file=/home/$username/.passwd-s3fs
s3fs $tubeBucket /s3mnt -o passwd_file=/etc/pwd-s3fs -o url=$endpoint #Adjust endpoint in accordance with service



