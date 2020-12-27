#!/bin/bash

### Parameters
action=$1
domain=$2
rootDirectory=$3
owner=$(who am i | awk '{print $1}')
sitesEnabled='/etc/nginx/sites-enabled/'
availableSites='/etc/nginx/sites-available/'
userDirectory='/var/www/'

if [ "$(whoami)" != 'root' ]; then
	echo $"You have no permission to run $0 as non-root user. Use sudo"
		exit 1;
fi

if [ "$action" != 'create' ] && [ "$action" != 'delete' ]
	then
		echo $"Invalid action, You need to use (create or delete) action -- Lower-case only"
		exit 1;
fi

while [ "$domain" == "" ]
do
	echo -e $"Please provide a domain."
	read domain
done

if [ "$rootDirectory" == "" ]; then
	rootDirectory=${domain//./}
fi

### if root dir starts with '/', don't use /var/www as default starting point
if [[ "$rootDirectory" =~ ^/ ]]; then
	userDirectory=''
fi

rootDirectory=$userDirectory$rootDirectory

if [ "$action" == 'create' ]
	then
		### check if domain already exists
		if [ -e $availableSites$domain ]; then
			echo -e $"This domain already exists.\nTry Another one"
			exit;
		fi

		### check directory exists or not
		if ! [ -d $userDirectory$rootDirectory ]; then
			### create the directory
			mkdir $userDirectory$rootDirectory
			### give permission to root dir
			chmod 755 $userDirectory$rootDirectory
			### write test file in the new domain dir
			if ! echo "<?php echo phpinfo(); ?>" > $userDirectory$rootDirectory/phpinfo.php
				then
					echo $"ERROR: Not able to write in file $userDirectory/$rootDirectory/phpinfo.php. Please check permissions."
					exit;
			else
					echo $"Added content to $userDirectory$rootDirectory/phpinfo.php."
			fi
		fi

		### create virtual host rules file
		if ! echo "server {
			listen   80;
			root $userDirectory$rootDirectory;
			index index.php index.html index.htm;
			server_name $domain;

			# serve static files directly
			location ~* \.(jpg|jpeg|gif|css|png|js|ico|html)$ {
				access_log off;
				expires max;
			}

			# removes trailing slashes (prevents SEO duplicate content issues)
			if (!-d \$request_filename) {
				rewrite ^/(.+)/\$ /\$1 permanent;
			}

			# unless the request is for a valid file (image, js, css, etc.), send to bootstrap
			if (!-e \$request_filename) {
				rewrite ^/(.*)\$ /index.php?/\$1 last;
				break;
			}

			# removes trailing 'index' from all controllers
			if (\$request_uri ~* index/?\$) {
				rewrite ^/(.*)/index/?\$ /\$1 permanent;
			}

			# catch all
			error_page 404 /index.php;

			location ~ \.php$ {
				fastcgi_split_path_info ^(.+\.php)(/.+)\$;
				fastcgi_pass 127.0.0.1:9000;
				fastcgi_index index.php;
				include fastcgi_params;
			}

			location ~ /\.ht {
				deny all;
			}

		}" > $availableSites$domain
		then
			echo -e $"ERROR while create $domain file"
			exit;
		else
			echo -e $"\nNew Virtual Host Created\n"
		fi

		### Add domain in /etc/hosts
		if ! echo -e "\n127.0.0.1	$domain" >> /etc/hosts
			then
				echo $"ERROR: Not able write in /etc/hosts"
				exit;
		else
				echo -e $"Host added to /etc/hosts file \n"
		fi

		if [ "$owner" == "" ]; then
			chown -R $(whoami):www-data $userDirectory$rootDirectory
		else
			chown -R $owner:www-data $userDirectory$rootDirectory
		fi

		### enable website
		ln -s $availableSites$domain $sitesEnabled$domain

		### restart Nginx
		service nginx restart

		### show the finished message
		echo -e $"Complete! \nYou now have a new Virtual Host \nYour new host is: http://$domain \nAnd its located at $userDirectory$rootDirectory"
		exit;
	else
		### check whether domain already exists
		if ! [ -e $availableSites$domain ]; then
			echo -e $"This domain dont exists.\nPlease Try Another one"
			exit;
		else
			### Delete domain in /etc/hosts
			newhost=${domain//./\\.}
			sed -i "/$newhost/d" /etc/hosts

			### disable website
			rm $sitesEnabled$domain

			### restart Nginx
			service nginx restart

			### Delete virtual host rules files
			rm $availableSites$domain
		fi

		### check if directory exists or not
		if [ -d $userDirectory$rootDirectory ]; then
			echo -e $"Delete host root directory ? (s/n)"
			read deldir

			if [ "$deldir" == 's' -o "$deldir" == 'S' ]; then
				### Delete the directory
				rm -rf $userDirectory$rootDirectory
				echo -e $"Directory deleted"
			else
				echo -e $"Host directory conserved"
			fi
		else
			echo -e $"Host directory not found. Ignored"
		fi

		### shows the finished message
		echo -e $"Complete!\nYou removed Virtual Host $domain"
		exit 0;
fi
