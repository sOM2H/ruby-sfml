# Changelog

All notable changes are documented here. The format roughly follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the gem
versioning is [described in the README](README.md#versioning) — first
three segments mirror the targeted CSFML release, fourth segment is
ruby-sfml's own patch level.

HTML API docs: <https://ruby-sfml-doc.netlify.app/>

## [Unreleased]

## [3.0.0.7] — 2026-05-12

Documentation pass. Every public class / module / method now
carries at least a one-line RDoc comment — coverage went from
~36% (`rake rdoc:coverage`) to ~68%. Pair this release with the
new docs site at <https://ruby-sfml-doc.netlify.app/>.

### Changed — documentation

- Hand-written, context-aware docstrings on the value classes
  (`Vector2`, `Vector3`, `Color`, `Rect`, `Time`): every operator,
  every helper, every pattern-match hook.
- Audio API surface (`Sound`, `Music`, `SoundStream`, `Listener`):
  every playback method, every property setter/getter, every 3D-
  audio knob has a real description.
- Graphics — `Transformable` mixin (`#position` / `#rotation` /
  `#scale` / `#origin` / `#move` / `#rotate` / `#scale_by`), then
  `CircleShape` / `RectangleShape` / `ConvexShape` / `Text` /
  `VertexArray` / `RenderWindow`. Color named-accessors,
  geometric introspection, fill / outline / texture binding.
- Network — typed `Packet` reader / writer methods, full FTP
  surface (`#download` / `#upload` / `#directory_listing` / …).
- The autodoc pass fills in trivial setter / getter / predicate
  pairs everywhere else, so the docs site has at least an
  identifiable signature line on every public method.

### Changed — infra

- `documentation_uri` in the gemspec now points to
  <https://ruby-sfml-doc.netlify.app/> (was rubydoc.info).
  rubydoc.info still works as an archive of older releases.
- `.rdoc_options` ships inside the gem (`gem unpack` exposes it),
  so the docs-site repo can `rdoc` an unpacked release without
  re-supplying title / template / markup / exclude config.
- Added `script/build-docs.sh` — local-only build that renders
  `../ruby-sfml-doc/public/`. Optional `--check` mode catches
  "docs out of date with source" in a pre-push hook.

## [3.0.0.6] — 2026-05-12

Quality-of-life release: the CSFML 3.0 surface was already covered;
this round adds the helpers and tooling you reach for when building
on top of it.

### Added — system

- **Vector2 / Vector3 math** — `#distance`, `#distance_sq`,
  `#lerp`, `#project_on`, `#reflect`, `#clamp_length`, `#zero?`,
  `#abs`, plus `Vector2#angle`, `#angle_to(other)`,
  `#rotated(degrees)` / `#rotated_rad(radians)`,
  `#perpendicular`, and `Vector3#angle_between`.
  Both classes gain `#to_v3` / `#to_v2` for cross-dimension
  promotion + scalar coercion (`2 * vec`).

### Added — graphics

- `RenderWindow#screenshot(path)` — capture the current
  back-buffer to disk (PNG / JPG / BMP / TGA inferred by
  extension).
- `RenderWindow#capture_image` — same capture, returns an
  in-memory `SFML::Image` for further processing.
- **`SFML::SpriteSheet`** — slice a uniformly-gridded image into
  numbered frames. `.load(path, frame_size:, padding:, margin:)`,
  `#region(i)`, `#region_at(col, row)`, `#sprite(i)`,
  `#animation(fps:, ...)`.
- **`SFML::TextureAtlas`** — load Aseprite / TexturePacker JSON
  descriptors. `.load(json_path)`, `#region(name)`,
  `#sprite(name)`, `#animation(names, fps:)` (auto-derives fps
  from Aseprite per-frame durations when present).
- **`SFML::Animation`** — frame-based animation that drives a
  Sprite's texture_rect over time. Loop / one-shot,
  `#update(dt)`, `#reset`, `#done?`. Sprite-style transform
  setters (`position=`, `rotation=`, `scale=`, `origin=`,
  `color=`) for ergonomic use.
- **`SFML::ParticleSystem`** — VertexArray-backed particle pool.
  `#spawn(position:, velocity:, lifetime:, color:, size:)`,
  optional `gravity:`, `update_particle` subclass hook for
  drag / attractors / colour curves.

### Added — game-loop

- **Fixed timestep** — `fixed_timestep N` class macro on
  `SFML::App` calls `update(dt)` exactly N times per second with
  a fixed dt (semi-implicit Euler accumulator, capped at 5
  catch-up steps to prevent the "spiral of death"). Read
  `interpolation_alpha` from `#draw` to smoothly render between
  fixed updates.
- **Input actions DSL** — `action :jump, keys: [...],
  scancodes: [...], mouse_buttons: [...], joy_buttons: [...]`
  on `SFML::App` and `SFML::Scene`. Poll with `action_pressed?
  (:name)` from `update` / `draw`; build digital axes with
  `axis(negative:, positive:)`. Scene actions inherit from the
  host App's actions.

### Added — errors

- Domain-specific exception hierarchy:
  - `SFML::LoadError` — asset load failures (file, memory,
    stream)
  - `SFML::AudioError` — capture / OpenAL / channel-map
  - `SFML::NetworkError` — sockets / packet framing
  - `SFML::ShaderError` — GLSL compile / link
  - `SFML::GraphicsError` — generic graphics-side failures
  - `SFML::WindowError` — window / context creation
  All inherit from `SFML::Error`, so existing
  `rescue SFML::Error` blocks keep catching everything.

### Added — CI / tooling

- CI badge in `README.md`.

## [3.0.0.5] — 2026-05-11

Round-trip release: closes every remaining CSFML 3.0 gap that's
useful from Ruby. The library now covers the surface area you'd
expect for porting a CSFML application straight across.

### Added — graphics

- `Color#+`, `Color#-`, `Color#*` (alias `modulate`),
  `Color#to_integer` / `Color.from_integer(value)` — channel-wise
  saturating arithmetic, plus packed 0xRRGGBBAA round-trips.
- Texture binding + geometric introspection on the three concrete
  shapes via the new `Graphics::ShapeInspectable` mixin:
  `CircleShape`/`RectangleShape`/`ConvexShape` all gain
  `texture` / `texture=` / `set_texture(tex, reset_rect:)`,
  `texture_rect` / `texture_rect=`, `point(i)`, `geometric_center`,
  `local_bounds`, `global_bounds`, `transform`, `inverse_transform`,
  `dup` / `clone`. `RectangleShape` additionally exposes
  `point_count`.
- `SFML::Shape` — callback-driven abstract shape. Subclass and
  override `#point_count` / `#point(i)` to drive geometry from
  live Ruby data; call `#update` after the source data changes.
- `SFML::TransformableObject` — standalone transform container
  (CSFML's `sfTransformable*`). Useful as a base for custom
  drawables that combine a transform with their own rendering.
- `VertexArray#dup` / `#clone` — independent deep copy.
- `VertexBuffer#bind` / `VertexBuffer.unbind` — bind a VBO as the
  active GL vertex buffer (for mixing raw GL with SFML rendering).
- Texture sRGB variants via the `srgb:` kwarg on
  `Texture.load`, `Texture.create`, `Texture.from_memory`,
  `Texture.from_image`, and `Texture#resize`.
- `Shader#set_mat3` / `#set_mat4` / `#set_mat3_array` /
  `#set_mat4_array` and `Shader#set_bvec(name, *components)` —
  matrix and bool-vector uniforms.
- `Shader.from_stream(vertex:, geometry:, fragment:)`,
  `Font.from_stream(io)`, `Image.from_stream(io)`,
  `Texture.from_stream(io, srgb:, ...)` — load any of these from a
  Ruby IO-like object (File, StringIO, network reader). Backed by
  the new `SFML::InputStream` adapter that wraps a Ruby IO as
  CSFML's `sfInputStream*`.

### Added — audio

- Full 3D-audio surface on `SoundStream` (mirror of Sound / Music):
  `pan`, `min_gain` / `max_gain`, `max_distance`,
  `spatialization_enabled?`, `direction`, `cone`, `velocity`,
  `doppler_factor`, `directional_attenuation_factor`,
  `effect_processor=` (real-time DSP filter), `channel_map` — and
  the `=` setters.
- `SoundRecorder#channel_map` — read the channel layout the
  recorder is producing.
- `SFML::SoundRecorder` — callback-based mic capture. Subclass
  and override `#on_start` / `#on_process_samples(samples,
  channels)` / `#on_stop`. The pre-existing module-level helpers
  (`SoundRecorder.available?` / `.devices` / `.default_device`)
  are preserved as class methods.
- `Music.from_stream(io, **opts)` and
  `SoundBuffer.from_stream(io)` — stream-backed audio loaders.

### Added — network

- `SFML::Network::Packet` — wire-compatible with `sf::Packet`. Typed
  read / write for `Bool`, `Int8`–`Int64`, `Uint8`–`Uint64`,
  `Float`, `Double`, `String`; `#data` / `#size` / `#read_position`
  / `#end_of_packet?` / `#ok?` / `#clear` / `#dup`.
- `TcpSocket#send_packet` / `#receive_packet` and
  `UdpSocket#send_packet(packet, to:, port:)` /
  `#receive_packet` — structured framing on top of the existing
  raw byte send/receive.

### Added — window

- `Keyboard::SCAN_CODES` — full layout-independent scancode table
  (146 entries matching `sfScancode`).
- `Keyboard.scancode_pressed?(:scan_w)` — query the physical key
  regardless of keyboard layout (the standard for WASD-style games).
- `Keyboard.localize(scancode)` / `.delocalize(key)` /
  `.description(scancode)` — convert between physical scancodes
  and logical keys under the current OS layout, plus the
  human-readable description string.
- `Keyboard.virtual_keyboard_visible=` — on-screen keyboard toggle
  for touchscreen / mobile builds (no-op on desktop).
- `VideoMode.fullscreen_modes` — all video modes the display
  supports for true-fullscreen window creation, sorted from most
  to least pixels.
- `VideoMode#valid?` — does the display actually support this mode
  at fullscreen?
- `SFML::Context` — headless GL context. Activate it on a thread
  to compile shaders / make raw GL calls without a window. Static
  `Context.active_context_id`, `.extension_available?(name)`,
  `.gl_function(name)`.

### Added — system

- `SFML::InputStream(io)` — wraps a Ruby IO-like object (anything
  answering `read` / `seek` / `pos` / `size`) as the
  `sfInputStream*` argument CSFML loader functions take. Used
  internally by every `*.from_stream` factory.

## [3.0.0.4] — 2026-05-09

### Added — graphics

- `Sprite#dup` / `#clone`, `Sprite#texture` (borrowed reference),
  `Sprite#transform`, `Sprite#inverse_transform`.
- `View#scissor` / `View#scissor=` — normalised [0..1] clip rect
  applied at render time (paired with the existing `viewport` API).
- `Texture.from_memory(bytes, smooth:, repeated:)` — decode +
  upload a Ruby String of bytes (PNG / JPG / BMP / TGA / …) as a
  texture. Bypasses the disk for embedded assets / network blobs.
- `Texture#resize(w, h)` — reallocate GPU memory in place.
- `Texture#swap(other)` — atomically swap GPU memory between two
  textures (cheap double-buffer pattern).
- `Texture#native_handle` — the OpenGL texture-object name for
  raw GL interop.
- `Texture#update_from_texture(source, offset:)`,
  `Texture#update_from_render_window(window, offset:)`,
  `Texture#update_from_window(window, offset:)` — copy pixels
  from another GPU texture / from a window's back-buffer / from a
  bare-Window's framebuffer into this texture at `offset`.
- `RenderWindow#viewport(view = self.view)` and
  `RenderWindow#scissor(view = self.view)` — pixel-space
  `SFML::Rect`s the view actually covers / clips. Same on
  `RenderTexture`.
- `Shader#set_int_color(name, color)` — uploads a `SFML::Color`
  as a `vec4` uniform (CSFML normalises 0–255 → 0.0–1.0 for you).

### Added — audio
- `Sound#dup` / `#clone`, `Sound#buffer` reader.
- `Sound#pan` / `#pan=`, `Sound#min_gain`/`#max_gain` (and `=`),
  `Sound#max_distance` (and `=`), `Sound#spatialization_enabled?` /
  `#spatialization_enabled=`,
  `Sound#directional_attenuation_factor` (and `=`) — the full
  remaining 3D-audio surface from CSFML's SoundSource.
- Same set on `Music`: `pan`, gain clamps, max-distance,
  spatialisation, directional-attenuation.
- `Music#channel_count`, `Music#sample_rate` — stream introspection.
- `Music#loop_points` / `#loop_points=` — set the looping window
  inside a track ([offset_time, length_time] pair of `SFML::Time`s).
- `Music.from_memory(bytes, **opts)` — stream from a Ruby String
  of bytes (in-memory MP3 / OGG / FLAC). Caller's bytes must
  outlive the `Music` (we pin the Ruby buffer).
- `SoundBuffer.from_memory(bytes)` — decode `.wav` / `.ogg` /
  `.flac` from RAM.
- `SoundBuffer.from_samples(samples, sample_rate:, channel_count:,
  channel_map:)` — build a buffer from a Ruby Array of int16
  samples. Default channel maps for 1- and 2-channel content.
- `SoundBuffer#dup`, `SoundBuffer#sample_count`,
  `SoundBuffer#samples` — sample-level introspection.

## [3.0.0.3] — 2026-05-09

### Added — typography
- `Font#family` — human-readable family name from `sfFont_getInfo`.
- `Font#has_glyph?(codepoint)` — accepts an Integer codepoint or
  a single-character String.
- `Font#kerning(a, b, character_size:, bold: false)` — wraps
  `sfFont_getKerning` / `getBoldKerning` for accurate glyph
  pairing. Used in advanced text layout.
- `Font#line_spacing(size)`, `Font#underline_position(size)`,
  `Font#underline_thickness(size)` — typography metrics for the
  given character size.
- `Font#texture(size)` — borrowed `SFML::Texture` of the glyph
  atlas (handy for debug visualisations of what's been rasterised).
- `Font#dup` / `#clone` — independent deep copy.
- `Font.from_memory(bytes)` — load from a Ruby String (embedded
  assets, network responses, `data:` URLs).
- `Text#find_character_pos(index)` — exact `Vector2` position of
  the character at the given byte index. Critical for caret /
  selection rendering in text inputs.
- `Text#letter_spacing` / `#line_spacing` getters (the setters
  were already there).
- `Text#dup` / `#clone` — independent copy with the same string
  and font reference.
- `Text#transform` / `#inverse_transform` — the `SFML::Transform`
  the renderer applies when drawing this Text.

### Added — Image / Texture / RenderTexture
- `Image.from_memory(bytes)` — decode PNG / JPG / BMP / TGA /
  GIF / HDR / PSD from a Ruby String. Mirror of
  `Image#save_to_memory`.
- `Image#copy_from(source, at:, source_rect: nil, apply_alpha: false)`
  — stamp a region of `source` into self. Useful for hand-built
  texture atlases or composite images.
- `Texture.create(width, height)` — allocate a blank GPU
  texture; pair with `Texture#update(image)` to stream pixels.
- `Texture.maximum_size` / `Texture.unbind` — class-level
  helpers.
- `Texture#bind(coord:)` — manually bind for raw OpenGL interop.
- `Texture#srgb?`, `Texture#generate_mipmap`, `Texture#dup`.
- `RenderTexture.maximum_anti_aliasing_level`,
  `RenderTexture#srgb?`, `RenderTexture#generate_mipmap`.
- `RenderTexture#active=`, `#push_gl_states`, `#pop_gl_states`,
  `#reset_gl_states` — same GL-state machinery as RenderWindow.

### Added — Window / RenderWindow polish
- `RenderWindow#focused?` / `#request_focus` / `#position` /
  `#position=` / `#srgb?`.
- `RenderWindow#visible=`, `#key_repeat_enabled=`,
  `#joystick_threshold=`.
- `RenderWindow#active=`, `#push_gl_states`, `#pop_gl_states`,
  `#reset_gl_states` — for mixing raw OpenGL calls with SFML
  rendering. Surround custom GL with push/pop so SFML's
  internal state survives.
- `RenderWindow#wait_event(timeout:)` — block until the next
  event or `timeout` elapses (a `SFML::Time`). For low-power /
  event-driven apps that don't need a 60Hz update loop.
- `Window#cursor=`, `#cursor_visible=`, `#cursor_grabbed=` —
  parity with the same setters that already existed on
  `RenderWindow`.
- `Window#joystick_threshold=`, `Window#context_settings`,
  `Window#wait_event(timeout:)`.

### Added — Shader
- `Shader#bind`, `Shader.unbind`, `Shader#native_handle` — for
  raw GL interop and debug introspection.

### Fixed
- `SFML::App._dispatch` now forwards `:resized` events to *both*
  `on_resize(width, height)` *and* `on_event(event)`. The 3.0.0.2
  refactor accidentally routed `:resized` only through the
  structured hook, which broke any app that forwarded
  `on_event` to a sub-system (e.g. `def on_event(e) =
  @gui.on_event(e)`) — the GUI never got told to refresh its
  view + reflow on resize. Both hooks now receive the event;
  apps that already use `on_resize` are unaffected.

## [3.0.0.2] — 2026-05-09

### Added
- **`SFML::App`** — subclass-friendly main loop. Removes the
  boilerplate of window creation, event pumping, dt management,
  and clear/display so a small app fits in a few methods.
- Class-level configuration DSL for `SFML::App`. Defaults that
  used to be passed to `.new` can now be declared in the class
  body and inherited:
  ```ruby
  class MyApp < SFML::App
    width        800
    height       600
    title        "Smooth"
    framerate    120
    antialiasing 4
    background   SFML::Color["#1a1a1a"]
  end
  ```
  Per-instance kwargs to `.new` still override on a case-by-case
  basis. Available macros: `width`, `height`, `title`, `framerate`,
  `vsync`, `background`, `style`, `fullscreen`, `antialiasing`,
  `context`.
- **`SFML::ContextSettings`** — configures the OpenGL context the
  window backs onto: anti-aliasing level, depth/stencil bits, GL
  version. The fifth argument to `sfRenderWindow_create` is no
  longer `NULL` by default; pass `antialiasing: 4` (or
  `context: SFML::ContextSettings.new(...)`) to
  `RenderWindow.new` / `SFML::App.new` to turn on MSAA. Read back
  what the driver actually gave you with
  `window.context_settings`. Wraps `sfContextSettings` and
  `sfRenderWindow_getSettings`.
- **`on_key`** — class-level keybinding DSL. Bind a key to an
  instance method, a Proc, or a block; bindings inherit through
  subclasses with later definitions shadowing earlier ones:
  ```ruby
  class MyApp < SFML::App
    on_key :escape, :quit
    on_key :f11,    :toggle_fullscreen
    on_key :p       do |app| app.toggle_pause end
  end
  ```
  Bindings live as the class's `key_handlers` Hash; the same DSL
  is also available on `SFML::Scene`, where scene-level bindings
  shadow app-level ones for the active scene.
- **`pause` / `resume` / `toggle_pause` / `paused?`** on
  `SFML::App` — while paused, `update(dt)` is skipped but `draw`
  continues, so a pause overlay can be drawn on top of a frozen
  scene.
- **`on_resize(width, height)`** hook on `SFML::App` and
  `SFML::Scene` — replaces the `case event in {type: :resized,
  size: {x:, y:}}` boilerplate that used to live inside
  `on_event`. Default forwards to the active scene.
- **`SFML::Scene`** — base class for stateful screens (menu,
  gameplay, results screen, settings overlay, etc.). Lifecycle
  hooks (`setup` / `update` / `draw` / `on_event` / `on_resize` /
  `teardown`), its own `on_key` DSL, and a `switch_to(other)`
  shortcut that delegates to the host app. The host app picks a
  starting scene with the `initial_scene SomeScene` class macro;
  `App.switch_to` tears down the previous scene before calling
  `setup` on the new one.
- New example
  [24_scenes](examples/24_scenes/scenes.rb) — title → play scene
  pair built on `SFML::Scene` + `initial_scene`.
- New example
  [04_app_class](examples/04_app_class/app_class.rb) — bouncing
  ball on top of `SFML::App` with class-level config and
  `on_key` bindings (replaces the old `04_game_class` example).

### Changed
- `SFML::App._dispatch` no longer auto-quits on Esc. Apps that
  want it bind it explicitly with `on_key :escape, :quit`. The
  window-close button (`:closed`) still always quits.
- Audio specs (anything under `spec/sfml/audio/`) are now
  auto-tagged `:audio` and skipped by default on macOS, where
  CoreAudio + the CSFML OpenAL backend occasionally hang the
  test group. Opt-in with `bundle exec rspec --tag audio`.
  Linux runs the full suite as before.

## [3.0.0.1] — 2026-05-07

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
- `App` — subclass-friendly main loop with `setup` / `update(dt)` /
  `draw` / `on_event` hooks.
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
