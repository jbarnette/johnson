--- !ruby/object:Gem::Specification 
name: johnson
version: !ruby/object:Gem::Version 
  hash: 31
  segments: 
  - 1
  - 2
  - 0
  version: 1.2.0
platform: ruby
authors: 
- John Barnette
- Aaron Patterson
- Yehuda Katz
- Matthew Draper
autorequire: 
bindir: bin
cert_chain: []

date: !timestamp 
  at: "2010-01-25 09:00:00 +01:00"
  "@marshal_with_utc_coercion": false
default_executable: 
dependencies: 
- !ruby/object:Gem::Dependency 
  name: gemcutter
  requirement: &id001 !ruby/object:Gem::Requirement 
    requirements: 
    - - ">="
      - !ruby/object:Gem::Version 
        hash: 21
        segments: 
        - 0
        - 2
        - 1
        version: 0.2.1
  type: :development
  version_requirement: 
  version_requirements: *id001
- !ruby/object:Gem::Dependency 
  name: rake-compiler
  requirement: &id002 !ruby/object:Gem::Requirement 
    requirements: 
    - - ~>
      - !ruby/object:Gem::Version 
        hash: 7
        segments: 
        - 0
        - 6
        version: "0.6"
  type: :development
  version_requirement: 
  version_requirements: *id002
- !ruby/object:Gem::Dependency 
  name: hoe
  requirement: &id003 !ruby/object:Gem::Requirement 
    requirements: 
    - - ">="
      - !ruby/object:Gem::Version 
        hash: 27
        segments: 
        - 2
        - 5
        - 0
        version: 2.5.0
  type: :development
  version_requirement: 
  version_requirements: *id003
description: |-
  Johnson wraps JavaScript in a loving Ruby embrace. It embeds the
  Mozilla SpiderMonkey JavaScript runtime as a C extension.
email: 
- jbarnette@rubyforge.org
- aaron.patterson@gmail.com
- wycats@gmail.com
- matthew@trebex.net
executables: []

extensions: []

extra_rdoc_files: []

files: []

has_rdoc: true
homepage: http://github.com/jbarnette/johnson
licenses: []

post_install_message: 
rdoc_options: []

require_paths: 
- lib
required_ruby_version: !ruby/object:Gem::Requirement 
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      hash: 3
      segments: 
      - 0
      version: "0"
required_rubygems_version: !ruby/object:Gem::Requirement 
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      hash: 3
      segments: 
      - 0
      version: "0"
requirements: []

rubyforge_project: johnson
rubygems_version: 1.3.7
signing_key: 
specification_version: 3
summary: Johnson wraps JavaScript in a loving Ruby embrace
test_files: []



