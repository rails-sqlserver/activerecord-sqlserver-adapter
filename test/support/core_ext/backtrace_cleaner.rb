# frozen_string_literal: true

# Need to handle `ActiveRecord` lines like they are in the source rather than in the Rails gem.
module SQLServer
  module BacktraceCleaner
    extend ActiveSupport::Concern

    private

    def add_gem_filter
      gems_paths = (Gem.path | [Gem.default_dir]).map { |p| Regexp.escape(p) }
      return if gems_paths.empty?

      gems_regexp = %r{\A(#{gems_paths.join("|")})/(bundler/)?gems/([^/]+)-([\w.]+)/(.*)}
      gems_result = '\3 (\4) \5'

      add_filter do |line|
        if line.match?(/activerecord/)
          line
        else
          line.sub(gems_regexp, gems_result)
        end
      end
    end

    def add_gem_silencer
      add_silencer do |line|
        ActiveSupport::BacktraceCleaner::FORMATTED_GEMS_PATTERN.match?(line) && !/activerecord/.match?(line)
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveSupport::BacktraceCleaner.prepend(SQLServer::BacktraceCleaner)
end
