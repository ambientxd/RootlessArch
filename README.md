# RootlessArch
Arch Linux, Rootlessly installed.

## Features
- Gotty, with Paru (AUR helper) preinstalled.
- Sudo for elevated privileges
- Essential Applications preinstalled
- Lightweight
- Custom installation / startup configurations

## Installation
```
curl -LO https://raw.githubusercontent.com/ambientxd/RootlessArch/main/installer.sh
bash installer.sh
```

Or, you can move it to /usr/bin if you want it to be executable for every user:
```
curl -LO https://raw.githubusercontent.com/ambientxd/RootlessArch/main/installer.sh
sudo mv installer.sh /usr/bin/rla
sudo chmod +x /usr/bin/rla  # You can run "rla" to install RootlessArch now!
```