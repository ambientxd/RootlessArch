#!/bin/bash

# RootlessArch
# Copyright (C) 2022 ambientxd
# This program comes with ABSOLUTELY NO WARRANTY
# This is free software, and you are welcome to redistribute it
# under certain conditions

# This application is open source at https://github.com/ambientxd/RootlessArch

# Configuration for custom usage.
PacmanCustomPackages="" # Those packages gets pre-installed in the installation process.
filePath="$(pwd)/$0" # Installer's file path
shellConfig="$HOME/.bashrc"
logFile="$HOME/installer.log"

# Random essential variables
backupPackages=""


function printUsage(){
echo "$0 - A part of RootlessArch"
echo ""
echo "Usage: $0 <arguments>"
echo "Options:"
echo "  $0 {-r    --reinstall}: Reinstall System"
echo "  $0 {-d --selfdestruct}: Uninstall rootlessArch"
echo "  $0 {-v      --verbose}: Install System (Verbose Mode)"
echo "  $0 {        --upgrade}: Upgrade System"
echo "                          WARNING: Arch Linux's packages will be DESTROYED."
echo "                          WARNING: Only packages using paru/pacman will be backed up"
echo "                          WARNING: and files in \$HOME."
exit 0
}



function startArchLinux(){
    rm -rf $HOME/tmp/*
    bash $HOME/.local/share/junest/bin/junest proot --fakeroot export ROOTHOMEDIR=$HOME \&\& \$SHELL
}

function patchBugs(){
    cd $HOME/tmp
    git clone https://github.com/ambientxd/RootlessArch >> $logFile


    # Makepkg, Fakechroot and Fakeroot
    cd $HOME/tmp/RootlessArch/patches
    chmod a+x makepkg
    chmod a+x fakechroot
    chmod a+x fakeroot
    cp makepkg fakechroot fakeroot $HOME/.junest/usr/bin



    # Pacman
    cp mirrorlist $HOME/.junest/etc/pacman.d/mirrorlist
    echo "[options]" >> $HOME/.junest/etc/pacman.conf
    echo "RootDir     = $HOME/.junest" >> $HOME/.junest/etc/pacman.conf

    # Docker Systemctl Replacement
    curl -LO https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl3.py 
    cp systemctl3.py $HOME/.junest/bin/systemctl
    
}
function firstStartup(){
    # Install required packages.
    export ROOTHOMEDIR=$HOME
    sudovm="$HOME/.local/share/junest/bin/junest proot --fakeroot"
    $sudovm useradd $USER
    paruj="$sudovm runuser -u $USER -- paru"
    pacmanj="$sudovm pacman"
    $pacmanj -Syu --ignore base-devel --noconfirm >> $logFile
    $pacmanj -S --noconfirm neofetch nano python tar gzip unzip which btop zstd man-db binutils make psmisc >> $logFile
    $pacmanj -R yay --noconfirm &>>$logFile #Broken package

    # Install Paru (AUR Helper)
    PARU_VERSION="1.11.1"

    cd $HOME/tmp
    curl -LO https://github.com/Morganamilo/paru/releases/download/v$PARU_VERSION/paru-v$PARU_VERSION-x86_64.tar.zst
    $HOME/.local/share/junest/bin/junest proot --fakeroot tar -xvf $HOME/tmp/paru-v$PARU_VERSION-x86_64.tar.zst >> $logFile
    cp paru $HOME/.junest/usr/bin/paru
    cp paru.conf $HOME/.junest/etc/paru.conf

    cp man/paru.8 $HOME/.junest/usr/share/man/man8/paru.8
    cp man/paru.conf.5 $HOME/.junest/usr/share/man/man5/paru.conf.5

    cp completions/bash $HOME/.junest/usr/share/bash-completion/completions/paru.bash
    cp completions/fish $HOME/.junest/usr/share/fish/vendor_completions.d/paru.fish
    cp completions/zsh $HOME/.junest/usr/share/zsh/site-functions/_paru

    # Install backed up packages (if there is)
    $paruj -S --noconfirm gotty-bin $backupPackages $PacmanCustomPackages >> $logFile


    #GoTTy - pts not accessable bug
    $sudovm chmod a+x -R /dev/pts
}
function installer(){
    ### Start of installation process
    unlink /tmp &>>$logFile
    mkdir $HOME/tmp &>>$logFile
    ln -sf /tmp $HOME/tmp &>>$logFile
    cd $HOME/tmp

    # Installing JuNest (Arch linux on Proot) [https://github.com/fsquillace/junest]
    git clone https://github.com/fsquillace/junest.git ~/.local/share/junest
    curl -LO --retry 69 https://dwa8bhj1f036z.cloudfront.net/junest/junest-x86_64.tar.gz
    bash $HOME/.local/share/junest/bin/junest setup -i junest-x86_64.tar.gz >>$logFile

    # Install required packages
    echo "installation-finished-success" > $HOME/.installstatus
    
}
function uninstall(){
    cd $HOME
    rm -rf .local/share/junest &>>$logFile
    rm -rf .junest &>>$logFile
    rm -rf .installstatus &>>$logFile
    rm -rf .bashrc &>>$logFile
    touch .bashrc
}
function reinstall(){
    uninstall
    installer
    exit
}

# Installation Status Checker

# SilentInstall
function silentInstall(){
clear
echo -e "
\033[38;2;23;147;209m        
                   ▄
                  ▟█▙
                 ▟███▙
                ▟█████▙
               ▟███████▙
              ▂▔▀▜██████▙
             ▟██▅▂▝▜█████▙
            ▟█████████████▙
           ▟███████████████▙
          ▟█████████████████▙
         ▟███████████████████▙
        ▟█████████▛▀▀▜████████▙
       ▟████████▛      ▜███████▙
      ▟█████████        ████████▙
     ▟██████████        █████▆▅▄▃▂
    ▟██████████▛        ▜█████████▙
   ▟██████▀▀▀              ▀▀██████▙
  ▟███▀▘                       ▝▀███▙
 ▟▛▀                               ▀▜▙
         RootlessArch Installer
"


echo -e "\e[32mWhile we're doing the hard work for you, you can have a break until the installation process finishes.\033[38;2;23;147;209m"

installer 2>>$logFile & PID=$! >>$logFile
# While process is running...
i=1
sp="/-\|"
echo ""
echo -n "Installing System...  "
while kill -0 $PID 2>> $logFile; do 
    printf "\b${sp:i++%${#sp}:1}"
    sleep 0.5
done
printf "\b Finished\n"

patchBugs 2>>$logFile & PID=$! >>$logFile
echo -n "Patching bugs...  "
while kill -0 $PID 2>> $logFile; do 
    printf "\b${sp:i++%${#sp}:1}"
    sleep 0.5
done
printf "\b Finished\n"

firstStartup 2>>$logFile & PID=$! >>$logFile
echo -n "Installing essensital system packages...  "
while kill -0 $PID 2>> $logFile; do 
    printf "\b${sp:i++%${#sp}:1}"
    sleep 0.5
done
printf "\b Finished\n"
echo -n "Installation finished! Rerun the script to start Arch Linux!"
}

### System update
function backupPackages(){
    sudovm="$HOME/.local/share/junest/bin/junest proot --fakeroot"
    backupPackages=$($sudovm paru -Qq)
}



function upgradeSys(){
clear
echo -e "
\033[38;2;23;147;209m        
                   ▄
                  ▟█▙
                 ▟███▙
                ▟█████▙
               ▟███████▙
              ▂▔▀▜██████▙
             ▟██▅▂▝▜█████▙
            ▟█████████████▙
           ▟███████████████▙
          ▟█████████████████▙
         ▟███████████████████▙
        ▟█████████▛▀▀▜████████▙
       ▟████████▛      ▜███████▙
      ▟█████████        ████████▙
     ▟██████████        █████▆▅▄▃▂
    ▟██████████▛        ▜█████████▙
   ▟██████▀▀▀              ▀▀██████▙
  ▟███▀▘                       ▝▀███▙
 ▟▛▀                               ▀▜▙
          RootlessArch Updater
"


i=1
sp="/-\|"

echo -e "\e[32mWhile we're doing the hard work for you, you can have a break until the installation process finishes.\033[38;2;23;147;209m"

backupPackages 2>>$logFile & PID=$! >>$logFile
echo -n "Backing up packages...  "
while kill -0 $PID 2>> $logFile; do 
    printf "\b${sp:i++%${#sp}:1}"
    sleep 0.5
done
printf "\b Finished\n"

uninstall 2>>$logFile & PID=$! >>$logFile
echo -n "Removing image...  "
while kill -0 $PID 2>> $logFile; do 
    printf "\b${sp:i++%${#sp}:1}"
    sleep 0.5
done
printf "\b Finished\n"

installer 2>>$logFile & PID=$! >>$logFile
echo -n "Reinstalling image...  "
while kill -0 $PID 2>> $logFile; do 
    printf "\b${sp:i++%${#sp}:1}"
    sleep 0.5
done
printf "\b Finished\n"

patchBugs 2>>$logFile & PID=$! >>$logFile
echo -n "Patching bugs...  "
while kill -0 $PID 2>> $logFile; do 
    printf "\b${sp:i++%${#sp}:1}"
    sleep 0.5
done
printf "\b Finished\n"

firstStartup 2>>$logFile & PID=$! >>$logFile
echo -n "Reinstalling system packages and backup packages...  "
while kill -0 $PID 2>> $logFile; do 
    printf "\b${sp:i++%${#sp}:1}"
    sleep 0.5
done
printf "\b Finished\n"
echo -n "Upgrade finished! Rerun the script to start Arch Linux!"
}

# Handling Arguments

case $1 in
    -v|--verbose)
        echo "" > $logFile
        installer
        patchBugs
        firstStartup
        exit
        ;;
    -d|--selfdestruct)
        uninstall
        echo "System has been uninstalled."
        exit
        ;;
    -s|--silentinstall)
        echo "" > $logFile
        checkInstaller
        exit
        ;;
    --upgrade)
        echo "" > $logFile
        upgradeSys
        exit
        ;;
    -*)
        printUsage
        ;;
esac

function checkInstaller(){
    if [ -f $HOME/.installstatus ]; then
        clear
        
        startArchLinux
    else
        silentInstall
    fi
            
}

echo "" > $logFile
checkInstaller