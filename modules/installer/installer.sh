#! @runtimeShell@
# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
clear
cat <<"EOF"
             ,---,
           ,--.' |                 .--.,
           |  |  :               ,--.'  \
  ,----._,.:  :  :               |  | /\/
 /   /  ' /:  |  |,--.  ,--.--.  :  : :
|   :     ||  :  '   | /       \ :  | |-,
|   | .\  .|  |   /' :.--.  .-. ||  : :/|
.   ; ';  |'  :  | | | \__\/: . .|  |  .'
'   .   . ||  |  ' | : ," .--.; |'  : '
 `---`-'| ||  :  :_:,'/  /  ,.  ||  | |
 .'__/\_: ||  | ,'   ;  :   .'   \  : \
 |   :    :`--''     |  ,     .-./  |,'
  \   \  /            `--`---'   `--'
   `--`-'
EOF

echo "Welcome to ghaf installer!"
echo "To install image choose path to the device on which image will be installed."

read -p "Device path [e.g. /dev/sda]: " DEVICE_PATH
echo "Starting flushing..."

if sudo dd if=@systemImgDrv@ of=$DEVICE_PATH conv=sync bs=4K status=progress; then
    sync
    echo "Flushing finished successfully!"
    echo "Now you can detach installation device and reboot to ghaf."
else
    echo "Some error occured during flushing process, exit code: $?."
fi

sleep 1
shutdown -r
