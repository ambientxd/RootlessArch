#!/bin/bash

# Configurations for custom usage.
InstallerFile="%INSTALLERFILE%"
CustomArgs=""

# Running installer.sh
bash $InstallerFile --run "%COMMAND%" $CustomArgs$@