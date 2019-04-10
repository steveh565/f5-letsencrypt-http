# F5 Lets Encrypt Certificate automation handbook

Installation
Copy the file “f5-letsencrypt-http.tgz” to the folder /var/tmp on the target F5 Big-IP device.
Expand the archive: tar -zxvf f5-letsencrypt-http.tgz
Execute the installation script:  cd letsencrypt; ./initialize.sh install
(Optional) Populate domains.txt file: cd /shared/letsencrypt; vi domains.txt
Execute initialization script: cd /shared/letsencrypt; ./initialize.sh initialize_bigip
-	Configures Lets Encrypt OCSP certificate validator
-	Configures Lets Encrypt automatic HTTP validator components
-	Configures iCall automatic 30-day trigger to validate / renew managed certificates
-	Configures managed client-ssl profiles: “auto_<FQDN>”


Operations – Add new site
Edit domains.txt file: cd /shared/letsencrypt; vi domains.txt
-	Add a new line for each site, starting with the FQDN for new site including all SANs separated by spaces
-	E.g. www.foo.ca san1.foo.ca san2.foo.ca san3.foo.ca
Run create_clientssl_profiles.sh: cd /shared/letsencrypt; ./create_clientssl_profiles.sh
Configure F5 to front-end the site: f5.http iApp Template; default cert/key; lets_encrypt_irule
NB: Steps to complete vary depending on the starting scenario for a given application/site, however the final result must be that request for the public application/site are directed to the F5 (typically via DNS), which in turn passes the request to the application servers.
Run ACME client script: cd /shared/letsencrypt; ./dehydrated -c


Operations - Certificate Renewal
Normally this process is fully automated by an iCall script that runs every 30 days. Certificates with less than 30 days until expiry will be automatically renewed.
Manually running the ACME client script will force a renewal check certificates for sites in domains.txt file: cd /shared/letsencrypt; ./dehydrated -c
