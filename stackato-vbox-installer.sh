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
}

welcome
verify
