# :C3 pick — sliders, input/output cycling, alpha toggle.
Output assets/pick.gif
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
Type "nvim -i NONE --cmd 'luafile vhs/demo-init.lua' vhs/colors.txt"
Enter
Sleep 5s
Type ":C3 highlighter enable"
Enter
Sleep 1s
Show

Sleep 1s
Type ":C3 pick"
Enter
Sleep 1.5s
# Nudge the red channel, then jump the green one to 80%
Type "d"
Sleep 300ms
Type "d"
Sleep 300ms
Type ","
Sleep 500ms
Type "j"
Sleep 300ms
Type "8"
Sleep 1s
# Toggle the alpha slider on, give it a value, toggle it off
Type "a"
Sleep 800ms
Type "jj"
Sleep 300ms
Type "5"
Sleep 1s
Type "a"
Sleep 800ms
# Cycle input color space: RGB -> HSL -> CMYK
Type "i"
Sleep 1s
Type "i"
Sleep 1s
# Cycle the output format a few times (hex -> css -> latex)
Type "o"
Sleep 800ms
Type "o"
Sleep 800ms
Type "o"
Sleep 800ms
Type "o"
Sleep 1s
Enter
Sleep 2s

Hide
Type ":qa!"
Enter
