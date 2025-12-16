#!/usr/bin/env bash
#------------------------------------------------------------------------------
# Some Synology NAS and Expansion Units do not have enough power to spin-up
# multiple Seagate's 20TB and larger drives during boot-up.
#
# This script uses Seagate's openSeaChest to set your 16TB and larger Seagate
# Exos and Ironwolf Pro HDDs to stagger their spin-up and enables lowCurrentSpinup.
#
# Power-Up in Standby (PUIS):
# PUIS ensures that drives remain in standby mode during system startup and only spin up when accessed.
#
# Low Current Spin-Up:
# This feature reduces the power draw during spin-up by starting the drives more gradually.
#
# Github: https://github.com/007revad/Seagate_lowCurrentSpinup
# Script verified at https://www.shellcheck.net/
#
# Run in a shell with sudo (replace /volume1/scripts/ with path to script):
# sudo -s /volume1/scripts/seagate_lowcurrentspinup.sh
#
# To disable PUIS and lowCurrentSpinup
# sudo -s /volume1/scripts/seagate_lowcurrentspinup.sh disable
#
# https://github.com/Seagate/openSeaChest
# https://www.perplexity.ai/search/my-synology-1821-wont-start-up-DCEWq2y5TvO4WoUsFli_sw
#------------------------------------------------------------------------------

# openSeaChest version variables
vSeaChest=v24.08.1
archive=openSeaChest-v24.08.1-linux-x86_64-portable

scriptver="v1.0.1"
script=Seagate_lowCurrentSpinup
#repo="007revad/Seagate_lowCurrentSpinup"
#scriptname=seagate_lowcurrentspinup

# Show script version
echo "$script $scriptver"

# Check script is running as root
if [[ $( whoami ) != "root" ]]; then
    echo -e "\nERROR This script must be run as sudo or root!\n"
    exit 1
fi

if [[ $1 == "disable" ]]; then
    disable="yes"
fi


# shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
# shellcheck disable=SC2329  # Don't warn about This function is never invoked.
pause(){ 
    # When debugging insert pause command where needed
    read -s -r -n 1 -p "Press any key to continue..."
    read -r -t 0.1 -s -e --  # Silently consume all input
    stty echo echok  # Ensure read didn't disable echoing user input
    echo -e "\n"
}

# Download openSeaChest portable if needed
if [[ ! -f /opt/openSeaChest_PowerControl ]] || [[ ! -f /opt/openSeaChest_Configure ]]; then
    if [[ ! -f "/tmp/${archive}.tar.xz" ]]; then
        echo -e "\nDownloading openSeaChest portable from Seagate"
        wget -P /tmp/ https://github.com/Seagate/openSeaChest/releases/download/"${vSeaChest:?}/${archive:?}".tar.xz &>/dev/null
    fi
fi

# Extract openSeaChest_PowerControl to /tmp if needed
if [[ ! -d "/tmp/${archive:?}" ]] && [[ -f "/tmp/${archive}.tar.xz" ]]; then
    echo -e "\nExtracting openSeaChest archive"
    tar -xf "/tmp/${archive}.tar.xz" -C /tmp

    # Delete downloaded archive
    rm "/tmp/${archive}.tar.xz"
    echo
fi


# Create /opt if needed
if [[ ! -d /opt ]]; then
    if mkdir /opt; then
        chown root:root /opt
        chmod 711 /opt
    else
        echo -e "ERROR Failed to create /opt !"
        exit 1
    fi
fi

# Copy openSeaChest_PowerControl to /opt if needed
if [[ ! -f /opt/openSeaChest_PowerControl ]]; then
    if cp /tmp/"${archive:?}"/openSeaChest_PowerControl /opt/openSeaChest_PowerControl; then
        # openSeaChest/releases/download/v24.08.1 needs owner:group set
        chown root:root /opt/openSeaChest_PowerControl
        chmod 755 /opt/openSeaChest_PowerControl
    else
        echo -e "ERROR Failed to copy openSeaChest_PowerControl to /opt !"
        exit 1
    fi    
fi

# Copy openSeaChest_Configure to /opt if needed
if [[ ! -f /opt/openSeaChest_Configure ]]; then
    if cp /tmp/"${archive:?}"/openSeaChest_Configure /opt/openSeaChest_Configure; then
        # openSeaChest/releases/download/v24.08.1 needs owner:group set
        chown root:root /opt/openSeaChest_Configure
        chmod 755 /opt/openSeaChest_Configure
    else
        echo -e "ERROR Failed to copy openSeaChest_Configure to /opt !"
        exit 1
    fi    
fi

# Delete tmp extracted archive directory
if [[ ! -d "/tmp/${archive:?}" ]]; then
    rm -rf "/tmp/${archive:?}"
fi


set_puis(){ 
    # Set Power Up In Standby
    #--------------------------------------------------------------------------
    # --puisFeature [ info | spinup | enable | disable ]  (SATA Only)
    #         Use this option to enable or disable the power up in standby (PUIS) feature on SATA drives.
    #         Arguments:
    #             info    - display information about the PUIS support on the device
    #             spinup  - issue the PUIS spinup set features command to spin up the device to active/idle state.
    #             enable  - enable the PUIS feature using setfeatures command
    #             disable - disable the PUIS feature using setfeatures command
    #         Note: Not all products support this feature.
    #--------------------------------------------------------------------------
    # Check if PUIS is supported
    if ! /opt/openSeaChest_PowerControl -d "$sg" --puisFeature info | grep -q 'PUIS is supported'; then
        /opt/openSeaChest_PowerControl -d "$sg" --puisFeature info | tail +9
    else
        if [[ $disable == "yes" ]]; then
            # Disable PUIS
            /opt/openSeaChest_PowerControl -d "$sg" --puisFeature disable | tail +9 | head -n -1
        else
            # Enable PUIS
            /opt/openSeaChest_PowerControl -d "$sg" --puisFeature enable | tail +9 | head -n -1
        fi
    fi
}

set_lcs(){ 
    # Set lowCurrentSpinup
    #--------------------------------------------------------------------------
    # --lowCurrentSpinup [ low | ultra | disable ]  (SATA Only) (Seagate Only)
    #         Use this option to set the state of the low current spinup feature on Seagate SATA drives.
    #         When this setting is enabled for low or ultra low mode,
    #         the drive will take longer to spinup and become ready.
    #         Note: This feature is not available on every drive.
    #         Note: Some products will support low, but not the ultra low current spinup mode.
    #--------------------------------------------------------------------------
    if [[ $disable == "yes" ]]; then
        /opt/openSeaChest_Configure -d "$sg" --lowCurrentSpinup disable | tail +11
    else
        /opt/openSeaChest_Configure -d "$sg" --lowCurrentSpinup low | tail +11
    fi
}


# Process SATA Seagate HDDs larger than 16TB
IFS=$'\n' read -r -d '' -a array < <(/opt/openSeaChest_PowerControl --scan |\
    # Only Seagate SATA drives support PUIS
    #grep -E '^ATA.*ST[2-4][0,9][0]{3,}')  # All Seagate 20TB and larger drives
    #grep -E '^ATA.*ST[1-4][0-9][0]{3,}NT')  # All Seagate Exos and Ironwolf Pro drives 10TB and larger
    grep -E '^ATA.*ST(1[68]|[23][02468])[0]{3,}NT')  # All Seagate Exos and Ironwolf Pro 16TB to 38TB

    #grep -E '^ATA.*ST[1-4][0-9][0]{3,}')  # debug with smaller Seagate Ironwolf drives
IFS=

if [[ "${#array[@]}" -gt "0" ]]; then
    if [[ $disable == "yes" ]]; then
        echo -e "Disabling 'Enable Power-Up in Standby' and 'Low Current Spin-up'\n"
    else
        echo -e "Enabling 'Enable Power-Up in Standby' and 'Low Current Spin-up'\n"
    fi
    for drive in "${array[@]}"; do
        #echo "$drive" | awk '{print $3, $4}'  # debug
        sg=$(echo "$drive" | awk '{print $2}')
#        /opt/openSeaChest_PowerControl -d "$sg" --puisFeature enable

        # PUIS info
#        /opt/openSeaChest_PowerControl -d "$sg" --puisFeature info | tail +9
        #echo

        set_puis
        set_lcs

    done
else
    echo -e "\nNo Seagate Exos or Ironwolf Pro 16TB to 38TB HDDs found.\n"
fi
