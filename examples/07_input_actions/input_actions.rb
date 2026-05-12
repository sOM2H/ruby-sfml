#!/usr/bin/env ruby
# frozen_string_literal: true

# Same WASD-style movement as a typical game — but instead of polling
# `Keyboard.key_pressed?(:w)` directly, we map physical inputs to
# **named actions** with the `action` DSL.
#
# Why bother? Three reasons:
#   1. You bind input once, then `update` talks in verbs (`:left`,
#      `:fire`). Remapping is one line; consuming code never changes.
#   2. Each action can have multiple bindings — arrow keys *and* WASD
#      *and* gamepad axes simultaneously.
#   3. Scancodes (physical keys) and key codes (logical, layout-aware)
#      coexist. WASD as scancodes keeps the physical position across
#      QWERTY/AZERTY/Dvorak.
#
# Demonstrates:
#   - `action :name, keys: [...], scancodes: [...], mouse_buttons:`
#   - `#action_pressed?(:name)` polled inside `#update`
#   - `#axis(negative:, positive:)` for digital 1D input
#
# Esc to quit.
#
#     bundle exec ruby examples/07_input_actions/input_actions.rb

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "sfml"

class InputActionsDemo < SFML::App
  width  800
  height 600
  title  "Input actions — WASD + arrows + LMB"
  background SFML::Color["#0d1117"]

  on_key :escape, :quit

  # Movement: WASD as **scancodes** (so the physical W key always
  # moves you up regardless of keyboard layout), arrow keys as
  # **logical keys** for users who prefer them.
  action :move_up,    scancodes: [:scan_w], keys: [:up]
  action :move_down,  scancodes: [:scan_s], keys: [:down]
  action :move_left,  scancodes: [:scan_a], keys: [:left]
  action :move_right, scancodes: [:scan_d], keys: [:right]

  # Multiple physical inputs for one action.
  action :fire,  keys: [:space, :lctrl], mouse_buttons: [:left]
  action :boost, keys: [:lshift]

  def setup
    @player = SFML::CircleShape.new(
      radius: 22, origin: [22, 22],
      position: [width / 2, height / 2],
      fill_color: SFML::Color.cornflower_blue,
    )
    @bullets = []
    @fire_cooldown = 0.0

    @font = SFML::Font.default
    @hud  = SFML::Text.new(@font, "", character_size: 14,
                           fill_color: SFML::Color.white, position: [10, 10])
  end

  def update(dt)
    seconds  = dt.as_seconds
    base     = action_pressed?(:boost) ? 480 : 220

    # `axis(...)` collapses two opposing actions into Float in {-1, 0, +1}.
    move = SFML::Vector2[
      axis(negative: :move_left, positive: :move_right),
      axis(negative: :move_up,   positive: :move_down),
    ]
    move = move.normalize unless move.length <= 1.0
    @player.position = @player.position + move * (base * seconds)

    # Fire — rate-limited so holding doesn't spam.
    @fire_cooldown -= seconds
    if action_pressed?(:fire) && @fire_cooldown <= 0
      @bullets << {
        pos:  SFML::Vector2[@player.position.x, @player.position.y],
        vel:  SFML::Vector2[0, -520],
        life: 1.4,
      }
      @fire_cooldown = 0.12
    end

    @bullets.each do |b|
      b[:pos] += b[:vel] * seconds
      b[:life] -= seconds
    end
    @bullets.reject! { |b| b[:life] <= 0 || b[:pos].y < -20 }

    @hud.string =
      "WASD or arrows to move  •  Space / LMB / Ctrl to fire  •  Shift to boost\n" \
      "bound actions: #{self.class.action_bindings.keys.sort.inspect}\n" \
      "active bullets: #{@bullets.size}#{action_pressed?(:boost) ? "  •  BOOSTING" : ""}"
  end

  def draw
    @bullets.each do |b|
      shot = SFML::CircleShape.new(
        radius: 4, origin: [4, 4], position: [b[:pos].x, b[:pos].y],
        fill_color: SFML::Color.new(255, 200, 60),
      )
      window.draw(shot)
    end
    window.draw(@player)
    window.draw(@hud)
  end
end

InputActionsDemo.new.run
