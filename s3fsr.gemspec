
Gem::Specification.new do |s|
  s.name              = 's3fsr'
  s.version           = '1.4'
  s.summary           = "FUSE File System for Amazon S3"
  s.description       = s.summary
  s.email             = 'stephen@exigencecorp.com'
  s.author            = 'Stephen Haberman'
  s.has_rdoc          = false
  s.homepage          = 'http://github.com/stephenh/s3fsr'
  s.files             = ["lib/s3fsr.rb", "lib/aws-matt/s3.rb", "lib/aws-matt/s3/error.rb", "lib/aws-matt/s3/base.rb", "lib/aws-matt/s3/service.rb", "lib/aws-matt/s3/object.rb", "lib/aws-matt/s3/logging.rb", "lib/aws-matt/s3/bittorrent.rb", "lib/aws-matt/s3/version.rb", "lib/aws-matt/s3/exceptions.rb", "lib/aws-matt/s3/extensions.rb", "lib/aws-matt/s3/owner.rb", "lib/aws-matt/s3/parsing.rb", "lib/aws-matt/s3/acl.rb", "lib/aws-matt/s3/authentication.rb", "lib/aws-matt/s3/bucket.rb", "lib/aws-matt/s3/response.rb", "lib/aws-matt/s3/connection.rb"]
  s.executables       << 's3fsr'
end

