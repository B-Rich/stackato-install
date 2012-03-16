# ActiveState Stackato + VirtualBox install script

### WARNING WARNING WARNING WARNING WARNING
#
# This script uses sudo (to install VirtualBox if needed)
# You should read through this script before running it.
#
###

###
#
# Static variables:
#
###

VERSION=0.1.2
RELEASE_DATE=2012-03-15

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
# Define all the steps to perform in separate functions, then call them
# at the bottom of the script.
#
###

function welcome() {
    cat <<EOS

*** This is stackato-vbox-installer - version $VERSION - $RELEASE_DATE

EOS

    verify_os

    cat <<EOS
You will be asked for your password if VirtualBox needs to be installed.

Press <CTL>-c to quit now.

Full details available here:

    https://github.com/ActiveState/stackato-install#readme

EOS

    prompt "Press <CTL>-c to exit or press <ENTER> to continue..."
}

function verify_os() {
    if [ -z $BASH_VERSION ]; then
        echo "Error: this installer needs to be run by bash"
        exit 1
    fi

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

function verify_system() {
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
        need_cmd 'hdiutil'
        need_cmd 'installer'
        need_cmd 'vm_stat'
    else
        need_cmd 'free'
    fi

    # Extract the active network device name from ifconfig
    NET_DEVICE=`ifconfig | perl -e '$t=do{local$/;<>};@m=split/^(\S+)(?::|\s\s+)/m,$t;shift(@m);for($i=0;$i<@m;$i+=2){next if$m[$i]=~/^(lo|ppp)/;next unless$m[$i+1]=~/inet (addr:)?\d/;print$m[$i];last}'`
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
        prompt "Press <CTL>-c to exit or press <ENTER> to continue..."
    fi
}

function install_vbox() {
    VBOXMANAGE=`which VBoxManage`
    if [ -z $VBOXMANAGE ]; then
        sudo -k; catch
        echo
        case $OS in
            linux)
                echo "*** Installing VirtualBox from Debian package"
                echo 'sudo apt-get install virtualbox'
                sudo apt-get install -y virtualbox; catch
                ;;
            darwin)
                echo "*** Installing VirtualBox from virtualbox.org"
                echo "curl -L $VIRTUALBOX_DMG_URL > $VIRTUALBOX_DMG_FILE"
                curl -L $VIRTUALBOX_DMG_URL > $VIRTUALBOX_DMG_FILE; catch
                echo "hdiutil mount $VIRTUALBOX_DMG_FILE"
                hdiutil mount $VIRTUALBOX_DMG_FILE; catch
                echo 'sudo installer -pkg /Volumes/VirtualBox/VirtualBox.mpkg -target /Applications/'
                sudo installer -pkg /Volumes/VirtualBox/VirtualBox.mpkg -target /Applications/; catch
                echo "hdiutil unmount /Volumes/VirtualBox"
                hdiutil unmount /Volumes/VirtualBox; catch
                ;;
        esac

        VBOXMANAGE=`which VBoxManage`
    fi
}

function download_stackato() {
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

function unzip_stackato() {
    if [ ! -f $STACKATO_OVF_FILE ]; then
        echo
        echo "*** Unzipping Stackato zip file"
        echo "unzip $STACKATO_ZIP_FILE"
        unzip $STACKATO_ZIP_FILE; catch
    fi
}

function import_stackato_vm() {
    echo
    echo "*** Import Stackato VM file into VirtualBox"
    echo "$VBOXMANAGE import $STACKATO_OVF_FILE"

    $VBOXMANAGE import $STACKATO_OVF_FILE; catch

    # Extract the last VM name from the list. This seems to be the one that
    # was just imported.
    VM_NAME=`VBoxManage list vms | perl -0e '$_=<>;s/(?:.*\n)?"(.*?)".*/$1/s;print'`
    catch
}

function configure_stackato_vm() {
    echo
    echo "*** Configure the Stackato VM"

    echo "$VBOXMANAGE modifyvm $VM_NAME --nic1 bridged"
    $VBOXMANAGE modifyvm $VM_NAME --nic1 bridged; catch

    echo "$VBOXMANAGE modifyvm $VM_NAME --bridgeadapter1 $NET_DEVICE"
    $VBOXMANAGE modifyvm $VM_NAME --bridgeadapter1 $NET_DEVICE; catch

    echo "$VBOXMANAGE modifyvm $VM_NAME --memory $MEM_REQUIRED_MB"
    $VBOXMANAGE modifyvm $VM_NAME --memory $MEM_REQUIRED_MB; catch
}

function start_stackato_vm() {
    echo
    echo "*** Start the Stackato VM"
    echo "$VBOXMANAGE startvm $VM_NAME"

    $VBOXMANAGE startvm $VM_NAME; # catch
}

function success() {
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

function die {
    echo $1
    exit 1
}

function catch() {
    if [ $? -ne 0 ]; then
        die "Error: command failed"
    fi
}

function need_cmd() {
    CMD=$1
    bin=`which $CMD`
    if [ -z $bin ]; then die "Error: '$CMD' command required"; fi
}

function prompt() {
    # Open a file descriptor to terminal
    exec 5<> /dev/tty
    echo -n $1
    read <&5
    # Close the file descriptor
    exec 5>&-
}

# Check free mem on host and guess a number to use between 1-2GB
function get_mem_size() {
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
install_vbox
download_stackato
unzip_stackato
import_stackato_vm
configure_stackato_vm
start_stackato_vm
success
