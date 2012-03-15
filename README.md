## Stackato One Line Install

You can install/configure/start an ActiveState Stackato Micro Cloud VM running
on the VirtualBox hypervisor running on your laptop/whatever with this one
simple command:

    curl -L http://bit.ly/stackato-microcloud | bash

NOTE: This script currently only works on Debian Linux and Max OS X host
systems.  Other systems may be supported in the future.

## How it Works

This command fetches a Bash shell script from GitHub and runs it. The command
may make you type your sudo password, so you are advised to review this
script before running it.

The script is just automating these fairly simple steps:

* Download and Install Virtualbox (if not already installed)
  * Requires `sudo` if installation required
  * Uses `sudo apt-get install` on Debian systems
* Download the Stackato VM zipfile (if not already downloaded)
* Unzip the Stackato VM (if not already unzipped)
* Import the Stackato VM image into VirtualBox
* Configure the VM to use bridged networking on you active network device
* Set the VM to use an appropriate amount of RAM on your system
* Start the newly installed/configured VM
* Print a message of what to do next, and where to find more doc

## About the Stackato Micro Cloud

Stackato is a Private PaaS solution from ActiveState:
http://www.activestate.com/stackato

PaaS is Platform as a Service. You can deploy apps to Stackato and having them
running in minutes.

Private means you get to host it yourself, wherever you want. Stackato is just
a VM with all the modern programming languages, databases, etc preconfigured
to just work. You can download this VM and run it anywhere. This script helps
you do that as simply as possible.

Micro Cloud is the license option that lets you run Stackato for free. It
limits you to a single VM node deployment and non-commercial (or internal
commercial) usage.
