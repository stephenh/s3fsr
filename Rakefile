require 'rubygems'
require 'rake'
require 'rake/packagetask'
require 'rake/gempackagetask'

namespace :dist do
  spec = Gem::Specification.new do |s|
    s.name              = 's3fsr'
    s.version           = '1.0'
    s.summary           = "FUSE File System for Amazon S3"
    s.description       = s.summary
    s.email             = 'stephen@exigencecorp.com.com'
    s.author            = 'Stephen Haberman'
    s.has_rdoc          = false
    s.homepage          = 'http://github.com/stephenh/s3fsr'
    s.files             = FileList['Rakefile', 'lib/**/*.rb', 'bin/*']
    s.executables       << 's3fsr'
  end

  task :package
  Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar_gz = true
    pkg.package_files.include('{lib,bin}/**/*')
    pkg.package_files.include('Rakefile')
  end
end


