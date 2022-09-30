#!/bin/bash

# Configurations for custom usage.
InstallerFile="%INSTALLERFILE%"

# Running installer.sh
$(basename $InstallerFile) --run "%COMMAND% $@"