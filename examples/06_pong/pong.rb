#!/usr/bin/env ruby
# frozen_string_literal: true

# Two-player Pong with an in-window score.
#
#   Left paddle:  W / S
#   Right paddle: Up / Down
#   Quit:         Esc or close button
#
#     bundle exec ruby examples/06_pong/pong.rb

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "sfml"

WIDTH, HEIGHT      = 800, 600
PADDLE_W, PADDLE_H = 12, 100
BALL_R             = 10
PADDLE_SPEED       = 480.0  # px/sec
BALL_BASE_SPEED    = 380.0

window = SFML::RenderWindow.new(WIDTH, HEIGHT, "Pong", framerate: 60)

# Default search root is `<dir of script>/assets/`. Font.default is the
# bundled DejaVu Sans, so we don't need a system install of the font.
font   = SFML::Font.default
bounce = SFML::Sound.new(SFML::Assets.sound("blip"), volume: 30)

def make_paddle(x)
  SFML::RectangleShape.new(
    size:       [PADDLE_W, PADDLE_H],
    position:   [x, HEIGHT / 2 - PADDLE_H / 2],
    fill_color: SFML::Color.white,
  )
end

left  = make_paddle(30)
right = make_paddle(WIDTH - 30 - PADDLE_W)

ball = SFML::CircleShape.new(
  radius:     BALL_R,
  origin:     [BALL_R, BALL_R],
  position:   [WIDTH / 2, HEIGHT / 2],
  fill_color: SFML::Color.cornflower_blue,
)

midline = SFML::RectangleShape.new(
  size:       [2, HEIGHT],
  position:   [WIDTH / 2 - 1, 0],
  fill_color: SFML::Color["#222"],
)

score_text = SFML::Text.new(font, "0   0",
  character_size: 64,
  fill_color:     SFML::Color["#666"],
  style:          :bold,
  position:       [WIDTH / 2, 30],
)
# Centre the score horizontally using its real glyph bounds.
score_text.origin = [score_text.local_bounds.width / 2, 0]

# Helpers -------------------------------------------------------------------

def random_ball_velocity(direction_x)
  vy = (rand * 2 - 1) * BALL_BASE_SPEED * 0.6
  SFML::Vector2[BALL_BASE_SPEED * direction_x, vy]
end

def reset_ball(ball, direction_x)
  ball.position = [WIDTH / 2, HEIGHT / 2]
  random_ball_velocity(direction_x)
end

def reflect_off_paddle(ball_pos, paddle, side)
  paddle_center_y = paddle.position.y + PADDLE_H / 2.0
  hit             = ((ball_pos.y - paddle_center_y) / (PADDLE_H / 2.0)).clamp(-1.0, 1.0)

  vx = BALL_BASE_SPEED * (side == :left ? 1 : -1)
  vy = hit * BALL_BASE_SPEED * 0.9
  SFML::Vector2[vx, vy]
end

def move_paddle(paddle, dt, up_key:, down_key:)
  y = paddle.position.y
  y -= PADDLE_SPEED * dt if SFML::Keyboard.key_pressed?(up_key)
  y += PADDLE_SPEED * dt if SFML::Keyboard.key_pressed?(down_key)
  y = y.clamp(0.0, HEIGHT - PADDLE_H)
  paddle.position = [paddle.position.x, y]
end

# Game state ---------------------------------------------------------------

velocity   = random_ball_velocity(rand < 0.5 ? -1 : 1)
score_l    = 0
score_r    = 0
clock      = SFML::Clock.new

# Main loop ----------------------------------------------------------------

while window.open?
  dt = clock.restart.as_seconds

  window.each_event do |event|
    case event
    in {type: :closed}                     then window.close
    in {type: :key_pressed, code: :escape} then window.close
    else # ignore everything else
    end
  end

  move_paddle(left,  dt, up_key: :w,  down_key: :s)
  move_paddle(right, dt, up_key: :up, down_key: :down)

  pos    = ball.position + velocity * dt
  vx, vy = velocity.x, velocity.y

  # Top/bottom walls
  if pos.y < BALL_R
    pos = SFML::Vector2[pos.x, BALL_R]
    vy = vy.abs
    bounce.pitch = 0.85; bounce.play
  elsif pos.y > HEIGHT - BALL_R
    pos = SFML::Vector2[pos.x, HEIGHT - BALL_R]
    vy = -vy.abs
    bounce.pitch = 0.85; bounce.play
  end

  # Paddle hits — checked against ball bounding box
  ball_left   = pos.x - BALL_R
  ball_right  = pos.x + BALL_R
  ball_top    = pos.y - BALL_R
  ball_bottom = pos.y + BALL_R

  hit_left = ball_left  < left.position.x  + PADDLE_W &&
             ball_right > left.position.x  &&
             ball_bottom > left.position.y &&
             ball_top   < left.position.y + PADDLE_H &&
             vx < 0

  hit_right = ball_right > right.position.x  &&
              ball_left  < right.position.x + PADDLE_W &&
              ball_bottom > right.position.y &&
              ball_top   < right.position.y + PADDLE_H &&
              vx > 0

  if hit_left
    pos      = SFML::Vector2[left.position.x + PADDLE_W + BALL_R, pos.y]
    velocity = reflect_off_paddle(pos, left, :left)
    bounce.pitch = 1.0; bounce.play
  elsif hit_right
    pos      = SFML::Vector2[right.position.x - BALL_R, pos.y]
    velocity = reflect_off_paddle(pos, right, :right)
    bounce.pitch = 1.0; bounce.play
  else
    velocity = SFML::Vector2[vx, vy]
  end

  # Scoring — ball passed a paddle
  if pos.x < -BALL_R
    score_r += 1
    velocity = reset_ball(ball, 1)
    score_text.string = "#{score_l}   #{score_r}"
    score_text.origin = [score_text.local_bounds.width / 2, 0]
  elsif pos.x > WIDTH + BALL_R
    score_l += 1
    velocity = reset_ball(ball, -1)
    score_text.string = "#{score_l}   #{score_r}"
    score_text.origin = [score_text.local_bounds.width / 2, 0]
  else
    ball.position = pos
  end

  window.clear(SFML::Color["#0a0a0a"])
  window.draw(midline)
  window.draw(score_text)
  window.draw(left)
  window.draw(right)
  window.draw(ball)
  window.display
end
