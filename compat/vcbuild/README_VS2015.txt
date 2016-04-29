Instructions for building Git for Windows using VS2015.
================================================================

[1] Install nuget.exe somewhere on your system and add it to your PATH.
    https://docs.nuget.org/consume/command-line-reference
    https://dist.nuget.org/index.html

[2] Download required nuget packages for third-party libraries.
    Using a bash shell window, type:
        cd compat/vcbuild
        make all
    This will download the packages, unpack them into GEN.PKGS,
    and copy the {include, lib, bin} directories into GEN.DEPS.

[3] Build 64-bit version of Git for Windows.
    Using a bash shell window:
        cd to the root directory
        make MSVC=1 DEBUG=1

    * Note config.mak.uname currently contains hard-coded paths
      to the various MSVC and SDK libraries.

[4] Add compat/vcbuild/GEN.DEPS/bin to your PATH.

    * I still need to add a step to make the third-party DLLs
      along side the generated EXEs.

[5] You should then be able to run interactive commands.

[6] To debug/profile in VS, open the git.exe in VS and run/debug it.

    * I do not have .sln/.vcproj files at this time.

[7] Enjoy!


