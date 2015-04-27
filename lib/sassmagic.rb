load_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'stylesheets'))

# Register on the Sass path via the environment.
ENV['SASS_PATH'] = [ENV['SASS_PATH'], load_path].compact.join(File::PATH_SEPARATOR)
ENV['SASS_ENV'] ||= 'development'

# Register as a Compass extension.
# begin
#   require 'compass'
#   Compass::Frameworks.register('sassmagic', stylesheets_directory: load_path)
# rescue LoadError
# end
# require 'debugger'
# debugger
# $:.unshift"#{File.dirname(__FILE__)}"
$:.unshift(load_path + '/')


require 'sass'

require 'sassmagic/utils'
require 'sassmagic/remote'
require 'sassmagic/reset'
require 'sassmagic/installer'



