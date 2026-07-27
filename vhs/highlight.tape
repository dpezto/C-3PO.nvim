# Highlighter — type the toggle once, then flip it with @:
Output assets/highlight.gif
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
Type "nvim --clean -u vhs/demo-init.lua vhs/colors.txt"
Enter
Sleep 2s
Show

Sleep 2s
Type ":Ccc highlighter toggle"
Enter
Sleep 1.5s
Type "@:"
Sleep 1.5s
Type "@:"
Sleep 1.5s
Type "@:"
Sleep 2s

Hide
Type ":qa!"
Enter
