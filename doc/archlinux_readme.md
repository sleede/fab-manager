# Specific instructions concerning installation on ArchLinux

## Ruby 2.3.0
Ruby 2.3.0 has a known issue with openSSL version > 1.0 (which is ArchLinux default). 
To overpass this problem, you must install ruby with special indication of the openSSL installation to use.

```bash
sudo pacman -S gcc5
rvm pkg install openssl
CC=gcc-5 rvm install 2.3.0 -C --with-openssl-dir=$HOME/.rvm/usr
```

There's also an issue with openSSL and `puma` but this is fixed by using puma version > 3.