# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'trace_parser.rb'

git_sha1 = `git rev-parse --verify HEAD`.strip

Gem::Specification.new do |s|
  s.name        = 'trace_parser'
  s.version     = TraceParser::VERSION
  s.date        = Time.now.strftime("%Y-%m-%d")
  s.summary     = "TraceParser"
  s.description = "git sha1: #{git_sha1}"
  s.authors     = ["Shunsuke Naganuma"]
  s.email       = "a70258798@fluky.info"
  s.description = "Immutable Linked List implemented in C-Extensions"
  s.files       = `git ls-files`.split($/)
  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.extensions  = %w[ext/trace_parser/extconf.rb]
  s.homepage    = 'http://rubygems.org/gems/'
  s.license     = 'MIT'
  s.require_paths = ["lib"]
end

