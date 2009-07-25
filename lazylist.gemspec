# -*- encoding: utf-8 -*-
Gem::Specification.new do |s|
    s.name = 'lazylist'
    s.version = '0.3.2'
    s.summary = "Implementation of lazy lists for Ruby"
    s.description = ""

    s.add_dependency('dslkit', '~> 0.2')

    s.files = ["CHANGES", "COPYING", "README", "Rakefile", "VERSION", "examples", "examples/examples.rb", "examples/hamming.rb", "examples/pi.rb", "examples/sieve.rb", "install.rb", "lazylist.gemspec", "lib", "lib/lazylist", "lib/lazylist.rb", "lib/lazylist/enumerable.rb", "lib/lazylist/enumerator_queue.rb", "lib/lazylist/list_builder.rb", "lib/lazylist/thread_queue.rb", "lib/lazylist/version.rb", "make_doc.rb", "tests", "tests/runner.rb", "tests/test.rb", "tests/test_enumerable.rb"]

    s.require_path = 'lib'

    s.has_rdoc = true
    s.extra_rdoc_files << 'doc-main.txt'
    s.rdoc_options << '--main' << 'doc-main.txt'
    s.test_files << 'tests/runner.rb'

    s.author = "Florian Frank"
    s.email = "flori@ping.de"
    s.homepage = "http://lazylist.rubyforge.org"
    s.rubyforge_project = "lazylist"
  end
