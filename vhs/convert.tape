# :Ccc convert — type it once, then cycle with @:
Output assets/convert.gif
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
Type "i#ff8800"
Escape
Type "0"
Type ":Ccc highlighter enable"
Enter
Sleep 500ms
Show

Sleep 1s
Type ":Ccc convert"
Enter
Sleep 1.2s
Type "@:"
Sleep 1.2s
Type "@:"
Sleep 1.2s
Type "@:"
Sleep 1.2s
Type "@:"
Sleep 1.2s
Type "@:"
Sleep 1.5s

Hide
Type ":qa!"
Enter
