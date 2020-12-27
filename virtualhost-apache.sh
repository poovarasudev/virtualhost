#!/bin/bash

### Parameters
action=$1
domain=$2
rootDirectory=$3
owner=$(who am i | awk '{print $1}')
email='webmaster@localhost'
sitesEnabled='/etc/apache2/sites-enabled/'
availableSites='/etc/apache2/sites-available/'
userDirectory='/var/www/'
availableSitesdomain=$availableSites$domain.conf

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
		if [ -e $availableSitesdomain ]; then
			echo -e $"This domain already exists.\nTry Another one"
			exit;
		fi

		### check directory exists or not
		if ! [ -d $rootDirectory ]; then
			### create the directory
			mkdir $rootDirectory
			### give permission to root dir
			chmod 755 $rootDirectory
			### write test file in the new domain dir
			if ! echo "<?php echo phpinfo(); ?>" > $rootDirectory/phpinfo.php
			then
				echo $"ERROR: Not able to write in file $rootDirectory/phpinfo.php. Please check permissions"
				exit;
			else
				echo $"Added content to $rootDirectory/phpinfo.php"
			fi
		fi

		### create virtual host rules file
		if ! echo "
		<VirtualHost *:80>
			ServerAdmin $email
			ServerName $domain
			ServerAlias $domain
			DocumentRoot $rootDirectory
			<Directory />
				AllowOverride All
			</Directory>
			<Directory $rootDirectory>
				Options Indexes FollowSymLinks MultiViews
				AllowOverride all
				Require all granted
			</Directory>
			ErrorLog /var/log/apache2/$domain-error.log
			LogLevel error
			CustomLog /var/log/apache2/$domain-access.log combined
		</VirtualHost>" > $availableSitesdomain
		then
			echo -e $"There is an ERROR creating $domain file"
			exit;
		else
			echo -e $"\nNew Virtual Host Created\n"
		fi

		### Add domain in /etc/hosts
		if ! echo -e "\n127.0.0.1	$domain" >> /etc/hosts
		then
			echo $"ERROR: Not able to write in /etc/hosts"
			exit;
		else
			echo -e $"Host added to /etc/hosts file \n"
		fi

		if [ "$owner" == "" ]; then
			chown -R $(whoami):$(whoami) $rootDirectory
		else
			chown -R $owner:$owner $rootDirectory
		fi

		### enable website
		a2ensite $domain

		### restart Apache
		/etc/init.d/apache2 reload

		### show the finished message
		echo -e $"Complete! \nYou now have a new Virtual Host \nYour new host is: http://$domain \nAnd its located at $rootDirectory"
		exit;
	else
		### check whether domain already exists
		if ! [ -e $availableSitesdomain ]; then
			echo -e $"This domain does not exist.\nPlease try another one"
			exit;
		else
			### Delete domain in /etc/hosts
			newhost=${domain//./\\.}
			sed -i "/$newhost/d" /etc/hosts

			### disable website
			a2dissite $domain

			### restart Apache
			/etc/init.d/apache2 reload

			### Delete virtual host rules files
			rm $availableSitesdomain
		fi

		### check if directory exists or not
		if [ -d $rootDirectory ]; then
			echo -e $"Delete host root directory ? (y/n)"
			read deldir

			if [ "$deldir" == 'y' -o "$deldir" == 'Y' ]; then
				### Delete the directory
				rm -rf $rootDirectory
				echo -e $"Directory deleted"
			else
				echo -e $"Host directory conserved"
			fi
		else
			echo -e $"Host directory not found. Ignored!!!"
		fi

		### show the finished message
		echo -e $"Complete!\nYou just removed Virtual Host $domain"
		exit 0;
fi
