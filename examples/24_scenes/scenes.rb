#!/usr/bin/env ruby
# frozen_string_literal: true

# Two scenes wired through SFML::App. Title scene shows a press-Enter
# prompt; play scene drops the bouncing ball from the 03 example. Esc
# from play returns to title; Esc from title quits.
#
#     bundle exec ruby examples/24_scenes/scenes.rb

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "sfml"

class TitleScene < SFML::Scene
  on_key :enter,  :start
  on_key :escape, ->(s) { s.app.quit }

  def setup
    font = SFML::Font.default
    @title  = SFML::Text.new(font, "PRESS ENTER", character_size: 56,
                             fill_color: SFML::Color.white)
    @hint   = SFML::Text.new(font, "Esc to quit", character_size: 18,
                             fill_color: SFML::Color.new(160, 165, 180))
    place_text(width, height)
  end

  def on_resize(w, h) = place_text(w, h)

  def draw
    window.draw(@title)
    window.draw(@hint)
  end

  def start = switch_to(PlayScene)

  private

  def place_text(w, h)
    tb = @title.local_bounds
    @title.position = [(w - tb.width) / 2 - tb.x, (h - tb.height) / 2 - tb.y - 20]
    hb = @hint.local_bounds
    @hint.position  = [(w - hb.width) / 2 - hb.x, h - hb.height - 24]
  end
end

class PlayScene < SFML::Scene
  on_key :escape, :back_to_title
  on_key :space,  :recenter

  RADIUS = 25

  def setup
    @ball = SFML::CircleShape.new(
      radius:     RADIUS,
      origin:     [RADIUS, RADIUS],
      position:   [width / 2, height / 2],
      fill_color: SFML::Color.cornflower_blue,
    )
    @velocity = SFML::Vector2[280, 220]
  end

  def update(dt)
    secs   = dt.as_seconds
    nx     = @ball.position + @velocity * secs
    vx, vy = @velocity.x, @velocity.y
    if nx.x < RADIUS || nx.x > width - RADIUS
      vx = -vx
      nx = SFML::Vector2[nx.x.clamp(RADIUS, width - RADIUS), nx.y]
    end
    if nx.y < RADIUS || nx.y > height - RADIUS
      vy = -vy
      nx = SFML::Vector2[nx.x, nx.y.clamp(RADIUS, height - RADIUS)]
    end
    @velocity      = SFML::Vector2[vx, vy]
    @ball.position = nx
  end

  def draw          = window.draw(@ball)
  def recenter      = (@ball.position = [width / 2, height / 2])
  def back_to_title = switch_to(TitleScene)
end

class SceneDemo < SFML::App
  width        800
  height       600
  title        "SFML::App + scenes"
  background   SFML::Color["#1a1a1a"]
  framerate    60
  antialiasing 4

  initial_scene TitleScene
end

SceneDemo.new.run
