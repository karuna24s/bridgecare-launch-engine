# frozen_string_literal: true

InertiaRails.configure do |config|
  # Opt in to InertiaRails 4.0 behavior; silences upgrade warning on each request.
  config.always_include_errors_hash = true

  # Bust client cache when Vite assets change (matches inertia_rails install generator).
  config.version = ViteRuby.digest if defined?(ViteRuby)
end
