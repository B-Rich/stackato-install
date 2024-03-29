# ActiveState Stackato + VirtualBox install script

### WARNING WARNING WARNING WARNING WARNING
#
# This script uses sudo (to install VirtualBox if needed)
# You should read through this script before running it.
#
###

if [ -z "$BASH" ]; then
    if [ ! -z "$-" ]; then
        opts="-$-"
    fi
    exec /usr/bin/env bash $opts "$0" "$@"
    echo "Error: this installer needs to be run by bash"
    echo "Unable to restart with bash shell"
    exit 1
fi

###
#
# Static variables:
#
###

VERSION=0.1.4
RELEASE_DATE=2012-03-22

# Get OS type. Expect: linux or darwin or something else
OS=$OSTYPE
if [ -z "$OS" ]; then OS="unknown"; fi
# Remove version from darwin10.0
OS=${OS/[0-9]*/}
# Remove -gnu from linux-gnu
OS=${OS/-*/}

STACKATO_URL=http://downloads.activestate.com/stackato/vm/v1.0.6/stackato-vm-vbox-v1.0.6.zip
STACKATO_ZIP_FILE=${STACKATO_URL/*\//}
STACKATO_OVF_FILE=Stackato-VM/Stackato-v1.0.6.ovf
STACKATO_LICENSE_FILE=StackatoMicroCloudLicenseAgreement.html

VIRTUALBOX_DMG_URL=http://download.virtualbox.org/virtualbox/4.1.10/VirtualBox-4.1.10-76795-OSX.dmg
VIRTUALBOX_DMG_FILE=${VIRTUALBOX_DMG_URL/*\//}

###
#
# Define all the steps to perform in separate functions, then call them at the
# bottom of the script.
#
###

welcome() {
    cat <<EOS

*** This is stackato-vbox-installer - version $VERSION - $RELEASE_DATE

EOS

    verify_os

    cat <<EOS

This script will automate the following things for you:

    * Download and Install Virtualbox (if not already installed)
    * Download the Stackato VM zipfile (if not already downloaded)
    * Unzip the Stackato VM (if not already unzipped)
    * Import the Stackato VM image into VirtualBox
    * Configure the VM to use bridged networking on you active network device
    * Set the VM to use an appropriate amount of RAM on your system
    * Start the newly installed/configured VM
    * Print a message of what to do next, and where to find more doc

You will be asked for your password if VirtualBox needs to be installed.

Full details available here:

    https://github.com/ActiveState/stackato-install#readme

EOS

    prompt
}

verify_os() {
    x=`type which`; catch
    if [ $OS != 'linux' ] && [ $OS != 'darwin' ]; then
        die "Error: this installer currently only runs on Debian Linux or OS X"
    fi
    if [ $OS == 'linux' ]; then
        APTGET=`which apt-get`
        if [ -z $APTGET ]; then
            die "Error: this installer currently only runs on Debian-style for Linux"
        fi
    fi
}

verify_system() {
    need_cmd 'bash'
    need_cmd 'cat'
    need_cmd 'curl'
    need_cmd 'ifconfig'
    need_cmd 'perl'
    need_cmd 'rm'
    need_cmd 'sudo'
    need_cmd 'unzip'
    need_cmd 'which'

    if [ $OS == 'darwin' ]; then
        need_cmd 'grep'
        need_cmd 'hdiutil'
        need_cmd 'installer'
        need_cmd 'vm_stat'
        need_cmd 'wc'
    else
        need_cmd 'free'
    fi

    # Extract the active network device name from ifconfig
    NET_DEVICE=`ifconfig | perl -e '$t=do{local$/;<>};@m=split/^(\S+)(?::|\s\s+)/m,$t;shift(@m);%m=@m;for$k(sort keys%m){next if$k=~/^(lo|ppp|vmnet)/;next unless$m{$k}=~/inet (addr:)?\d/;print$k;last}'`
    if [ -z $NET_DEVICE ]; then
        die "Error: No network device seems to be active."
    fi

    # Get memory requirement and make sure host has it
    get_mem_size
    if [[ $MEM_REQUIRED_MB -gt $MEM_FREE_MB ]]; then
        cat <<EOS

*** WARNING WARNING WARNING

${MEM_REQUIRED_MB}MB free memory required, ${MEM_FREE_MB}MB available."

Starting Stackato in this state may cause your host to run out of memory
and become unresponsive. :-(

EOS
        prompt
    fi
}

check_for_other_hypervisors() {
    if [ $OS == "darwin" ]; then
        INSTALLED=`ls -l /Applications/ | grep -i vmware | wc -l`
        RUNNING=`ps -eaf | grep -i vmware | grep app | wc -l`
        if [ $RUNNING != '0' ]; then
            cat <<EOS

*** WARNING WARNING WARNING

You appear to be running a VMware hypervisor program. This script wants to run
VirtualBox. Running these two programs together has been known to cause a
system crash in some cases. You may wish to cancel this script and stop your
other VM software. Then you can run this script again.

EOS
            prompt
        elif [ $INSTALLED != '0' ]; then
            cat <<EOS

*** WARNING WARNING WARNING

You appear to have a VMware product installed (but not running).  Note that
this script is trying to start a VirtualBox VM. These two programs are known
to sometimes cause a system crash when run together. Be sure to not run
VMware, whilst running VirtualBox (unless you really know what you are doing).

EOS
            prompt
        fi
    fi
}

install_vbox() {
    VBOXMANAGE=`which VBoxManage`
    if [ -z $VBOXMANAGE ]; then
        sudo -k; catch
        echo
        case $OS in
            linux)
                echo "*** Installing VirtualBox from Debian package"
                if [ `apt-cache search virtualbox | grep -i '^virtualbox ' | wc -l` == '1' ]; then
                    PKG=virtualbox
                elif [ `apt-cache search virtualbox-ose | grep -i '^virtualbox-ose ' | wc -l` == '1' ]; then
                    PKG=virtualbox-ose
                else
                    echo "Can't find a virtualbox debian package."
                    die "Try installing VirtualBox yourself and then run this again."
                fi
                echo "sudo apt-get install -y $PKG"
                sudo apt-get install -y $PKG; catch
                ;;
            darwin)
                echo "*** Installing VirtualBox from virtualbox.org"
                echo "curl -L $VIRTUALBOX_DMG_URL > $VIRTUALBOX_DMG_FILE"
                curl -L $VIRTUALBOX_DMG_URL > $VIRTUALBOX_DMG_FILE; catch
                echo "hdiutil mount $VIRTUALBOX_DMG_FILE"
                hdiutil mount $VIRTUALBOX_DMG_FILE; catch
                echo 'sudo installer -pkg /Volumes/VirtualBox/VirtualBox.mpkg -target /'
                sudo installer -pkg /Volumes/VirtualBox/VirtualBox.mpkg -target /; catch
                echo "hdiutil unmount /Volumes/VirtualBox"
                hdiutil unmount /Volumes/VirtualBox; catch
                ;;
        esac

        VBOXMANAGE=`which VBoxManage`
    fi
}

download_stackato() {
    if [ -f $STACKATO_LICENSE_FILE ]; then
        rm $STACKATO_LICENSE_FILE
    fi
    if [ ! -f $STACKATO_ZIP_FILE ]; then
        echo
        echo "*** Downloading Stackato-for-VirtualBox zip file"
        echo "curl -L $STACKATO_URL > $STACKATO_ZIP_FILE"
        curl -L $STACKATO_URL > $STACKATO_ZIP_FILE; catch
    fi
}

unzip_stackato() {
    if [ ! -f $STACKATO_OVF_FILE ]; then
        echo
        echo "*** Unzipping Stackato zip file"
        echo "unzip $STACKATO_ZIP_FILE"
        unzip $STACKATO_ZIP_FILE; catch
    fi
}

import_stackato_vm() {
    echo
    echo "*** Import Stackato VM file into VirtualBox"
    echo "$VBOXMANAGE import $STACKATO_OVF_FILE"

    $VBOXMANAGE import $STACKATO_OVF_FILE; catch

    # Extract the last VM name from the list. This seems to be the one that
    # was just imported.
    VM_NAME=`VBoxManage list vms | perl -0e '$_=<>;s/(?:.*\n)?"(.*?)".*/$1/s;print'`
    catch
}

configure_stackato_vm() {
    echo
    echo "*** Configure the Stackato VM"

    echo "$VBOXMANAGE modifyvm $VM_NAME --nic1 bridged"
    $VBOXMANAGE modifyvm $VM_NAME --nic1 bridged; catch

    echo "$VBOXMANAGE modifyvm $VM_NAME --bridgeadapter1 $NET_DEVICE"
    $VBOXMANAGE modifyvm $VM_NAME --bridgeadapter1 $NET_DEVICE; catch

    echo "$VBOXMANAGE modifyvm $VM_NAME --memory $MEM_REQUIRED_MB"
    $VBOXMANAGE modifyvm $VM_NAME --memory $MEM_REQUIRED_MB; catch
}

start_stackato_vm() {
    echo
    echo "*** Start the Stackato VM"
    echo "$VBOXMANAGE startvm $VM_NAME"

    $VBOXMANAGE startvm $VM_NAME; # catch
}

success() {
    cat <<EOS

Everything seems to have worked. You should now see a VirtualBox VM booting.
Watch the console screen and wait for the boot to finish. It may take several
minutes. When it is done the console screen should have a url like:

    https://stackato-XXXX.local

Load that url in a browser. You should see a Stackato web management console.
From this console you can control and monitor almost every aspect of your new
VM.

Your next steps will be:

  * Fill out the setup screen
  * Go to the App Store tab
  * Install some interesting Apps
  * ♥ Stackato

Enjoy!

PS For more help getting started, look here:

    http://bit.ly/stackato-microcloud-getting-started

EOS
}

###
#
# Helper functions
#
###

die() {
    echo $1
    exit 1
}

catch() {
    if [ $? -ne 0 ]; then
        die "Error: command failed"
    fi
}

need_cmd() {
    CMD=$1
    bin=`which $CMD`
    if [ -z $bin ]; then die "Error: '$CMD' command required"; fi
}

prompt() {
    # Open a file descriptor to terminal
    exec 5<> /dev/tty
    echo -n "Press <CTL>-c to exit or press <ENTER> to continue..."
    read <&5
    # Close the file descriptor
    exec 5>&-
}

# Check free mem on host and guess a number to use between 1-2GB
get_mem_size() {
    case $OS in
        linux)
            MEM_FREE_MB=`free -m | perl -0e '($t=<>)=~s/.*?buffers\/cache:\s+\S+\s+(\S+).*/$1/s;print$1'`
            ;;
        darwin)
            MEM_FREE_MB=`vm_stat | perl -0e '($t=<>)=~/(\d+)\s+bytes.*Pages free:\s+(\d+).*Pages active:\s+(\d+)/s or die; print($1*($2+$3)/1024)'`
            ;;
    esac
    MEM_FREE_MB=$((MEM_FREE_MB/10*8))
    if [[ $MEM_FREE_MB -gt 2048 ]]; then
        MEM_REQUIRED_MB=2048
    elif [[ $MEM_FREE_MB -lt 1024 ]]; then
        MEM_REQUIRED_MB=1024
    else
        MEM_REQUIRED_MB=$MEM_FREE_MB
    fi
}

###
#
# These are the calls to the high level functions performed by this script:
#
###

welcome
verify_system
check_for_other_hypervisors
install_vbox
download_stackato
unzip_stackato
import_stackato_vm
configure_stackato_vm
start_stackato_vm
success
