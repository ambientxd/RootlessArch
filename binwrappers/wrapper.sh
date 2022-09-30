#!/bin/bash

# Configurations for custom usage.
InstallerFile="%INSTALLERFILE%"

# Running installer.sh
$InstallerFile --run "%COMMAND% $@"