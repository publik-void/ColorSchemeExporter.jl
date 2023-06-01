using Colors
using Dictionaries

# This will be the background color for the standard lightwarm scheme. The main
# requirement for this one is to tilt the light spectrum of the screen away from
# blue and emphasize red while maintaining adequate luminance for a light
# background color relative to the screen's backlight. Thus, let's define this
# starting point in RGB, because it allows to directly control the mix of the 3
# color bands.
base_lightwarm_rgb = RGB(1., .91, .7)
# base_lightwarm_rgb = RGB(1., .93, .78)

# The amount of contrast between dark and light schemes
base_luminance_span  = 75.

# To reduce the contrast between foreground and background
foreground_luminance_light_muting = .15
foreground_luminance_dark_muting = .3
foreground_chroma_muting = .7

# "Grayed out" color stands in for black or white depending on background
gray_luminance_muting = .65
gray_chroma_muting = .65

# As above, stands in for bright black or bright white depending on background
verygray_luminance_muting = .85
verygray_chroma_muting = .3

# Hue adjustments – to taste
base_hue_lightwarm_offset =  0.
base_hue_darkwarm_offset = -15.
base_hue_lightcold_offset = 15.
base_hue_darkcold_offset = -35.

# Huecolors – the requirements here would be to keep these mostly isoluminant
# and equally spaced across the hue circle while having them resmble the colors
# they are named after.
huecolor_luminance = 60.
huecolor_bright_luminance = 80.
huecolor_luminance_offsets = dictionary((:red => -10., :blue => -20.))
huecolor_chroma = 100.
huecolor_bright_chroma = 100.
huecolor_hue_offset = 20.

# Calculate some intermediates from the starting points
base_lightwarm_lchab = convert(LCHab, base_lightwarm_rgb)

base_luminance_light = base_lightwarm_lchab.l
base_luminance_dark = base_luminance_light - base_luminance_span

base_chroma = base_lightwarm_lchab.c

base_hue_warm = base_lightwarm_lchab.h
base_hue_cold = base_hue_warm + 180.
base_hue_lightwarm = base_hue_warm + base_hue_lightwarm_offset
base_hue_darkwarm = base_hue_warm + base_hue_darkwarm_offset
base_hue_lightcold = base_hue_cold + base_hue_lightcold_offset
base_hue_darkcold = base_hue_cold + base_hue_darkcold_offset

foreground_luminance_dark =
  base_luminance_dark + foreground_luminance_dark_muting * base_luminance_span
foreground_luminance_light =
  base_luminance_light - foreground_luminance_light_muting * base_luminance_span
foreground_chroma = base_chroma * (1. - foreground_chroma_muting)

gray_luminance_dark =
  base_luminance_dark + (1. - gray_luminance_muting) * base_luminance_span
gray_luminance_light =
  base_luminance_light - (1. - gray_luminance_muting) * base_luminance_span
gray_chroma = base_chroma * (1. - gray_chroma_muting)

verygray_luminance_dark =
  base_luminance_dark + (1. - verygray_luminance_muting) * base_luminance_span
verygray_luminance_light =
  base_luminance_light - (1. - verygray_luminance_muting) * base_luminance_span
verygray_chroma = base_chroma * (1. - verygray_chroma_muting)

cs0_background_darkwarm  =
  LCHab(base_luminance_dark , base_chroma, base_hue_darkwarm)
cs0_background_darkcold  =
  LCHab(base_luminance_dark , base_chroma, base_hue_darkcold)
cs0_background_lightwarm =
  LCHab(base_luminance_light, base_chroma, base_hue_lightwarm)
cs0_background_lightcold =
  LCHab(base_luminance_light, base_chroma, base_hue_lightcold)

cs0_foreground_darkwarm  =
  LCHab(foreground_luminance_dark , foreground_chroma, base_hue_darkwarm)
cs0_foreground_darkcold  =
  LCHab(foreground_luminance_dark , foreground_chroma, base_hue_darkcold)
cs0_foreground_lightwarm =
  LCHab(foreground_luminance_light, foreground_chroma, base_hue_lightwarm)
cs0_foreground_lightcold =
  LCHab(foreground_luminance_light, foreground_chroma, base_hue_lightcold)

cs0_gray_darkwarm  =
  LCHab(gray_luminance_dark , gray_chroma, base_hue_darkwarm)
cs0_gray_darkcold  =
  LCHab(gray_luminance_dark , gray_chroma, base_hue_darkcold)
cs0_gray_lightwarm =
  LCHab(gray_luminance_light, gray_chroma, base_hue_lightwarm)
cs0_gray_lightcold =
  LCHab(gray_luminance_light, gray_chroma, base_hue_lightcold)

cs0_verygray_darkwarm  =
  LCHab(verygray_luminance_dark , verygray_chroma, base_hue_darkwarm)
cs0_verygray_darkcold  =
  LCHab(verygray_luminance_dark , verygray_chroma, base_hue_darkcold)
cs0_verygray_lightwarm =
  LCHab(verygray_luminance_light, verygray_chroma, base_hue_lightwarm)
cs0_verygray_lightcold =
  LCHab(verygray_luminance_light, verygray_chroma, base_hue_lightcold)

cs0_ansi_huecolors = [
  c => LCHab{Float64}(
    huecolor_luminance + get(huecolor_luminance_offsets, c, 0.),
    huecolor_chroma,
    ansi_base_hues[c] + huecolor_hue_offset)
  for c in ansi_huecolors]

cs0_ansi_huecolors_bright = [
  brightname(c) => LCHab{Float64}(
    huecolor_bright_luminance + get(huecolor_luminance_offsets, c, 0.),
    huecolor_bright_chroma,
    ansi_base_hues[c] + huecolor_hue_offset)
  for c in ansi_huecolors]

# Create color dictionaries
cs0lw = dictionary((
  :background => cs0_background_lightwarm,
  :foreground => cs0_foreground_darkcold,
  :black => cs0_background_darkcold,
  :white => cs0_gray_lightwarm,
  :bright_black => colorant"black",
  :bright_white => cs0_verygray_lightwarm,
  cs0_ansi_huecolors..., cs0_ansi_huecolors_bright...))

cs0dw = dictionary((
  :background => cs0_background_darkwarm,
  :foreground => cs0_foreground_lightcold,
  :black => cs0_gray_darkwarm,
  :white => cs0_background_lightcold,
  :bright_black => cs0_verygray_darkwarm,
  :bright_white => colorant"white",
  cs0_ansi_huecolors..., cs0_ansi_huecolors_bright...))

cs0lc = dictionary((
  :background => cs0_background_lightcold,
  :foreground => cs0_foreground_darkwarm,
  :black => cs0_background_darkwarm,
  :white => cs0_gray_lightcold,
  :bright_black => colorant"black",
  :bright_white => cs0_verygray_lightcold,
  cs0_ansi_huecolors..., cs0_ansi_huecolors_bright...))

cs0dc = dictionary((
  :background => cs0_background_darkcold,
  :foreground => cs0_foreground_lightwarm,
  :black => cs0_gray_darkcold,
  :white => cs0_background_lightwarm,
  :bright_black => cs0_verygray_darkcold,
  :bright_white => colorant"white",
  cs0_ansi_huecolors..., cs0_ansi_huecolors_bright...))

cs0lh = dictionary((
  :background => colorant"white",
  :foreground => colorant"black",
  # …
  cs0_ansi_huecolors..., cs0_ansi_huecolors_bright...))

cs0dh = dictionary((
  :background => colorant"black",
  :foreground => colorant"white",
  # …
  cs0_ansi_huecolors..., cs0_ansi_huecolors_bright...))

@write_files("cs0", cs0lw, cs0dw, cs0lc, cs0dc, cs0lh, cs0dh)
