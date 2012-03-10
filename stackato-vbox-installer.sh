# check system requirements
# clear sudo password
# make sure virtualbox is installed
# download stackato
# unzip stackato
# import stackato
# determine network device
# set networking on vm
# start vm
# print instructions to start web console

VERSION=0.0.1
RELEASE_DATE=2012-03-08
STACKATO_URL=http://downloads.activestate.com/stackato/vm/v1.0.4/stackato-vm-vbox-v1.0.4.zip
STACKATO_ZIP_FILE=stackato-vm-vbox-v1.0.4.zip
STACKATO_OVF_FILE=Stackato-VM/Stackato-v1.0.4.ovf

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
    echo "This is stackato-vbox-installer - version $VERSION - $RELEASE_DATE"
}

function verify() {
    if [ -z $STACKATO_VBOX_TEST ]; then
        echo
        echo "O NOES! This script is still in development. Stay tuned..."
        echo
        echo "Follow progress here: https://github.com/ActiveState/stackato-vbox-installer"
        exit 1
    else
        cd
    fi

    if [ -z $BASH_VERSION ]; then echo "Error: this installer needs to be run by bash"; exit 1; fi

    x=`type which`;catch
    APTGET=`which apt-get`
    if [ -z $APTGET ]; then die "Error: this installer only runs on Debian Linux currently"; fi

    want_cmd 'sudo'
    want_cmd 'wget'
    want_cmd 'unzip'

    NET_DEVICE=`ifconfig | perl -e '$/="";for(<>){print ${[split]}[0] if /inet addr:(\S+)/ and $1 !~ /^127/}'`
    if [ -z $NET_DEVICE ]; then die "Error: No network device seems to be active."; fi

    VBOX=`which virtualbox`
    VBOXMANAGE=`which VBoxManage`
}

function reset_sudo() {
    sudo -k; catch
}

function install_vbox() {
    if [ -z $VBOX ]; then
        sudo apt-get virtualbox; catch
    else
        if [ -z $VBOXMANAGE ]; then
            echo "Error: VirtualBox installed but VBoxManage not installed"
            exit 1
        fi
    fi
}

function download_stackato() {
    if [ ! -f $STACKATO_ZIP_FILE ]; then
        wget $STACKATO_URL; catch
    fi
}

function unzip_stackato() {
    if [ ! -f $STACKATO_OVF_FILE ]; then
        unzip $STACKATO_ZIP_FILE; catch
    fi
    VM_NAME=`VBoxManage list vms | perl -0e '$_=<>;s/.*\n"(.*?)".*/$1/s;print'`
    catch
}

function import_stackato_vm() {
    $VBOXMANAGE import $STACKATO_OVF_FILE; catch
}

function setup_network() {
    VBoxManage modifyvm $VM_NAME --nic1 bridged; catch
    VBoxManage modifyvm $VM_NAME --bridgeadapter1 $NET_DEVICE; catch
}

function start_stackato_vm() {
    VBoxManage startvm $VM_NAME; catch
}

function success() {
    echo
    cat <<EOS
Everything seems to have worked. You should now see a VirtualBox VM booting.
Watch the console screen and wait for the boot to finish. It may take several
minutes. When it is done the console screen should have a url like:

    https://stackato-xxxx.local

Load that url in a browser and continue your journey. Your next steps will be:

  * Fill out the setup screen
  * Go to the App Store tab
  * Install some interesting Apps
  * ♥ Stackato

Enjoy!

EOS
}

welcome
verify
reset_sudo
install_vbox
download_stackato
unzip_stackato
# import_stackato_vm
setup_network
start_stackato_vm
success
