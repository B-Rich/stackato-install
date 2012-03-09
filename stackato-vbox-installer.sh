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

# Print intro message. Name, Version, Release Date.
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
    fi
    # assert linux
    # assert debian
    # assert working network device
    # check if vbox installed
    # verify vbox version
    # check if stackato zip already downloaded
    # check if stackato zip already unzipped
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

# reset_sudo
# install_vbox
# download_stackato
# unzip_stackato

success
