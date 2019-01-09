# Last modified files

## ver. 0.0.9

1. uniBlocks.lua - modified 'Arabic Presentation Forms-A' to include a segment of 32 chars 'Non-Characters'
2. appConfig.lua - reflect above described change made to uniBlocks.lua
3. wxCalc.lua    - corrected a mispelled name that would crash the wxCalc, _utf8lup was renamed _utf8lkp in extrastr.lua
4. uniBlocks.lua - correct conversion error in Unicode's formula (was wrong with 07f7 in Samaritan)
5. wxCalc.lua    - same as above
6. wxLoupe       - same as above
6. extrastr.lua  - added sanity checks for str_sub_utf_8
7. punctuation   - folder with functions to scan the Unicode's NameList.txt file and retrieve all punctuation code-points
8. extrastr.lua  - added str_ispunct_u and Unicode's punctuation list
9. unipunct.lua  - added to the project
10. docs/punctuations.txt   - added to the project's documentation
11. extrastr.lua - added iterator to extract UTF_8 characters from a line of text 


