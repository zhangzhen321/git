#/bin/sh
cd /usr/src/git
make -j15 install-html && prefix=/mingw64 make -j15 -C contrib/subtree install-html