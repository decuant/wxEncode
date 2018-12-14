# wxEncode

using wxLua display both a binary and text views of a file.  

the application uses wxLua 2.8.12.3 - Lua 5.2.2

to run the application simply install the wxLua package in your machine, download this application, make the wxLua package visible in the execution environment (PATH in Windows) and run it with this very command: lua wxMain  

encode an ASCII file to utf_8.  
create a sample file with some Unicode page blocks.  
check file's UTF_8 code by blocks of validity [see Unicode RFC 3629](https://tools.ietf.org/html/rfc3629#section-4).  
copy byte/UTF_8/Word/Line bytes to clipboard.  
trace most of the operations on a logging file.  
code is tested to run only on Windows 10, but there shall be no issues on Linux.  

see List of Unicode characters - [Wikipedia](https://en.wikipedia.org/wiki/List_of_Unicode_characters)

aim of the application originally was to convert an ASCII file containing accented letters to UTF_8 because of the different codepages running on my laptop and the results of the 'dir' command  

accented letters belong to this Unicode block: Latin-1 Supplement  

there's a main (and only) window with some menu commands.  
import filename is read from the config file each time the import is launched.  
bytes display can be selected as oct/dec/hex.  
can refresh setting by menu command and update the view on the fly.  
having a wxWidget timer available it will call a cycle of garbage collection when a ticktimer fires.  
the application can create a number of samples char from the Unicode segmented list, just enable the creation in the setupinf file and run a Create Samples.  
there's an optional small window to display the current character with a very big size font.  
there's an optional small window to calculate the UTF_8 bytes sequence from Unicode and vice versa.  

shortly I will add some screenshots to display what the application capabilities are, but it's such a small step to install it on your machine that I ask you why not donwload it and give it a try?

I worked out this application using ZeroBrane, from within I usually start it, this makes easy for me to leave the setupinf.lua file open on the editor and modify the import name on the fly.  

Note:
-----

I use a monospaced font for the left pane display and any other font for the right display pane.  
Fonts may not display characters correctly, but this is a limitation of the font in use itself.  

Issues:
-------

* cursor's alignement on the text box is currently broken because of the new file read implementation 
* text's scrollbar does not handle any mouse command.  
* encoding only works when a file isn't in a standard Unicode format.  
* the window's client area height is correct only when running from ZeroBrane, if using the lua.exe interpreter than a fix must be applied at OnSize event (actually there is no way to get the statusbar's height)
  
file utf8table.lua is still used but deprecated.  
file utility.lua is no more used and deprecated.  
file random.lua is not used at all and deprecated.  

--------------------------  
to easily find help on formatting this very file then [click here](https://help.github.com/articles/basic-writing-and-formatting-syntax/)
