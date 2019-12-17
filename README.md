# bin
general purpose scripts

link_JLink_to_usr_local_bin fixes the way the SEGGER JLink programs are linked into /usr/local/bin. The brew install
does install things correctly in /Applications/SEGGER/JLink, but the links in /usr/local/bin cannot simply be invoked
by the shell, but must be "opened" either using Finder and clicking on the link, or by preceeding the
link name with 'open' which of course is a pain. Not a horrible pain, but it is different from how things work
under Linux. So this script fixes those links so they can simply be invoked by name from the command line.
