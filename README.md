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
| Window   | `RenderWindow`, `VideoMode`, `Event`, `Keyboard`             |
| Graphics | `Color`, `Texture`, `Sprite`, `CircleShape`, `RectangleShape`, `Font`, `Text` |
| Audio    | `SoundBuffer`, `Sound`, `Music`                              |
| Helpers  | `Assets` (search-path + cache), `Game` (lifecycle main loop) |

The `SFML::Network` module is intentionally not in the first release; it'll come later.

## Examples

All under [examples/](examples/) — run from the gem root:

```sh
bundle exec ruby examples/<name>.rb
```

| File                                    | What it shows                                                |
| --------------------------------------- | ------------------------------------------------------------ |
| [hello_window.rb](examples/hello_window.rb) | Empty window, manual loop                                    |
| [events_demo.rb](examples/events_demo.rb)   | Pattern matching on input events                             |
| [bouncing_ball.rb](examples/bouncing_ball.rb) | dt-based physics, `CircleShape` + `RectangleShape`           |
| [game_class.rb](examples/game_class.rb)     | Same as bouncing_ball but built on `SFML::Game`              |
| [pong.rb](examples/pong.rb)                 | Two-player Pong with in-window score (`Text`) and bounce sound (`Sound`) |

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
