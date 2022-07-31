#/bin/bash
yum install rpmdevtools wget redhat-lsb-core gcc perl-IPC-Cmd perl-Data-Dumper createrepo -y
rpmdev-setuptree
cd ~/rpmbuild
wget https://nginx.org/packages/centos/7/SRPMS/nginx-1.14.1-1.el7_4.ngx.src.rpm
rpm -i nginx-1.14.1-1.el7_4.ngx.src.rpm
wget https://gist.github.com/lalbrekht/6c4a989758fccf903729fc55531d3a50/raw/8104e513dd9403a4d7b5f1393996b728f8733dd4/gistfile1.txt
mv gistfile1.txt SPECS/nginx.spec -f 
wget https://www.openssl.org/source/openssl-1.1.1q.tar.gz --no-check-certificate
tar xf openssl-1.1.1q.tar.gz
yum-builddep SPECS/nginx.spec -y
sed 's/openssl-1.1.1a/rpmbuild\/openssl-1.1.1q/' SPECS/nginx.spec | tee SPECS/nginx.spec
rpmbuild -bb SPECS/nginx.spec
yum localinstall RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm -y
systemctl start nginx 
mkdir /usr/share/nginx/html/repo
cp RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm /usr/share/nginx/html/repo
wget https://downloads.percona.com/downloads/percona-release/percona-release-1.0-27/redhat/percona-release-1.0-27.noarch.rpm -O /usr/share/nginx/html/repo/percona-release-1.0-27.noarch.rpm
createrepo /usr/share/nginx/html/repo/
sed '11i\autoindex on;' /etc/nginx/conf.d/default.conf | tee /etc/nginx/conf.d/default.conf
nginx -s reload
cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF
yum install percona-release -y



