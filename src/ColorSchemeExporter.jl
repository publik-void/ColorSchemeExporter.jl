module ColorSchemeExporter

using FixedPointNumbers
using Colors
using Dictionaries

export ansi_monos, ansi_huecolors, ansi_base_hues, ansi_base_saturations,
  ansi_base_values, ansi_base_lightnesses, brightname, termview, write_files,
  @write_files, ansi_color_indexes

indent(str::AbstractString, n = 1, indent_width = 2) =
  replace(str, r"^"m => " " ^ (n * indent_width))

ansi_monos = (:black, :white)
ansi_huecolors = (:red, :yellow, :green, :cyan, :blue, :magenta)

ansi_color_indexes = dictionary((
  0   => :black         ,
  1   => :red           ,
  2   => :green         ,
  3   => :yellow        ,
  4   => :blue          ,
  5   => :magenta       ,
  6   => :cyan          ,
  7   => :white         ,
  8   => :bright_black  ,
  9   => :bright_red    ,
  10  => :bright_green  ,
  11  => :bright_yellow ,
  12  => :bright_blue   ,
  13  => :bright_magenta,
  14  => :bright_cyan   ,
  15  => :bright_white  ))

ansi_base_hues = dictionary((
  :red     =>   0.,
  :yellow  =>  60.,
  :green   => 120.,
  :cyan    => 180.,
  :blue    => 240.,
  :magenta => 300.,
  :black   =>   0.,
  :white   =>   0.))

ansi_base_saturations = dictionary((
  :red     => 1.,
  :yellow  => 1.,
  :green   => 1.,
  :cyan    => 1.,
  :blue    => 1.,
  :magenta => 1.,
  :black   => 0.,
  :white   => 0.))

ansi_base_values = dictionary((
  :red     => 1.,
  :yellow  => 1.,
  :green   => 1.,
  :cyan    => 1.,
  :blue    => 1.,
  :magenta => 1.,
  :black   => 0.,
  :white   => 1.))

ansi_base_lightnesses = dictionary((
  :red     => .5,
  :yellow  => .5,
  :green   => .5,
  :cyan    => .5,
  :blue    => .5,
  :magenta => .5,
  :black   => 0.,
  :white   => 1.))

brightname(name) = Symbol(:bright_, name)

"Wraps a colorant to be shown as a colored square in the terminal. May result in
badly colored output if some caller tries to truncate the output."
struct TermView{C <: Colorant, B <: Union{Nothing, Colorant}}
  c::C
  b::B
  n::UInt8
end

termview_default_background_color = nothing
terview_default_n = UInt8(8)

# Really helpful here, but also helpful in terms of elucidating the broader
# terminal color/styling capabilities:
# https://stackoverflow.com/a/33206814
function Base.show(io::IO, tv::TermView)
  f = x -> Int(x.i)
  rgba = RGBA{N0f8}(tv.c)
  r = f(rgba.r); g = f(rgba.g); b = f(rgba.b)
  fg = "\x1b[38;2;$(r);$(g);$(b)m"
  if isnothing(tv.b)
    # r = HSLA(rgba).l ≥ .5 ? 0 : 255; g = r; b = r
    # r = 0; g = r; b = r
    bg = ""
  else
    rgba = RGBA{N0f8}(tv.b)
    r = f(rgba.r); g = f(rgba.g); b = f(rgba.b)
    bg = "\x1b[48;2;$(r);$(g);$(b)m"
  end
  sq = rgba.alpha < one(rgba.alpha) ? "□" : "■"
  rst = "\x1b[0m"
  print(io, fg, bg, repeat(sq, tv.n), rst)
end

function termview(color::Colorant,
  background_color::Union{Nothing, <:Colorant} = nothing;
  default_background_color = termview_default_background_color,
  n = terview_default_n)
  return TermView(color,
    isnothing(background_color) ? default_background_color : background_color,
    n)
end

function termview(colorss...;
  default_background_color = termview_default_background_color,
  n = terview_default_n)
  ks = [union(map(keys, colorss)...)...]
  bs = [keytype(colors) ≠ Symbol ? default_background_color :
    get(colors, :background, default_background_color)
    for colors in colorss]
  tvss = ((((TermView(get(colors, k, b), b, n)
    for (colors, b) in zip(colorss, bs))...,) for k in ks)...,)
  return Dictionary(ks, tvss)
end

function key_convert(key::Union{Symbol, AbstractString, Number})
  return Symbol(lowercase(replace(string(key), " " => "_", "-" => "_")))
end

function key_convert(colors)
  if eltype(keys(colors)) <: Symbol
    return colors
  else
    return Dictionary(map(key_convert, keys(colors)), values(colors))
  end
end

function fill_defaults(colors)
  colors = deepcopy(colors)

  defaults = dictionary((
    :bright_black   => :black,
    :bright_red     => :red,
    :bright_green   => :green,
    :bright_yellow  => :yellow,
    :bright_blue    => :blua,
    :bright_magenta => :magenta,
    :bright_cyan    => :cyan,
    :bright_white   => :white,
    :cursor         => :foreground,
    :cursor_reverse => :background,
    :bold           => :foreground,
    :badge          => :bold,
    :cursor         => :foreground,
    :cursor_guide   => :background,
    :cursor_text    => :cursor_reverse,
    :link           => :bold,
    :selection      => :foreground,
    :selected_text  => :background))

  indirection(key) = haskey(colors, key) ? colors[key] :
    haskey(defaults, key) ? indirection(defaults[key]) : nothing

  for key in keys(defaults)
    if !haskey(colors, key)
      c = indirection(key)
      if !isnothing(c)
        insert!(colors, key, c)
      end
    end
  end

  return colors
end

function as_itermcolors(colors)
  colors = fill_defaults(key_convert(colors))

  itermcolors_names = dictionary((
    :black          =>  "Ansi 0 Color",
    :red            =>  "Ansi 1 Color",
    :green          =>  "Ansi 2 Color",
    :yellow         =>  "Ansi 3 Color",
    :blue           =>  "Ansi 4 Color",
    :magenta        =>  "Ansi 5 Color",
    :cyan           =>  "Ansi 6 Color",
    :white          =>  "Ansi 7 Color",
    :bright_black   =>  "Ansi 8 Color",
    :bright_red     =>  "Ansi 9 Color",
    :bright_green   => "Ansi 10 Color",
    :bright_yellow  => "Ansi 11 Color",
    :bright_blue    => "Ansi 12 Color",
    :bright_magenta => "Ansi 13 Color",
    :bright_cyan    => "Ansi 14 Color",
    :bright_white   => "Ansi 15 Color",
    :background     => "Background Color",
    :foreground     => "Foreground Color",
    :bold           => "Bold Color",
    :badge          => "Badge Color",
    :cursor         => "Cursor Color",
    :cursor_guide   => "Cursor Guide Color",
    :cursor_text    => "Cursor Text Color",
    :link           => "Link Color",
    :selection      => "Selection Color",
    :selected_text  => "Selected Text Color"))

  colors_dict = map(pairs(itermcolors_names)) do (k, name)
    name => colors[k]
  end |> dictionary

  itermcolors_dict = map(pairs(colors_dict)) do (k, c)
    c_rgba_float64 = RGBA{Float64}(c)
    c_dict = dictionary((
      "Color Space" => "sRGB",
      "Red Component" => c_rgba_float64.r,
      "Green Component" => c_rgba_float64.g,
      "Blue Component" => c_rgba_float64.b,
      "Alpha Component" => c_rgba_float64.alpha))
    k => c_dict
  end |> dictionary

  function dict(d)
    dict_str = """
      <dict>
      """
    for (k, v) in pairs(d)
      item_str = """
      <key>$k</key>
      """
      if v isa String
        item_str *= """
          <string>$v</string>
          """
      elseif v isa Real
        item_str *= """
          <real>$v</real>
          """
      else
        item_str *= indent(dict(v))
      end
      dict_str *= indent(item_str)
    end
    dict_str *= """
      </dict>
      """
    return dict_str
  end

  itermcolors_str = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" \
      "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    """
  itermcolors_str *= dict(itermcolors_dict)
  itermcolors_str *= """
    </plist>
    """
  return itermcolors_str
end

function as_st_config(colors)
  colors = fill_defaults(key_convert(colors))

  color_indexes = dictionary((pairs(ansi_color_indexes)...,
    259 => :background    ,
    258 => :foreground    ,
    256 => :cursor        ,
    257 => :cursor_reverse))

  # color_index_variable_names = dictionary((
  #   :background     => "defaultfg",
  #   :foreground     => "defaultbg",
  #   :cursor         => "defaultcs",
  #   :cursor_reverse => "defaultrcs"))

  p0 = "// Generated from the Julia code in the `custom-color-schemes` Git \
    repository\n"

  p1 = "// Terminal colors\n\
    static const char *colorname[] = {\n"
  base_colornames   = getindices(color_indexes, 0:7)
  bright_colornames = getindices(color_indexes, 8:15)
  for (colornames, adjective) in ((base_colornames  , "normal"),
                                  (bright_colornames, "bright"))
    p1 *= indent("// 8 $(adjective) colors\n")
    for key in colornames
      p1 *= indent((haskey(colors, key) ? "\"#$(hex(colors[key], :rrggbb))\"" :
        "0") * ",\n")
    end
    p1 *= "\n"
  end
  p1 *= indent("[255] = 0,\n")
  p1 *= "\n"
  p1 *= indent("// additional colors after 255\n")
  i = 256
  while haskey(color_indexes, i)
    p1 *= indent("\"#$(hex(colors[color_indexes[i]], :rrggbb))\",\n")
    i += 1
  end
  p1 *= "};\n"

  p2 = ""

  return join((p for p in (p0, p1, p2) if !isempty(p)), "\n")
end

function as_xresources(colors)
  colors = fill_defaults(key_convert(colors))

  xresources_names = dictionary((
    :background     => "background",
    :foreground     => "foreground",
    :cursor         => "cursorColor",
    :black          =>  "color0",
    :red            =>  "color1",
    :green          =>  "color2",
    :yellow         =>  "color3",
    :blue           =>  "color4",
    :magenta        =>  "color5",
    :cyan           =>  "color6",
    :white          =>  "color7",
    :bright_black   =>  "color8",
    :bright_red     =>  "color9",
    :bright_green   => "color10",
    :bright_yellow  => "color11",
    :bright_blue    => "color12",
    :bright_magenta => "color13",
    :bright_cyan    => "color14",
    :bright_white   => "color15"))

  prefix = "*"

  str = "! Generated from the Julia code in the `custom-color-schemes` Git \
    repository\n\n"
  for (k, name) in pairs(xresources_names)
    if haskey(colors, k)
      str *= "! $k\n$prefix$(name): #$(hex(colors[k], :rrggbb))\n\n"
    end
  end
  return str
end

function as_console_escape_codes(colors)
  colors = fill_defaults(key_convert(colors))

  str = """\
  #!/bin/sh

  # Generated from the Julia code in the `custom-color-schemes` Git repository

  """

  escape_cmd(i, k) = "printf \"\e]P$(uppercase(string(i; base = 16)))\
    $(hex(colors[k], :rrggbb))\" # $k\n"

  for (i, k) in pairs(ansi_color_indexes)
    if k ∉ (:black, :white); str *= escape_cmd(i, k); end
  end

  colors[:black] = colors[:background]
  colors[:white] = colors[:foreground]

  branch_0 = ""
  for (i, k) in pairs(ansi_color_indexes)
    if k ∈ (:black, :white); branch_0 *= escape_cmd(i, k); end
  end

  use_optional_setterm = false # `setterm` gets reset often anyway

  if !use_optional_setterm
    str *= branch_0
  else
    dark = HSV(colors[:background]).v ≤ HSV(colors[:foreground]).v
    k0 = dark ? :black : :white; k1 = dark ? :white : :black

    colors[k0] = colors[:background]
    colors[k1] = colors[:foreground]

    branch_1 = ""
    for (i, k) in pairs(ansi_color_indexes)
      if k ∈ (:black, :white); branch_1 *= escape_cmd(i, k); end
    end

    setterm_test = "if command -v setterm 1> /dev/null; then"
    setterm_cmd = "setterm -background $k0 -foreground $k1"

    str *= "\n"
    if dark
      str *= """\
        $branch_0\

        $setterm_test
        $(indent(setterm_cmd))
        fi
        """
    else
      str *= """\
        $setterm_test
        $(indent(branch_1))
        $(indent(setterm_cmd))
        else
        $(indent(branch_0))\
        fi
        """
    end
  end

  return str
end

function html_view(colorss...; name = nothing, names = nothing)
  background_color = colorant"black"
  foreground_color = colorant"white"

  paragraphs_str = ""
  for i in 1:2
    rows_str = ""
    if !isnothing(names)
      items_str = """
        <th scope="col"></th>
        """
      for name in names
        items_str *= """
          <th scope="col" style=font-size:small>$name</th>
          """
      end
      rows_str *= """
        <tr>
        $(indent(items_str))
        </tr>
        """
    end

    for k in union(map(keys, colorss)...)
      items_str = """
        <td style="font-family:monospace">$k</td>
        """
      for colors in colorss
        color = get(colors, k, colorant"transparent")
        h = hex(color, :RRGGBBAA)
        bg_str = i == 1 ? "#$h" :
          "#$(hex(get(colors, :background, background_color), :RRGGBBAA))"
        fg_str = "#$h"
        items_str *= """
          <td style=\"\
            font-family:monospace; \
            background-color:$bg_str; \
            color:$fg_str; \
            padding-left:1em; \
            padding-right:1em\">$h</td>
          """
      end
      rows_str *= """
        <tr>
        $(indent(items_str))
        </tr>
        """
    end

    caption_str = i == 1 ? "Colors" :
      "Colors as foreground on respective background"

    table_str = """
      <table>
      <caption>$caption_str</caption>
      $(indent(rows_str))
      </table>
      """

    paragraphs_str *= """
      <p>
      $(indent(table_str))
      </p>
      """
  end

  name_strs = isnothing(names) ? ("" for _ in colorss) :
    (isnothing(name) ? "" :
      " for <span style=\"font-family:monospace\">$name</span>"
      for name in names)
  for (colors, name_str) in zip(colorss, name_strs)
    bg = get(colors, :background, background_color)
    fg = get(colors, :foreground, foreground_color)
    sample_str = """
      This is some sample text$name_str: Lorem ipsum dolor sit amet, \
      consectetur adipiscing elit. Curabitur cursus rutrum turpis tincidunt \
      sollicitudin. Duis eu iaculis massa, sit amet vehicula ex. Vivamus \
      placerat ultricies est, at efficitur arcu. Vivamus imperdiet sem in leo \
      lobortis, non pellentesque sapien tincidunt. Nulla facilisi. Aenean non \
      nisl at ante ultricies scelerisque. Mauris vulputate dui magna, sit amet \
      faucibus erat vestibulum quis. Fusce dui lacus, porttitor id justo quis, \
      elementum hendrerit nisl.
      """
    if haskey(colors, :black)
      sample_str *= """
        <br><br>
        <span style="color:#$(hex(colors[:black]))">
          Here we have some text in black. Lorem ipsum dolor sit amet, \
          consectetur adipiscing elit.
        </span>
        """
    end
    if haskey(colors, :white)
      sample_str *= """
        <br><br>
        <span style="color:#$(hex(colors[:white]))">
          Here we have some text in white. Lorem ipsum dolor sit amet, \
          consectetur adipiscing elit.
        </span>
        """
    end
    paragraphs_str *= """
      <p style="background-color:#$(hex(bg)); color:#$(hex(fg))">
      $(indent(sample_str))
      </p>
      """
  end

  title_str = isnothing(name) ? "Color view" :
    "Color view of <span style=\"font-family:monospace\">$name</span>"

  html_str =
    """
    <!DOCTYPE html>
    <html>
    <body style="\
      color:#$(hex(foreground_color, :RRGGBBAA)); \
      background-color:#$(hex(background_color, :RRGGBBAA)); \
      font-size:2em; \
      margin:2em">

    <h1>$title_str</h1>
    $paragraphs_str

    </body>
    </html>
    """
  return html_str
end

"""
    write_files(part_1_name => part_1_colors, ...; name, out_dir)

Export a color scheme named `name` consisting of several parts named
`part_1_name`, etc. in the formats supported by this package to subdirectories
of `out_dir`.

See also `@write_files`.
"""
function write_files(colorss::Pair...;
    name = "colors", out_dir = joinpath(pwd(), "out"))
  name_dir = joinpath(out_dir, name)
  names = map(first, colorss)
  mkpath(name_dir)

  html_str = html_view(map(last, colorss)...; names, name)
  write(joinpath(name_dir, "html-preview.html"), html_str)

  for (partname, colors) in colorss
    for (formatter, ext, format_name, executable_bit) in (
        (as_itermcolors, "itermcolors", "iTerm2", false),
        (as_st_config, "h", "st", false),
        (as_xresources, "theme.Xresources", "Xresources", false),
        (as_console_escape_codes, "sh", "console-escape-codes", true))
      str = formatter(colors)
      path_dir = joinpath(name_dir, format_name, name)
      path_file = joinpath(path_dir, "$partname.$ext")
      mkpath(path_dir)
      write(path_file, str)
      if executable_bit; chmod(path_file, 0o744); end
    end
  end
  return termview(map(last, colorss)...)
end

"""
    @write_files(out_dir, name, part_1, ...)

Calls `write_files` and uses the variable names of the parts.
"""
macro write_files(out_dir, name, colorss...)
  exs = (:($(string(colors)) => $colors) for colors in colorss)
  return :(write_files($(exs...); name = $name, out_dir = $out_dir))
end

end # module ColorSchemeExporter
