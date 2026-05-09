<h1>
  <img src="ruby-sfml.png" alt="" height="48" align="absmiddle">
  ruby-sfml
</h1>

Modern, idiomatic Ruby bindings for [SFML 3.x](https://www.sfml-dev.org/) via [CSFML](https://github.com/SFML/CSFML) and [Ruby FFI](https://github.com/ffi/ffi).

[![gem version](https://img.shields.io/gem/v/ruby-sfml.svg)](https://rubygems.org/gems/ruby-sfml)
[![docs](https://img.shields.io/badge/docs-rubydoc.info-blue.svg)](https://www.rubydoc.info/gems/ruby-sfml)

> **Status:** API surface complete for SFML 3.0 — system, window, graphics (incl. stencil buffer + VBOs), audio (incl. 3D positional + custom DSP + procedural streams), network (incl. HTTP / FTP / socket selector), input (keyboard, mouse, joystick, touch, sensors), plus the higher-level `App` / `Scene` / `Assets` helpers. 410 RSpec examples, 24 runnable example folders.

## Why

The original [rbSFML](https://github.com/Groogy/rbSFML) is unmaintained and only works against SFML 2 and Ruby 2.2. `ruby-sfml` targets the current SFML 3.x line, modern Ruby (3.2+), and a Ruby-first API — blocks instead of polling loops, symbols instead of enums, operators on vectors, automatic resource cleanup via GC.

## Installation

ruby-sfml needs **Ruby ≥ 3.2** and **CSFML 3.0** (or compatible 3.x) on
the system. Install in two steps:

### 1. Install dependencies (CSFML)

| OS                       | Command                                  | Notes                                                                    |
| ------------------------ | ---------------------------------------- | ------------------------------------------------------------------------ |
| Ubuntu 25.04+ / Debian   | `sudo apt install libcsfml-dev`          | Ships CSFML 3                                                            |
| Ubuntu 22.04 / 24.04     | repo too old (CSFML 2.5)                 | Build from [3.0.0 release](https://github.com/SFML/CSFML/releases/tag/3.0.0) |
| macOS (brew)             | `brew install csfml`                     | Currently 3.x                                                            |
| Arch Linux               | `sudo pacman -S csfml`                   | Currently 3.x                                                            |
| Windows                  | https://www.sfml-dev.org/download/csfml/ | Pick the 3.0 tarball                                                     |

### 2. Install the gem

In a Bundler-managed project, add to your `Gemfile`:

```ruby
gem "ruby-sfml", "~> 3.0"
```

then `bundle install`.

Or drop it in directly:

```sh
gem install ruby-sfml
```

Hosted on [rubygems.org](https://rubygems.org/gems/ruby-sfml); HTML
docs auto-generate at
[rubydoc.info/gems/ruby-sfml](https://www.rubydoc.info/gems/ruby-sfml).

### How the CSFML check happens

ruby-sfml verifies the linked CSFML in two places so a missing or
out-of-date library never falls through to a cryptic segfault:

- **At `gem install`** — `extconf.rb` checks for the five
  `libcsfml-*` libraries plus a CSFML 3.0+ symbol
  (`sfClock_isRunning`). Aborts with a clear message if the system
  has CSFML 2.x.
- **At `require "sfml"`** — the same probe runs as a runtime sanity
  check, in case libraries were swapped between install and use.

## A 13-line app

```ruby
require "sfml"

class Hello < SFML::App
  title        "Hello"
  background   SFML::Color.cornflower_blue
  antialiasing 4

  def setup
    @ball = SFML::CircleShape.new(radius: 30, fill_color: SFML::Color.white,
                                  position: [200, 200])
  end

  def update(dt) = @ball.move(60 * dt.as_seconds * SFML::Vector2[1, 0])
  def draw       = window.draw(@ball)
end

Hello.new.run
```

`SFML::App` handles window creation, the main loop, event pumping, dt, and the Esc/close-button quit. Override `setup` / `update` / `draw` / `on_event`. Class-level macros (`title`, `framerate`, `antialiasing`, `background`, ...) set per-class defaults; per-instance kwargs to `.new` still override on a case-by-case basis. Drop into the manual loop style any time you want full control.

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
| Window   | `RenderWindow`, `Window` (bare, GL-only), `VideoMode`, `Event`, `Keyboard`, `Mouse`, `Joystick`, `Touch`, `Sensor`, `Cursor`, `Clipboard` |
| Graphics | `Color`, `Image`, `Texture`, `RenderTexture`, `Sprite`, `CircleShape`, `RectangleShape`, `ConvexShape`, `Vertex`, `VertexArray`, `VertexBuffer`, `Font`, `Text`, `View`, `BlendMode`, `StencilMode`, `RenderStates`, `Shader`, `Transform` |
| Audio    | `SoundBuffer`, `Sound`, `Music`, `Listener`, `SoundCone`, `SoundStream`, `SoundRecorder`, `SoundBufferRecorder` (3D positional + cones + Doppler + custom DSP via `effect_processor=`) |
| Helpers  | `Assets` (search-path + cache), `App` (lifecycle main loop with class-level config + `on_key` DSL + `pause` / `on_resize`), `Scene` (stateful screens + `switch_to` between them), `ContextSettings` (MSAA / GL version) |

**Network**: `IpAddress`, `TcpSocket`, `TcpListener`, `UdpSocket`, `SocketSelector` for stream / datagram networking, plus the niche `Http` and `Ftp` clients (use Ruby's `Net::HTTP` / `Net::FTP` if you have the choice — these exist for parity with CSFML).

## What's intentionally *not* wrapped

Three corners of CSFML 3 deliberately stay out:

- **Geometry shaders** — CSFML doesn't expose them at all (only
  vertex and fragment stages); there's nothing on the C side to
  wrap.
- **Raw `sf::SoundRecorder`** (per-buffer callbacks on the audio
  thread) — fights the GVL too hard for what it gives. Use
  `SFML::SoundBufferRecorder` for the common "record into memory,
  save on stop" path.
- **Custom `sf::InputStream`** for loading assets from non-file
  sources — Ruby's `IO` covers this. Read the bytes yourself and
  feed them into the byte-string constructors.

If anything else is missing or blocking you, **open an issue**.

## Other Ruby bindings worth knowing about

- SFML 2.x is *not* covered. The previous-generation gem
  [rbSFML](https://github.com/Groogy/rbSFML) targets SFML 2; it's
  unmaintained and only works with Ruby ≤ 2.2.
- [RubySFML3](https://github.com/gAndy50/RubySFML3) — a thin FFI
  wrapper that exposes the CSFML C API directly. If you want raw
  bindings (no idiomatic Ruby layer, no auto-cleanup), check that
  project instead.

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
| 04  | [app_class](examples/04_app_class/app_class.rb)                                 | Same idea on top of `SFML::App`                                     |
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
| 17  | [voice_memo](examples/17_voice_memo/voice_memo.rb)                             | Record from microphone via `SoundBufferRecorder`, save + play back |
| 18  | [draw_primitives](examples/18_draw_primitives/draw_primitives.rb)              | Raw `draw_primitives` — line burst rebuilt every frame             |
| 19  | [udp_loopback](examples/19_udp_loopback/udp_loopback.rb)                       | UDP send/receive on localhost via `Network::UdpSocket`             |
| 20  | [bare_window](examples/20_bare_window/bare_window.rb)                          | `SFML::Window` (no 2D batcher) — events for raw-OpenGL apps        |
| 21  | [window_icon](examples/21_window_icon/window_icon.rb)                          | Procedural 32×32 icon set as the window/taskbar icon              |
| 22  | [stencil_mask](examples/22_stencil_mask/stencil_mask.rb)                       | Two-pass `StencilMode` masking — cursor spotlight clip            |
| 23  | [sound_stream](examples/23_sound_stream/sound_stream.rb)                       | Real-time sine synth via `SFML::SoundStream` subclass             |

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

## Versioning

The gem version is `MAJOR.MINOR.PATCH.GEM_PATCH` — the first three segments mirror the CSFML release the gem was built against; the fourth is our own patch level for fixes / additions on top of the same upstream:

| gem version | targets CSFML | meaning                                         |
| ----------- | ------------- | ----------------------------------------------- |
| `3.0.0.0`   | 3.0.0         | First cut against CSFML 3.0.0                   |
| `3.0.0.1`   | 3.0.0         | Bug fix on top of CSFML 3.0.0                   |
| `3.0.1.0`   | 3.0.1         | CSFML 3.0.1 ships, we re-cut                    |
| `3.1.0.0`   | 3.1.0         | New CSFML minor — added bindings for new APIs   |

`SFML::CSFML_VERSION` exposes the upstream string at runtime.

Bundler-pinning patterns:

```ruby
gem "ruby-sfml", "~> 3.0"      # any 3.x.x.x — typical
gem "ruby-sfml", "~> 3.0.0"    # only 3.0.0.x — hold across a CSFML minor
gem "ruby-sfml", "~> 3.0.0.0"  # only our patches on CSFML 3.0.0 — paranoid pin
```

## Process exit

ruby-sfml installs a single `at_exit` hook that:

1. Stops every live `SFML::Sound` / `SFML::Music` so the audio thread quiets before anything is freed.
2. Calls `Kernel#exit!` with the appropriate status, bypassing Ruby's natural finalizer pass.

This is intentional. CSFML's GL context, font glyph atlases, and OpenAL state are reclaimed by the OS on process exit; running each `FFI::AutoPointer` finalizer in a non-deterministic order tends to crash inside libGL/libopenal. The OS doesn't care, and now neither do we.

The trade-off: any user `at_exit` hook registered **before** `require "sfml"` will be skipped. Hooks registered after the require run first (Ruby's at_exit is LIFO) and are unaffected. Put your `require` at the top of the file (the normal place for it) and there's nothing to think about.

## Architecture

Two layers. Users only touch the top one.

```
SFML::C    # thin FFI wrapper around CSFML, 1:1 with the C API
SFML       # idiomatic Ruby on top
```

Each render target (RenderWindow + RenderTexture) includes a `Graphics::RenderTarget` mixin that dispatches `clear`, `display`, `draw`, `view=`, `map_pixel_to_coords` etc. through the includer's `CSFML_PREFIX`. Adding a new target (say a future `RenderImage`) is ~30 lines.

When SFML 3.1 / CSFML 3.1 ships, only the bottom layer typically needs to move.

## Development

```sh
bundle install
bundle exec rspec        # 410 examples (all subsystems on Linux)
bundle exec rake rdoc    # generate HTML docs in doc/ (Aliki theme via RDoc 7)
```

The spec suite hits real CSFML for everything that isn't pure Ruby — `Clock` reads the real monotonic clock, `Text#local_bounds` measures real glyphs, audio loads a WAV — so a green run also confirms the FFI bindings line up. `spec/fixtures/` holds the only assets the suite touches (a font and a tiny WAV) so tests are independent of `examples/`.

CI runs the full suite on Ubuntu and macOS × Ruby 3.2 / 3.3 / 3.4. Linux builds CSFML 3 from source (cached), then runs specs under `xvfb-run` so the headless runner has an X server for `RenderWindow`.

### Audio specs on macOS

CoreAudio + the CSFML OpenAL backend occasionally hang an audio test group on macOS. To keep a darwin run reliable, every spec under `spec/sfml/audio/` is auto-tagged `:audio` and **excluded by default on darwin**. Force them in when you do want to run them:

```sh
bundle exec rspec --tag audio                  # only audio specs
bundle exec rspec spec/sfml/audio/sound_spec.rb --tag audio   # one file
```

On Linux the `:audio` filter doesn't fire — the whole suite runs by default.

## License

MIT. See [LICENSE.txt](LICENSE.txt).

The gem also bundles [DejaVu Sans](https://dejavu-fonts.github.io/) under its [permissive license](lib/sfml/assets/fonts/DejaVuSans.LICENSE.txt) — used as the default font when you don't supply your own.
