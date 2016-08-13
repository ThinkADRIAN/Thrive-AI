# -*- encoding: utf-8 -*-
# stub: api-ai-ruby 1.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "api-ai-ruby"
  s.version = "1.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["api.ai"]
  s.date = "2016-04-22"
  s.description = "Plugin makes it easy to integrate your Ruby application with https://api.ai natural language processing service."
  s.email = ["shingarev@api.ai"]
  s.homepage = "https://api.ai"
  s.licenses = ["Apache 2.0 License"]
  s.rubygems_version = "2.5.1"
  s.summary = "ruby SDK for https://api.ai"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>, ["~> 1.7"])
      s.add_development_dependency(%q<rake>, ["~> 10.0"])
      s.add_runtime_dependency(%q<http>, ["~> 0.9.4"])
      s.add_runtime_dependency(%q<http-form_data>, ["~> 1.0"])
    else
      s.add_dependency(%q<bundler>, ["~> 1.7"])
      s.add_dependency(%q<rake>, ["~> 10.0"])
      s.add_dependency(%q<http>, ["~> 0.9.4"])
      s.add_dependency(%q<http-form_data>, ["~> 1.0"])
    end
  else
    s.add_dependency(%q<bundler>, ["~> 1.7"])
    s.add_dependency(%q<rake>, ["~> 10.0"])
    s.add_dependency(%q<http>, ["~> 0.9.4"])
    s.add_dependency(%q<http-form_data>, ["~> 1.0"])
  end
end
