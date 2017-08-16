# frozen_string_literal: true

module LazyLazer
  # This is raised when a required attribute isn't included.
  class RequiredAttribute < StandardError; end

  # Raised when a missing attribute is called but a default isn't present.
  class MissingAttribute < StandardError; end
end
