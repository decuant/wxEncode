# Project Description

## 0.0.8 (04-Jan-2019)

**wxEncode** is a short **Lua** application to view a text file with the option 
of encoding the file from some codepage to UTF8.  

It displays 2 panes:  
[**Bytes**] which is the bare content of the file formatted Octal/Decimal/Hexadecimal  
[**Text**]  which is the textual representation, line by line.  

![wxEncode screenshot](/docs/Screenshot_1.png)

As per the screenshot, the left pane shows coloured bytes for UTF8 characters and 
highlights the position of the cursor; on the right pane the current line selected 
and undelined the corresponding cursor position.  

The image shows also 3 more dialogs:  

* **Calc**: calculator from/to UTF8 byte sequence - Unicode (U+) value.  
* **Find**: find text in the Text pane.  
* **Loupe**: magnification of the byte (or UTF8 sequence) at the cursor's position.  

The application is not an editor, in fact it does operate in a non-destructive way; 
the user can move the cursor around using the normal keyboard shortcuts that are 
expected in any editor:  

* Arrow left/right/up/down.  
* Page Up/Page Down (+ CTRL for big jumps).  
* Home/End (+ CTRL for start of file/end of file).  
* SHIFT + Arrow for selecting text.  
* CTRL+. / CTRL+, to jump the cursor at next/previous encoding error.  
* +/- or CTRL + Mouse Wheel to increase/decrese the font for the current pane.  
* Mouse Wheel to scroll to bottom/to top a number of lines at 1 time.
* Left Click for selecting the cursor's position, or start/end of seletion.
* TAB to cycle the active pane

**Note** that the cursor movement is bound to UTF8 bytes sequence, so that selecting 
a byte which is not the start of the sequence will fall automatically to the start.  

**Note** that scrolling on the right pane has different behaviour than the left pane 
since in the left pane more lines can fit in 1 single line and this really depends 
on both the physical file and the choosen number of columns. By default the 
application is shipped with 16 columns for the left pane, but it can be set to 
any number depending on the user's preference and monitor's size.

## Features

* Check the file for valid UTF8 encoding.  
* Convert the file from selected codepage to UTF8.  
* Create a file with Unicode's blocks definition (see next screeshot)  

[Unicode RFC 3629](https://tools.ietf.org/html/rfc3629#section-4)

[List of Unicode characters](https://en.wikipedia.org/wiki/List_of_Unicode_characters)


![CreateByBlock screenshot](/docs/Screenshot_2.png)

The image depicts a portion of the configuration's file, **appConfig.lua**, where 
the user can choose which Unicode block to output to file (by default the 
application will output all blocks excepts segments where Unicode hasn't defined 
validity {tagged with No_Block} or the 3 Surrogates blocks). The user can disable 
a block by simply setting the 'true' flag to 'false'.

The application's configuration file, **appConfig.lua**, has many options to tweak 
the appereance of the 2 panes, which file to import/export and the external 
Unicode's Names List to use for displaying a description for the current 
character in the Loupe's dialog.  

One option is to set the fonts to display bytes, text lines, and for the Loupe. 
The user will usually set a mono-spaced font for the left pane (BYTES). 

This feature, together with the generation of Unicode's blocks, can let the user 
see which glyphs are implemented by the font selected, and the behaviour of it. 

**Note** that lines of text will be printed using the bi-directional feature of 
wxWidgets, so that, as an example, Hebrew, Arabic and some old languages will be 
printed from right to left and that there will be an obvious mis-alignemnt between 
the Loupe and the current cursor position.  

**Note** the 3 different options to save the current buffer in memory:  
1. export: will save the file to the filename set in the configuration file;
2. overwrite: will write the buffer to the same filename as input;
3. save as: will open a file dialog to manually choose a filename.

## Codepage conversion

At the time of writing this document, the experimental auto-detection of the 
correct codepage for the input file is not completed, but, anyway, the user 
can select 1 out of many codepages available (ISO/OEM/WIN). To list the available 
codepages there's a menu option to output the list to the trace file.  

Set/Change the codepage in the configuration file and then call the transcoder.  
If testing the actual codepage (when unknown) the cycle of operation would be:  

1. Import the file with some codepage set  
2. Test the transcode and terminate if happy with it, or  
3. Change codepage and refresh settings or re-import the file.  

The sub-folder **transcode** implements the codepage to UTF8 conversion and can 
be used from the command line in a stand-alone mode or included in another project. 

## Auxiliary punctuation folder

In the project's sub-folder **punctuation** there's a driver for extracting the 
code-points that are marked as punctuation in the Unicode's NameList.txt file. 
An auxiliary function translates the UTF8 codes to Lua' syntax and the resulting 
(very long) string can be embedded in a project or loaded dynamically with the 
'dofile' statement. An example of operation is in the 'test.lua' file.  
An example of usage is in **extrastr.lua** file, where both the methods are shown.  
Running the driver will produce 2 files: 

1. docs\Punctuation.txt (see screenshot below)
2. punctuation\unipunct.lua

![Punctuation screenshot](/docs/Screenshot_4.png)

## wxWidgets and Lua installation

Only the steps for installation on Windows will be listed. although it shall 
run on Linux and MacOs too.  

1. Download wxWidgets 2.8.12.3 (Windows Unicode) for Lua, **wxLua 5.20**. [wxLua web site](https://wxlua.sourceforge.net/)
2. Download Lua 5.2.2 [Lua web site](https://www.lua.org/) 
3. Extract wxLua to a directory of choice (something like. c:\wxLua520).  
4. Open the Windows' control panel and the Advanced System Settings.  
5. Open the Environment Variables editor.
6. Create an entry for the User with the following line: 
	LUA_CPATH=c:\wxLua520\bin\?.dll 
7. Add c:\wxLua520\bin to the System's PATH variable:

![Windows Environment](/docs/Screenshot_3.png)

The user can then open the Command Prompt, move to the directory where wxEncode 
has been installed and then run it with the command:  

**lua appMain.lua**

As an alternative, the user can download and install **ZeroBrane Studio**, set 
the current project directory to the wxEncode folder, select the Lua interpreter 
version for the project to be 5.2 and simply launch via the 'Run' menu command. 
Before launch right click on **appMain.lua** that can be found on the project's 
file list and select "Set As Start File".  

ZeroBrane can be found at [ZeroBrane web site](https://studio.zerobrane.com/)  

##Issues

1. Running the application from the Command Prompt and running the application from 
ZeroBrane will display a noticeable difference, in fact from ZeroBrane the application 
looks a lot nicer.

2. Drawing is not that fast.

##Updates

The list of modificationcs is here:  
[List of changes](Changes.md)

## Author

The autor can be reached at decuant@gmail.com

## License

The standard MIT license applies.
