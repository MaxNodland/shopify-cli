# frozen_string_literal: true

module Extension
  module Models
    module SpecificationHandlers
      class Default
        attr_reader :specification

        def initialize(specification)
          @specification = specification
        end

        def identifier
          specification.identifier.to_s.upcase
        end

        def graphql_identifier
          identifier
        end

        def name
          message('name')
        end

        def tagline
          message('tagline') || ""
        end

        def config(_context)
          raise NotImplementedError, "'#{__method__}' must be implemented for #{self.class}"
        end

        def create(_directory_name, _context)
          raise NotImplementedError, "'#{__method__}' must be implemented for #{self.class}"
        end

        def extension_context(_context)
          nil
        end

        def valid_extension_contexts
          []
        end

        protected

        def argo
          Features::Argo.new(
            git_template: specification.features.argo.git_template,
            renderer_package_name: specification.features.argo.renderer_package_name,
          )
        end

        private

        def message(key, *params)
          return unless messages.key?(key.to_sym)
          messages[key.to_sym] % params
        end

        def messages
          @messages ||= Messages::TYPES[identifier.downcase.to_sym] || {}
        end
      end
    end
  end
end
