module SFML
  # A pool-backed particle emitter built on top of `SFML::VertexArray`.
  # Each particle is two triangles (a quad) so a single CSFML draw
  # call ships thousands at once.
  #
  #   class Sparks < SFML::ParticleSystem
  #     def emit_one
  #       angle = rand(0.0..2 * Math::PI)
  #       speed = rand(80.0..200.0)
  #       spawn(
  #         position:  @origin,
  #         velocity:  SFML::Vector2.new(Math.cos(angle), Math.sin(angle)) * speed,
  #         lifetime:  0.8,
  #         color:     SFML::Color.new(255, 200, 50),
  #         size:      4,
  #       )
  #     end
  #   end
  #
  #   sparks = Sparks.new(max: 500)
  #
  #   def update(dt)
  #     5.times { sparks.emit_one } if mouse_down?
  #     sparks.update(dt)
  #   end
  #
  #   def draw
  #     window.draw(sparks)
  #   end
  #
  # Particles fade linearly from full alpha at spawn to zero alpha
  # at `lifetime`. Override `#update_particle(p, dt)` to apply
  # gravity, drag, custom colour curves, etc.
  #
  # Acceleration: pass `gravity:` to the constructor for the common
  # case (px/s² added to velocity every frame). For richer behaviour,
  # subclass and override.
  class ParticleSystem
    # A single particle. Plain Struct so allocations stay cheap;
    # mutated in-place from `#update`.
    Particle = Struct.new(
      :x, :y,
      :vx, :vy,
      :age, :lifetime,
      :r, :g, :b, :a,
      :size,
    ) do
      # `true` if alive.
      def alive? = age < lifetime
      # Returns the normalized age.
      def normalized_age = age / lifetime
    end

    DEFAULT_GRAVITY = [0.0, 0.0].freeze

    def initialize(max: 1000, gravity: DEFAULT_GRAVITY, texture: nil)
      @max          = Integer(max)
      @gravity_x    = Float(gravity[0])
      @gravity_y    = Float(gravity[1])
      @texture      = texture
      @particles    = []
      @vertex_array = VertexArray.new(:triangles)
    end

    attr_reader :particles, :texture
    # Returns the size.
    def size = @particles.size
    # `true` if empty.
    def empty? = @particles.empty?
    # `true` if full.
    def full?  = @particles.size >= @max

    # Spawn a new particle. Silently dropped if the pool is full
    # (better than reallocating; users can size up `max:`).
    #
    # @param position [Vector2, Array] world coords
    # @param velocity [Vector2, Array] px/s
    # @param lifetime [Numeric] seconds
    # @param color [SFML::Color]
    # @param size [Numeric] half-side of the quad in pixels
    def spawn(position:, velocity: [0, 0], lifetime: 1.0, color: Color.white, size: 4)
      return if full?

      px, py = _xy(position)
      vx, vy = _xy(velocity)

      @particles << Particle.new(
        Float(px), Float(py),
        Float(vx), Float(vy),
        0.0, Float(lifetime),
        color.r, color.g, color.b, color.a,
        Float(size),
      )
      self
    end

    # Drop every live particle.
    def clear
      @particles.clear
      self
    end

    # Advance all particles by `dt` and remove dead ones.
    def update(dt)
      seconds = dt.is_a?(Time) ? dt.as_seconds : Float(dt)
      gx, gy  = @gravity_x, @gravity_y

      @particles.each do |p|
        next unless p.alive?

        # Gravity + integration. Subclasses can override
        # update_particle to layer additional forces / drag.
        p.vx += gx * seconds
        p.vy += gy * seconds
        p.x  += p.vx * seconds
        p.y  += p.vy * seconds
        p.age += seconds
        update_particle(p, seconds)
      end

      @particles.delete_if { |p| !p.alive? }

      self
    end

    # Hook: tweak a particle's state. Default does nothing; override
    # for drag, attractors, colour curves over lifetime, etc.
    def update_particle(_particle, _dt); end

    # Drawable interface — rebuilds the VertexArray and forwards.
    def draw_on(target, states_ptr = nil)
      _rebuild_vertex_array
      @vertex_array.draw_on(target, states_ptr)
    end

    private

    def _xy(value)
      case value
      when Vector2 then [value.x, value.y]
      when Array   then value
      else raise ArgumentError, "expected Vector2 or [x, y]; got #{value.class}"
      end
    end

    # Pack live particles into the vertex array as two triangles each.
    # We rebuild from scratch every frame — for ~1000 particles this
    # is ~6000 vertex writes per frame, which is well within budget.
    def _rebuild_vertex_array
      @vertex_array.clear
      @particles.each do |p|
        next unless p.alive?

        s = p.size
        # Fade alpha linearly from full → zero across lifetime.
        alpha = (p.a * (1.0 - p.normalized_age)).round.clamp(0, 255)
        col = Color.new(p.r, p.g, p.b, alpha)

        # Two triangles forming a quad centred on (x, y).
        tl = Vertex.new([p.x - s, p.y - s], color: col)
        tr = Vertex.new([p.x + s, p.y - s], color: col)
        bl = Vertex.new([p.x - s, p.y + s], color: col)
        br = Vertex.new([p.x + s, p.y + s], color: col)

        @vertex_array << tl << tr << br
        @vertex_array << tl << br << bl
      end
    end
  end
end
