# ruby-sfml

Modern, idiomatic Ruby bindings for [SFML 3.x](https://www.sfml-dev.org/) via [CSFML](https://github.com/SFML/CSFML) and [Ruby FFI](https://github.com/ffi/ffi).

> **Status:** very early development. The API will change.

## Why

The original [rbSFML](https://github.com/Groogy/rbSFML) is unmaintained and only works against SFML 2 and Ruby 2.2. `ruby-sfml` targets the current SFML 3.x line, modern Ruby (3.2+), and a Ruby-first API — blocks instead of polling loops, symbols instead of enums, operators on vectors, automatic resource cleanup via GC.

## Requirements

- Ruby `>= 3.2`
- CSFML 3.x installed at the system level

### Install CSFML

| OS              | Command                                  |
| --------------- | ---------------------------------------- |
| Ubuntu / Debian | `sudo apt install libcsfml-dev`          |
| macOS (brew)    | `brew install csfml`                     |
| Arch Linux      | `sudo pacman -S csfml`                   |
| Windows         | https://www.sfml-dev.org/download/csfml/ |

If CSFML is missing, `gem install ruby-sfml` will fail at install time with a helpful message — it won't silently install a broken gem.

## A 12-line game

```ruby
require "sfml"

class Hello < SFML::Game
  def setup
    @ball = SFML::CircleShape.new(radius: 30, fill_color: SFML::Color.white,
                                  position: [200, 200])
  end

  def update(dt)  = @ball.move(60 * dt.as_seconds * SFML::Vector2[1, 0])
  def draw        = window.draw(@ball)
end

Hello.new(title: "Hello", background: SFML::Color.cornflower_blue).run
```

`SFML::Game` handles window creation, the main loop, event pumping, dt, and the Esc/close-button quit. Override `setup` / `update` / `draw` / `on_event`. Drop into the manual loop style any time you want full control.

## A 5-line manual loop

```ruby
require "sfml"

window = SFML::RenderWindow.new(800, 600, "Hello", framerate: 60)

while window.open?
  window.each_event do |event|
    case event
    in {type: :closed}                     then window.close
    in {type: :key_pressed, code: :escape} then window.close
    else # always include `else` — case/in raises on unmatched events.
    end
  end

  window.clear(SFML::Color.cornflower_blue)
  window.display
end
```

## Available modules

| Area     | Classes                                                      |
| -------- | ------------------------------------------------------------ |
| System   | `Vector2`, `Vector3`, `Rect`, `Time`, `Clock`                |
| Window   | `RenderWindow`, `VideoMode`, `Event`, `Keyboard`, `Mouse`, `Joystick`, `Cursor`, `Clipboard` |
| Graphics | `Color`, `Image`, `Texture`, `RenderTexture`, `Sprite`, `CircleShape`, `RectangleShape`, `ConvexShape`, `Vertex`, `VertexArray`, `Font`, `Text`, `View`, `BlendMode`, `RenderStates`, `Shader` |
| Audio    | `SoundBuffer`, `Sound`, `Music`, `Listener` (3D positional audio supported on Sound and Music) |
| Helpers  | `Assets` (search-path + cache), `Game` (lifecycle main loop) |

The `SFML::Network` module is intentionally not in the first release; it'll come later.

## Examples

Each example is a self-contained folder under [examples/](examples/),
numbered roughly in learning order. Assets each example needs sit next
to its script. Run from the gem root:

```sh
bundle exec ruby examples/<NN_name>/<name>.rb
```

| #   | Example                                                                        | What it shows                                                       |
| --- | ------------------------------------------------------------------------------ | ------------------------------------------------------------------- |
| 01  | [hello_window](examples/01_hello_window/hello_window.rb)                       | Empty window, manual event loop                                     |
| 02  | [events_demo](examples/02_events_demo/events_demo.rb)                          | Pattern matching on input events                                    |
| 03  | [bouncing_ball](examples/03_bouncing_ball/bouncing_ball.rb)                    | dt-based physics, `CircleShape` + `RectangleShape`                  |
| 04  | [game_class](examples/04_game_class/game_class.rb)                             | Same idea on top of `SFML::Game`                                    |
| 05  | [mouse_demo](examples/05_mouse_demo/mouse_demo.rb)                             | Polling vs. events; paint with the mouse                            |
| 06  | [pong](examples/06_pong/pong.rb)                                               | Two-player Pong with in-window score (`Text`) and bounce `Sound`    |
| 07  | [scrolling_world](examples/07_scrolling_world/scrolling_world.rb)              | `View` as a 2D camera: drag-pan, wheel-zoom around cursor, FPS HUD  |
| 08  | [joystick_demo](examples/08_joystick_demo/joystick_demo.rb)                    | Live gamepad inspector (axes, buttons, connect/disconnect)          |
| 09  | [image_viewer](examples/09_image_viewer/image_viewer.rb)                       | Load a PNG, mutate the `Image`, re-upload to `Texture` on a key     |
| 10  | [pixel_paint](examples/10_pixel_paint/pixel_paint.rb)                          | Paint into a CPU `Image`, blit to GPU `Texture` each dirty frame    |
| 11  | [particles](examples/11_particles/particles.rb)                                | Thousands of points in one draw call via `VertexArray` + `ConvexShape` ground |
| 12  | [render_texture](examples/12_render_texture/render_texture.rb)                 | Off-screen `RenderTexture` for trail / motion-blur effects        |
| 13  | [tilemap](examples/13_tilemap/tilemap.rb)                                      | Textured `VertexArray` tilemap + additive `BlendMode` torch       |
| 14  | [shader_wave](examples/14_shader_wave/shader_wave.rb)                          | Pure GLSL fragment `Shader` — procedural ripple + plasma          |
| 15  | [cursors_clipboard](examples/15_cursors_clipboard/cursors_clipboard.rb)        | All 21 system `Cursor` shapes + `Clipboard` copy/paste            |
| 16  | [spatial_audio](examples/16_spatial_audio/spatial_audio.rb)                    | 3D positional `Sound` + `Listener` — three drones around the cursor |

## Architecture

Two layers. Users only touch the top one.

```
SFML::C    # thin FFI wrapper around CSFML, 1:1 with the C API
SFML       # idiomatic Ruby on top
```

When SFML 3.1 / CSFML 3.1 ships, only the bottom layer typically needs to move.

## Idioms baked in

- **Symbols, not enums:** `Keyboard.key_pressed?(:escape)`, not `Keyboard::Key::Escape`.
- **Pattern matching for events:**
  ```ruby
  case event
  in {type: :key_pressed, code: :escape}
  in {type: :resized, size: {x:, y:}}
  in {type: :mouse_button_pressed, button: :left, position: {x:, y:}}
  end
  ```
- **Vectors with operators:** `pos + velocity * dt`, `2 * vec`, `vec.length`, deconstruction in `case/in`.
- **Kwargs constructors:** `Sprite.new(texture, position: [0, 0], color: SFML::Color.red)`, `CircleShape.new(radius: 10, fill_color: ...)` — no setter chains.
- **Asset manager with cache:** `SFML::Assets.font("DejaVuSans")`, `SFML::Assets.sound("blip")` — load each thing once, refer by name.
- **GC-managed resources:** every CSFML pointer goes through `FFI::AutoPointer`, so `sfXxx_destroy` is called automatically.

## Tests

```sh
bundle exec rspec
```

The suite hits real CSFML for everything that isn't pure Ruby — `Clock` reads the real monotonic clock, `Text#local_bounds` measures real glyphs, audio loads a WAV — so a green run also confirms the FFI bindings line up.

## License

MIT. See [LICENSE.txt](LICENSE.txt).
