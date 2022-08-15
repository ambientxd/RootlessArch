#!/bin/bash

# RootlessArch
# Copyright (C) 2022 ambientxd
# This program comes with ABSOLUTELY NO WARRANTY
# This is free software, and you are welcome to redistribute it
# under certain conditions


# Configuration for custom usage.
PacmanCustomPackages="" # Those packages gets pre-installed in the installation process.
filePath="$(pwd)/$0" # Installer's file path
shellConfig="$HOME/.bashrc"

#Files
sudoPatch="
#!/bin/bash\n
for opt in \"\$@\"\n
do\n
    case \"\$1\" in\n
        --) shift ; break ;;\n
        -*) shift ;;\n
        *) break ;;\n
    esac\n
done\n
\n
export FAKEROOTDONTTRYCHOWN=true\n
if [[ -n \"\${@}\" ]]\n
then\n
  if [[ \$FAKECHROOT == true ]]\n
  then\n
      fakechrootcmd=\"\"\n
  else\n
      fakechrootcmd=\"fakechroot --lib $HOME/.junest/lib/libfakeroot/fakechroot/libfakechroot.so\"\n
  fi\n
\n
  if [[ -n \$FAKED_MODE ]]\n
  then\n
      fakerootcmd=\"\"\n
  else\n
      fakerootcmd=\"/usr/bin/fakeroot --lib $HOME/.junest/lib/libfakeroot/libfakeroot.so\"\n
  fi\n
\n
  \$fakechrootcmd \$fakerootcmd \"\${@}\"\n
fi
"


function printUsage(){
echo "$0 - A part of RootlessArch"
echo ""
echo "Usage: $0 <arguments>"
echo "Options:"
echo "  $0 {-r --reinstall}: Reinstall System"
echo "  $0 {-u --selfdestruct}: Uninstall rootlessArch"
echo "  $0 {-v --verbose}: Install System (Verbose Mode)"
exit 0
}



function startArchLinux(){
    rm -rf $HOME/tmp/*
    bash $HOME/.local/share/junest/bin/junest proot --fakeroot export ROOTHOMEDIR=$HOME \&\& \$SHELL
}

function patchBugs(){
    cd $HOME/tmp
    git clone https://github.com/ambientxd/RootlessArch >/dev/null


    # Makepkg, Fakechroot and Fakeroot
    cd $HOME/tmp/RootlessArch/patches
    cp makepkg fakechroot fakeroot $HOME/.junest/usr/bin


    # Pacman
    cp mirrorlist $HOME/.junest/etc/pacman.d/mirrorlist
    echo "[options]" >> $HOME/.junest/etc/pacman.conf
    echo "RootDir     = $HOME/.junest" >> $HOME/.junest/etc/pacman.conf

    # Docker Systemctl Replacement
    curl -LO https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl3.py 
    cp systemctl3.py $HOME/.junest/bin/systemctl
    cp systemctl3.py $HOME/.junest/usr/bin/systemctl
    
}
function firstStartup(){
    # Install required packages.
    sudovm="$HOME/.local/share/junest/bin/junest proot --fakeroot"
    pacmanj="$sudovm pacman"
    $pacmanj -Syu --ignore base-devel --noconfirm >/dev/null
    $pacmanj -S --noconfirm neofetch nano python tar gzip unzip which btop zstd man-db $PacmanCustomPackages >/dev/null
    $pacmanj -R yay --noconfirm &>/dev/null #Broken package

    # Install Paru (AUR Helper)
    PARU_VERSION="1.11.1"

    cd $HOME/tmp
    curl -LO https://github.com/Morganamilo/paru/releases/download/v$PARU_VERSION/paru-v$PARU_VERSION-x86_64.tar.zst
    $HOME/.local/share/junest/bin/junest proot --fakeroot tar -xvf $HOME/tmp/paru-v$PARU_VERSION-x86_64.tar.zst >/dev/null
    cp paru $HOME/.junest/usr/bin/paru
    cp paru.conf $HOME/.junest/etc/paru.conf

    cp man/paru.8 $HOME/.junest/usr/share/man/man8/paru.8
    cp man/paru.conf.5 $HOME/.junest/usr/share/man/man5/paru.conf.5

    cp completions/bash $HOME/.junest/usr/share/bash-completion/completions/paru.bash
    cp completions/fish $HOME/.junest/usr/share/fish/vendor_completions.d/paru.fish
    cp completions/zsh $HOME/.junest/usr/share/zsh/site-functions/_paru


    #GoTTy
}
function installer(){
    ### Start of installation process
    unlink /tmp &>/dev/null
    mkdir $HOME/tmp &>/dev/null
    ln -sf /tmp $HOME/tmp &>/dev/null
    cd $HOME/tmp

    # Installing JuNest (Arch linux on Proot) [https://github.com/fsquillace/junest]
    git clone https://github.com/fsquillace/junest.git ~/.local/share/junest
    curl -LO --retry 69 https://dwa8bhj1f036z.cloudfront.net/junest/junest-x86_64.tar.gz
    bash $HOME/.local/share/junest/bin/junest setup -i junest-x86_64.tar.gz >/dev/null

    # Install required packages
    echo "installation-finished-success" > $HOME/.installstatus
    
}
function uninstall(){
    cd $HOME
    rm -rf .local/share/junest &>/dev/null
    rm -rf .junest &>/dev/null
    rm -rf .installstatus &>/dev/null
    rm -rf .bashrc &>/dev/null
    touch .bashrc
    echo "System has been uninstalled."
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
         RootlessArch installer
"


echo -e "\e[32mWhile we're doing the hard work for you, you can have a break until the installation process finishes.\033[38;2;23;147;209m"

installer 2>/dev/null & PID=$! >/dev/null
# While process is running...
i=1
sp="/-\|"
echo ""
echo -n "Installing System...  "
while kill -0 $PID 2> /dev/null; do 
    printf "\b${sp:i++%${#sp}:1}"
    sleep 0.5
done
printf "\b Finished\n"

patchBugs 2>/dev/null & PID=$! >/dev/null
echo -n "Patching bugs...  "
while kill -0 $PID 2> /dev/null; do 
    printf "\b${sp:i++%${#sp}:1}"
    sleep 0.5
done
printf "\b Finished\n"

firstStartup 2>/dev/null & PID=$! >/dev/null
echo -n "Installing essensital system packages...  "
while kill -0 $PID 2> /dev/null; do 
    printf "\b${sp:i++%${#sp}:1}"
    sleep 0.5
done
printf "\b Finished\n"
echo -n "Installation finished! Rerun the script to start Arch Linux!"
}

# Handling Arguments

case $1 in
    -v|--verbose)
        installer
        patchBugs
        firstStartup
        exit
        ;;
    -u|--selfdestruct)
        uninstall
        exit
        ;;
    -s|--silentinstall)
        silentInstall
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

checkInstaller