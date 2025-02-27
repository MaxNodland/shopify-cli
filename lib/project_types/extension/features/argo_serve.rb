module Extension
  module Features
    class ArgoServe
      include SmartProperties

      YARN_SERVE_COMMAND = %w(server)
      NPM_SERVE_COMMAND = %w(run-script server)

      property! :specification_handler, accepts: Extension::Models::SpecificationHandlers::Default
      property! :argo_runtime, accepts: Features::ArgoRuntime
      property! :context, accepts: ShopifyCli::Context
      property! :port, accepts: Integer, default: 39351
      property  :tunnel_url, accepts: String, default: nil
      property! :js_system, accepts: ->(jss) { jss.respond_to?(:call) }, default: ShopifyCli::JsSystem

      def call
        validate_env!

        CLI::UI::Frame.open(context.message("serve.frame_title")) do
          next if start_server
          context.abort(context.message("serve.serve_failure_message"))
        end
      end

      private

      def start_server
        js_system.call(context, yarn: yarn_serve_command, npm: npm_serve_command)
      end

      def specification
        specification_handler.specification
      end

      def renderer_package
        specification_handler.renderer_package(context)
      end

      def required_fields
        specification.features.argo.required_fields
      end

      def yarn_serve_command
        YARN_SERVE_COMMAND + options
      end

      def npm_serve_command
        NPM_SERVE_COMMAND  + ["--"] + options
      end

      def validate_env!
        ExtensionProject.reload

        return if required_fields.none?

        ShopifyCli::Tasks::EnsureEnv.call(context, required: required_fields)
        ShopifyCli::Tasks::EnsureDevStore.call(context) if required_fields.include?(:shop)

        project = ExtensionProject.current

        return if required_fields.all? do |field|
          value = project.env.public_send(field)
          value && !value.strip.empty?
        end

        context.abort(context.message("serve.serve_missing_information"))
      end

      def options
        project = ExtensionProject.current

        @serve_options ||= [].tap do |options|
          options << "--port=#{port}" if argo_runtime.supports?(:port)
          options << "--store=#{project.env.shop}" if argo_runtime.supports?(:shop)
          options << "--apiKey=#{project.env.api_key}" if argo_runtime.supports?(:api_key)
          options << "--rendererVersion=#{renderer_package.version}" if argo_runtime.supports?(:renderer_version)
          options << "--uuid=#{project.registration_uuid}" if argo_runtime.supports?(:uuid)
          options << "--publicUrl=#{tunnel_url}" if !tunnel_url.nil? && argo_runtime.supports?(:public_url)
          options << "--name=#{project.title}" if argo_runtime.supports?(:name)
        end
      end
    end
  end
end
