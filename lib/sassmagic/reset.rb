# sass文件重写，主要修改了属性解析函数，编译文件函数，文件涉及：sass.rb,to_css.rb,base.rb，sass_convert.rb，sass_scss.rb
module Sass::Script::Functions::UserFunctions
  def option(name)
    Sass::Script::Value::String.new(@options[name.value.to_sym].to_s)
  end

  def set_a_variable(name, value)
    environment.set_var(name.value, value)
    return Sass::Script::Value::Null.new
  end

  def set_a_global_variable(name, value)
    environment.set_global_var(name.value, value)
    return Sass::Script::Value::Null.new
  end

  def get_a_variable(name)
    environment.var(name.value) || Sass::Script::Value::String.new("undefined")
  end
end

module Sass::Script::Functions
  include Sass::Script::Functions::UserFunctions
  def reverse(string)
    assert_type string, :String
    Sass::Script::Value::String.new(string.value.reverse)
  end
  declare :reverse, [:string]
  def pxtorem(string)
    assert_type string, :String
    Sass::Script::Value::String.new(string+'rem')
  end
  declare :pxtorem, [:string]
  # Dynamically calls a function. This can call user-defined
  # functions, built-in functions, or plain CSS functions. It will
  # pass along all arguments, including keyword arguments, to the
  # called function.
  #
  # @example
  #   call(rgb, 10, 100, 255) => #0a64ff
  #   call(scale-color, #0a64ff, $lightness: -10%) => #0058ef
  #
  #   $fn: nth;
  #   call($fn, (a b c), 2) => b
  #
  # @overload call($name, $args...)
  #   @param $name [String] The name of the function to call.
  def call(name, *args)
    assert_type name, :String, :name
    kwargs = args.last.is_a?(Hash) ? args.pop : {}
    funcall = Sass::Script::Tree::Funcall.new(
        name.value,
        args.map {|a| Sass::Script::Tree::Literal.new(a)},
        Sass::Util.map_vals(kwargs) {|v| Sass::Script::Tree::Literal.new(v)},
        nil,
        nil)
    funcall.options = options
    perform(funcall)
  end
  declare :call, [:name], :var_args => true, :var_kwargs => true
end



# 重写编译
module Sass
  class << self
    # @private
    attr_accessor :tests_running
  end

  # The global load paths for Sass files. This is meant for plugins and
  # libraries to register the paths to their Sass stylesheets to that they may
  # be `@imported`. This load path is used by every instance of {Sass::Engine}.
  # They are lower-precedence than any load paths passed in via the
  # {file:SASS_REFERENCE.md#load_paths-option `:load_paths` option}.
  #
  # If the `SASS_PATH` environment variable is set,
  # the initial value of `load_paths` will be initialized based on that.
  # The variable should be a colon-separated list of path names
  # (semicolon-separated on Windows).
  #
  # Note that files on the global load path are never compiled to CSS
  # themselves, even if they aren't partials. They exist only to be imported.
  #
  # @example
  #   Sass.load_paths << File.dirname(__FILE__ + '/sass')
  # @return [Array<String, Pathname, Sass::Importers::Base>]
  def self.load_paths
    @load_paths ||= if ENV['SASS_PATH']
                      ENV['SASS_PATH'].split(Sass::Util.windows? ? ';' : ':')
                    else
                      []
                    end
  end

  # Compile a Sass or SCSS string to CSS.
  # Defaults to SCSS.
  #
  # @param contents [String] The contents of the Sass file.
  # @param options [{Symbol => Object}] An options hash;
  #   see {file:SASS_REFERENCE.md#sass_options the Sass options documentation}
  # @raise [Sass::SyntaxError] if there's an error in the document
  # @raise [Encoding::UndefinedConversionError] if the source encoding
  #   cannot be converted to UTF-8
  # @raise [ArgumentError] if the document uses an unknown encoding with `@charset`
  def self.compile(contents, options = {})
    options[:syntax] ||= :scss
    Engine.new(contents, options).to_css
  end

  # Compile a file on disk to CSS.
  #
  # @raise [Sass::SyntaxError] if there's an error in the document
  # @raise [Encoding::UndefinedConversionError] if the source encoding
  #   cannot be converted to UTF-8
  # @raise [ArgumentError] if the document uses an unknown encoding with `@charset`
  #
  # @overload compile_file(filename, options = {})
  #   Return the compiled CSS rather than writing it to a file.
  #
  #   @param filename [String] The path to the Sass, SCSS, or CSS file on disk.
  #   @param options [{Symbol => Object}] An options hash;
  #     see {file:SASS_REFERENCE.md#sass_options the Sass options documentation}
  #   @return [String] The compiled CSS.
  #
  # @overload compile_file(filename, css_filename, options = {})
  #   Write the compiled CSS to a file.
  #
  #   @param filename [String] The path to the Sass, SCSS, or CSS file on disk.
  #   @param options [{Symbol => Object}] An options hash;
  #     see {file:SASS_REFERENCE.md#sass_options the Sass options documentation}
  #   @param css_filename [String] The location to which to write the compiled CSS.
  def self.compile_file(filename, *args)
    # debugger
    # puts filename
    # puts args
    # Sass.logger(filename, args)
    ctx = Sass::Script::Functions::EvaluationContext.new(Sass::Environment.new(nil, {}))

    # print 'star compile file:'
    #加载json
    # 获取设置
    $configHash = ctx.load_json(File.expand_path("#{File.dirname(filename)}/sassmagic.json")) || {}
    # puts $configHash
    options = args.last.is_a?(Hash) ? args.pop : {}
    options = options.merge $configHash
    css_filename = args.shift
    # debugger
    #是否需要额外输出样式表
    if options.has_key?"outputExtra"
      options["outputExtra"] ||= []
      options["outputExtra"].each {|v|

        extra_filename = css_filename + ''
        #替换成1x 2x 3x
        extra_filename.gsub!(/\.css$/ , '.'+v+'.css')
        if extra_filename
          options[:css_filename] = extra_filename
          options["multiple"] = v
          result = Sass::Engine.for_file(filename, options).render
          # open(css_filename, "w") {|css_file| css_file.write(result)}
          File.open(extra_filename, 'w') {|css_file| css_file.write(result)}
          nil
        else
          result = Sass::Engine.for_file(filename, options).render
          result
        end
      }
    end

    options.delete("multiple")
    result = Sass::Engine.for_file(filename, options).render
    if css_filename
      options[:css_filename] ||= css_filename
      open(css_filename, "w") {|css_file| css_file.write(result)}
      nil
    else
      result
    end
  end


end


#重写属性解析to_css.rb
# A visitor for converting a Sass tree into CSS.
class Sass::Tree::Visitors::ToCss < Sass::Tree::Visitors::Base
  # The source mapping for the generated CSS file. This is only set if
  # `build_source_mapping` is passed to the constructor and \{Sass::Engine#render} has been
  # run.
  attr_reader :source_mapping

  # @param build_source_mapping [Boolean] Whether to build a
  #   \{Sass::Source::Map} while creating the CSS output. The mapping will
  #   be available from \{#source\_mapping} after the visitor has completed.
  def initialize(build_source_mapping = false)
    @tabs = 0
    @line = 1
    @offset = 1
    @result = ""
    @source_mapping = Sass::Source::Map.new if build_source_mapping
  end

  # Runs the visitor on `node`.
  #
  # @param node [Sass::Tree::Node] The root node of the tree to convert to CSS>
  # @return [String] The CSS output.
  def visit(node)
    super
  rescue Sass::SyntaxError => e
    e.modify_backtrace(:filename => node.filename, :line => node.line)
    raise e
  end

  protected

  def with_tabs(tabs)
    old_tabs, @tabs = @tabs, tabs
    yield
  ensure
    @tabs = old_tabs
  end

  # Associate all output produced in a block with a given node. Used for source
  # mapping.
  def for_node(node, attr_prefix = nil)
    return yield unless @source_mapping
    start_pos = Sass::Source::Position.new(@line, @offset)
    yield

    range_attr = attr_prefix ? :"#{attr_prefix}_source_range" : :source_range
    return if node.invisible? || !node.send(range_attr)
    source_range = node.send(range_attr)
    target_end_pos = Sass::Source::Position.new(@line, @offset)
    target_range = Sass::Source::Range.new(start_pos, target_end_pos, nil)
    @source_mapping.add(source_range, target_range)
  end

  # Move the output cursor back `chars` characters.
  def erase!(chars)
    return if chars == 0
    str = @result.slice!(-chars..-1)
    newlines = str.count("\n")
    if newlines > 0
      @line -= newlines
      @offset = @result[@result.rindex("\n") || 0..-1].size
    else
      @offset -= chars
    end
  end

  # Avoid allocating lots of new strings for `#output`. This is important
  # because `#output` is called all the time.
  NEWLINE = "\n"

  # Add `s` to the output string and update the line and offset information
  # accordingly.
  def output(s)
    if @lstrip
      s = s.gsub(/\A\s+/, "")
      @lstrip = false
    end

    newlines = s.count(NEWLINE)
    if newlines > 0
      @line += newlines
      @offset = s[s.rindex(NEWLINE)..-1].size
    else
      @offset += s.size
    end

    @result << s
  end

  # Strip all trailing whitespace from the output string.
  def rstrip!
    erase! @result.length - 1 - (@result.rindex(/[^\s]/) || -1)
  end

  # lstrip the first output in the given block.
  def lstrip
    old_lstrip = @lstrip
    @lstrip = true
    yield
  ensure
    @lstrip = @lstrip && old_lstrip
  end

  # Prepend `prefix` to the output string.
  def prepend!(prefix)
    @result.insert 0, prefix
    return unless @source_mapping

    line_delta = prefix.count("\n")
    offset_delta = prefix.gsub(/.*\n/, '').size
    @source_mapping.shift_output_offsets(offset_delta)
    @source_mapping.shift_output_lines(line_delta)
  end

  def visit_root(node)
    #输出样式表
    # debugger
    node.children.each do |child|
      next if child.invisible?
      visit(child)
      unless node.style == :compressed
        output "\n"
        if child.is_a?(Sass::Tree::DirectiveNode) && child.has_children && !child.bubbles?
          output "\n"
        end
      end
    end
    rstrip!
    return "" if @result.empty?

    output "\n"

    unless Sass::Util.ruby1_8? || @result.ascii_only?
      if node.style == :compressed
        # A byte order mark is sufficient to tell browsers that this
        # file is UTF-8 encoded, and will override any other detection
        # methods as per http://encoding.spec.whatwg.org/#decode-and-encode.
        prepend! "\uFEFF"
      else
        prepend! "@charset \"UTF-8\";\n"
      end
    end

    @result
  rescue Sass::SyntaxError => e
    e.sass_template ||= node.template
    raise e
  end

  def visit_charset(node)
    for_node(node) {output("@charset \"#{node.name}\";")}
  end

  def visit_comment(node)
    return if node.invisible?
    spaces = ('  ' * [@tabs - node.resolved_value[/^ */].size, 0].max)

    content = node.resolved_value.gsub(/^/, spaces)
    if node.type == :silent
      content.gsub!(%r{^(\s*)//(.*)$}) {|md| "#{$1}/*#{$2} */"}
    end
    if (node.style == :compact || node.style == :compressed) && node.type != :loud
      content.gsub!(/\n +(\* *(?!\/))?/, ' ')
    end
    for_node(node) {output(content)}
  end

  # @comment
  #   rubocop:disable MethodLength
  def visit_directive(node)
    was_in_directive = @in_directive
    tab_str = '  ' * @tabs
    if !node.has_children || node.children.empty?
      output(tab_str)
      for_node(node) {output(node.resolved_value)}
      output(!node.has_children ? ";" : " {}")
      return
    end

    @in_directive = @in_directive || !node.is_a?(Sass::Tree::MediaNode)
    output(tab_str) if node.style != :compressed
    for_node(node) {output(node.resolved_value)}
    output(node.style == :compressed ? "{" : " {")
    output(node.style == :compact ? ' ' : "\n") if node.style != :compressed

    was_prop = false
    first = true
    node.children.each do |child|
      next if child.invisible?
      if node.style == :compact
        if child.is_a?(Sass::Tree::PropNode)
          with_tabs(first || was_prop ? 0 : @tabs + 1) do
            visit(child)
            output(' ')
          end
        else
          if was_prop
            erase! 1
            output "\n"
          end

          if first
            lstrip {with_tabs(@tabs + 1) {visit(child)}}
          else
            with_tabs(@tabs + 1) {visit(child)}
          end

          rstrip!
          output "\n"
        end
        was_prop = child.is_a?(Sass::Tree::PropNode)
        first = false
      elsif node.style == :compressed
        output(was_prop ? ";" : "")
        with_tabs(0) {visit(child)}
        was_prop = child.is_a?(Sass::Tree::PropNode)
      else
        with_tabs(@tabs + 1) {visit(child)}
        output "\n"
      end
    end
    rstrip!
    if node.style == :expanded
      output("\n#{tab_str}")
    elsif node.style != :compressed
      output(" ")
    end
    output("}")
  ensure
    @in_directive = was_in_directive
  end
  # @comment
  #   rubocop:enable MethodLength

  def visit_media(node)
    with_tabs(@tabs + node.tabs) {visit_directive(node)}
    output("\n") if node.style != :compressed && node.group_end
  end

  def visit_supports(node)
    visit_media(node)
  end

  def visit_cssimport(node)
    visit_directive(node)
  end
  #属性重写开始
  def visit_prop(node)
    opt = node.options
    if $configHash == nil || $configHash == {}
      #读取配置文件
      ctx = Sass::Script::Functions::EvaluationContext.new(Sass::Environment.new(nil, {}))
      #加载json
      # 获取设置
      filename = opt[:filename] || ''
      $configHash = ctx.load_json(File.expand_path("#{File.dirname(filename)}/sassmagic.json")) || {}
      opt = opt.merge $configHash
    else
      opt = opt.merge $configHash
    end

    multiple =  opt["multiple"] || false
    devicePixelRatio =  opt["devicePixelRatio"] || 1
    # debugger
    #干预输出
    if multiple
      # 过滤掉不需要处理的name
      isNeedChangeMultiple = true;
      opt["ignore"].each{|v|
        # debugger
        if $classignore
          isNeedChangeMultiple = false
        end
      }
      if isNeedChangeMultiple
        treated_prop = pxttodpr(node.resolved_value,devicePixelRatio,multiple)
      else
        treated_prop = node.resolved_value
      end

    else
      if opt['isNeedPxToRem']
        if opt["browserDefaultFontSize"].to_i !=  0
          configRem = opt["browserDefaultFontSize"].to_i
        else
          configRem = 75
        end
        treated_prop = pxtorem(node,node.resolved_value,configRem,opt["ignore"])
      else
        treated_prop = node.resolved_value
      end
    end



    #输出属性resolved_name和值resolved_value
    return if node.resolved_value.empty?
    tab_str = '  ' * (@tabs + node.tabs)
    output(tab_str)
    for_node(node, :name) {output(node.resolved_name)}
    if node.style == :compressed
      output(":")
      for_node(node, :value) {output(treated_prop)}
    else
      output(": ")
      for_node(node, :value) {output(treated_prop)}
      output(";")
    end
  end

  def pxtorem(node,str,rem,ignore)
    ret = str
    ignore = ignore || []
    # 过滤掉不需要处理的name
    isNeedChangeValue = true;
    ignore.each{|v|
      # debugger
      if $classignore && (node.resolved_name.include? v)
        isNeedChangeValue = false
      end
    }
    if isNeedChangeValue
      #字符串替换px
      #'0 1px.jpg 1px 2px;3pxabc 4px'.scan(/([\.\d]+)+(px)+([;\s]+|$)/)
      #=> [["1", "px", " "], ["2", "px", ";"], ["4", "px", ""]]
      str.scan(/([\.\d]+)+(px)+([;\s]+|$)/i){ |c,v|
        if !(ignore.include? c+v) && (c != '1')
          ret = ret.gsub(c.to_s,(format("%.3f",c.to_f/rem).to_f).to_s).gsub(v,'rem')
        end
      }
    end
    return ret
  end

  def pxttodpr(str,dpr,multiple)
    ret = str
    #字符串替换px
    #'0 1px.jpg 1px 2px;3pxabc 4px'.scan(/([\.\d]+)+(px)+([;\s]+|$)/)
    #=> [["1", "px", " "], ["2", "px", ";"], ["4", "px", ""]]
    str.scan(/([\.\d]+)+(px)+([;\s]+|$)/i){ |c,v|
      if c != '1'
        ret = ret.gsub(c.to_s,((c.to_i/dpr.to_i) * multiple.to_i).to_s)
      end
    }
    return ret
  end

  #属性重写结束
  # @comment
  #   rubocop:disable MethodLength
  def visit_rule(node)
    # debugger
    opt = node.options
    if $configHash == nil || $configHash == {}
      #读取配置文件
      ctx = Sass::Script::Functions::EvaluationContext.new(Sass::Environment.new(nil, {}))
      #加载json
      # 获取设置
      filename = opt[:filename] || ''
      $configHash = ctx.load_json(File.expand_path("#{File.dirname(filename)}/sassmagic.json")) || {}
      opt = opt.merge $configHash
    else
      opt = opt.merge $configHash
    end
    # 判断是否不需要rem进行自动处理，通过class
    $classignore = false
    opt["ignore"] ||= []
    opt["ignore"].each{|v|
      # debugger
      if (node.resolved_rules.to_s).include? v
        $classignore = true
      end
    }

    with_tabs(@tabs + node.tabs) do
      rule_separator = node.style == :compressed ? ',' : ', '
      line_separator =
          case node.style
            when :nested, :expanded; "\n"
            when :compressed; ""
            else; " "
          end
      rule_indent = '  ' * @tabs
      per_rule_indent, total_indent = if [:nested, :expanded].include?(node.style)
                                        [rule_indent, '']
                                      else
                                        ['', rule_indent]
                                      end

      joined_rules = node.resolved_rules.members.map do |seq|
        next if seq.has_placeholder?
        rule_part = seq.to_s
        if node.style == :compressed
          rule_part.gsub!(/([^,])\s*\n\s*/m, '\1 ')
          rule_part.gsub!(/\s*([,+>])\s*/m, '\1')
          rule_part.strip!
        end
        rule_part
      end.compact.join(rule_separator)

      joined_rules.lstrip!
      joined_rules.gsub!(/\s*\n\s*/, "#{line_separator}#{per_rule_indent}")

      old_spaces = '  ' * @tabs
      if node.style != :compressed
        if node.options[:debug_info] && !@in_directive
          visit(debug_info_rule(node.debug_info, node.options))
          output "\n"
        elsif node.options[:trace_selectors]
          output("#{old_spaces}/* ")
          output(node.stack_trace.gsub("\n", "\n   #{old_spaces}"))
          output(" */\n")
        elsif node.options[:line_comments]
          output("#{old_spaces}/* line #{node.line}")

          if node.filename
            relative_filename =
                if node.options[:css_filename]
                  begin
                    Sass::Util.relative_path_from(
                        node.filename, File.dirname(node.options[:css_filename])).to_s
                  rescue ArgumentError
                    nil
                  end
                end
            relative_filename ||= node.filename
            output(", #{relative_filename}")
          end

          output(" */\n")
        end
      end

      end_props, trailer, tabs  = '', '', 0
      if node.style == :compact
        separator, end_props, bracket = ' ', ' ', ' { '
        trailer = "\n" if node.group_end
      elsif node.style == :compressed
        separator, bracket = ';', '{'
      else
        tabs = @tabs + 1
        separator, bracket = "\n", " {\n"
        trailer = "\n" if node.group_end
        end_props = (node.style == :expanded ? "\n" + old_spaces : ' ')
      end
      output(total_indent + per_rule_indent)
      for_node(node, :selector) {output(joined_rules)}
      output(bracket)

      with_tabs(tabs) do
        node.children.each_with_index do |child, i|
          output(separator) if i > 0
          visit(child)
        end
      end

      output(end_props)
      output("}" + trailer)
    end
  end
  # @comment
  #   rubocop:enable MethodLength

  def visit_keyframerule(node)
    visit_directive(node)
  end

  private

  def debug_info_rule(debug_info, options)
    node = Sass::Tree::DirectiveNode.resolved("@media -sass-debug-info")
    Sass::Util.hash_to_a(debug_info.map {|k, v| [k.to_s, v.to_s]}).each do |k, v|
      rule = Sass::Tree::RuleNode.new([""])
      rule.resolved_rules = Sass::Selector::CommaSequence.new(
          [Sass::Selector::Sequence.new(
               [Sass::Selector::SimpleSequence.new(
                    [Sass::Selector::Element.new(k.to_s.gsub(/[^\w-]/, "\\\\\\0"), nil)],
                    false)
               ])
          ])
      prop = Sass::Tree::PropNode.new([""], Sass::Script::Value::String.new(''), :new)
      prop.resolved_name = "font-family"
      prop.resolved_value = Sass::SCSS::RX.escape_ident(v.to_s)
      rule << prop
      node << rule
    end
    node.options = options.merge(:debug_info => false,
                                 :line_comments => false,
                                 :style => :compressed)
    node
  end
end

require 'optparse'

# 重写base.rb 去掉require
module Sass::Exec
  # The abstract base class for Sass executables.
  class Base
    # @param args [Array<String>] The command-line arguments
    def initialize(args)
      @args = args
      @options = {}
    end

    # Parses the command-line arguments and runs the executable.
    # Calls `Kernel#exit` at the end, so it never returns.
    #
    # @see #parse
    def parse!
      # rubocop:disable RescueException
      begin
        parse
      rescue Exception => e
        # Exit code 65 indicates invalid data per
        # http://www.freebsd.org/cgi/man.cgi?query=sysexits. Setting it via
        # at_exit is a bit of a hack, but it allows us to rethrow when --trace
        # is active and get both the built-in exception formatting and the
        # correct exit code.
        at_exit {exit 65} if e.is_a?(Sass::SyntaxError)

        raise e if @options[:trace] || e.is_a?(SystemExit)

        if e.is_a?(Sass::SyntaxError)
          $stderr.puts e.sass_backtrace_str("standard input")
        else
          $stderr.print "#{e.class}: " unless e.class == RuntimeError
          $stderr.puts e.message.to_s
        end
        $stderr.puts "  Use --trace for backtrace."

        exit 1
      end
      exit 0
      # rubocop:enable RescueException
    end

    # Parses the command-line arguments and runs the executable.
    # This does not handle exceptions or exit the program.
    #
    # @see #parse!
    def parse
      @opts = OptionParser.new(&method(:set_opts))

      @opts.parse!(@args)

      process_result

      @options
    end

    # @return [String] A description of the executable
    def to_s
      @opts.to_s
    end

    protected

    # Finds the line of the source template
    # on which an exception was raised.
    #
    # @param exception [Exception] The exception
    # @return [String] The line number
    def get_line(exception)
      # SyntaxErrors have weird line reporting
      # when there's trailing whitespace
      if exception.is_a?(::SyntaxError)
        return (exception.message.scan(/:(\d+)/).first || ["??"]).first
      end
      (exception.backtrace[0].scan(/:(\d+)/).first || ["??"]).first
    end

    # Tells optparse how to parse the arguments
    # available for all executables.
    #
    # This is meant to be overridden by subclasses
    # so they can add their own options.
    #
    # @param opts [OptionParser]
    def set_opts(opts)
      Sass::Util.abstract(this)
    end

    # Set an option for specifying `Encoding.default_external`.
    #
    # @param opts [OptionParser]
    def encoding_option(opts)
      encoding_desc = if Sass::Util.ruby1_8?
                        'Does not work in Ruby 1.8.'
                      else
                        'Specify the default encoding for input files.'
                      end
      opts.on('-E', '--default-encoding ENCODING', encoding_desc) do |encoding|
        if Sass::Util.ruby1_8?
          $stderr.puts "Specifying the encoding is not supported in ruby 1.8."
          exit 1
        else
          Encoding.default_external = encoding
        end
      end
    end

    # Processes the options set by the command-line arguments. In particular,
    # sets `@options[:input]` and `@options[:output]` to appropriate IO streams.
    #
    # This is meant to be overridden by subclasses
    # so they can run their respective programs.
    def process_result
      input, output = @options[:input], @options[:output]
      args = @args.dup
      input ||=
          begin
            filename = args.shift
            @options[:filename] = filename
            open_file(filename) || $stdin
          end
      @options[:output_filename] = args.shift
      output ||= @options[:output_filename] || $stdout
      @options[:input], @options[:output] = input, output
    end

    COLORS = {:red => 31, :green => 32, :yellow => 33}

    # Prints a status message about performing the given action,
    # colored using the given color (via terminal escapes) if possible.
    #
    # @param name [#to_s] A short name for the action being performed.
    #   Shouldn't be longer than 11 characters.
    # @param color [Symbol] The name of the color to use for this action.
    #   Can be `:red`, `:green`, or `:yellow`.
    def puts_action(name, color, arg)
      return if @options[:for_engine][:quiet]
      printf color(color, "%11s %s\n"), name, arg
      STDOUT.flush
    end

    # Same as `Kernel.puts`, but doesn't print anything if the `--quiet` option is set.
    #
    # @param args [Array] Passed on to `Kernel.puts`
    def puts(*args)
      return if @options[:for_engine][:quiet]
      Kernel.puts(*args)
    end

    # Wraps the given string in terminal escapes
    # causing it to have the given color.
    # If terminal esapes aren't supported on this platform,
    # just returns the string instead.
    #
    # @param color [Symbol] The name of the color to use.
    #   Can be `:red`, `:green`, or `:yellow`.
    # @param str [String] The string to wrap in the given color.
    # @return [String] The wrapped string.
    def color(color, str)
      raise "[BUG] Unrecognized color #{color}" unless COLORS[color]

      # Almost any real Unix terminal will support color,
      # so we just filter for Windows terms (which don't set TERM)
      # and not-real terminals, which aren't ttys.
      return str if ENV["TERM"].nil? || ENV["TERM"].empty? || !STDOUT.tty?
      "\e[#{COLORS[color]}m#{str}\e[0m"
    end

    def write_output(text, destination)
      if destination.is_a?(String)
        open_file(destination, 'w') {|file| file.write(text)}
      else
        destination.write(text)
      end
    end

    private

    def open_file(filename, flag = 'r')
      return if filename.nil?
      flag = 'wb' if @options[:unix_newlines] && flag == 'w'
      file = File.open(filename, flag)
      return file unless block_given?
      yield file
      file.close
    end

    def handle_load_error(err)
      dep = err.message[/^no such file to load -- (.*)/, 1]
      raise err if @options[:trace] || dep.nil? || dep.empty?
      $stderr.puts <<MESSAGE
Required dependency #{dep} not found!
    Run "gem install #{dep}" to get it.
  Use --trace for backtrace.
MESSAGE
      exit 1
    end
  end
end

# 重写sass_convert.rb 去掉require
module Sass::Exec
  # The `sass-convert` executable.
  class SassConvert < Base
    # @param args [Array<String>] The command-line arguments
    def initialize(args)
      super
      # require 'sass'
      @options[:for_tree] = {}
      @options[:for_engine] = {:cache => false, :read_cache => true}
    end

    # Tells optparse how to parse the arguments.
    #
    # @param opts [OptionParser]
    def set_opts(opts)
      opts.banner = <<END
Usage: sass-convert [options] [INPUT] [OUTPUT]

Description:
  Converts between CSS, indented syntax, and SCSS files. For example,
  this can convert from the indented syntax to SCSS, or from CSS to
  SCSS (adding appropriate nesting).
END

      common_options(opts)
      style(opts)
      input_and_output(opts)
      miscellaneous(opts)
    end

    # Processes the options set by the command-line arguments,
    # and runs the CSS compiler appropriately.
    def process_result
      # require 'sass'

      if @options[:recursive]
        process_directory
        return
      end

      super
      input = @options[:input]
      if File.directory?(input)
        raise "Error: '#{input.path}' is a directory (did you mean to use --recursive?)"
      end
      output = @options[:output]
      output = input if @options[:in_place]
      process_file(input, output)
    end

    private

    def common_options(opts)
      opts.separator ''
      opts.separator 'Common Options:'

      opts.on('-F', '--from FORMAT',
              'The format to convert from. Can be css, scss, sass.',
              'By default, this is inferred from the input filename.',
              'If there is none, defaults to css.') do |name|
        @options[:from] = name.downcase.to_sym
        raise "sass-convert no longer supports LessCSS." if @options[:from] == :less
        unless [:css, :scss, :sass].include?(@options[:from])
          raise "Unknown format for sass-convert --from: #{name}"
        end
      end

      opts.on('-T', '--to FORMAT',
              'The format to convert to. Can be scss or sass.',
              'By default, this is inferred from the output filename.',
              'If there is none, defaults to sass.') do |name|
        @options[:to] = name.downcase.to_sym
        unless [:scss, :sass].include?(@options[:to])
          raise "Unknown format for sass-convert --to: #{name}"
        end
      end

      opts.on('-i', '--in-place',
              'Convert a file to its own syntax.',
              'This can be used to update some deprecated syntax.') do
        @options[:in_place] = true
      end

      opts.on('-R', '--recursive',
              'Convert all the files in a directory. Requires --from and --to.') do
        @options[:recursive] = true
      end

      opts.on("-?", "-h", "--help", "Show this help message.") do
        puts opts
        exit
      end

      opts.on("-v", "--version", "Print the Sass version.") do
        puts("Sass #{Sass.version[:string]}")
        exit
      end
    end

    def style(opts)
      opts.separator ''
      opts.separator 'Style:'

      opts.on('--dasherize', 'Convert underscores to dashes.') do
        @options[:for_tree][:dasherize] = true
      end

      opts.on('--indent NUM',
              'How many spaces to use for each level of indentation. Defaults to 2.',
              '"t" means use hard tabs.') do |indent|

        if indent == 't'
          @options[:for_tree][:indent] = "\t"
        else
          @options[:for_tree][:indent] = " " * indent.to_i
        end
      end

      opts.on('--old', 'Output the old-style ":prop val" property syntax.',
              'Only meaningful when generating Sass.') do
        @options[:for_tree][:old] = true
      end
    end

    def input_and_output(opts)
      opts.separator ''
      opts.separator 'Input and Output:'

      opts.on('-s', '--stdin', :NONE,
              'Read input from standard input instead of an input file.',
              'This is the default if no input file is specified. Requires --from.') do
        @options[:input] = $stdin
      end

      encoding_option(opts)

      opts.on('--unix-newlines', 'Use Unix-style newlines in written files.',
              ('Always true on Unix.' unless Sass::Util.windows?)) do
        @options[:unix_newlines] = true if Sass::Util.windows?
      end
    end

    def miscellaneous(opts)
      opts.separator ''
      opts.separator 'Miscellaneous:'

      opts.on('--cache-location PATH',
              'The path to save parsed Sass files. Defaults to .sass-cache.') do |loc|
        @options[:for_engine][:cache_location] = loc
      end

      opts.on('-C', '--no-cache', "Don't cache to sassc files.") do
        @options[:for_engine][:read_cache] = false
      end

      opts.on('--trace', :NONE, 'Show a full Ruby stack trace on error') do
        @options[:trace] = true
      end
    end

    def process_directory
      unless @options[:input] = @args.shift
        raise "Error: directory required when using --recursive."
      end

      output = @options[:output] = @args.shift
      raise "Error: --from required when using --recursive." unless @options[:from]
      raise "Error: --to required when using --recursive." unless @options[:to]
      unless File.directory?(@options[:input])
        raise "Error: '#{@options[:input]}' is not a directory"
      end
      if @options[:output] && File.exist?(@options[:output]) &&
          !File.directory?(@options[:output])
        raise "Error: '#{@options[:output]}' is not a directory"
      end
      @options[:output] ||= @options[:input]

      if @options[:to] == @options[:from] && !@options[:in_place]
        fmt = @options[:from]
        raise "Error: converting from #{fmt} to #{fmt} without --in-place"
      end

      ext = @options[:from]
      Sass::Util.glob("#{@options[:input]}/**/*.#{ext}") do |f|
        output =
            if @options[:in_place]
              f
            elsif @options[:output]
              output_name = f.gsub(/\.(c|sa|sc|le)ss$/, ".#{@options[:to]}")
              output_name[0...@options[:input].size] = @options[:output]
              output_name
            else
              f.gsub(/\.(c|sa|sc|le)ss$/, ".#{@options[:to]}")
            end

        unless File.directory?(File.dirname(output))
          puts_action :directory, :green, File.dirname(output)
          FileUtils.mkdir_p(File.dirname(output))
        end
        puts_action :convert, :green, f
        if File.exist?(output)
          puts_action :overwrite, :yellow, output
        else
          puts_action :create, :green, output
        end

        process_file(f, output)
      end
    end

    def process_file(input, output)
      input_path, output_path = path_for(input), path_for(output)
      if input_path
        @options[:from] ||=
            case input_path
              when /\.scss$/; :scss
              when /\.sass$/; :sass
              when /\.less$/; raise "sass-convert no longer supports LessCSS."
              when /\.css$/; :css
            end
      elsif @options[:in_place]
        raise "Error: the --in-place option requires a filename."
      end

      if output_path
        @options[:to] ||=
            case output_path
              when /\.scss$/; :scss
              when /\.sass$/; :sass
            end
      end

      @options[:from] ||= :css
      @options[:to] ||= :sass
      @options[:for_engine][:syntax] = @options[:from]

      out =
          Sass::Util.silence_sass_warnings do
            if @options[:from] == :css
              require 'sass/css'
              Sass::CSS.new(input.read, @options[:for_tree]).render(@options[:to])
            else
              if input_path
                Sass::Engine.for_file(input_path, @options[:for_engine])
              else
                Sass::Engine.new(input.read, @options[:for_engine])
              end.to_tree.send("to_#{@options[:to]}", @options[:for_tree])
            end
          end

      output = input_path if @options[:in_place]
      write_output(out, output)
    rescue Sass::SyntaxError => e
      raise e if @options[:trace]
      file = " of #{e.sass_filename}" if e.sass_filename
      raise "Error on line #{e.sass_line}#{file}: #{e.message}\n  Use --trace for backtrace"
    rescue LoadError => err
      handle_load_error(err)
    end

    def path_for(file)
      return file.path if file.is_a?(File)
      return file if file.is_a?(String)
    end
  end
end

# 重写sass_scss.rb 去掉require
module Sass::Exec
  # The `sass` and `scss` executables.
  class SassScss < Base
    attr_reader :default_syntax

    # @param args [Array<String>] The command-line arguments
    def initialize(args, default_syntax)
      super(args)
      @options[:sourcemap] = :auto
      @options[:for_engine] = {
          :load_paths => default_sass_path
      }
      @default_syntax = default_syntax
    end

    protected

    # Tells optparse how to parse the arguments.
    #
    # @param opts [OptionParser]
    def set_opts(opts)
      opts.banner = <<END
Usage: #{default_syntax} [options] [INPUT] [OUTPUT]

Description:
  Converts SCSS or Sass files to CSS.
END

      common_options(opts)
      watching_and_updating(opts)
      input_and_output(opts)
      miscellaneous(opts)
    end

    # Processes the options set by the command-line arguments,
    # and runs the Sass compiler appropriately.
    def process_result
      # require 'sass'

      if !@options[:update] && !@options[:watch] &&
          @args.first && colon_path?(@args.first)
        if @args.size == 1
          @args = split_colon_path(@args.first)
        else
          @options[:update] = true
        end
      end
      load_compass if @options[:compass]
      return interactive if @options[:interactive]
      return watch_or_update if @options[:watch] || @options[:update]
      super

      if @options[:sourcemap] != :none && @options[:output_filename]
        @options[:sourcemap_filename] = Sass::Util.sourcemap_name(@options[:output_filename])
      end

      @options[:for_engine][:filename] = @options[:filename]
      @options[:for_engine][:css_filename] = @options[:output] if @options[:output].is_a?(String)
      @options[:for_engine][:sourcemap_filename] = @options[:sourcemap_filename]
      @options[:for_engine][:sourcemap] = @options[:sourcemap]

      run
    end

    private

    def common_options(opts)
      opts.separator ''
      opts.separator 'Common Options:'

      opts.on('-I', '--load-path PATH', 'Specify a Sass import path.') do |path|
        (@options[:for_engine][:load_paths] ||= []) << path
      end

      opts.on('-r', '--require LIB', 'Require a Ruby library before running Sass.') do |lib|
        require lib
      end

      opts.on('--compass', 'Make Compass imports available and load project configuration.') do
        @options[:compass] = true
      end

      opts.on('-t', '--style NAME', 'Output style. Can be nested (default), compact, ' \
                                    'compressed, or expanded.') do |name|
        @options[:for_engine][:style] = name.to_sym
      end

      opts.on("-?", "-h", "--help", "Show this help message.") do
        puts opts
        exit
      end

      opts.on("-v", "--version", "Print the Sass version.") do
        puts("Sass #{Sass.version[:string]}")
        exit
      end
    end

    def watching_and_updating(opts)
      opts.separator ''
      opts.separator 'Watching and Updating:'

      opts.on('--watch', 'Watch files or directories for changes.',
              'The location of the generated CSS can be set using a colon:',
              "  #{@default_syntax} --watch input.#{@default_syntax}:output.css",
              "  #{@default_syntax} --watch input-dir:output-dir") do
        @options[:watch] = true
      end

      # Polling is used by default on Windows.
      unless Sass::Util.windows?
        opts.on('--poll', 'Check for file changes manually, rather than relying on the OS.',
                'Only meaningful for --watch.') do
          @options[:poll] = true
        end
      end

      opts.on('--update', 'Compile files or directories to CSS.',
              'Locations are set like --watch.') do
        @options[:update] = true
      end

      opts.on('-f', '--force', 'Recompile every Sass file, even if the CSS file is newer.',
              'Only meaningful for --update.') do
        @options[:force] = true
      end

      opts.on('--stop-on-error', 'If a file fails to compile, exit immediately.',
              'Only meaningful for --watch and --update.') do
        @options[:stop_on_error] = true
      end
    end

    def input_and_output(opts)
      opts.separator ''
      opts.separator 'Input and Output:'

      if @default_syntax == :sass
        opts.on('--scss',
                'Use the CSS-superset SCSS syntax.') do
          @options[:for_engine][:syntax] = :scss
        end
      else
        opts.on('--sass',
                'Use the indented Sass syntax.') do
          @options[:for_engine][:syntax] = :sass
        end
      end

      # This is optional for backwards-compatibility with Sass 3.3, which didn't
      # enable sourcemaps by default and instead used "--sourcemap" to do so.
      opts.on(:OPTIONAL, '--sourcemap=TYPE',
              'How to link generated output to the source files.',
              '  auto (default): relative paths where possible, file URIs elsewhere',
              '  file: always absolute file URIs',
              '  inline: include the source text in the sourcemap',
              '  none: no sourcemaps') do |type|
        if type && !%w[auto file inline none].include?(type)
          $stderr.puts "Unknown sourcemap type #{type}.\n\n"
          $stderr.puts opts
          exit
        elsif type.nil?
          Sass::Util.sass_warn <<MESSAGE.rstrip
DEPRECATION WARNING: Passing --sourcemap without a value is deprecated.
Sourcemaps are now generated by default, so this flag has no effect.
MESSAGE
        end

        @options[:sourcemap] = (type || :auto).to_sym
      end

      opts.on('-s', '--stdin', :NONE,
              'Read input from standard input instead of an input file.',
              'This is the default if no input file is specified.') do
        @options[:input] = $stdin
      end

      encoding_option(opts)

      opts.on('--unix-newlines', 'Use Unix-style newlines in written files.',
              ('Always true on Unix.' unless Sass::Util.windows?)) do
        @options[:unix_newlines] = true if Sass::Util.windows?
      end

      opts.on('-g', '--debug-info',
              'Emit output that can be used by the FireSass Firebug plugin.') do
        @options[:for_engine][:debug_info] = true
      end

      opts.on('-l', '--line-numbers', '--line-comments',
              'Emit comments in the generated CSS indicating the corresponding source line.') do
        @options[:for_engine][:line_numbers] = true
      end
    end

    def miscellaneous(opts)
      opts.separator ''
      opts.separator 'Miscellaneous:'

      opts.on('-i', '--interactive',
              'Run an interactive SassScript shell.') do
        @options[:interactive] = true
      end

      opts.on('-c', '--check', "Just check syntax, don't evaluate.") do
        require 'stringio'
        @options[:check_syntax] = true
        @options[:output] = StringIO.new
      end

      opts.on('--precision NUMBER_OF_DIGITS', Integer,
              "How many digits of precision to use when outputting decimal numbers.",
              "Defaults to #{Sass::Script::Value::Number.precision}.") do |precision|
        Sass::Script::Value::Number.precision = precision
      end

      opts.on('--cache-location PATH',
              'The path to save parsed Sass files. Defaults to .sass-cache.') do |loc|
        @options[:for_engine][:cache_location] = loc
      end

      opts.on('-C', '--no-cache', "Don't cache parsed Sass files.") do
        @options[:for_engine][:cache] = false
      end

      opts.on('--trace', :NONE, 'Show a full Ruby stack trace on error.') do
        @options[:trace] = true
      end

      opts.on('-q', '--quiet', 'Silence warnings and status messages during compilation.') do
        @options[:for_engine][:quiet] = true
      end
    end

    def load_compass
      begin
        require 'compass'
      rescue LoadError
        require 'rubygems'
        begin
          require 'compass'
        rescue LoadError
          puts "ERROR: Cannot load compass."
          exit 1
        end
      end
      Compass.add_project_configuration
      Compass.configuration.project_path ||= Dir.pwd
      @options[:for_engine][:load_paths] ||= []
      @options[:for_engine][:load_paths] += Compass.configuration.sass_load_paths
    end

    def interactive
      require 'sass/repl'
      Sass::Repl.new(@options).run
    end

    # @comment
    #   rubocop:disable MethodLength
    def watch_or_update
      require 'sass/plugin'
      Sass::Plugin.options.merge! @options[:for_engine]
      Sass::Plugin.options[:unix_newlines] = @options[:unix_newlines]
      Sass::Plugin.options[:poll] = @options[:poll]
      Sass::Plugin.options[:sourcemap] = @options[:sourcemap]

      if @options[:force]
        raise "The --force flag may only be used with --update." unless @options[:update]
        Sass::Plugin.options[:always_update] = true
      end

      raise <<MSG if @args.empty?
What files should I watch? Did you mean something like:
    #{@default_syntax} --watch input.#{@default_syntax}:output.css
    #{@default_syntax} --watch input-dir:output-dir
MSG

      if !colon_path?(@args[0]) && probably_dest_dir?(@args[1])
        flag = @options[:update] ? "--update" : "--watch"
        err =
            if !File.exist?(@args[1])
              "doesn't exist"
            elsif @args[1] =~ /\.css$/
              "is a CSS file"
            end
        raise <<MSG if err
File #{@args[1]} #{err}.
    Did you mean: #{@default_syntax} #{flag} #{@args[0]}:#{@args[1]}
MSG
      end

      # Watch the working directory for changes without adding it to the load
      # path. This preserves the pre-3.4 behavior when the working directory was
      # on the load path. We should remove this when we can look for directories
      # to watch by traversing the import graph.
      class << Sass::Plugin.compiler
        # We have to use a class var to make this visible to #watched_file? and
        # #watched_paths.
        # rubocop:disable ClassVars
        @@working_directory = Sass::Util.realpath('.').to_s
        # rubocop:ensable ClassVars

        def watched_file?(file)
          super(file) ||
              (file =~ /\.s[ac]ss$/ && file.start_with?(@@working_directory + File::SEPARATOR))
        end

        def watched_paths
          @watched_paths ||= super + [@@working_directory]
        end
      end

      dirs, files = @args.map {|name| split_colon_path(name)}.
          partition {|i, _| File.directory? i}
      files.map! do |from, to|
        to ||= from.gsub(/\.[^.]*?$/, '.css')
        sourcemap = Sass::Util.sourcemap_name(to) if @options[:sourcemap]
        [from, to, sourcemap]
      end
      dirs.map! {|from, to| [from, to || from]}
      Sass::Plugin.options[:template_location] = dirs

      Sass::Plugin.on_updated_stylesheet do |_, css, sourcemap|
        [css, sourcemap].each do |file|
          next unless file
          puts_action :write, :green, file
        end
      end

      had_error = false
      Sass::Plugin.on_creating_directory {|dirname| puts_action :directory, :green, dirname}
      Sass::Plugin.on_deleting_css {|filename| puts_action :delete, :yellow, filename}
      Sass::Plugin.on_deleting_sourcemap {|filename| puts_action :delete, :yellow, filename}
      Sass::Plugin.on_compilation_error do |error, _, _|
        if error.is_a?(SystemCallError) && !@options[:stop_on_error]
          had_error = true
          puts_action :error, :red, error.message
          STDOUT.flush
          next
        end

        raise error unless error.is_a?(Sass::SyntaxError) && !@options[:stop_on_error]
        had_error = true
        puts_action :error, :red,
                    "#{error.sass_filename} (Line #{error.sass_line}: #{error.message})"
        STDOUT.flush
      end

      if @options[:update]
        Sass::Plugin.update_stylesheets(files)
        exit 1 if had_error
        return
      end

      puts ">>> Sass is watching for changes. Press Ctrl-C to stop."

      Sass::Plugin.on_template_modified do |template|
        puts ">>> Change detected to: #{template}"
        STDOUT.flush
      end
      Sass::Plugin.on_template_created do |template|
        puts ">>> New template detected: #{template}"
        STDOUT.flush
      end
      Sass::Plugin.on_template_deleted do |template|
        puts ">>> Deleted template detected: #{template}"
        STDOUT.flush
      end

      Sass::Plugin.watch(files)
    end
    # @comment
    #   rubocop:enable MethodLength

    def run
      input = @options[:input]
      output = @options[:output]

      @options[:for_engine][:syntax] ||= :scss if input.is_a?(File) && input.path =~ /\.scss$/
      @options[:for_engine][:syntax] ||= @default_syntax
      engine =
          if input.is_a?(File) && !@options[:check_syntax]
            Sass::Engine.for_file(input.path, @options[:for_engine])
          else
            # We don't need to do any special handling of @options[:check_syntax] here,
            # because the Sass syntax checking happens alongside evaluation
            # and evaluation doesn't actually evaluate any code anyway.
            Sass::Engine.new(input.read, @options[:for_engine])
          end

      input.close if input.is_a?(File)

      if @options[:sourcemap] != :none && @options[:sourcemap_filename]
        relative_sourcemap_path = Sass::Util.relative_path_from(
            @options[:sourcemap_filename], Sass::Util.pathname(@options[:output_filename]).dirname)
        rendered, mapping = engine.render_with_sourcemap(relative_sourcemap_path.to_s)
        write_output(rendered, output)
        write_output(mapping.to_json(
                                                                        :type => @options[:sourcemap],
                                                                        :css_path => @options[:output_filename],
                                                                        :sourcemap_path => @options[:sourcemap_filename]) + "\n",
                     @options[:sourcemap_filename])
      else
        write_output(engine.render, output)
      end
    rescue Sass::SyntaxError => e
      write_output(Sass::SyntaxError.exception_to_css(e), output) if output.is_a?(String)
      raise e
    ensure
      output.close if output.is_a? File
    end

    def colon_path?(path)
      !split_colon_path(path)[1].nil?
    end

    def split_colon_path(path)
      one, two = path.split(':', 2)
      if one && two && Sass::Util.windows? &&
          one =~ /\A[A-Za-z]\Z/ && two =~ /\A[\/\\]/
        # If we're on Windows and we were passed a drive letter path,
        # don't split on that colon.
        one2, two = two.split(':', 2)
        one = one + ':' + one2
      end
      return one, two
    end

    # Whether path is likely to be meant as the destination
    # in a source:dest pair.
    def probably_dest_dir?(path)
      return false unless path
      return false if colon_path?(path)
      Sass::Util.glob(File.join(path, "*.s[ca]ss")).empty?
    end

    def default_sass_path
      return unless ENV['SASS_PATH']
      # The select here prevents errors when the environment's
      # load paths specified do not exist.
      ENV['SASS_PATH'].split(File::PATH_SEPARATOR).select {|d| File.directory?(d)}
    end
  end
end
