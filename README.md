# NPM сборка NGINX + PHP5FPM + MYSQL под DOCKER

Нормального описания нигде не нашел - поэтому пришлось все пилить самому, убил на это 2 дня. <br>
Надеюсь кому нибудь это пригодится. <br>
<br>
Описываю как с этим рабоать.
<br>
ubuntu 16.04
<br>
apt-get update
apt-get upgrade
reboot
apt-get install docker.io
docker pull mysql
docker pull phusion/baseimage - это хорошая сборка убунту с минимум функций - как раз подойдет для контейнеров докера (все строится на нем поэтому у кого есть силы - рекомендую покопаться в этом дистрибутиве на наличие косяков хотя и говорят там все круто настроили)
docker pull phusion/baseimage:0.9.15 - эта версия нужно потому, что там есть php5, если устанавливать все со стандартным - то тогда везде будет php 7.0 - который, увы, не поддерживается, некоторыми CMS 
docker pull mk77/nginx_image
docker pull mk77/php5fpm_image
docker 

---------------------------------------------------------------------
Создаем 8 контейнеров для хранения смежных данных
---------------------------------------------------------------------
docker volume create --name mysql_data
docker volume create --name mysql_socket
docker volume create --name nginx_settings
docker volume create --name nglogs
docker volume create --name phpfpm_settings
docker volume create --name phpfpm_socket
docker volume create --name phplogs
docker volume create --name siteplace

---------------------------------------------------------------------
Создаем папку для работы с контейнерами на главном хосте с линками
---------------------------------------------------------------------
mkdir /home/work
cd /home/work
ln -s /var/lib/docker/volumes/mysql_data/_data mysql_data
ln -s /var/lib/docker/volumes/mysql_socket/_data mysql_socket
ln -s /var/lib/docker/volumes/nginx_settings/_data nginx_settings
ln -s /var/lib/docker/volumes/nglogs/_data nglogs
ln -s /var/lib/docker/volumes/phpfpm_settings/_data phpfpm_settings
ln -s /var/lib/docker/volumes/phpfpm_socket/_data phpfpm_socket
ln -s /var/lib/docker/volumes/phplogs/_data phplogs
ln -s /var/lib/docker/volumes/siteplace/_data siteplace


---------------------------------------------------------------------
Создаем mysql контейнер исходя из нашего имаджа mysql (официальный) - при этом данных хранятся в volume что мы создали ранее
---------------------------------------------------------------------
docker run --name mysql -v mysql_socket:/var/run/mysqld -v mysql_data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=12345 -e MYSQL_DATABASE=testdb -e MYSQL_USER=test -e MYSQL_PASSWORD=test -d mysql 

---------------------------------------------------------------------
Создаем php5fpm контейнер исходя из нашего имаджа php5fpm_image (свой сделанный) - при этом данных хранятся в volume что мы создали ранее
---------------------------------------------------------------------
docker run --name php5fpm-container --privileged -v phpfpm_settings:/etc/php5 -v phplogs:/var/log/php5 -v siteplace:/home/www/siteplace -v mysql_socket:/var/run/mysqld  -v phpfpm_socket:/var/run/php5-fpm --link mysql:mysql -t php5fpm_image

----------------------------------------------------------------------
Создаем nginx контейнер исходя из нашего имаджа nginx_image (свой сделанный) - при этом данных хранятся в volume что мы создали ранее
----------------------------------------------------------------------
docker run --name nginx-container -v nginx_settings:/etc/nginx -v nglogs:/var/log/nginx -v siteplace:/home/www/siteplace -v phpfpm_socket:/var/run/php5-fpm --link php5fpm-container:php5-fpm -p 80:80 -p 443:443 -t nginx_image 


Все связка готова и должна работать.
Кажется все просто но блять я убил 2 дня на то, чтобы разобраться, что где как.
О связке.
Все смежные данные где нужна работа между двумя контейнерами - хранятся на docker volumes
Они хранятся в папке /var/lib/docker/volumes/
Для удобства на них сделаны ссылки в папке /home/work
Для того, чтобы заработал скрипт php - нужно проложить стандартный nginx конфиг который вы обычно кладете по пути /etc/nginx/sites-enabled/sitejashd.com
Класть теперь нужно это в /home/work/nginx_settings/sites-enabled/ashd.com
По факту именно сюда и обращается ваш контейнер nginx
Можете этот контейнер убивать или делать что-то еще, конфиг никуда не денется - он всегда у вас.
