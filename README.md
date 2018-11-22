# wxEncode

using wxLua display both a binary and text views of a file.  
encode an ASCII file to utf_8.  
create a sample file with some Unicode page blocks.  
check file's UTF_8 code by blocks of validity [see Unicode RFC 3629](https://tools.ietf.org/html/rfc3629#section-4).  
copy byte/UTF_8/Word/Line bytes to clipboard.  
trace most of the operations on a logging file.  
code is tested to run only on Windows 10.  

see List of Unicode characters - [Wikipedia](https://en.wikipedia.org/wiki/List_of_Unicode_characters)

aim of the application originally was to convert an ASCII file containing accented letters to UTF_8 because of  
the different codepages running on my laptop and the results of the 'dir' command

accented letters belong to this Unicode block: Latin-1 Supplement

there's a main (and only) window with some menu commands.  
import filename is read from a config file each time the import is launched.  
bytes display can be selected as oct/dec/hex.  

I worked out this application using ZeroBrane, from within I usually start it.  
this makes easy for me to leave the setupinf.lua file open on the editor and modify the import name on the fly.  

Issues:
-------

* cursor's alignement on the text box is correct only when displaying 2 bytes UTF_8, not with 3 bytes or 4 bytes encoding
* window's dc refresh can become rather slow when there's a lot of colouring going on.  
* text's scrollbar does not handle any mouse command.  
* encoding only works when a file isn't in a standard Unicode format.  
  
  
to easily find help on formatting this very file then [click here](https://help.github.com/articles/basic-writing-and-formatting-syntax/)
