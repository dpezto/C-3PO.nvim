# Completion — the project's own \definecolor names, in the popup, in color.
Output assets/autocompletion.gif
Set FontFamily "FiraCode Nerd Font Mono"
Set FontSize 18
Set Width 900
Set Height 560
Set Margin 45
Set MarginFill "vhs/backdrop.png"
Set WindowBar Colorful
Set WindowBarSize 36
Set BorderRadius 14
Set Padding 16

Hide
Type "nvim --clean -u vhs/demo-init-blink.lua vhs/demo.tex"
Enter
Sleep 3s
Type "12gg"
Show

Sleep 2s
Type "o"
Sleep 500ms
Type "\textcolor{"
Sleep 2s
Type "sa"
Sleep 2s
Type "berB"
Sleep 1.5s
Ctrl+y
Sleep 800ms
Type "}{Thank the Maker!}"
Escape
Sleep 2.5s

Hide
Type ":qa!"
Enter
