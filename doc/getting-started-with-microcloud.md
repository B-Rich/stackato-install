## What to do with your new ActiveState Stackato Micro Cloud VM

If you just ran this command:

    curl -L http://bit.ly/stackato-microcloud | bash

and everything went ok, then you have a virtual machine window that is running
ActiveState's Stackato software, and you were told to read this doc. Welcome!

So what next?

First wait for the VM to finish booting up. When it is done you should see url
on the VM console window. Type this url into a web browser. This url is being
served by your new Stackato VM and it is a fully functional control panel for
doing interesting things with Stackato. The rest of this doc will tell you
what interesting things you might want to try to get started with Stqackato.

The browser will warn you about an unsigned ssl certificate. Your cert is
generated on first boot, and thus there is no way to make it signed by
default. Go ahead and accept the exception. Nothing will catch on fire. The
Stackato Web Console (here after refered to as "the console") needs to run
over https because it is passing sensitive info between you and the VM.

Now you see the Stackato setup screen. This allows you to create an admin user
account and password. The password is extra special because it also will be
the `stackato` user password if you want to ssh directly into the VM.

Next you will see the welcome screen of The Console in all its glory. For
starters click on Graphs to see some realtime graphs of your new baby. Then go
to the App Store and find an app that interests you and install it.

## Docs In Progress

More soon. Stay tuned...
