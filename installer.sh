#!/bin/bash

# RootlessArch
# Copyright (C) 2022 ambientxd
# This program comes with ABSOLUTELY NO WARRANTY
# This is free software, and you are welcome to redistribute it
# under certain conditions

# This application is open source at https://github.com/ambientxd/RootlessArch

# Configuration for custom usage.
variablesDirectory="$HOME/.rla"
PacmanCustomPackages="" # Those packages gets pre-installed in the installation process.
filePath="$(pwd)/$(basename $0)" # Installer's file path
shellConfig="$HOME/.bashrc"
logFile="$variablesDirectory/logs/installer$RANDOM$RANDOM.log"


# Random essential variables
#backupPackages=""

if [ ! -f "$filePath" ]; then
    filePath=$0 # This was ran either by $PATH, or full.
fi

# Checks
checkIfInstalled(){
    isInstalled=false
    if [ -d "$variablesDirectory/linuximage/usr/bin" ]; then
        isInstalled=true
    fi
}

checkIfInstalled
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
echo "  $0 {-r   --run}: Runs a command (Example: bash $0 --run whoami)"
echo "  $0 {---create-wrappers | -cw (--to <DIR> --as <USER>)}: Creates wrappers for uses outside of RootlessArch (defaults to ~/.local/bin)"
echo ""
exit 0
}

function patchBugs(){
    cd $HOME/tmp
    git clone https://github.com/ambientxd/RootlessArch >> $logFile

    #GottyInstallation Config
    GottyInstallationoConfig_pkgver=1.4.0

    # Makepkg, Fakechroot and Fakeroot, and Gotty Installation
    cd $HOME/tmp/RootlessArch/patches
    chmod a+x makepkg
    chmod a+x fakechroot
    chmod a+x fakeroot

    homediresc="$variablesDirectory/linuximage"

    # Replacing variable $ROOTHOMEDIR in *files with the linuximage directory.
    sed -i "s+\$ROOTHOMEDIR+$homediresc+" makepkg
    sed -i "s+\$ROOTHOMEDIR+$homediresc+" fakechroot
    sed -i "s+\$ROOTHOMEDIR+$homediresc+" fakeroot
    sed -i "s+\$ROOTHOMEDIR+$homediresc+" pacman.conf

    chmod 755 makepkg
    chmod 755 fakechroot
    chmod 755 fakeroot

    cp makepkg fakechroot fakeroot $variablesDirectory/linuximage/usr/bin
    cp pacman.conf $variablesDirectory/linuximage/etc
    
    # Testing BubbleWrap
    bubblewrapTest=$($HOME/.local/share/junest/bin/junest ns --fakeroot whoami)
    if [ "$bubblewrapTest" == "root" ]; then
        touch $variablesDirectory/bubbleWrapEnabled
    fi

    # Global BashRC editing
    echo "export PS1='[\e[32m\$(whoami)\e[0m@\e[94mRootlessArch \e[35m\$(pwd)\e[0m]\$ '" >> $variablesDirectory/linuximage/etc/bash.bashrc
    echo "alias ls='ls --color=always'" >> $variablesDirectory/linuximage/etc/bash.bashrc
}
function firstStartup(){
    # Install required packages.
    sudovm="$HOME/.local/share/junest/bin/junest proot --fakeroot"
    $sudovm useradd $USER
    paruj="$sudovm runuser -u $USER -- paru"
    pacmanj="$sudovm pacman"
    $pacmanj -Syu --ignore base-devel --noconfirm
    $pacmanj -S --noconfirm neofetch tar gzip unzip which btop zstd man-db binutils make psmisc psutils iputils procps-ng
    $pacmanj -R yay --noconfirm #Broken package

    # Install Paru (AUR Helper) (Manually)
    PARU_VERSION="1.11.1"

    cd $HOME/tmp
    curl -LO https://github.com/Morganamilo/paru/releases/download/v$PARU_VERSION/paru-v$PARU_VERSION-x86_64.tar.zst
    $HOME/.local/share/junest/bin/junest proot --fakeroot tar -xvf $HOME/tmp/paru-v$PARU_VERSION-x86_64.tar.zst >> $logFile
    cp paru $variablesDirectory/linuximage/usr/bin/paru
    cp paru.conf $variablesDirectory/linuximage/etc/paru.conf

    cp man/paru.8 $variablesDirectory/linuximage/usr/share/man/man8/paru.8
    cp man/paru.conf.5 $variablesDirectory/linuximage/usr/share/man/man5/paru.conf.5

    cp completions/bash $variablesDirectory/linuximage/usr/share/bash-completion/completions/paru.bash
    cp completions/fish $variablesDirectory/linuximage/usr/share/fish/vendor_completions.d/paru.fish
    cp completions/zsh $variablesDirectory/linuximage/usr/share/zsh/site-functions/_paru

    # Gotty Quick Installation
    cd /tmp
    curl -LO https://github.com/sorenisanerd/gotty/releases/download/v1.5.0/gotty_v1.5.0_linux_amd64.tar.gz
    $sudoj tar -xvf gotty_linux_amd64.tar.gz
    cp gotty $variablesDirectory/linuximage/usr/bin

    #Gotty communication
    echo "#!/bin/bash" >> $variablesDirectory/linuximage/usr/bin/gottycom
    echo 'for x in $(ls /dev/pts); do' >> $variablesDirectory/linuximage/usr/bin/gottycom
    echo '  echo "$@" >> /dev/pts/$x' >> $variablesDirectory/linuximage/usr/bin/gottycom
    echo 'done' >> $variablesDirectory/linuximage/usr/bin/gottycom
    chmod a+x+w $variablesDirectory/linuximage/usr/bin/gottycom
}
function installer(){
    ### Start of installation process
    unlink /tmp &>>$logFile
    mkdir $HOME/tmp &>>$logFile
    ln -sf /tmp $HOME/tmp &>>$logFile
    cd $HOME/tmp

    # Installing JuNest (Arch linux on Proot) [https://github.com/fsquillace/junest]
    git clone https://github.com/fsquillace/junest.git ~/.local/share/junest
    bash $HOME/.local/share/junest/bin/junest setup >>$logFile
    
}
function uninstall(){
    cd $HOME
    rm -rf $variablesDirectory
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
echo -e "\033[38;2;23;147;209m"  
echo "                   ▄"
echo "                  ▟█▙"
echo "                 ▟███▙"
echo "                ▟█████▙"
echo "               ▟███████▙"
echo "              ▂▔▀▜██████▙"
echo "             ▟██▅▂▝▜█████▙"
echo "            ▟█████████████▙"
echo "           ▟███████████████▙"
echo "          ▟█████████████████▙"
echo "         ▟███████████████████▙"
echo "        ▟█████████▛▀▀▜████████▙"
echo "       ▟████████▛      ▜███████▙"
echo "      ▟█████████        ████████▙"
echo "     ▟██████████        █████▆▅▄▃▂"
echo "    ▟██████████▛        ▜█████████▙"
echo "   ▟██████▀▀▀              ▀▀██████▙"
echo "  ▟███▀▘                       ▝▀███▙"
echo " ▟▛▀                               ▀▜▙"
echo -e "\e[32m      RootlessArch is installing...\033[38;2;23;147;209m"

installer 2>>$logFile & PID=$! >>$logFile
# While process is running...
i=1
sp="|/-\\"
echo ""
echo -n "Downloading System...  "
while kill -0 $PID 2>> $logFile; do 
    printf "\b${sp:i++%${#sp}:1}"
    sleep 0.5
done
printf "\b\033[96m [Finished]\n\033[38;2;23;147;209m"

patchBugs 2>>$logFile & PID=$! >>$logFile
echo -n "Patching bugs...  "
while kill -0 $PID 2>> $logFile; do 
    printf "\b${sp:i++%${#sp}:1}"
    sleep 0.5
done
printf "\b\033[96m [Finished]\n\033[38;2;23;147;209m"

firstStartup 2>>$logFile & PID=$! >>$logFile
echo -ne "Installing essential system packages...  \e[0m"
sleep 1
clear
while kill -0 $PID 2>> $logFile; do 
    sleep 0.5
done
printf "\b\033[96m [Finished]\n\033[38;2;23;147;209m"
echo -n "\n\nInstallation finished! Rerun the script to start Arch Linux!\033[0m"
}

### System update
function backupPackages(){
    sudovm="$HOME/.local/share/junest/bin/junest proot --fakeroot"
    backupPackages=$($sudovm paru -Qq)
}

# Handling Arguments

function startArchLinux(){
    rm -rf $HOME/tmp/*

    # Selecting which configurations to use
    startjunest="$HOME/.local/share/junest/bin/junest proot --fakeroot"
    if [ -f $variablesDirectory/bubbleWrapEnabled ]; then
        startjunest="$HOME/.local/share/junest/bin/junest ns --fakeroot"
    fi

    if [ "$(whoami 2>/dev/null)" == "root" ]; then startjunest="$HOME/.local/share/junest/bin/junest root"; fi # Broken
    $startjunest $run
    exitCode=$!
        
}

function checkInstaller(){
    if [ $isInstalled == "true" ]; then
        clear
        
        echo "Welcome to Arch Linux!"
        startArchLinux
    else
        mkdir $variablesDirectory
        mkdir $variablesDirectory/logs
        silentInstall

        clear
        echo "Welcome to Arch Linux!"
        startArchLinux
    fi
            
}

# Wrappers creation
createWrappers(){
    echo "Downloading wrapper script..."
    curl -L https://raw.githubusercontent.com/ambientxd/RootlessArch/main/binwrappers/wrapper.sh -o /tmp/wrapper.sh

    echo "Copying files..."
    cp "$filePath" $variablesDirectory/wrapinstaller.sh # Make a installer.sh backup in case of movement or deletion.

    # Checking if user exists
    echo "Checking if user $wrapAs exist..."
    if [ "$(bash $0 --run runuser -u $wrapAs -- whoami)" != "$wrapAs" ]; then
        echo "User does not exist."
        exit
    fi
    # Getting files in WrappersDir
    filecws=$(ls $variablesDirectory/linuximage/usr/bin | wc -l)
    filecw=0

    for file in $(ls $variablesDirectory/linuximage/usr/bin); do
        cp /tmp/wrapper.sh $wrapperTo/$file
        sed -i "s+%COMMAND%+runuser -u ${wrapAs} -- $file+" $wrapperTo/$file 2>/dev/null
        sed -i "s+%INSTALLERFILE%+$variablesDirectory/wrapinstaller.sh+" $wrapperTo/$file 2>/dev/null
        chmod a+x $wrapperTo/$file
        echo -ne "\r\033[K($(printf %.2f%% "$((10**3 * 100 * $filecw/$filecws))e-3")) Created $wrapperTo/$file" 
        filecw=$(($filecw+1))
    done
    echo -ne "\r\033[K(100%) Wrappers creation completed."

    echo -e "\033[34m"  
    echo Wrappers have been created"!"
    echo
    echo To use these wrappers, type go to this directory:
    echo -e "\033[31mcd $wrapperTo"  
    echo -ne "\033[0m"
}
ROOTHOMEDIR="$variablesDirectory/linuximage"



# Export variables
export JUNEST_HOME="$variablesDirectory/linuximage"
export JUNEST_TEMPDIR="$HOME/tmp"

case $1 in
    -v|--verbose)
        echo "" > $logFile
        mkdir $variablesDirectory
        mkdir $variablesDirectory/logs
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
    -r|--run)
        shift
        run=$@
        startArchLinux
        exit
        ;;
    --create-wrappers|-cw)
        # Wrappers Configuration
        wrapperTo=$variablesDirectory/bin
        wrapAs=root
        shift
        
        # Arguments handler
        for i in $@; do
            case $1 in
                --to)
                    wrapperTo=$2
                    shift
                    shift
                    ;;
                
                --as)
                    wrapAs=$2
                    shift
                    shift
                    ;;
            esac
        done

        mkdir -p $wrapperTo
        echo "Creating wrappers to $wrapperTo (Wrapping as $wrapAs)"

        if [ ! -d "$wrapperTo" ]; then
            echo "WrapperDir doesn't exist."
            exit
        fi

        createWrappers
        exit
        ;;

    -*)
        printUsage
        ;;
esac

checkInstaller