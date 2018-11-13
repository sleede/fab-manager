# Specific instructions concerning installation on ArchLinux

## Ruby 2.3.0
Ruby 2.3.0 has a known issue with openSSL version > 1.0 (which is ArchLinux default). 
To overpass this problem, you must install ruby with special indication of the openSSL installation to use.

```bash
# first, install GCC 5 from AUR (https://aur.archlinux.org/packages/gcc5/)
# you can use pacaur, yaourt or whatever you want ...
pacaur -S gcc5
# then, install openssl-1.0 (in addition of 1.1)
sudo pacman -S openssl-1.0
# finally, install ruby 2.3 using the bindings
CC=/usr/bin/gcc-5 PKG_CONFIG_PATH=/usr/lib/openssl-1.0/pkgconfig:/usr/lib/pkgconfig CFLAGS+=" -I/usr/include/openssl-1.0" LDFLAGS+=" -L/usr/lib/openssl-1.0 -lssl" rvm install 2.3.0
```

There's also an issue with openSSL and `puma` but this is fixed by using puma version > 3.
