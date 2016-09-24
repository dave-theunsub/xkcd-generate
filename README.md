# xkcd-generate, 2016 -
Last updated 24 Sept 2016

This program was made for fun.  It may or may not be the right way to
do things.

https://dave-theunsub.github.io/xkcd-generate/ 
https://github.com/dave-theunsub/xkcd-generate/

Binaries for installation (rpm, deb, xz) are available there.
  
RPM installation  
  a. Get and import the key in one step  
  rpm --import https://davem.fedorapeople.org/RPM-GPG-KEY-DaveM-10-Sept-2016  
  
  b. Verify the list of gpg keys installed in RPM DB  
  rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} --> %{summary}\n'  
  
  c. Check the signature of the rpm.  For this example, we'll use version 0.0.6   
  rpm --checksig xkcd-generate-0.0.6-1.fc.noarch.rpm  
  or  
  rpm --checksig xkcd-generate-0.0.6-1.el7.noarch.rpm  
  
  d. You should see something like this:  
  /home/you/xkcd-generate-0.0.6-1.fc.noarch.rpm rsa sha1 (md5) pgp md5 OK
  
  e. dnf install xkcd-generate-0.0.6-1.fc.noarch.rpm  
  or  
  dnf install xkcd-generate-0.0.6-1.el7.noarch.rpm  
  
Ubuntu / Debian install  
  
  a.  sudo dpkg -i xkcd-generate_0.0.6-1_all.deb  
  
  b.  sudo apt-get install -f  
  
You can also verify the tarball.  Using 5.22 as the example version, ensure
you have downloaded the tarball, its detached signature (.asc), and the key
in step "a" above.  
  
  a. Get the key (skip if you already have it)  
  wget https://davem.fedorapeople.org/RPM-GPG-KEY-DaveM-10-Sept-2016  
  
  b. Import it (skip if you have done it already)  
  gpg --import RPM-GPG-KEY-DaveM-10-Sept-2016  
  
  c. Verify  
  gpg2 --verify xkcd-generate-0.0.6.tar.xz.asc xkcd-generate-0.0.6.tar.xz  
  or  
  gpg --verify clamtk-5.22.tar.gz.asc clamtk-5.22.tar.gz  
  
  d. You should see something like this:  
  gpg: Signature made Sun 11 Sep 2016 06:29:41 AM CDT using RSA key ID  
  (snipped for brevity)  
  
Dave M <dave.nerd @ gmail>, 2016 -  
