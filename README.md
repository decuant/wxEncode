# wxEncode
using wxLua display a binary and text view of a file and encode it utf_8

aim of the application was to convert an ASCII file containing accented letters to UTF_8

there's a main (and only) window with some menu commands. 
import filename is read from a config file each time the import is launched
bytes display can be selected as oct/dec/hex

I worked out this using ZeroBrane, from within I usually start the application. 
this makes easy for me to leave the setupinf.lua file open on the editor and modify the import name on the fly.

cursor alignement is correct only when displaying 2 bytes UTF_8, not with 3 bytes or 4 bytes encoding

