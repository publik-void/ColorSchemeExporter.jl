brightname(name) = Symbol(:bright_, name)

ansi_monos = (:black, :white)
ansi_huecolors = (:red, :yellow, :green, :cyan, :blue, :magenta)

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
