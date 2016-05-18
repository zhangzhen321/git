#/bin/sh
USERPROFILE=/c/GitBuildOutput
export USERPROFILE
/usr/src/build-extra/installer/release.sh 2.8.2-gvfs

HOME=/c/GitBuildOutput
export HOME
/usr/src/build-extra/portable/release.sh 2.8.2-gvfs