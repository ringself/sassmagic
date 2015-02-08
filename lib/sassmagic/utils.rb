## use base.sass
## $ git clone https://github.com/jsw0528/base.sass && cd base.sass && rake
## License
## Licensed under the [MIT License](http://www.opensource.org/licenses/mit-license.php).

#env
# require 'tinypng'
module Sass::Script::Functions

  # Returns the value of environment variable associated with the given name.
  # Returns null if the named variable does not exist.
  #
  # Examples:
  # env(SASS_ENV) => development
  # env(sass_env) => development
  # env(sass-env) => development
  def env(name)
    assert_type name, :String
    ruby_to_sass(ENV[name.value.gsub('-', '_').upcase])
  end

  # Returns the config associated with the given name.
  # Configs are be grouped by `SASS_ENV` environment.
  #
  # Examples:
  # $app-config: (
  #   development: (
  #     foo: bar
  #   ),
  #   production: (
  #     foo: baz
  #   )
  # );
  #
  # $ sass --watch -r base.sass src:dist
  # app-config(foo) => bar
  #
  # $ SASS_ENV=production sass --watch -r base.sass src:dist
  # app-config(foo) => baz
  def app_config(name)
    assert_type name, :String
# debugger
    config = environment.global_env.var('app-config')
    return null unless config.is_a? Sass::Script::Value::Map

    config = map_get(config, env(identifier('sass-env')))

    map_get(config, name)
  end

end

#strftime
module Sass::Script::Functions

  # Formats time according to the directives in the given format string.
  # Read more: http://www.ruby-doc.org/core-2.1.1/Time.html#method-i-strftime
  #
  # Examples:
  # strftime()             => 1399392214
  # strftime('%FT%T%:z')   => 2014-05-07T00:03:34+08:00
  # strftime('at %I:%M%p') => at 12:03AM
  def strftime(format = nil)
    time = Time.now.localtime

    if format
      assert_type format, :String
      identifier(time.strftime(format.value))
    else
      identifier(time.to_i.to_s)
    end
  end

end

#sass_to_ruby
module Sass::Script::Functions

  protected

  def sass_to_ruby(obj)
    return to_ruby_hash(obj) if obj.is_a? Sass::Script::Value::Map
    return to_ruby_array(obj) if obj.is_a? Sass::Script::Value::List
    return obj.inspect if obj.is_a? Sass::Script::Value::Color
    obj.value
  end

  def to_ruby_hash(sass_map)
    sass_map.to_h.inject({}) do |memo, (k, v)|
      memo[k.to_s] = sass_to_ruby(v)
      memo
    end
  end

  def to_ruby_array(sass_list)
    sass_list.to_a.map do |item|
      sass_to_ruby(item)
    end
  end

end

#ruby_to_sass
module Sass::Script::Functions

  protected

  def ruby_to_sass(obj)
    return bool(obj) if obj.is_a?(TrueClass) || obj.is_a?(FalseClass)
    return null if obj.nil?
    return number(obj) if obj.is_a? Numeric
    return to_sass_list(obj) if obj.is_a? Array
    return to_sass_map(obj) if obj.is_a? Hash
    identifier(obj.to_s)
  end

  def to_sass_map(ruby_hash)
    sass_map = map({})

    ruby_hash.each do |k, v|
      sass_map = map_merge(
          sass_map,
          map(Hash[identifier(k.to_s), ruby_to_sass(v)])
      )
    end

    sass_map
  end

  def to_sass_list(ruby_array)
    list(ruby_array.map { |item|
       ruby_to_sass(item)
     }, :comma)
  end

end


#inline_image 取图片base64编码
module Sass::Script::Functions

  def inline_image(path, mime_type = nil)
    # debugger
    path = path.value
    real_path = File.expand_path("#{File.dirname(options[:filename])}/#{path}")
    inline_image_string(data(real_path), compute_mime_type(path, mime_type))
  end

  declare :inline_image, [], var_args: true, var_kwargs: true

  protected
  def inline_image_string(data, mime_type)
    data = [data].flatten.pack('m').gsub("\n","")
    url = "url(data:#{mime_type};base64,#{data})"
    unquoted_string(url)
  end

  private
  def compute_mime_type(path, mime_type = nil)
    return mime_type.value if mime_type
    case path
      when /\.png$/i
        'image/png'
      when /\.jpe?g$/i
        'image/jpeg'
      when /\.gif$/i
        'image/gif'
      when /\.svg$/i
        'image/svg+xml'
      when /\.otf$/i
        'font/opentype'
      when /\.eot$/i
        'application/vnd.ms-fontobject'
      when /\.ttf$/i
        'font/truetype'
      when /\.woff$/i
        'application/font-woff'
      when /\.off$/i
        'font/openfont'
      when /\.([a-zA-Z]+)$/
        "image/#{Regexp.last_match(1).downcase}"
      else
        raise Sass.logger.debug("A mime type could not be determined for #{path}, please specify one explicitly.")
    end
  end

  def data(real_path)
    # debugger
    if File.readable?(real_path)
      File.open(real_path, "rb") {|io| io.read}
    else
      raise Sass.logger.debug("File not found or cannot be read: #{real_path}")
    end
  end

end




#url重写
module Sass::Script::Functions

  FONT_TYPES = {
      eot: 'embedded-opentype',
      woff: 'woff',
      ttf: 'truetype',
      svg: 'svg'
  }

  MIME_TYPES = {
      png: 'image/png',
      jpg: 'image/jpeg',
      jpeg: 'image/jpeg',
      gif: 'image/gif',
      eot: 'application/vnd.ms-fontobject',
      woff: 'application/font-woff',
      ttf: 'font/truetype',
      svg: 'image/svg+xml'
  }

  PATH_REGEX = /^(.*)(\.\w+)(\??[^#]*)(#?.*)$/

  # Reinforce the official `url()` in CSS to support multi url and data url.
  # Activates only when all paths are wrapped with quotes.
  #
  # Examples:
  # url(http://a.com/b.png)      => url(http://a.com/b.png) # Did nothing
  # url('http://a.com/b.png')    => url(http://a.com/b.png?1399394203)
  # url('a.png', 'b.png')        => url(a.png?1399394203), url(b.png?1399394203)
  # url('a.eot#iefix', 'b.woff') => url(a.eot?1399394203#iefix) format('embedded-opentype'), url(b.woff?1399394203) format('woff')
  #
  # url('a.png', $timestamp: false)   => url(a.png)
  # url('a.png', $timestamp: '1.0.0') => url(a.png?1.0.0)
  #
  # $app-config: (timestamp: '1.0.0');
  # url('a.png') => url(a.png?1.0.0)
  #
  # $app-config: (timestamp: 'p1');
  # url('a.png', $timestamp: 'p0') => url(a.png?p0)
  #
  # url('a.png', $base64: true) => url(data:image/png;base64,iVBORw...)
  def url(*paths)
    # debugger
    $configHash ||= load_json(File.expand_path("#{File.dirname(options[:filename])}/sassmagic.json")) || Hash.new
    kwargs = paths.last.is_a?(Hash) ? paths.pop : {}
    raise Sass::SyntaxError, 'url() needs one path at least' if paths.empty?

    encode = kwargs['base64'] == bool(true)
    ts = timestamp(kwargs['timestamp'])

    paths = paths.map { |path| sass_to_ruby(path) }.flatten
    .map { |path| compress_img(path);to_url(path, encode, ts) }

    list(paths, :comma)
  end
  declare :url, [], var_args: true, var_kwargs: true


  private
  def compress_img(path)
    #图片压缩
    # debugger
    require "net/https"
    require "uri"

    key = $configHash['tinypngKye'] || "_opLq9BVg-AHRQn0Fh0WNapWX83K6gmH"
    input = path
    # real_path = File.expand_path("#{File.dirname(path)}/#{path}")
    # output = "tiny-output.png"

    uri = URI.parse("https://api.tinypng.com/shrink")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

# Uncomment below if you have trouble validating our SSL certificate.
# Download cacert.pem from: http://curl.haxx.se/ca/cacert.pem
# http.ca_file = File.join(File.dirname(__FILE__), "cacert.pem")

    request = Net::HTTP::Post.new(uri.request_uri)
    request.basic_auth("api", key)

    response = http.request(request, File.binread(input))
    # debugger
    if response.code == "201"
      # Compression was successful, retrieve output from Location header.
      # debugger
      output = path
      path.gsub!(/\.(png|jpg)$/,'_tinypng.\1')
      # output['.png'] = '_tinypng.png'
      # output['.jpg'] = '_tinypng.jpg'
      File.binwrite(output, http.get(response["location"]).body)
    else
      # Something went wrong! You can parse the JSON body for details.
      puts "Compression failed"
    end
  end
  def timestamp(ts)
    # no kwargs
    if ts.nil?
      cfg = app_config(identifier('timestamp'))
      ts = cfg == null ? bool(true) : cfg
    end

    return nil unless ts.to_bool
    return strftime.value if ts.is_a? Sass::Script::Value::Bool
    ts.value.to_s
  end

  def sign(query)
    case query.size
      when 0
        '?'
      when 1
        ''
      else
        '&'
    end
  end

  def to_url(path, encode, ts)
    output = "url(#{path})"
    # debugger
    if path.is_a?(String) && path =~ PATH_REGEX

      path, ext, query, anchor = $1 + $2, $2[1..-1].downcase.to_sym, $3, $4

      if MIME_TYPES.key? ext
        # 网络地址
        if path =~ /^(http:|https:)\/\//
          # path = path.replace(/(http:\/\/)|(http:\/\/)/,'//')
          path['http://'] = '//'
          output = output_path(path, ext, query, anchor, ts)
        else
          if $configHash["imageMaxSize"]
            #替换图片地址
            output = if encode
                       output_data(path, ext)
                     else
                       #替换图片
                       # debugger
                       filesize = File.size(File.expand_path("#{File.dirname(options[:filename])}/#{path}"))
                       if filesize < $configHash["imageMaxSize"].to_i
                         output_data(path, ext)
                       else
                         path = change_path(path)
                         output_path(path, ext, query, anchor, ts)
                       end
                     end
          else
            output = if encode
                       output_data(path, ext)
                     else
                       output_path(path, ext, query, anchor, ts)
                     end
          end
        end


      end

    end

    if output.is_a? Array
      list(output, :space)
    else
      identifier(output)
    end
  end

  def output_data(path, ext)
    data = [read_file(File.expand_path(File.expand_path("#{File.dirname(options[:filename])}/#{path}")))].pack('m').gsub(/\s/, '')
    "url(data:#{MIME_TYPES[ext]};base64,#{data})"
  end

  def output_path(path, ext, query, anchor, ts)
    query += sign(query) + ts unless ts.nil?

    output = "url(#{path}#{query}#{anchor})"
    return output unless FONT_TYPES.key? ext

    [identifier(output), identifier("format('#{FONT_TYPES[ext]}')")]
  end
  def change_path(path)
    # debugger
    $configHash["imagesPath"] ||= Hash.new
    if $configHash["imagesPath"].has_key?(File.expand_path("#{File.dirname(options[:filename])}/#{path}"))
      return $configHash["imagesPath"][File.expand_path("#{File.dirname(options[:filename])}/#{path}")]
    end

    # 调用上传任务
    # debugger
    nodetask = $configHash["imageLoader"] || false
    taskargs = File.expand_path("#{File.dirname(options[:filename])}/#{path}")
    # debugger
    if nodetask && File::exists?( File.expand_path("#{File.dirname(options[:filename])}/#{nodetask}") )
      task = system('node '+File.expand_path("#{File.dirname(options[:filename])}/#{nodetask}")+' '+File.expand_path("#{File.dirname(options[:filename])}/sassmagic.json")+' '+taskargs)
      if task
        # puts 'nodetask success'
        $configHash = load_json(File.expand_path("#{File.dirname(options[:filename])}/sassmagic.json"))
        $configHash["imagesPath"] ||= Hash.new
        if $configHash["imagesPath"].has_key?(path)
          return $configHash["imagesPath"][path]
        else
          return path
        end
      else
        # puts 'nodetask faile'
        if $configHash["imagesPath"].has_key?(path)
          return $configHash["imagesPath"][path]
        else
          return path
        end
      end
    else
      if $configHash["imagesPath"].has_key?(path)
        return $configHash["imagesPath"][path]
      else
        return path
      end
    end



  end
end


#parse_json load_json read_file
require 'json'

module Sass::Script::Functions

  $cached_files = {}

  # Parses a local json file, returns a map, and the result will be cached.
  # If the `path` is not a absolute path, relative to current process directory.
  #
  # Examples:
  # parse-json('~/Desktop/example.json')
  # parse-json('package.json')
  def parse_json(path)
    assert_type path, :String
    path = File.expand_path(path.value)

    if $cached_files.key? path
      Sass.logger.debug "Reading file from cache: #{path}"
      $cached_files[path]
    else
      $cached_files[path] = ruby_to_sass(load_json(path))
    end
  end


  #protected

  def load_json(path)
    if File::exists?( path )
      JSON.load(
          read_file(File.expand_path(path)).to_s.gsub(/(\\r|\\n)/, '')
      )
    end
  end

  def read_file(path)
    raise Sass::SyntaxError, "File not found or cannot be read: #{path}" unless File.readable? path

    Sass.logger.debug "Reading file: #{path}"
    File.open(path, 'rb') { |f| f.read }
  end
end



