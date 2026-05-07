module SFML
  # How a draw call interacts with the stencil buffer. The classic
  # use is masking — first you draw a "mask" shape that writes a
  # value into the stencil buffer, then you draw the masked content
  # with a comparison that only lets pixels through where the
  # stencil matches.
  #
  #   target.clear(SFML::Color.black, stencil: 0)
  #
  #   # Phase 1 — write the mask shape into the stencil buffer.
  #   write = SFML::StencilMode.new(
  #     comparison: :always, update_operation: :replace, reference: 1,
  #     only_write_mask: true,   # don't actually paint colour
  #   )
  #   target.draw(mask_circle, stencil_mode: write)
  #
  #   # Phase 2 — draw the content; only pixels where stencil == 1
  #   # survive.
  #   read = SFML::StencilMode.new(
  #     comparison: :equal, update_operation: :keep, reference: 1,
  #   )
  #   target.draw(scene, stencil_mode: read)
  #
  # `stencilOnly` (`only_write_mask:`) is a niche flag — set it to
  # true on the mask-write pass if you don't want the mask shape
  # itself to be visible in the colour buffer.
  class StencilMode
    # Order matches sfStencilComparison in CSFML 3.
    COMPARISONS = %i[never less less_equal greater greater_equal equal not_equal always].freeze
    COMPARISON_INDEX = COMPARISONS.each_with_index.to_h.freeze

    # Order matches sfStencilUpdateOperation in CSFML 3.
    OPERATIONS = %i[keep zero replace increment decrement invert].freeze
    OPERATION_INDEX = OPERATIONS.each_with_index.to_h.freeze

    attr_reader :comparison, :update_operation, :reference, :mask, :only_write_mask

    def initialize(comparison: :always, update_operation: :keep,
                   reference: 0, mask: 0xFFFFFFFF, only_write_mask: false)
      raise ArgumentError, "Unknown stencil comparison: #{comparison.inspect}" \
        unless COMPARISON_INDEX.key?(comparison)
      raise ArgumentError, "Unknown stencil update_operation: #{update_operation.inspect}" \
        unless OPERATION_INDEX.key?(update_operation)

      @comparison       = comparison
      @update_operation = update_operation
      @reference        = Integer(reference)
      @mask             = Integer(mask)
      @only_write_mask  = !!only_write_mask
      freeze
    end

    def ==(other)
      other.is_a?(StencilMode) &&
        comparison == other.comparison &&
        update_operation == other.update_operation &&
        reference == other.reference &&
        mask == other.mask &&
        only_write_mask == other.only_write_mask
    end
    alias eql? ==
    def hash = [comparison, update_operation, reference, mask, only_write_mask].hash

    def to_s
      "StencilMode(#{comparison}, #{update_operation}, ref=#{reference}, " \
        "mask=#{format('0x%08X', mask)}, only_write=#{only_write_mask})"
    end
    alias inspect to_s

    # @!visibility private
    # Write our fields into a CSFML StencilMode struct (typically a
    # sub-struct of an existing RenderStates buffer).
    def populate(struct)
      struct[:comparison]       = COMPARISON_INDEX[@comparison]
      struct[:update_operation] = OPERATION_INDEX[@update_operation]
      struct[:reference][:value] = @reference
      struct[:mask][:value]      = @mask
      struct[:only_write_mask]  = @only_write_mask
      struct
    end

    # @!visibility private
    def self.from_native(struct)
      new(
        comparison:       COMPARISONS[struct[:comparison]],
        update_operation: OPERATIONS[struct[:update_operation]],
        reference:        struct[:reference][:value],
        mask:             struct[:mask][:value],
        only_write_mask:  struct[:only_write_mask],
      )
    end
  end
end
