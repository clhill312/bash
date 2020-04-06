# install necessary packages
yum install -y httpd createrepo rsync policycoreutils-python-utils


# update /etc/fstab

# create partition
fdisk /dev/sdc
n
p 

# format as xfs file system
mkfs.xfs /dev/sdc1

# get UUID of partition
lsblk -o NAME,MOUNTPOINT,UUID

# update /etc/fstab
# mount
mount /dev/sdc1 /var/www/html



for repo in {AppStream,BaseOS,extras}
do 
    # create folders
    mkdir -p /var/www/html/centos/8.1.1911/$repos

    #initiize repo
    createrepo /var/www/html/centos/8.1.1911/$repo/x86_64/os

    #sync files from mirror
    rsync -avzhP rsync://ftp.fau.de/centos/8.1.1911/$repo/x86_64/ /var/www/html/centos/8.1.1911/$repo/x86_64/

    #update repo
    createrepo --update /var/www/html/centos/8.1.1911/$repo/x86_64/os

done


# enable apache
systemctl enable httpd
systemctl start httpd

# configure firewalld
firewall-cmd --add-service=http --permanent
firewall-cmd --reload

# configure selinux
semanage fcontext -a -t httpd_sys_content_t "/var/www/html(/.*)?"
restorecon -Rv /var/www/html



# create yum repo config
for repo in {AppStream,BaseOS,extras}
do
    rm -f /etc/yum.repos.d/CentOS
done

rm /etc/yum.repo
cat << 'EOF' >> $repo.txt
[AppStream]
name=CentOS-$releasever - AppStream
baseurl=http://$ipaddress/centos/8.1.1911/AppStream/$basearch/os/
gpgcheck=0
enabled=1
EOF



