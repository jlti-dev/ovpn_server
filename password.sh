#!/bin/sh
file="/docker/server/pw"
if [ -d "/docker/logs" ]; then
	log="/docker/logs/auth"
else
	log="/dev/null"
fi
echo "$(date +[%Y-%m-%d]%T) Reading tempfile $1" >> $log
username="$(head -n 1 $1)"
password="$(tail -n 1 $1)"
echo "$(date +[%Y-%m-%d]%T) Checking Authentication" >> $log
if [ -z "$username" ]; then
	echo "$(date +[%Y-%m-%d]%T) No user specified" >> $log
	exit 1
fi
if [ -z "$password"  ]; then
	echo "$(date +[%Y-%m-%d]%T) No password specified" >> $log
	exit 1
fi
echo "$(date +[%Y-%m-%d]%T) username is $username" >> $log
pw="$(cat $file | grep $username | cut -d : -f 2)"
algo="$(echo $pw | cut -d $ -f 2)"
salt="$(echo $pw | cut -d $ -f 3)"
hash="$(echo $pw | cut -d $ -f 4)"

if [ -z "$algo" ]; then
	echo "$(date +[%Y-%m-%d]%T) Algorithm not determined" >> $log
	exit 1
fi
if [ -z "$salt" ]; then
	echo "$(date +[%Y-%m-%d]%T) salt not determined" >> $log
	exit 1
fi
if [ -z "$hash" ]; then
	echo "$(date +[%Y-%m-%d]%T) Hash not determined" >> $log
	exit 1
fi


newHash="$(openssl passwd -$algo -salt $salt $password)"
if [ -z "$newHash" ]; then
	echo "$(date +[%Y-%m-%d]%T) New Hash not determined" >> $log
	exit 1
fi
#newHash beinhaltet ebenfalls den algorithmus sowie den salt, daher vergleich mit PW
if [ "$pw" = "$newHash" ]; then
	echo "$(date +[%Y-%m-%d]%T) Hashes match, authorized" >> $log
else
	echo "$(date +[%Y-%m-%d]%T) Hashes do not match, failed authorization!" >> $log
	exit 1
fi
