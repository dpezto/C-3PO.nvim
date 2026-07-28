# Highlighter, then :C3 convert — type each once, then repeat with @:
Output assets/highlight_convert.gif
Set FontFamily "FiraCode Nerd Font Mono"
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
Type "i#C0BA17"
Escape
Type "0"
Show
Type ":C3 highlighter enable"
Enter
Sleep 1.2s
Type "@:"
Sleep 1.2s
Type "@:"
Sleep 500ms

Sleep 1s
Type ":C3 convert"
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
