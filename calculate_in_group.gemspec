require_relative "lib/calculate_in_group/version"

Gem::Specification.new do |spec|
  spec.name        = "calculate_in_group"
  spec.version     = CalculateInGroup::VERSION
  spec.authors     = ["Igor Kasyanchuk"]
  spec.email       = ["igorkasyanchuk@gmail.com"]
  spec.homepage    = "https://github.com/igorkasyanchuk/calculate_in_group"
  spec.summary     = "Rails active record grouping with range"
  spec.description = "Rails active record grouping with range"
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails"
  spec.add_development_dependency "pg"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "mysql2"
end
