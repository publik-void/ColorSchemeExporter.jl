using FixedPointNumbers
using Colors
using Dictionaries

out_dir = joinpath(@__DIR__, "out")

indent(str::AbstractString) = replace(str, r"^"m => "  ")

"Wraps a colorant to be shown as a colored square in the terminal. May result in badly colored output if some caller tries to truncate the output."
struct TermView{C <: Colorant, B <: Union{Nothing, Colorant}}
  c::C
  b::B
  n::UInt8
end

TermView(c, b = nothing) = TermView(c, b, UInt8(8))

# Really helpful here, but also helpful in terms of elucidating the broader
# terminal color/styling capabilities:
# https://stackoverflow.com/questions/4842424/list-of-ansi-color-escape-sequences
function Base.show(io::IO, tv::TermView)
  f = x -> Int(x.i)
  rgba = RGBA{N0f8}(tv.c)
  r = f(rgba.r); g = f(rgba.g); b = f(rgba.b)
  fg = "\x1b[38;2;$(r);$(g);$(b)m"
  if isnothing(tv.b)
    # r = HSLA(rgba).l ≥ .5 ? 0 : 255; g = r; b = r
    r = 0; g = r; b = r
  else
    rgba = RGBA{N0f8}(tv.b)
    r = f(rgba.r); g = f(rgba.g); b = f(rgba.b)
  end
  bg = "\x1b[48;2;$(r);$(g);$(b)m"
  sq = rgba.alpha < one(rgba.alpha) ? "□" : "■"
  rst = "\x1b[0m"
  print(io, fg, bg, repeat(sq, tv.n), rst)
end

function termview(colorss...)
  ks = [union(map(keys, colorss)...)...]
  bs = [get(colors, :background, RGBA(0, 0, 0, 0)) for colors in colorss]
  tvss = ((((TermView(get(colors, k, b), b)
    for (colors, b) in zip(colorss, bs))...,) for k in ks)...,)
  return Dictionary(ks, tvss)
end

function itermcolors(colors)
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

  defaults = dictionary((
     "Ansi 0 Color"       => colorant"black",
     "Ansi 1 Color"       => "Ansi 0 Color",
     "Ansi 2 Color"       => "Ansi 0 Color",
     "Ansi 3 Color"       => "Ansi 0 Color",
     "Ansi 4 Color"       => "Ansi 0 Color",
     "Ansi 5 Color"       => "Ansi 0 Color",
     "Ansi 6 Color"       => "Ansi 0 Color",
     "Ansi 7 Color"       => "Ansi 0 Color",
     "Ansi 8 Color"       => "Ansi 0 Color",
     "Ansi 9 Color"       => "Ansi 1 Color",
    "Ansi 10 Color"       => "Ansi 2 Color",
    "Ansi 11 Color"       => "Ansi 3 Color",
    "Ansi 12 Color"       => "Ansi 4 Color",
    "Ansi 13 Color"       => "Ansi 5 Color",
    "Ansi 14 Color"       => "Ansi 6 Color",
    "Ansi 15 Color"       => "Ansi 7 Color",
    "Background Color"    => "Ansi 0 Color",
    "Foreground Color"    => "Ansi 7 Color",
    "Bold Color"          => "Foreground Color",
    "Badge Color"         => "Bold Color",
    "Cursor Color"        => "Foreground Color",
    "Cursor Guide Color"  => "Background Color",
    "Cursor Text Color"   => "Background Color",
    "Link Color"          => "Bold Color",
    # This warrants a bit of caution to distinguish between selections indicated
    # by applications and actual selections by iTerm2, since they may look the
    # same when iTerm2 simply falls back to the foreground and background colors
    "Selection Color"     => "Foreground Color",
    "Selected Text Color" => "Background Color"))

  key_convert = eltype(keys(colors)) <: Symbol ? identity :
    x -> Symbol(lowercase(replace(string(x), " " => "_", "-" => "_")))

  colors_dict = map(pairs(dictionary(pairs(colors)))) do (k, c)
    itermcolors_names[key_convert(k)] => c
  end |> dictionary

  function indirect(d, k, indirections)
    _k = indirections[k]
    return _k isa Colorant ? _k :
      haskey(d, _k) ? d[_k] : indirect(d, _k, indirections)
  end

  for k in setdiff(itermcolors_names, keys(colors_dict))
    insert!(colors_dict, k, indirect(colors_dict, k, defaults))
  end

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

function html_view(colorss...; name = nothing, names = nothing)
  colors_dicts = map(dictionary ∘ pairs, colorss)

  # background_colors = [colors_dict[:background]
  #   for colors_dict in colors_dicts if haskey(colors_dict, :background)]
  # background_color = !isempty(background_colors) &&
  #   allequal(map(RGBA{N0f8}, background_colors)) ? first(background_colors) :
  #                                                  colorant"black"
  # 
  # foreground_colors = [colors_dict[:foreground]
  #   for colors_dict in colors_dicts if haskey(colors_dict, :foreground)]
  # foreground_color = !isempty(foreground_colors) &&
  #   allequal(map(RGBA{N0f8}, foreground_colors)) ? first(foreground_colors) :
  #                                                  colorant"white"

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
          <th scope="col">$name</th>
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

  name_strs = isnothing(names) ? ("" for colors in colorss) :
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

function write_files(colorss::Pair...; name = "colors")
  colors_dicts = dictionary(colorss)
  names = map(first, colorss)
  mkpath(joinpath(out_dir, "html"))
  html_str = html_view(colors_dicts...; names, name)
  write(joinpath(out_dir, "html", "$name.html"), html_str)
  for (partname, colors) in pairs(colors_dicts)
    itermcolors_str = itermcolors(colors)
    mkpath(joinpath(out_dir, "itermcolors", "$name"))
    write(joinpath(out_dir, "itermcolors", "$name", "$partname.itermcolors"),
          itermcolors_str)
  end
  return termview(map(last, colorss)...)
end

macro write_files(name, colorss...)
  exs = (:($(string(colors)) => $colors) for colors in colorss)
  return :(write_files($(exs...); name = $name))
end
