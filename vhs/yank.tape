# :C3 yank — grab the color under the cursor in any format, then paste it.
Output assets/yank.gif
Set FontFamily "Fira Code"
Set FontSize 18
Set Width 900
Set Height 380
Set Margin 45
Set MarginFill "vhs/backdrop.png"
Set WindowBar Colorful
Set WindowBarSize 36
Set BorderRadius 14
Set Padding 16

Hide
Type "nvim --clean -u vhs/demo-init.lua"
Enter
Sleep 2s
Type "i#1e90ff"
Escape
Type "0"
Type ":C3 highlighter enable"
Enter
Sleep 500ms
Show

Sleep 1s
Type ":C3 yank latex_cmyk"
Enter
Sleep 1.5s
Type "o"
Escape
Type "p"
Sleep 1s
Type "0:C3 yank css_hsl"
Enter
Sleep 1.5s
Type "o"
Escape
Type "p"
Sleep 2s

Hide
Type ":qa!"
Enter
