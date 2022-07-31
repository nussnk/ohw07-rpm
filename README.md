# ohw07-rpm
#создаем ВМ через vagrant 
vagrant init
#меняем тип с base на centos/7
#запускаем ее
vagrant up
#логинимся
vagrant ssh

#повысим права до root
sudo -i

#ставим пакет rpmdevtools, который притащит кучу зависимостей
yum install rpmdevtools wget -y

#создаем директорию для будущего rpm пакета
rpmdev-setuptree

#получаем папку ~/rpmbuild, заходим в нее и смотрим содержимое
cd ~rpmbuild && ls -la

#в качестве подопытного будет nginx с поддержкой open-ssl. Качаем
wget https://nginx.org/packages/centos/7/SRPMS/nginx-1.14.1-1.el7_4.ngx.src.rpm

#ставим пакет
rpm -i nginx-1.14.1-1.el7_4.ngx.src.rpm

#можем убедиться, что пакет был установлен
#ls -R ~/rpmbuild
#/root/rpmbuild/SOURCES:                                                                     
#COPYRIGHT              nginx.conf           nginx.service         nginx.vh.default.conf     
#logrotate              nginx-debug.service  nginx.suse.logrotate                            
#nginx-1.14.1.tar.gz    nginx-debug.sysconf  nginx.sysconf                                   
#nginx.check-reload.sh  nginx.init.in        nginx.upgrade.sh                                
#                                                                                            
#/root/rpmbuild/SPECS:                                                                       
#nginx.spec

#подменим nginx.spec файл
wget https://gist.github.com/lalbrekht/6c4a989758fccf903729fc55531d3a50/raw/8104e513dd9403a4d7b5f1393996b728f8733dd4/gistfile1.txt
mv gistfile1.txt SPECS/nginx.spec -f 

#качаем openssl
wget https://www.openssl.org/source/openssl-1.1.1q.tar.gz

#распакаовываем
tar xf openssl-1.1.q.tar.gz

#ставим зависимости для nginx
yum-builddep SPECS/nginx.spec

#получаем ошибку "sh: lsb_release: command not found"

#смотрим что нужно поставить
yum provides lsb_release
#среди прочего в выводе видим: redhat-lsb-core-4.1-27.el7.centos.1.i686 : LSB Core module support 
#ставим
yum install redhat-lsb-core -y

#пробуем снова 
yum-builddep SPECS/nginx.spec -y
#пошла установка пакетов
#готово

#приступаем к сборке пакетов
rpmbuild -bb SPECS/nginx.spec

#получаем ./configure: error: C compiler cc is not found  
#ставим
yum install gcc -y

#пробуем снова
rpmbuild -bb SPECS/nginx.spec

# опять что-то не так: error: Bad exit status from /var/tmp/rpm-tmp.fU5B6T (%build) 
# чуть выше видим /bin/sh: line 0: cd: /root/openssl-1.1.1a: No such file or directory
# в SPECS/nginx.spec видим строки:
#./configure %{BASE_CONFIGURE_ARGS} \    
#    --with-cc-opt="%{WITH_CC_OPT}" \    
#    --with-ld-opt="%{WITH_LD_OPT}" \    
#    --with-openssl=/root/openssl-1.1.1a 

# попробуем заменить путь до openssl на /root/rpmbuild/openssl-1.1.1q

# запускаем снова rpmbuild
rpmbuild -bb SPECS/nginx.spec

#опять ошибка Can't locate IPC/Cmd.pm
№ гуглим, ставим
yum install perl-IPC-Cmd -y

# запускаем снова rpmbuild
rpmbuild -bb SPECS/nginx.spec

# ощибка - Can't locate Data/Dumper.pm
# гуглим - ставим
yum install perl-Data-Dumper -y

# запускаем снова rpmbuild
rpmbuild -bb SPECS/nginx.spec
# получилось!

# ставим пакет, смортим:
yum localinstall RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm

# запускаем и смотрим статус
systemctl start nginx && systemctl status nginx
# все хорошо

# переходим к созданию репозитория
mkdir /usr/share/nginx/html/repo

# копируем в созданную директорию полученный пакет
cp RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm /usr/share/nginx/html/repo

# ставим createrepo
yum install createrepo -y

# создаем репозиторий
createrepo /usr/share/nginx/html/repo/

# добавляем параметр для листинга директории
vi /etc/nginx/conf.d/default.conf

# проверяем конфиги и перезагружаем nginx
nginx -t
nginx -s reload

# качаем страницу и смотрим, что пакет отображается в выводе
curl -a http://localhost/repo

# добавим репозиторий в yum, создав отдельный файл otus.repo в /etc/yum.repos.d/
cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF

# смотрим вывод yum repolist
yum repolist | grep otus
# видим наш репозиторий

# теперь добавим туда percona
wget https://downloads.percona.com/downloads/percona-release/percona-release-1.0-27/redhat/percona-release-1.0-27.noarch.rpm -O /usr/share/nginx/html/repo/percona-release-1.0-27.noarch.rpm

# обновим репозиторий
createrepo /usr/share/nginx/html/repo/

# обновим кэш
yum makecache

# выведем список пакетов
yum list | grep otus

# почему-то видим только percona, поставим
yum install percona-release

# готово

