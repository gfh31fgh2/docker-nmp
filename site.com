server {
listen *:80; # port in internet
server_name YOUR_IP;
access_log /var/log/nginx/naccess.log;
error_log /var/log/nginx/nerror.log;
root /home/www/siteplace;


# main
location / {
root /home/www/siteplace;
index index.php index.html;
if (!-e $request_filename) {
rewrite ^(/.*)$ /index.php?q=$1 last;
break;
                        }
}

# php
location ~ ^/.*\.php$ {
root /home/www/siteplace;
#include fastcgi_params;
fastcgi_pass unix:/var/run/php5-fpm/php5-fpm.sock;
fastcgi_hide_header X-Powered-By;
fastcgi_index index.php;
fastcgi_param DOCUMENT_ROOT /home/www/siteplace;
fastcgi_param SCRIPT_FILENAME /home/www/siteplace$fastcgi_script_name;
fastcgi_param PATH_TRANSLATED /home/www/siteplace$fastcgi_script_name;

include fastcgi_params;

fastcgi_param QUERY_STRING $query_string;
fastcgi_param REQUEST_METHOD $request_method;
fastcgi_param CONTENT_TYPE $content_type;
fastcgi_param CONTENT_LENGTH $content_length;
fastcgi_param AUTH_USER $remote_user;
fastcgi_param REMOTE_USER $remote_user;
fastcgi_intercept_errors on;
fastcgi_ignore_client_abort off;
fastcgi_connect_timeout 100;
fastcgi_send_timeout 180;
fastcgi_read_timeout 180;
fastcgi_buffer_size 128k;
fastcgi_buffers 4 256k;
fastcgi_busy_buffers_size 256k;
fastcgi_temp_file_write_size 256k;
                       }

#end
}
