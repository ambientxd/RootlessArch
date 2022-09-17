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
#backupPackages=""

# Startup settings
runGottyOnStartup=false # Replaces variable $run.
run="su $USER" # The command to run when started

## Gotty
gotty_command="gotty"
function runGottyCommand(){
    if [ "$GottyenableWritePermissions" == true ]; then
        gotty_command="$gotty_command -w"
    fi
    
    gotty_command="$gotty_command --timeout $GottyTimeout"

    gotty_command="$gotty_command --width $GottyWidth"
    gotty_command="$gotty_command --height $GottyHeight"

    gotty_command="$gotty_command --address $GottyAddress"
    gotty_command="$gotty_command --port $GottyPort"
    gotty_command="$gotty_command --max-connection $GottyMaxConnection"

    if [ "$GottyenableAuthentication" == true ]; then
        gotty_command="$gotty_command --credential $GottyAuthenticationUsername:$GottyAuthenticationPassword"
    fi
    
    gotty_command="$gotty_command $GottyCustomArgs"
    gotty_command="$gotty_command $GottyCommand"
}
GottyenableWritePermissions=true
GottyTimeout=0
GottyCommand="bash"

GottyWidth=0
GottyHeight=0

GottyAddress="0.0.0.0"
GottyPort=8080
GottyMaxConnection=0

# Gotty Authentication
GottyenableAuthentication=false
GottyAuthenticationUsername="admin" # Works if $GottyenableAuthentication is enabled, spaces are permitted.
GottyAuthenticationPassword="password"

# Gotty Custom Arguments
GottyCustomArgs=""
if [ "$runGottyOnStartup" == true ]; then
    runGottyCommand
    run="$gotty_command"
fi

function printUsage(){
echo "$0 - A part of RootlessArch"
echo ""
echo "Usage: $0 <arguments>"
echo "Options:"
echo "  $0 {-r    --reinstall}: Reinstall System"
echo "  $0 {-d --selfdestruct}: Uninstall RootlessArch"
echo "  $0 {-v      --verbose}: Install System (Verbose Mode)"
echo "  $0 {-r   --runcommand}: Runs a command (Example: bash $0 --runcommand whoami)"
echo ""
exit 0
}

function patchBugs(){
    cd $HOME/tmp
    git clone https://github.com/ambientxd/RootlessArch >> $logFile


    # Makepkg, Fakechroot and Fakeroot
    cd $HOME/tmp/RootlessArch/patches
    chmod a+x makepkg
    chmod a+x fakechroot
    chmod a+x fakeroot

    homediresc='\/home\/'"$USER"

    sed -i "s/\$ROOTHOMEDIR/$homediresc/" makepkg
    sed -i "s/\$ROOTHOMEDIR/$homediresc/" fakechroot
    sed -i "s/\$ROOTHOMEDIR/$homediresc/" fakeroot
    sed -i "s/\$ROOTHOMEDIR/$homediresc/" pacman.conf

    chmod 755 makepkg
    chmod 755 fakechroot
    chmod 755 fakeroot

    cp makepkg fakechroot fakeroot $HOME/.junest/usr/bin
    mv pacman.conf $HOME/.junest/etc
    
    # Testing BubbleWrap
    bubblewrapTest=$($HOME/.local/share/junest/bin/junest ns --fakeroot whoami)
    if [ "$bubblewrapTest" == "root" ]; then
        touch $HOME/rlavars/bubbleWrapEnabled
    fi
}
function firstStartup(){
    # Install required packages.
    export ROOTHOMEDIR=$HOME
    sudovm="$HOME/.local/share/junest/bin/junest proot --fakeroot"
    $sudovm useradd $USER
    paruj="$sudovm runuser -u $USER -- paru"
    pacmanj="$sudovm pacman"
    $pacmanj -Syu --ignore base-devel --noconfirm
    $pacmanj -S --noconfirm neofetch tar gzip unzip which btop zstd man-db binutils make psmisc psutils iputils procps-ng
    $pacmanj -R yay --noconfirm #Broken package

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

    # Install backed up packages (if there is) & Gotty
    $paruj -S --noconfirm gotty-bin $backupPackages $PacmanCustomPackages

    #Gotty communication
    echo "for x in $(ls /dev/pts); do if [ \$x != "ptmx" ]; then echo "\$@" >> /dev/pts/\$x; fi; done" >> $HOME/.junest/usr/bin/gottycom
    chmod a+x+w $HOME/.junest/usr/bin/gottycom
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
    echo "installation-finished-success" > $HOME/rlavars/installstatus
    
}
function uninstall(){
    cd $HOME
    rm -rf .local/share/junest &>>$logFile
    rm -rf .junest &>>$logFile
    rm -rf rlavars &>>$logFile
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
sp="|/-\\"
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
echo -ne "Installing essential system packages...  \e[0m"
while kill -0 $PID 2>> $logFile; do 
    sleep 0.5
done
printf "\033[38;2;23;147;209m\b Finished\n"
echo -n "Installation finished! Rerun the script to start Arch Linux!"
}

### System update
function backupPackages(){
    sudovm="$HOME/.local/share/junest/bin/junest proot --fakeroot"
    backupPackages=$($sudovm paru -Qq)
}

# Handling Arguments

case $1 in
    -v|--verbose)
        echo "" > $logFile
        mkdir $HOME/rlavars
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
        echo "Still in progress, sorry :)"
        exit
        ;;
    -*)
        printUsage
        ;;
esac

function startArchLinux(){
    rm -rf $HOME/tmp/*
    echo "Welcome to Arch Linux!"

    # Selecting which configurations to use
    startjunest="$HOME/.local/share/junest/bin/junest proot --fakeroot "
    if [ -f $HOME/rlavars/bubbleWrapEnabled ]; then
        startjunest="$HOME/.local/share/junest/bin/junest ns --fakeroot "
    fi
    $startjunest $run
    exitCode=$!
        
}

function checkInstaller(){
    if [ -f $HOME/rlavars/installstatus ]; then
        clear
        
        startArchLinux
    else
        mkdir $HOME/rlavars
        silentInstall
    fi
            
}

echo "" > $logFile
checkInstaller