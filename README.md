## Stackato One Line Install

You can install/configure/start an ActiveState Stackato Micro Cloud VM running
on the VirtualBox hypervisor running on your laptop/whatever with this one
simple command:

    curl -L http://bit.ly/stackato-microcloud | bash

This command fetches a Bash shell script from GitHub and runs it. The command
will make you type your sudo password, so you are advised to review this
script before running it.

## Limitations

This script currently only works on Debian Linux host systems. Other systems
may be supported in the future.

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
