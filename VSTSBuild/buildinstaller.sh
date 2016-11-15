#/bin/sh
rm -f /tmp.7z
USERPROFILE=/c/GitBuildOutput
export USERPROFILE
/usr/src/build-extra/installer/release.sh 2.10.2-gvfs

HOME=/c/GitBuildOutput
export HOME
/usr/src/build-extra/portable/release.sh 2.10.2-gvfs
