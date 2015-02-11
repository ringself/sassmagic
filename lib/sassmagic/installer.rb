module Sassmagic
  module Installers
    class Base
      # debugger
      def initialize(projectname = '')
        # Dir.mkdir("directory")
        # txt = File.open("directory/a.txt","w+")
        # txt.puts("hello world")
        # txt.close
        if projectname != ''
          projectname ="#{projectname}/"
        end
        directory "#{projectname}sass"
        directory "#{projectname}config"
        directory "#{projectname}stylesheet"
        directory "#{projectname}image"

        # write_file 'a.txt','hi'
        copy File.expand_path("#{File.dirname(__FILE__)}/config/imageuploader.js"),File.expand_path("#{Dir::pwd}/#{projectname}/config/imageuploader.js")
        copy File.expand_path("#{File.dirname(__FILE__)}/config/sassmagic.json"),File.expand_path("#{Dir::pwd}/#{projectname}/config/sassmagic.json")
        finalize
      end
      attr_writer :logger

      def logger
        @logger ||= Logger.new
      end
      # copy/process a template in the compass template directory to the project directory.
      def copy(from, to, options = nil, binary = false)
        options ||= self.options if self.respond_to?(:options)
        if binary
          contents = File.new(from,"rb").read
        else
          contents = File.new(from).read
        end
        write_file to, contents, options, binary
      end

      # create a directory and all the directories necessary to reach it.
      def directory(dir, options = nil)
        options ||= self.options if self.respond_to?(:options)
        options ||= {}
        if File.exists?(dir) && File.directory?(dir)
          # do nothing
        elsif File.exists?(dir)
          msg = "#{basename(dir)} already exists and is not a directory."
          raise Compass::FilesystemConflict.new(msg)
        else
          log_action :directory, separate("#{basename(dir)}/"), options
          FileUtils.mkdir_p(dir)
        end
      end

      # Write a file given the file contents as a string
      def write_file(file_name, contents, options = nil, binary = false)
        options ||= self.options if self.respond_to?(:options)
        options ||= {}
        skip_write = false
        # debugger
        # contents = process_erb(contents, options[:erb]) if options[:erb]
        if File.exists?(file_name)
          existing_contents = IO.read(file_name)
          if existing_contents == contents
            log_action :identical, basename(file_name), options
            skip_write = true
          elsif options[:force]
            log_action :overwrite, basename(file_name), options
          else
            msg = "File #{basename(file_name)} already exists. Run with --force to force overwrite."
            raise puts(msg)
          end
        else
          log_action :create, basename(file_name), options
        end
        if skip_write
          FileUtils.touch file_name
        else
          mode = "w"
          mode << "b" if binary
          open(file_name, mode) do |file|
            file.write(contents)
          end
        end
      end

      def process_erb(contents, ctx = nil)
        ctx = Object.new.instance_eval("binding") unless ctx.is_a? Binding
        ERB.new(contents).result(ctx)
      end

      def remove(file_name)
        file_name ||= ''
        if File.directory?(file_name)
          FileUtils.rm_rf file_name
          log_action :remove, basename(file_name)+"/", options
        elsif File.exists?(file_name)
          File.unlink file_name
          log_action :remove, basename(file_name), options
        end
      end

      def basename(file)
        relativize(file) {|f| File.basename(file)}
      end

      def relativize(path)
        path = File.expand_path(path)
        if block_given?
          yield path
        else
          path
        end
      end

      # Write paths like we're on unix and then fix it
      def separate(path)
        path.gsub(%r{/}, File::SEPARATOR)
      end

      # Removes the trailing separator, if any, from a path.
      def strip_trailing_separator(path)
        (path[-1..-1] == File::SEPARATOR) ? path[0..-2] : path
      end

      def log_action(action, file, options)
        quiet = !!options[:quiet]
        quiet = false if options[:loud] && options[:loud] == true
        quiet = false if options[:loud] && options[:loud].is_a?(Array) && options[:loud].include?(action)
        unless quiet
          logger.record(action, file, options[:extra].to_s)
        end
      end


      def finalize(options = {})
        puts <<-NEXTSTEPS

*********************************************************************
Congratulations! Your compass project has been created.

You may now add sass stylesheets to the sass subdirectory of your project.

Sass files beginning with an underscore are called partials and won't be
compiled to CSS, but they can be imported into other sass stylesheets.

You can configure your project by editing the config.rb configuration file.

You must compile your sass stylesheets into CSS when they change.
This can be done in one of the following ways:
  1. To compile on demand:
     sassmagic --x [input] [output]

More Resources:

        NEXTSTEPS
      end



    end

    #   logger
    class Logger

      COLORS = { :clear => 0, :red => 31, :green => 32, :yellow => 33, :blue => 34 }

      ACTION_COLORS = {
          :error     => :red,
          :warning   => :yellow,
          :info      => :green,
          :compile   => :green,
          :overwrite => :yellow,
          :modified  => :yellow,
          :clean     => :yellow,
          :write     => :green,
          :create    => :green,
          :remove    => :yellow,
          :delete    => :yellow,
          :deleted   => :yellow,
          :created   => :yellow,
          :exists    => :green,
          :directory => :green,
          :identical => :green,
          :convert   => :green,
          :unchanged => :yellow
      }

      DEFAULT_ACTIONS = ACTION_COLORS.keys

      ACTION_CAN_BE_QUIET = {
          :error     => false,
          :warning   => true,
          :info      => true,
          :compile   => true,
          :overwrite => true,
          :modified  => true,
          :clean     => true,
          :write     => true,
          :create    => true,
          :remove    => true,
          :delete    => true,
          :deleted   => true,
          :created   => true,
          :exists    => true,
          :directory => true,
          :identical => true,
          :convert   => true,
          :unchanged => true
      }

      attr_accessor :actions, :options, :time

      def initialize(*actions)
        self.options = actions.last.is_a?(Hash) ? actions.pop : {}
        @actions = DEFAULT_ACTIONS.dup
        @actions += actions
      end

      # Record an action that has occurred
      def record(action, *arguments)
        return if options[:quiet] && ACTION_CAN_BE_QUIET[action]
        msg = ""
        if time
          msg << Time.now.strftime("%I:%M:%S.%3N %p")
        end
        msg << color(ACTION_COLORS[action])
        msg << "#{action_padding(action)}#{action}"
        msg << color(:clear)
        msg << " #{arguments.join(' ')}"
        log msg
      end

      def green
        wrap(:green) { yield }
      end

      def red
        wrap(:red) { yield }
      end

      def yellow
        wrap(:yellow) { yield }
      end

      def wrap(c, reset_to = :clear)
        $stderr.write(color(c))
        $stdout.write(color(c))
        yield
      ensure
        $stderr.write(color(reset_to))
        $stdout.write(color(reset_to))
        $stdout.flush
      end

      def color(c)
        if c && COLORS.has_key?(c.to_sym)
          if defined?($boring) && $boring
            ""
          else
            "\e[#{COLORS[c.to_sym]}m"
          end
        else
          ""
        end
      end

      # Emit a log message without a trailing newline
      def emit(msg)
        print msg
        $stdout.flush
      end

      # Emit a log message with a trailing newline
      def log(msg)
        puts msg
        $stdout.flush
      end

      # add padding to the left of an action that was performed.
      def action_padding(action)
        ' ' * [(max_action_length - action.to_s.length), 0].max
      end

      # the maximum length of all the actions known to the logger.
      def max_action_length
        @max_action_length ||= actions.inject(0){|memo, a| [memo, a.to_s.length].max}
      end
    end

    class NullLogger < Logger
      def record(*args)
      end

      def log(msg)
      end

      def emit(msg)
      end
    end
  end
end
