# ActiveState Stackato + VirtualBox install script

VERSION=0.0.5
RELEASE_DATE=2012-03-14

# Get OS type. Expect: linux or darwin or anything else
OS=$OSTYPE
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

function die {
    echo $1
    exit 1
}

function catch() {
    if [ $? -ne 0 ]; then
        die "Error: command failed"
    fi
}

function want_cmd() {
    CMD=$1
    bin=`which $CMD`
    if [ -z $bin ]; then die "Error: '$CMD' command required"; fi
}

function welcome() {
    echo
    echo "*** This is stackato-vbox-installer - version $VERSION - $RELEASE_DATE"
}

function verify() {
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

    want_cmd 'bash'
    want_cmd 'cat'
    want_cmd 'curl'
    want_cmd 'ifconfig'
    want_cmd 'perl'
    want_cmd 'rm'
    want_cmd 'sudo'
    want_cmd 'unzip'
    want_cmd 'which'

    if [ $OS == 'darwin' ]; then
        want_cmd 'hdiutil'
    fi

    # Extract the active network device name from ifconfig
    NET_DEVICE=`ifconfig | perl -e '$/="";for(<>){$d=${[split]}[0];if($d!~/^(lo|ppp0)/ and /inet (addr:)?(\S+)/){print $d;last}}'`
    if [ -z $NET_DEVICE ]; then
        die "Error: No network device seems to be active."
    fi
}

function reset_sudo() {
    sudo -k; catch
}

function install_vbox() {
    VBOXMANAGE=`which VBoxManage`
    if [ -z $VBOXMANAGE ]; then
        echo
        echo "*** Installing VirtualBox from Debian package"
        case $OS in
            linux)
                echo 'sudo apt-get install virtualbox'
                sudo apt-get install -y virtualbox; catch
                ;;
            darwin)
                echo "curl -L $VIRTUALBOX_DMG_URL > $VIRTUALBOX_DMG_FILE"
                curl -L $VIRTUALBOX_DMG_URL > $VIRTUALBOX_DMG_FILE; catch
                echo "hdiutil mount $VIRTUALBOX_DMG_FILE"
                hdiutil mount $VIRTUALBOX_DMG_FILE; catch
                echo 'sudo installer -pkg /Volumes/VirtualBox.mpkg -target "/Volumes/Macintosh HD"'
                sudo installer -pkg /Volumes/VirtualBox.mpkg -target "/Volumes/Macintosh HD"; catch
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

function config_network_device() {
    echo
    echo "*** Configure the Stackato VM"

    echo "$VBOXMANAGE modifyvm $VM_NAME --nic1 bridged"
    $VBOXMANAGE modifyvm $VM_NAME --nic1 bridged; catch

    echo "$VBOXMANAGE modifyvm $VM_NAME --bridgeadapter1 $NET_DEVICE"
    $VBOXMANAGE modifyvm $VM_NAME --bridgeadapter1 $NET_DEVICE; catch
}

function start_stackato_vm() {
    echo
    echo "*** Start the Stackato VM"
    echo "$VBOXMANAGE startvm $VM_NAME"

    $VBOXMANAGE startvm $VM_NAME; # catch
}

function success() {
    echo
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

welcome
verify
reset_sudo
install_vbox
download_stackato
unzip_stackato
import_stackato_vm
config_network_device
start_stackato_vm
success
