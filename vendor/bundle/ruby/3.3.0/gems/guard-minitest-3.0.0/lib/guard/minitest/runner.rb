require 'guard/minitest/inspector'
require 'English'

module Guard
  class Minitest < Plugin
    class Runner
      attr_accessor :inspector

      def initialize(options = {})
        @options = {
          all_after_pass:     false,
          bundler:            File.exist?("#{Dir.pwd}/Gemfile"),
          rubygems:           false,
          drb:                false,
          zeus:               false,
          spring:             false,
          all_env:            {},
          env:                {},
          include:            [],
          test_folders:       %w(test spec),
          test_file_patterns: %w(*_test.rb test_*.rb *_spec.rb),
          cli:                nil,
          autorun:            true
        }.merge(options)

        parse_deprecated_options

        [:test_folders, :test_file_patterns].each do |k|
          @options[k] = Array(@options[k]).uniq.compact
        end

        @inspector = Inspector.new(test_folders, test_file_patterns)
      end

      def run(paths, options = {})
        return unless options[:all] || !paths.empty?

        message = "Running: #{options[:all] ? 'all tests' : paths.join(' ')}"
        Compat::UI.info message, reset: true

        begin
          status = _run_possibly_bundled_command(paths, options[:all])
        rescue Errno::ENOENT => e
          Compat::UI.error e.message
          throw :task_has_failed
        end

        success = status.zero?

        # When using zeus or spring, the Guard::Minitest::Reporter can't be used because the minitests run in another
        # process, but we can use the exit status of the client process to distinguish between :success and :failed.
        if zeus? || spring?
          Compat::UI.notify(message, title: 'Minitest results', image: success ? :success : :failed)
        end

        run_all_coz_ok = @options[:all_after_pass] && success && !options[:all]
        run_all_coz_ok ?  run_all : success
      end

      def run_all
        paths = inspector.clean_all
        run(paths, all: true)
      end

      def run_on_modifications(paths = [])
        paths = inspector.clean(paths)
        run(paths, all: all_paths?(paths))
      end

      def run_on_additions(_paths)
        inspector.clear_memoized_test_files
        true
      end

      def run_on_removals(_paths)
        inspector.clear_memoized_test_files
      end

      private

      def cli_options
        @cli_options ||= Array(@options[:cli])
      end

      def bundler?
        @options[:bundler] && !@options[:spring]
      end

      def rubygems?
        !bundler? && @options[:rubygems]
      end

      def drb?
        @options[:drb]
      end

      def zeus?
        @options[:zeus].is_a?(String) || @options[:zeus]
      end

      def spring?
        @options[:spring].is_a?(String) || @options[:spring]
      end

      def all_after_pass?
        @options[:all_after_pass]
      end

      def test_folders
        @options[:test_folders]
      end

      def include_folders
        @options[:include]
      end

      def test_file_patterns
        @options[:test_file_patterns]
      end

      def autorun?
        @options[:autorun]
      end

      def _run(*args)
        Compat::UI.debug "Running: #{args.join(' ')}"
        return $CHILD_STATUS.exitstatus unless Kernel.system(*args).nil?

        fail Errno::ENOENT, args.join(' ')
      end

      def _run_possibly_bundled_command(paths, all)
        args = minitest_command(paths, all)
        bundler_env = !bundler? && defined?(::Bundler)
        bundler_env ? ::Bundler.with_original_env { _run(*args) } : _run(*args)
      end

      def _commander(paths)
        return drb_command(paths) if drb?
        return zeus_command(paths) if zeus?
        return spring_command(paths) if spring?
        ruby_command(paths)
      end

      def minitest_command(paths, all)
        cmd_parts = []

        cmd_parts << 'bundle exec' if bundler?
        cmd_parts << _commander(paths)

        [cmd_parts.compact.join(' ')].tap do |args|
          env = generate_env(all)
          args.unshift(env) if env.length > 0
        end
      end

      def drb_command(paths)
        %w(testdrb) + generate_includes(false) + relative_paths(paths)
      end

      def zeus_command(paths)
        command = @options[:zeus].is_a?(String) ? @options[:zeus] : 'test'
        ['zeus', command] + relative_paths(paths)
      end

      def spring_command(paths)
        command = @options[:spring].is_a?(String) ? @options[:spring] : 'bin/rake test'
        cmd_parts = [command]
        if cli_options.length > 0
          cmd_parts + paths + ['--'] + cli_options
        else
          cmd_parts + paths
        end
      end

      def ruby_command(paths)
        cmd_parts  = ['ruby']
        cmd_parts.concat(generate_includes)
        cmd_parts << '-r rubygems' if rubygems?
        cmd_parts << '-r bundler/setup' if bundler?
        cmd_parts << '-r minitest/autorun' if autorun?
        cmd_parts.concat(paths.map { |path| "-r ./#{path}" })

        # All the work is done through minitest/autorun
        # and requiring the test files, so this is just
        # a placeholder so Ruby doesn't try to exceute
        # code from STDIN.
        cmd_parts << '-e ""'

        cmd_parts << '--'
        cmd_parts += cli_options
        cmd_parts
      end

      def generate_includes(include_test_folders = true)
        if include_test_folders
          folders = test_folders + include_folders
        else
          folders = include_folders
        end

        folders.map { |f| %(-I"#{f}") }
      end

      def generate_env(all = false)
        base_env.merge(all ? all_env : {})
      end

      def base_env
        Hash[(@options[:env] || {}).map { |key, value| [key.to_s, value.to_s] }]
      end

      def all_env
        return { @options[:all_env].to_s => 'true' } unless @options[:all_env].is_a? Hash
        Hash[@options[:all_env].map { |key, value| [key.to_s, value.to_s] }]
      end

      def relative_paths(paths)
        paths.map { |p| "./#{p}" }
      end

      def all_paths?(paths)
        paths == inspector.all_test_files
      end

      def parse_deprecated_options
        if @options.key?(:notify)
          # TODO: no coverage
          Compat::UI.info %(DEPRECATION WARNING: The :notify option is deprecated. Guard notification configuration is used.)
        end

        [:seed, :verbose].each do |key|
          next unless (value = @options.delete(key))

          final_value = "--#{key}"
          final_value << " #{value}" unless [TrueClass, FalseClass].include?(value.class)
          cli_options << final_value

          Compat::UI.info %(DEPRECATION WARNING: The :#{key} option is deprecated. Pass standard command line argument "--#{key}" to Minitest with the :cli option.)
        end
      end
    end
  end
end
