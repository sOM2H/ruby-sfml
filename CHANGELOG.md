# Changelog

All notable changes are documented here. The format roughly follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the gem
versioning is [described in the README](README.md#versioning) — first
three segments mirror the targeted CSFML release, fourth segment is
ruby-sfml's own patch level.

## [Unreleased]

### Added
- `Window#icon=` and `RenderWindow#icon=` — set the window's title-bar /
  taskbar icon from any `SFML::Image`. Wraps `sfWindow_setIcon` /
  `sfRenderWindow_setIcon`. New example
  [21_window_icon](examples/21_window_icon/window_icon.rb) builds a
  procedural 32×32 ruby-style icon to demo the API.
- `Image#save_to_memory(format)` — encode an image to a Ruby String of
  bytes in the given format (`"png"`, `"jpg"`, `"bmp"`, `"tga"`),
  without touching the disk. Useful for screenshots over the network,
  data: URLs, or piping into other image-processing libraries. Wraps
  `sfImage_saveToMemory` plus the `sfBuffer_*` helpers in
  libcsfml-system.
- Shader array uniforms — `shader[:positions] = [[x, y], ...]` and
  similar for vec3 / vec4 arrays; also accepts `Vector2` / `Vector3`
  elements interchangeably. New explicit `Shader#set_float_array` for
  `uniform float arr[N];` (which can't be inferred via `[]=` because
  it'd collide with the vec3 case). Wraps the
  `sfShader_set{Float,Vec2,Vec3,Vec4}UniformArray` family.
- `Window#minimum_size=` / `#maximum_size=` and the same on
  `RenderWindow` — clamp how small or large the OS lets the user
  drag the window. Accepts `[w, h]`, `Vector2`, or `nil` (clears the
  limit). Wraps `sfWindow_setMinimumSize` / `setMaximumSize` and the
  RenderWindow equivalents.
- `Listener.velocity` and `Listener.cone` — finish the 3D-audio
  surface on the listener side. Velocity feeds the Doppler effect
  for sources whose `doppler_factor` is non-zero; cone (a
  `SoundCone`, or a Hash convertible to one) attenuates sources
  outside a directional pickup pattern.
- 3D-audio polish for `Sound` and `Music` — now expose `velocity`,
  `doppler_factor`, `direction`, and `cone` (via the new
  `SFML::SoundCone` value class — `inner_angle`, `outer_angle`,
  `outer_gain`). Cone setter accepts both a `SoundCone` and a
  Hash. Plus `effect_processor=` for installing a real-time DSP
  Ruby callable on the audio thread (`->(samples, channels) {
  ... }`); pass `nil` to remove it. The DSP path is documented as
  Ruby+GVL-limited and best for very light effects only. Wraps
  the corresponding `sfSound_*` and `sfMusic_*` setters/getters
  plus `setEffectProcessor`.
- `SFML::VertexBuffer` — GPU-resident vertex buffer (VBO). Same
  shape as `VertexArray` but vertices live on the GPU, so a draw
  call ships only an OpenGL handle instead of re-uploading every
  frame. `new(vertices, primitive_type:, usage:)` (one of `:stream`
  / `:dynamic` / `:static`), `update(vertices, offset:)` for
  partial uploads, `draw_range_on(target, first, count)` to draw a
  slice. `VertexBuffer.available?` reports whether the GPU
  supports VBOs at all (fall back to `VertexArray` if it doesn't).
  Wraps the `sfVertexBuffer_*` family plus the
  `sfRender{Window,Texture}_drawVertexBuffer{,Range}` draw paths.
- `Window.from_handle` / `RenderWindow.from_handle` — wrap an
  existing OS-level window (HWND, NSView*, X11 Window xid). The
  outside framework owns the window's lifecycle; SFML just renders
  into it. Pair with `#native_handle` to interop in the other
  direction. Wraps `sfWindow_createFromHandle` /
  `sfRenderWindow_createFromHandle` and the matching
  `getNativeHandle` getters.
- `SFML::SoundStream` — procedural audio source. Subclass it and
  override `#on_get_data` to return an Array of `Int16` PCM samples
  (or `nil` to stop); optionally override `#on_seek(time)` to
  support `playing_offset=`. Same playback / 3D-positional API as
  `Sound` and `Music` (volume, pitch, looping, position,
  attenuation, min_distance, relative_to_listener). Wraps the full
  `sfSoundStream_*` family. Includes example
  [23_sound_stream](examples/23_sound_stream/sound_stream.rb) — a
  real-time sine synth with arrow-key pitch / volume control.
- `SFML::Network::SocketSelector` — multiplex many sockets onto one
  blocking `wait`. `add` / `remove` / `clear` / `wait(timeout:)`
  / `ready?(socket)`. Polymorphic across `TcpListener`, `TcpSocket`,
  `UdpSocket`. The `wait` call releases the GVL, so other Ruby
  threads keep running during the syscall. Wraps the
  `sfSocketSelector_*` family.
- `SFML::Network::Ftp` — CSFML's FTP client wrapped as idiomatic Ruby:
  `connect`, `login` / `login_anonymous`, `working_directory`,
  `directory_listing`, `change_directory`, `parent_directory`,
  `create_directory`, `delete_directory`, `rename_file`,
  `delete_file`, `download`, `upload`, `send_command`, `keep_alive`,
  `disconnect`. Each call returns a `Response` (or
  `DirectoryResponse` / `ListingResponse`) with `#ok?`, `#status`,
  `#status_symbol`, `#message`, plus `#directory` or `#names`
  where applicable. Network calls release the GVL.
  Same caveat as Http — Ruby stdlib `Net::FTP` is the better choice
  in production.
- `SFML::Network::Http` — CSFML's HTTP/1.x client in idiomatic Ruby
  form. `Http.new(host, port:)` plus `#send_request(method:, uri:,
  fields:, body:, http_version:, timeout:)` returns an `Http::Response`
  with `#status` (Integer) / `#status_symbol` (`:ok`, `:not_found`,
  `:connection_failed`, …), `#body`, `#field(name)`, `#http_version`.
  Marked `blocking: true` so the GVL is released during the network
  round-trip and concurrent Ruby threads can run. Wraps
  `sfHttp_*`, `sfHttpRequest_*`, `sfHttpResponse_*`. Note: for any
  non-trivial use (TLS, redirects, JSON, retries), Ruby's stdlib
  `Net::HTTP` is the better tool — this binding exists for parity
  with CSFML, not because we recommend it.
- `SFML::Sensor` polling module — `available?(type)`, `enable(type)`,
  `disable(type)`, `value(type)` for the six sensor types
  (`:accelerometer`, `:gyroscope`, `:magnetometer`, `:gravity`,
  `:user_acceleration`, `:orientation`). The `:sensor_changed` event
  variant now decodes its `sensor:` and `value:` payloads. Wraps
  `sfSensor_isAvailable` / `sfSensor_setEnabled` /
  `sfSensor_getValue`.
- `SFML::Touch` polling module — `down?(finger)` and
  `position(finger, relative_to: window)`. Touch event variants
  (`:touch_began`, `:touch_moved`, `:touch_ended`) now decode their
  `finger:` and `position:` payloads (previously fell through to
  empty data). Wraps `sfTouch_isDown` / `sfTouch_getPosition` /
  `sfTouch_getPositionRenderWindow`.
- `Sound#playing_offset` / `playing_offset=` and `Music#playing_offset`
  / `playing_offset=` — read or seek the playback head as a
  `SFML::Time`. Setter also accepts a Numeric (interpreted as
  seconds). Wraps `sfSound_setPlayingOffset` /
  `sfMusic_setPlayingOffset` and the matching getters.
- Stencil buffer support — new `SFML::StencilMode` value class with
  symbolic comparisons (`:equal`, `:always`, etc.) and update
  operations (`:replace`, `:keep`, etc.). Pass it via `stencil_mode:`
  to `RenderTarget#draw` for two-pass mask/clip effects, and clear
  the stencil with `target.clear(color, stencil: N)` or
  `target.clear(stencil: N)`. Wraps `sfRenderWindow_clearStencil` /
  `clearColorAndStencil` (and the RenderTexture twins) plus the
  existing `stencil_mode` slot in `sfRenderStates`. New example
  [22_stencil_mask](examples/22_stencil_mask/stencil_mask.rb)
  demonstrates a cursor-following spotlight that clips an animated
  rainbow background.

### Fixed
- `at_exit` hook now writes the unhandled exception (message, class,
  backtrace) to stderr before calling `exit!`. Previously `exit!`
  short-circuited Ruby's terminal exception reporter, so an error in
  `setup` or any other top-level user code looked like a silent exit.

## [3.0.0.0] — initial release

First public cut. Targets **CSFML 3.0.0** (released March 2025) and
**Ruby ≥ 3.2**. API surface complete for the SFML 3.0 spec; some
engineering polish still pending (`gem build` end-to-end verification,
RBS signatures, hosted RDoc).

### System
- `Vector2`, `Vector3` — operator-friendly value classes with `coerce`
  (`2 * vec`), pattern-match `deconstruct`, `length`, `normalize`,
  `dot`/`cross`, conversion helpers
- `Rect` — single class for float / int rectangles with `contains?`,
  `intersects?`, deconstruction
- `Time`, `Clock` — monotonic timer, immutable Time arithmetic

### Window
- `RenderWindow` — main 2D drawing surface
- `Window` — bare GL-only window for raw-OpenGL apps
- `Event` — pattern-matchable hash-like value (`case event in {type: :key_pressed, code: :escape}`)
- `Keyboard`, `Mouse`, `Joystick` — polling APIs with symbol-named keys / buttons / axes
- `Cursor` — 21 system cursor types + `from_pixels` for custom shapes
- `Clipboard` — UTF-8 in / UTF-8 out via the unicode-string CSFML path
- `VideoMode`

### Graphics
- `Color`, `Image`, `Texture`, `RenderTexture`
- `Sprite`, `CircleShape`, `RectangleShape`, `ConvexShape` — share a
  `Transformable` mixin (position, rotation, scale, origin, move)
- `Vertex`, `VertexArray` — batched geometry; six primitive types
- `Font`, `Text` — UTF-8 strings, `local_bounds` / `global_bounds`,
  Font.find searches common system paths plus a bundled DejaVu Sans
- `View` — 2D camera, including `from_rect` and viewport for split-screen / minimap
- `RenderStates`, `BlendMode` — full blend mode catalogue, kwargs
  shortcut on `window.draw(thing, blend_mode: SFML::BlendMode::ADD)`
- `Shader` — load from file or memory, uniform setter that dispatches by
  Ruby type (`shader[:time] = 1.5`, `shader[:tex] = my_texture`,
  `shader[:tint] = SFML::Color.red`)
- `Transform` — standalone 4×3 matrix value class, chainable
- `RenderTarget#draw` accepts `texture:`, `blend_mode:`, `shader:`,
  `coordinate_type:`, `render_states:` kwargs
- `RenderTarget#draw_primitives(vertices, type)` — one-shot batch
  rendering without a `VertexArray` object

### Audio
- `SoundBuffer`, `Sound`, `Music`
- 3D positional audio on Sound and Music (`#position=`, `#attenuation=`,
  `#min_distance=`, `#relative_to_listener=`)
- `Listener` — global "ear" with `position`, `direction`, `up_vector`,
  `global_volume`
- `SoundBufferRecorder` + `SoundRecorder` static helpers — record audio
  from the system mic into a SoundBuffer

### Network
- `Network::IpAddress` — value class with `from_string`, `from_bytes`,
  `LOCALHOST` / `ANY` / `BROADCAST` constants, `local`, `public`
- `Network::TcpSocket`, `Network::TcpListener` — TCP client + server,
  blocking and non-blocking modes
- `Network::UdpSocket` — connectionless datagrams
- `SocketStatus` returned as symbols (`:done`, `:not_ready`,
  `:disconnected`, `:error`, `:partial`)
- Intentionally not wrapped: `Http`, `Ftp` (use Ruby stdlib's
  `Net::HTTP` / `Net::FTP` — they're nicer)

### Helpers
- `Game` — subclass-friendly main loop with `setup` / `update(dt)` /
  `draw` / `on_event` hooks. Auto-quit on Esc + close button.
- `Assets` — cached, search-path-driven loader.
  `SFML::Assets.font("DejaVuSans")`, `.texture(name)`, `.sound(name)`,
  `.music(name)`. Default search root is `<dir of $0>/assets/`.
- Bundled DejaVu Sans (Bitstream Vera license) — `SFML::Font.default`
  works without a system font install

### Engineering
- Two-tier API: `SFML::C::*` thin FFI bindings, `SFML::*` idiomatic
  Ruby on top. Most user-facing classes are ~50–150 LOC each
- `RenderTarget` mixin — `RenderWindow` and `RenderTexture` share
  every drawing method through CSFML_PREFIX dispatch
- 287 RSpec examples, all hitting real CSFML
- 20 self-contained example folders under [examples/](examples/)
- CI matrix: Ubuntu + macOS × Ruby 3.2 / 3.3 / 3.4
- Linux CI builds CSFML 3 from source (cached) and runs specs under
  `xvfb-run`
- `extconf.rb` checks every required `libcsfml-*` plus probes
  `sfClock_isRunning` (CSFML 3.0+ only) — `gem install` aborts with a
  helpful message on CSFML 2.x
- Same probe re-runs at `require "sfml"` time as a runtime sanity
  check
- `at_exit` hook stops live `Sound`/`Music` and bypasses Ruby's
  finalizer pass via `exit!` — eliminates a class of GL/OpenAL-teardown
  segfaults that plagued every non-trivial example
- RDoc 7 (Aliki theme) generated via `rake rdoc`
