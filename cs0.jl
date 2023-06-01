"""
This color scheme is based on the following design specifications:
* Have a dark and a light version
* Have a cold (blue-tinted) and a warm (orange-tinted) version
  …special focus should be on the warm version to make sure it reduces blue
  light exposure from usually blue-heavy screens somewhat
* Have a deliberately decreased contrast range
* Have two extra variants with maximized contrast (full black and white)
  …e.g. for working in the sun on a not-so-bright display
* To keep some distance between foreground and background colors, even without
  full contrast, use roughly opposite color hues
* Create a sort of color intensity gradient with the black and white colors
  and their intense versions. Have the foreground color be somewhere in the
  middle
* Use roughly isoluminant colors for the ANSI colors and try to adhere to the
  naming
* Work in (polar) CIELAB colorspace

This set of specifications almost invariably creates a
[Solarized](https://ethanschoonover.com/solarized)-like colorscheme, plus a
complement of warm dark and cold light versions. (And then of course the
high-contrast versions.) While having been inspired by Solarized, the
specifications have not been chosen to simply make a recreation of it. The main
goals of this colorscheme are to play nicely with terminals and to be
eye-friendly, especially in terms of blue light exposure.
"""
cs0

using Colors
using Dictionaries

# This will be the background color for the standard lightwarm scheme. The main
# requirement for this one is to tilt the light spectrum of the screen away from
# blue and emphasize red while maintaining adequate luminance for a light
# background color relative to the screen's backlight. Thus, let's define this
# starting point in RGB, because it allows to directly control the mix of the 3
# color bands.
base_lightwarm_rgb = RGB(1., .93, .78)

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

# For black and bright white, use a luminance offset from bright black and white
black_luminance_offset = -30.
bright_white_luminance_offset = 15.

# Background luminance adjustments – to taste, as long as they're small
background_luminance_lightwarm_offset = 0.
background_luminance_darkwarm_offset  = 3.
background_luminance_lightcold_offset = 4.
background_luminance_darkcold_offset  = 0.

# Hue adjustments – to taste but maybe not too big
base_hue_lightwarm_offset =  0.
base_hue_darkwarm_offset = -40.
base_hue_lightcold_offset = 20.
base_hue_darkcold_offset = -35.

# Huecolors – the requirements here would be to keep these mostly isoluminant
# and equally spaced across the hue circle while having them resemble the colors
# they are named after.
huecolor_luminance = 55.
huecolor_bright_luminance = 80.
huecolor_chroma = 80.
huecolor_bright_chroma = 110.
huecolor_hue_offset = 25.

huecolor_luminance_offsets =
  dictionary((:red => -15., :blue => -17., :magenta => -10., :cyan => -2.))
huecolor_bright_luminance_offsets =
  dictionary((:red => 15., :magenta => 5., :blue => -5., :cyan => -3.))
huecolor_chroma_offsets =
  dictionary((:red => 7.5, :yellow => 5., :cyan => 10.))
huecolor_hue_offsets =
  dictionary((:red => 7.5, :cyan => -7.5, :blue => 10., :yellow => -5.))

# Shades of Gray for the high contrast schemes
high_contrast_shade_luminances = [0., 20., 40., 60., 80., 100.]

# For iTerm2, completeness, distiguishability, whatever…
badge_alpha = .5

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

background_luminance_lightwarm =
  base_luminance_light + background_luminance_lightwarm_offset
background_luminance_darkwarm =
  base_luminance_dark + background_luminance_darkwarm_offset
background_luminance_lightcold =
  base_luminance_light + background_luminance_lightcold_offset
background_luminance_darkcold =
  base_luminance_dark + background_luminance_darkcold_offset

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
  LCHab(background_luminance_darkwarm , base_chroma, base_hue_darkwarm)
cs0_background_darkcold  =
  LCHab(background_luminance_darkcold , base_chroma, base_hue_darkcold)
cs0_background_lightwarm =
  LCHab(background_luminance_lightwarm, base_chroma, base_hue_lightwarm)
cs0_background_lightcold =
  LCHab(background_luminance_lightcold, base_chroma, base_hue_lightcold)

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

offset_luminance(c::LCHab, offset) = LCHab(c.l + offset, c.c, c.h)
cs0_background_darkwarm_dark =
  offset_luminance(cs0_background_darkwarm, black_luminance_offset)
cs0_background_darkcold_dark =
  offset_luminance(cs0_background_darkcold, black_luminance_offset)
cs0_background_lightwarm_light =
  offset_luminance(cs0_background_lightwarm, bright_white_luminance_offset)
cs0_background_lightcold_light =
  offset_luminance(cs0_background_lightcold, bright_white_luminance_offset)

cs0_ansi_huecolors = [
  c => LCHab(
    huecolor_luminance + get(huecolor_luminance_offsets, c, 0.),
    huecolor_chroma + get(huecolor_chroma_offsets, c, 0.),
    ansi_base_hues[c] + huecolor_hue_offset + get(huecolor_hue_offsets, c, 0.))
  for c in ansi_huecolors]

cs0_ansi_huecolors_bright = [
  brightname(c) => LCHab(
    huecolor_bright_luminance + get(huecolor_luminance_offsets, c, 0.) +
                                get(huecolor_bright_luminance_offsets, c, 0.),
    huecolor_bright_chroma,
    ansi_base_hues[c] + huecolor_hue_offset + get(huecolor_hue_offsets, c, 0.))
  for c in ansi_huecolors]

as_rgba(pairs::Pair{Symbol, <:Colorant}...) = map(pairs) do pair
    pair.first => RGBA(pair.second)
  end

as_rgb(pairs::Pair{Symbol, <:Colorant}...) = map(pairs) do pair
    pair.first => RGB(pair.second)
  end

cdict(pairs::Pair{Symbol, <:Colorant}...) =
  Dictionary{Symbol, Colorant}((pair.first for pair in pairs),
                               (pair.second for pair in pairs))
cdict(pairs::NTuple{<:Any, <:Pair{Symbol, <:Colorant}}) = cdict(pairs...)

create_high_contrast_shades(names...) =
  map(zip(names, sort(high_contrast_shade_luminances))) do (name, l)
    name => LCHab(l, 0., 0.)
  end

function add_extra_colors!(d)
  insert!(d, :badge, RGBA(RGB(d[:foreground]), badge_alpha))
end

# Create color dictionaries
cs0lw = cdict(as_rgb(
  :background => cs0_background_lightwarm,
  :foreground => cs0_foreground_darkcold,
  :black => cs0_background_darkcold_dark,
  :white => cs0_gray_lightwarm,
  :bright_black => cs0_background_darkcold,
  :bright_white => cs0_verygray_lightwarm,
  cs0_ansi_huecolors..., cs0_ansi_huecolors_bright...))

cs0dw = cdict(as_rgb(
  :background => cs0_background_darkwarm,
  :foreground => cs0_foreground_lightcold,
  :black => cs0_gray_darkwarm,
  :white => cs0_background_lightcold_light,
  :bright_black => cs0_verygray_darkwarm,
  :bright_white => cs0_background_lightcold,
  cs0_ansi_huecolors..., cs0_ansi_huecolors_bright...))

cs0lc = cdict(as_rgb(
  :background => cs0_background_lightcold,
  :foreground => cs0_foreground_darkwarm,
  :black => cs0_background_darkwarm_dark,
  :white => cs0_gray_lightcold,
  :bright_black => cs0_background_darkwarm,
  :bright_white => cs0_verygray_lightcold,
  cs0_ansi_huecolors..., cs0_ansi_huecolors_bright...))

cs0dc = cdict(as_rgb(
  :background => cs0_background_darkcold,
  :foreground => cs0_foreground_lightwarm,
  :black => cs0_gray_darkcold,
  :white => cs0_background_lightwarm_light,
  :bright_black => cs0_verygray_darkcold,
  :bright_white => cs0_background_lightwarm,
  cs0_ansi_huecolors..., cs0_ansi_huecolors_bright...))

cs0lh = cdict(as_rgb(create_high_contrast_shades(
    :foreground, :black, :bright_black, :white, :bright_white, :background)...,
  cs0_ansi_huecolors..., cs0_ansi_huecolors_bright...))

cs0dh = cdict(as_rgb(create_high_contrast_shades(
    :background, :black, :bright_black, :white, :bright_white, :foreground)...,
  cs0_ansi_huecolors..., cs0_ansi_huecolors_bright...))

cs0 = cs0lw, cs0dw, cs0lc, cs0dc, cs0lh, cs0dh

map(add_extra_colors!, cs0)

@write_files("cs0", cs0lw, cs0dw, cs0lc, cs0dc, cs0lh, cs0dh)
