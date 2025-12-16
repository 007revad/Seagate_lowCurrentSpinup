# Seagate Low Current Spinup

<a href="https://github.com/007revad/Seagate_lowCurrentSpinup/releases"><img src="https://img.shields.io/github/release/007revad/Seagate_lowCurrentSpinup.svg"></a>
![Badge](https://hitscounter.dev/api/hit?url=https%3A%2F%2Fgithub.com%2F007revad%2FSeagate_lowCurrentSpinup&label=Visitors&icon=github&color=%23198754&message=&style=flat&tz=Australia%2FSydney)
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/paypalme/007revad)
[![](https://img.shields.io/static/v1?label=Sponsor&message=%E2%9D%A4&logo=GitHub&color=%23fe8e86)](https://github.com/sponsors/007revad)
<!-- [![committers.top badge](https://user-badge.committers.top/australia/007revad.svg)](https://user-badge.committers.top/australia/007revad) -->

### Description

Some Synology NAS and Expansion Units do not have enough power to spin-up multiple Seagate large Exos drives during boot-up.

This script avoids the need to buy and install a higher wattage power supply.

It uses Seagate's openSeaChest v24.08.1 to set your Seagate Exos SATA HDDs to stagger their spin-up (PUIS) and enables lowCurrentSpinup.

    Power-Up in Standby (PUIS):
    PUIS ensures that drives remain in standby mode during system startup and only spin up when accessed
    
    Low Current Spin-Up:
    This feature reduces the power draw during spin-up by starting the drives more gradually

**NOTE:** After running the script you will need to reboot.

### Download the script

1. Download the latest version _Source code (zip)_ from https://github.com/007revad/Seagate_lowCurrentSpinup/releases
2. Save the download zip file to a folder on the Synology.
3. Unzip the zip file.

### To run the script via task scheduler

See [How to run from task scheduler](https://github.com/007revad/Seagate_lowCurrentSpinup/blob/main/how_to_run_from_scheduler.md)

### To run the script via SSH

[How to enable SSH and login to DSM via SSH](https://kb.synology.com/en-global/DSM/tutorial/How_to_login_to_DSM_with_root_permission_via_SSH_Telnet)

```YAML
sudo -s /volume1/scripts/seagate_lowcurrentspinup.sh
```

If you want to change the drives' settings back run the script with the disable option:

```YAML
sudo -s /volume1/scripts/seagate_lowcurrentspinup.sh disable
```

**Note:** Replace /volume1/scripts/ with the path to where the script is located.

### Troubleshooting

If the script won't run check the following:

1. Make sure you download the zip file and unzipped it to a folder on your Synology (not on your computer).
2. If the path to the script contains any spaces you need to enclose the path/scriptname in double quotes:
   ```YAML
   sudo -s "/volume1/my scripts/seagate_lowcurrentspinup.sh"
   ```
3. Make sure you unpacked the zip or rar file that you downloaded and are trying to run the seagate_lowcurrentspinup.sh file.
4. Set the script file as executable:
   ```YAML
   sudo chmod +x "/volume1/scripts/seagate_lowcurrentspinup.sh"
   ```

### Screenshots

<p align="center">Enabling PUIS and Low Power Spinup</p>
<p align="center"><img src="/images/enable.png"></p>

<br>

<p align="center">Disabling PUIS and Low Power Spinup</p>
<p align="center"><img src="/images/disable.png"></p>
