# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{couch_quickie}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Macario Ortega"]
  s.date = %q{2009-05-30}
  s.description = %q{FIX (describe your package)}
  s.email = ["macarui@gmail.com"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "Notes.txt", "README.rdoc"]
  s.files = ["History.txt", "Manifest.txt", "Notes.txt", "README.rdoc", "Rakefile", "examples/populate_db.rb", "examples/validation.rb", "lib/couch_quickie.rb", "lib/couch_quickie/core_ext.rb", "lib/couch_quickie/database.rb", "lib/couch_quickie/document/associations.rb", "lib/couch_quickie/document/base.rb", "lib/couch_quickie/document/design.rb", "lib/couch_quickie/document/generic.rb", "lib/couch_quickie/document/validation.rb", "lib/couch_quickie/response.rb", "lib/couch_quickie/string_hash.rb", "script/console", "script/destroy", "script/generate", "spec/database_spec.rb", "spec/document/design_spec.rb", "spec/document/document_spec.rb", "spec/document/many_to_many_spec.rb", "spec/document/quering_spec.rb", "spec/document/validation.rb", "spec/fixtures/book_view.json", "spec/fixtures/calendar.json", "spec/fixtures/calendar.rb", "spec/fixtures/obj.rb", "spec/fixtures/week.rb", "spec/serialization_spec.rb", "spec/spec_helper.rb", "spec/string_hash_spec.rb"]
  s.has_rdoc = true
  s.homepage = %q{FIX (url)}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{couch_quickie}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{FIX (describe your package)}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<json>, [">= 1.1.4"])
      s.add_runtime_dependency(%q<rest-client>, [">= 0.9.2"])
      s.add_runtime_dependency(%q<activesupport>, [">= 2.3.2"])
      s.add_runtime_dependency(%q<assaf-uuid>, [">= 2.0.1"])
      s.add_development_dependency(%q<newgem>, [">= 1.3.0"])
      s.add_development_dependency(%q<hoe>, [">= 1.8.0"])
    else
      s.add_dependency(%q<json>, [">= 1.1.4"])
      s.add_dependency(%q<rest-client>, [">= 0.9.2"])
      s.add_dependency(%q<activesupport>, [">= 2.3.2"])
      s.add_dependency(%q<assaf-uuid>, [">= 2.0.1"])
      s.add_dependency(%q<newgem>, [">= 1.3.0"])
      s.add_dependency(%q<hoe>, [">= 1.8.0"])
    end
  else
    s.add_dependency(%q<json>, [">= 1.1.4"])
    s.add_dependency(%q<rest-client>, [">= 0.9.2"])
    s.add_dependency(%q<activesupport>, [">= 2.3.2"])
    s.add_dependency(%q<assaf-uuid>, [">= 2.0.1"])
    s.add_dependency(%q<newgem>, [">= 1.3.0"])
    s.add_dependency(%q<hoe>, [">= 1.8.0"])
  end
end
