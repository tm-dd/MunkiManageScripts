## How to enable Apache on macOS 10.14.6 ?

With thanks for information from:

 - https://www.maclife.de/ratgeber/eigenen-webserver-unter-macos-1014-mojave-aufsetzen-gehts-100109677.html
 - https://getgrav.org/blog/macos-mojave-apache-ssl
 - https://www.garron.me/en/mac/how-to-enable-htaccess-apache-mac-os-x.html

Maybe this instructions will help you, to setup the Apache web server on macOS 10.14.
Please note, YOU DO IT ON YOUR OWN RISK, WITHOUT ANY WARRANTY.


## activate enable Apache 2

	admins-Mac:~ admin$ sudo cp /etc/apache2/httpd.conf ./httpd.conf.org
	admins-Mac:~ admin$ sudo vim /etc/apache2/httpd.conf
	
	admins-Mac:~ admin$ diff /etc/apache2/httpd.conf ./httpd.conf.org
	177c177
	< LoadModule php7_module libexec/apache2/libphp7.so
	---
	> #LoadModule php7_module libexec/apache2/libphp7.so
	221c221
	< ServerName munki.example.org:80
	---
	> #ServerName www.example.com:80
	admins-Mac:~ admin$

#### check the syntax

	admins-Mac:~ admin$ apachectl configtest
	Syntax OK
	admins-Mac:~ admin$

#### (re)start and test Apache 2

	admins-Mac:~ admin$ sudo launchctl load -w /System/Library/LaunchDaemons/org.apache.httpd.plist 
	admins-Mac:~ admin$
	
	admins-Mac:~ admin$ curl http://localhost/
	<html><body><h1>It works!</h1></body></html>
	admins-Mac:~ admin$
	
	admins-Mac:~ admin$ curl https://localhost/
	curl: (7) Failed to connect to localhost port 443: Connection refused
	admins-Mac:~ admin$
	
	==== the default directory of the web server ====
	
	admins-Mac:~ admin$ cd /Library/WebServer/Documents/
	admins-Mac:Documents admin$ ls -la
	total 72
	drwxr-xr-x  5 root  wheel    160 22 Feb  2019 .
	drwxr-xr-x  5 root  wheel    160 22 Feb  2019 ..
	-rw-r--r--  1 root  wheel   3726 22 Feb  2019 PoweredByMacOSX.gif
	-rw-r--r--  1 root  wheel  31958 22 Feb  2019 PoweredByMacOSXLarge.gif
	-rw-r--r--  1 root  wheel     45 11 Jun  2007 index.html.en
	admins-Mac:Documents admin$

### rename the index.html and allow indexing to view files from the web root 

	admins-Mac:~ admin$ sudo mv /Library/WebServer/Documents/index.html.en /Library/WebServer/Documents/original_index.html.en 
	
	admins-Mac:~ admin$ curl http://localhost/
	<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
	<html><head>
	<title>403 Forbidden</title>
	</head><body>
	<h1>Forbidden</h1>
	<p>You don't have permission to access /
	on this server.<br />
	</p>
	</body></html>
	admins-Mac:~ admin$

	admins-Mac:~ admin$ sudo vim /etc/apache2/httpd.conf
	admins-Mac:~ admin$ diff /etc/apache2/httpd.conf ./httpd.conf.org
	177c177
	< LoadModule php7_module libexec/apache2/libphp7.so
	---
	> #LoadModule php7_module libexec/apache2/libphp7.so
	221c221
	< ServerName munki.example.org:80
	---
	> #ServerName www.example.com:80
	259c259
	<     Options Indexes FollowSymLinks Multiviews
	---
	>     Options FollowSymLinks Multiviews
	admins-Mac:~ admin$ 
	
	admins-Mac:~ admin$ apachectl configtest
	Syntax OK
	admins-Mac:~ admin$ 
	
	admins-Mac:~ admin$ sudo apachectl graceful
	admins-Mac:~ admin$
	
	admins-Mac:~ admin$ curl http://localhost/
	<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
	<html>
	<head>
	 <title>Index of /</title>
	</head>
	<body>
	<h1>Index of /</h1>
	 <table>
	  <tr><th valign="top"><img src="/icons/blank.gif" alt="[ICO]"></th><th><a href="?C=N;O=D">Name</a></th><th><a href="?C=M;O=A">Last modified</a></th><th><a href="?C=S;O=A">Size</a></th><th><a href="?C=D;O=A">Description</a></th></tr>
	  <tr><th colspan="5"><hr></th></tr>
	<tr><td valign="top"><img src="/icons/image2.gif" alt="[IMG]"></td><td><a href="PoweredByMacOSX.gif">PoweredByMacOSX.gif</a>    </td><td align="right">2019-02-22 20:24  </td><td align="right">3.6K</td><td>&nbsp;</td></tr>
	<tr><td valign="top"><img src="/icons/image2.gif" alt="[IMG]"></td><td><a href="PoweredByMacOSXLarge.gif">PoweredByMacOSXLarge..&gt;</a></td><td align="right">2019-02-22 20:24  </td><td align="right"> 31K</td><td>&nbsp;</td></tr>
	<tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="original_index.html.en">original_index.html.en</a> </td><td align="right">2007-06-11 11:53  </td><td align="right"> 45 </td><td>&nbsp;</td></tr>
	  <tr><th colspan="5"><hr></th></tr>
	</table>
	</body></html>
	admins-Mac:~ admin$

### enable SSL for https with a selfsign certificate

	admins-Mac:~ admin$ sudo vim /etc/apache2/httpd.conf
	admins-Mac:~ admin$ diff /etc/apache2/httpd.conf ./httpd.conf.org
	75c75
	< LoadModule authn_socache_module libexec/apache2/mod_authn_socache.so
	---
	> #LoadModule authn_socache_module libexec/apache2/mod_authn_socache.so
	150c150
	< LoadModule ssl_module libexec/apache2/mod_ssl.so
	---
	> #LoadModule ssl_module libexec/apache2/mod_ssl.so
	177c177
	< LoadModule php7_module libexec/apache2/libphp7.so
	---
	> #LoadModule php7_module libexec/apache2/libphp7.so
	221c221
	< ServerName munki.example.org:80
	---
	> #ServerName www.example.com:80
	259c259
	<     Options Indexes FollowSymLinks Multiviews
	---
	>     Options FollowSymLinks Multiviews
	534c534
	< Include /private/etc/apache2/extra/httpd-ssl.conf
	---
	> #Include /private/etc/apache2/extra/httpd-ssl.conf
	admins-Mac:~ admin$
	
	admins-Mac:~ admin$ sudo vim /private/etc/apache2/extra/httpd-ssl.conf
	admins-Mac:~ admin$ ls -l /private/etc/apache2/extra/httpd-ssl.conf
	-rw-r--r--  1 root  wheel  13325 22 Feb  2019 /private/etc/apache2/extra/httpd-ssl.conf
	admins-Mac:~ admin$ grep "^SSLCertificate" /private/etc/apache2/extra/httpd-ssl.conf
	SSLCertificateFile "/private/etc/apache2/server.crt"
	SSLCertificateKeyFile "/private/etc/apache2/server.key"
	admins-Mac:~ admin$ ls -l /private/etc/apache2/
	total 128
	drwxr-xr-x  14 root  wheel    448  3 Sep 12:55 extra
	-rw-r--r--   1 root  wheel  21155  3 Sep 12:51 httpd.conf
	-rw-r--r--   1 root  wheel  21150 22 Feb  2019 httpd.conf.pre-update
	-rw-r--r--   1 root  wheel  13077 22 Feb  2019 magic
	-rw-r--r--   1 root  wheel  61118 22 Feb  2019 mime.types
	drwxr-xr-x   4 root  wheel    128 22 Feb  2019 original
	drwxr-xr-x   3 root  wheel     96 22 Feb  2019 other
	drwxr-xr-x   2 root  wheel     64 22 Feb  2019 users
	admins-Mac:~ admin$ cd /private/etc/apache2/
	admins-Mac:apache2 admin$ sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout server.key -out server.crt
	Generating a 2048 bit RSA private key
	........+++
	.......................+++
	writing new private key to 'server.key'
	-----
	You are about to be asked to enter information that will be incorporated
	into your certificate request.
	What you are about to enter is what is called a Distinguished Name or a DN.
	There are quite a few fields but you can leave some blank
	For some fields there will be a default value,
	If you enter '.', the field will be left blank.
	-----
	Country Name (2 letter code) []:DE
	State or Province Name (full name) []:Saxony
	Locality Name (eg, city) []:Dresden
	Organization Name (eg, company) []:
	Organizational Unit Name (eg, section) []:
	Common Name (eg, fully qualified host name) []:munki.example.org
	Email Address []:
	admins-Mac:apache2 admin$
	
	admins-Mac:apache2 admin$ sudo vim /etc/apache2/httpd.conf
	
	admins-Mac:~ admin$ diff /etc/apache2/httpd.conf ./httpd.conf.org
	75c75
	< LoadModule authn_socache_module libexec/apache2/mod_authn_socache.so
	---
	> #LoadModule authn_socache_module libexec/apache2/mod_authn_socache.so
	94c94
	< LoadModule socache_shmcb_module libexec/apache2/mod_socache_shmcb.so
	---
	> #LoadModule socache_shmcb_module libexec/apache2/mod_socache_shmcb.so
	150c150
	< LoadModule ssl_module libexec/apache2/mod_ssl.so
	---
	> #LoadModule ssl_module libexec/apache2/mod_ssl.so
	177c177
	< LoadModule php7_module libexec/apache2/libphp7.so
	---
	> #LoadModule php7_module libexec/apache2/libphp7.so
	221c221
	< ServerName munki.example.org:80
	---
	> #ServerName www.example.com:80
	259c259
	<     Options Indexes FollowSymLinks Multiviews
	---
	>     Options FollowSymLinks Multiviews
	534c534
	< Include /private/etc/apache2/extra/httpd-ssl.conf
	---
	> #Include /private/etc/apache2/extra/httpd-ssl.conf
	admins-Mac:~ admin$
	
	admins-Mac:~ admin$ apachectl configtest
	Syntax OK
	admins-Mac:~ admin$ 
	
	admins-Mac:~ admin$ sudo apachectl graceful
	admins-Mac:~ admin$ 
	
	admins-Mac:~ admin$ curl --insecure https://localhost/
	<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
	<html>
	<head>
	 <title>Index of /</title>
	</head>
	<body>
	<h1>Index of /</h1>
	 <table>
	  <tr><th valign="top"><img src="/icons/blank.gif" alt="[ICO]"></th><th><a href="?C=N;O=D">Name</a></th><th><a href="?C=M;O=A">Last modified</a></th><th><a href="?C=S;O=A">Size</a></th><th><a href="?C=D;O=A">Description</a></th></tr>
	  <tr><th colspan="5"><hr></th></tr>
	<tr><td valign="top"><img src="/icons/image2.gif" alt="[IMG]"></td><td><a href="PoweredByMacOSX.gif">PoweredByMacOSX.gif</a>    </td><td align="right">2019-02-22 20:24  </td><td align="right">3.6K</td><td>&nbsp;</td></tr>
	<tr><td valign="top"><img src="/icons/image2.gif" alt="[IMG]"></td><td><a href="PoweredByMacOSXLarge.gif">PoweredByMacOSXLarge..&gt;</a></td><td align="right">2019-02-22 20:24  </td><td align="right"> 31K</td><td>&nbsp;</td></tr>
	<tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="original_index.html.en">original_index.html.en</a> </td><td align="right">2007-06-11 11:53  </td><td align="right"> 45 </td><td>&nbsp;</td></tr>
	  <tr><th colspan="5"><hr></th></tr>
	</table>
	</body></html>
	admins-Mac:~ admin$ 

### Enable HTACCESS to protect files

	admins-Mac:~ admin$ sudo vim /etc/apache2/httpd.conf
	
	admins-Mac:~ admin$ diff /etc/apache2/httpd.conf ./httpd.conf.org
	75c75
	< LoadModule authn_socache_module libexec/apache2/mod_authn_socache.so
	---
	> #LoadModule authn_socache_module libexec/apache2/mod_authn_socache.so
	94c94
	< LoadModule socache_shmcb_module libexec/apache2/mod_socache_shmcb.so
	---
	> #LoadModule socache_shmcb_module libexec/apache2/mod_socache_shmcb.so
	150c150
	< LoadModule ssl_module libexec/apache2/mod_ssl.so
	---
	> #LoadModule ssl_module libexec/apache2/mod_ssl.so
	177c177
	< LoadModule php7_module libexec/apache2/libphp7.so
	---
	> #LoadModule php7_module libexec/apache2/libphp7.so
	221c221
	< ServerName munki.example.org:80
	---
	> #ServerName www.example.com:80
	259c259
	<     Options Indexes FollowSymLinks Multiviews
	---
	>     Options FollowSymLinks Multiviews
	267c267
	<     AllowOverride All
	---
	>     AllowOverride None
	534c534
	< Include /private/etc/apache2/extra/httpd-ssl.conf
	---
	> #Include /private/etc/apache2/extra/httpd-ssl.conf
	admins-Mac:~ admin$ 
	
	admins-Mac:~ admin$ sudo apachectl restart
	
	admins-Mac:~ admin$ curl http://localhost/example_file    # this file have to be protected with a .htaccess file before
	<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
	<html><head>
	<title>401 Unauthorized</title>
	</head><body>
	<h1>Unauthorized</h1>
	<p>This server could not verify that you
	are authorized to access the document
	requested.  Either you supplied the wrong
	credentials (e.g., bad password), or your
	browser doesn't understand how to supply
	the credentials required.</p>
	</body></html>
	admins-Mac:~ admin$

### fake DNS names, only for short tests

	admins-Mac:~ admin$ sudo vim /etc/hosts
	
	admins-Mac:~ admin$ cat /etc/hosts
	##
	# Host Database
	#
	# localhost is used to configure the loopback interface
	# when the system is booting.  Do not change this entry.
	##
	127.0.0.1	localhost
	255.255.255.255	broadcasthost
	::1             localhost
	127.0.0.1 	munki.example.org
	admins-Mac:~ admin$
	
	admins-Mac:~ admin$ curl --insecure https://munki.example.org/
	<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
	<html>
	<head>
	 <title>Index of /</title>
	</head>
	<body>
	<h1>Index of /</h1>
	 <table>
	  <tr><th valign="top"><img src="/icons/blank.gif" alt="[ICO]"></th><th><a href="?C=N;O=D">Name</a></th><th><a href="?C=M;O=A">Last modified</a></th><th><a href="?C=S;O=A">Size</a></th><th><a href="?C=D;O=A">Description</a></th></tr>
	  <tr><th colspan="5"><hr></th></tr>
	<tr><td valign="top"><img src="/icons/image2.gif" alt="[IMG]"></td><td><a href="PoweredByMacOSX.gif">PoweredByMacOSX.gif</a>    </td><td align="right">2019-02-22 20:24  </td><td align="right">3.6K</td><td>&nbsp;</td></tr>
	<tr><td valign="top"><img src="/icons/image2.gif" alt="[IMG]"></td><td><a href="PoweredByMacOSXLarge.gif">PoweredByMacOSXLarge..&gt;</a></td><td align="right">2019-02-22 20:24  </td><td align="right"> 31K</td><td>&nbsp;</td></tr>
	<tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="original_index.html.en">original_index.html.en</a> </td><td align="right">2007-06-11 11:53  </td><td align="right"> 45 </td><td>&nbsp;</td></tr>
	  <tr><th colspan="5"><hr></th></tr>
	</table>
	</body></html>
	admins-Mac:~ admin$
