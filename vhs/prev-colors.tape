# Restore a previously used color — g opens the row, CR applies.
Output assets/prev-colors.gif
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
Type "nvim --clean -u vhs/demo-init.lua vhs/colors.txt"
Enter
Sleep 2s
Show

Sleep 1s
# Pick and confirm one color so there is exactly one history entry
Type ":C3 pick"
Enter
Sleep 1s
Type "3"
Sleep 500ms
Enter
Sleep 800ms
# Move to another color, then restore the saved one from history
Type "W"
Sleep 500ms
Type ":C3 pick"
Enter
Sleep 1.2s
Type "g"
Sleep 1.5s
Enter
Sleep 1.2s
Enter
Sleep 2s

Hide
Type ":qa!"
Enter
