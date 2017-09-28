# frozen_string_literal: true

require_relative 'errors'

module LazyLazer
  # Simple PORO for key metadata. Yay value objects!
  class KeyMetadata
    attr_reader :source_key
    attr_reader :default
    attr_reader :transform

    def initialize(source_key:, required:, runtime_required:, default:, transform:)
      @source_key = source_key
      @required = required
      @runtime_required = runtime_required
      @default = default
      @transform = transform
      freeze
    end

    def required?
      @required
    end

    def runtime_required?
      @runtime_required
    end
  end
end
