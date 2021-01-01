#RUN SCRIPT VIA SUDO
#TODO: Replace all occurrences of /home/whatever with a variable called homepath
echo "Enter your current computer account's username (note that this is case-sensitive): "
read username

echo "Generate, if you have not already, and enter your ssh public key: "
read sshKey

echo "Enter your Amazon/Wasabi/DigitalOcean S3-compatible object storage access key: "
read accessKey

echo "Enter your Amazon/Wasabi/DigitalOcean S3-compatible object storage secret key: "
read secretKey

echo "Enter the name of the bucket containing the videos you will\nhave on your tube (https://github.com/prologic/tube) instance: "
read bucketName

apt-get update && upgrade

#Disable password ssh at /etc/ssh/sshd_config

#Add public key of user-provided ssh key
mkdir -p /home/$username/.ssh && touch /home/$username/.ssh/authorized_keys
echo $sshKey >> authorized_keys

#Change permissions on files. Only the user can do anything with their .ssh folder and has r/w access to their authorized_keys file.
chmod 700 /home/$username/.ssh && chmod 600 /home/$username/.ssh/authorized_keys

#User owns their .ssh directory
chown -R $username:$username /home/$username/.ssh

#Install prereqs for docker (STILL NECESSARY??)
apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

#Install docker
curl -sSL https://get.docker.com | sh

#Add user to docker group just in case they aren't in it.
#PRECEDE THIS WITH SUDO IF THE SCRIPT DOESN'T WORK. Shouldn't have to since the script needs to be executed as sudo
usermod -aG docker $username

#remove fuse & prepare to install s3fs-fuse
apt-get update
apt-get remove fuse
apt-get install s3fs

#Make S3 fuse folder and connect it to S3 or any object storage service with an S3-compatible api.
mkdir /home/$username/s3_fuse_folder
echo $accessKey:$secretKey >> /home/$username/.passwd-s3fs
chmod 600 /home/$username/.passwd-s3fs #Make the file containing the access and secret keys read/write only to the user

#Mount the S3 fuse bucket
chmod 777 /home/$username/s3_fuse_folder
s3fs -o use_cache=/home/$username/s3_fuse_folder mybucket /s3mnt -o passwd_file=/home/$username/.passwd-s3fs
s3fs $bucketName /s3mnt -o passwd_file=/etc/pwd-s3fs -o url=https://s3.wasabisys.com #Adjust endpoint in accordance with service
