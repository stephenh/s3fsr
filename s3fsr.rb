#!/usr/bin/env ruby

require 'fusefs'
require 'aws/s3'

if ARGV.length == 1 then
  BUCKET = nil ; MOUNT = ARGV[0]
elsif ARGV.length == 2 then
  BUCKET = ARGV[0] ; MOUNT = ARGV[1]
else
  puts "Usage: [bucket_name] directory_to_mount"
  exit 1
end
if ENV['AWS_ACCESS_KEY_ID'] == nil or ENV['AWS_SECRET_ACCESS_KEY'] == nil
  puts "Both AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables must be set"
  exit 1
end


S3ORGANIZER_DIR_SUFFIX = '_$folder$'
S3SYNC_DIR_CONTENTS = '{E40327BF-517A-46e8-A6C3-AF51BC263F59}'
S3SYNC_DIR_ETAG = 'd66759af42f282e1ba19144df2d405d0'
S3SYNC_DIR_LENGTH = 38
AWS::S3::Base.establish_connection!(:access_key_id => ENV['AWS_ACCESS_KEY_ID'], :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'])

class SFile
  def initialize(parent, s3obj)
    @parent = parent
    @s3obj = s3obj
  end
  def name
    @s3obj.key.split('/')[-1]
  end
  def is_directory?
    false
  end
  def is_file?
    true
  end
  def value
    @s3obj.value(:reload)
  end
  def write data
    AWS::S3::S3Object.store @s3obj.key, data, @s3obj.bucket.name, @s3obj.about.to_headers
  end
  def delete
    AWS::S3::S3Object.delete @s3obj.key, @s3obj.bucket.name
    @parent.content_deleted name
  end
  def size
    @s3obj.content_length
  end
  def touch
  end
end

class SBaseDir
  def is_directory?
    true
  end
  def is_file?
    false
  end
  def can_write_files?
    true
  end
  def content_deleted name
    get_contents.delete_if { |i| i.name == name }
  end
  def create_file child_key, content
    AWS::S3::S3Object.store(child_key, content, bucket)
    get_contents << SFile.new(self, AWS::S3::S3Object.find(child_key, bucket))
  end
  def create_dir child_key
    AWS::S3::S3Object.store(child_key, S3SYNC_DIR_CONTENTS, bucket)
    get_contents << SFakeDir.new(self, child_key)
  end
  def delete
    AWS::S3::S3Object.delete @key, bucket
    @parent.content_deleted name
  end
  def contents
    get_contents.collect { |i| i.name }
  end
  def get(name)
    get_contents.find { |i| i.name == name }
  end
  def size
    0
  end
  def touch
    @data = nil
  end
  private
    def get_contents
      return @data if @data != nil
      puts "Loading '#{name}' from #{bucket}..."
      @data = []
      s3_bucket = AWS::S3::Bucket.find(bucket, :prefix => prefix, :delimiter => '/')
      s3_bucket.object_cache.each do |s3_obj|
        # Technically we should use S3SYNC_DIR_LENGTH but aws-s3 decides it
        # needs to issue an HEAD request for every dir for that.
        if s3_obj.etag == S3SYNC_DIR_ETAG or s3_obj.key.end_with? S3ORGANIZER_DIR_SUFFIX
          @data << SFakeDir.new(self, s3_obj.key)
        else
          @data << SFile.new(self, s3_obj)
        end
      end
      s3_bucket.common_prefix_cache.each do |prefix|
        hidden = SFakeDir.new(self, prefix[0..-2])
        @data << hidden unless @data.find { |i| i.name == hidden.name }
      end
      puts "done"
      @data
    end
end

class SFakeDir < SBaseDir
  def initialize(parent, key)
    @parent = parent
    @key = key
    @data = nil
  end
  def name
    strip_dir_suffix @key.split('/')[-1]
  end
  def bucket
    @parent.bucket
  end
  private
    def prefix
      strip_dir_suffix(@key) + '/'
    end
    def strip_dir_suffix str
      str.end_with?(S3ORGANIZER_DIR_SUFFIX) ? str[0..-10] : str
    end
end

class SBucketDir < SBaseDir
  def initialize(parent, bucket_name)
    @parent = parent # either SBucketsDir or nil
    @bucket_name = bucket_name
  end
  def delete
    raise "cannot delete bucket dir #{name}" if @parent == nil
    AWS::S3::Bucket.delete name
    @parent.content_deleted name
  end
  def bucket
    @bucket_name
  end
  def name
    @bucket_name
  end
  def path_to_key child_key
    child_key
  end
  private
    def prefix
      ""
    end
end

class SBucketsDir < SBaseDir
  def initialize
    @data = nil
  end
  def can_write_files?
    false
  end
  def create_file child_key, content
    raise 'cannot create news outside of a bucket'
  end
  def create_dir child_key
    AWS::S3::Bucket.create(child_key)
    get_contents << SBucketDir.new(self, child_key)
  end
  def delete
    raise 'cannot delete the buckets dir'
  end
  def name
    return 'buckets'
  end
  def path_to_key child_key
    # if i == -1, this is for creating a bucket
    i = child_key.index('/')
    i != nil ? child_key[i+1..-1] : child_key
  end
  private
    def get_contents
      return @data if @data != nil
      puts "Loading buckets..."
      @data = []
      AWS::S3::Bucket.list(true).each do |s3_bucket|
        @data << SBucketDir.new(self, s3_bucket.name)
      end
      puts "done"
      @data
    end
end

class S3fsr
  def initialize(root)
    @root = root
  end
  def contents(path)
    o = get_object(path)
    o == nil ? "" : o.contents
  end
  def directory?(path)
    o = get_object(path) ; o == nil ? false : o.is_directory?
  end
  def file?(path)
    o = get_object(path) ; o == nil ? false : o.is_file?
  end
  def executable?(path)
    false
  end
  def size(path)
    get_object(path).size
  end
  def read_file(path)
    get_object(path).value
  end
  def can_write?(path)
    o = get_object(path)
    if o != nil
      o.is_file?
    else
      d = get_parent_object(path) ; d == nil ? false : d.can_write_files?
    end
  end
  def write_to(path, data)
    o = get_object(path)
    if o != nil
      o.write data
    else
      d = get_parent_object(path)
      if d != nil
        child_key = @root.path_to_key path[1..-1]
        d.create_file(child_key, data)
      end
    end
  end
  def can_delete?(path)
    o = get_object(path) ; o == nil ? false : o.is_file?
  end
  def delete(path)
    get_object(path).delete
  end
  def can_mkdir?(path)
    return false if get_object(path) != nil
    get_parent_object(path).is_directory?
  end
  def mkdir(path)
    child_key = @root.path_to_key path[1..-1]
    get_parent_object(path).create_dir(child_key)
  end
  def can_rmdir?(path)
    return false if path == '/'
    return false unless get_object(path).is_directory?
    get_object(path).contents.length == 0
  end
  def rmdir(path)
    get_object(path).delete
  end
  def touch(path)
    get_object(path).touch
  end
  private
    def get_parent_object(path)
      # path[1..-1] because '/'.split('/') -> ['']
      get_object('/' + (path[1..-1].split('/')[0..-2].join('/')))
    end
    def get_object(path)
      curr = @root
      # path[1..-1] because '/'.split('/') -> ['']
      path[1..-1].split('/').each do |part|
        curr = curr.get(part)
      end
      curr
    end
end

class MethodLogger
  instance_methods.each { |m| undef_method m unless m =~ /^__/ }
  def initialize(obj)
    @obj = obj
  end
  def method_missing(sym, *args, &block)
    begin
      puts "#{sym}(#{args})" unless sym == :respond_to? or sym == :write_to
      puts "#{sym}(#{args[0].length})" if sym == :write_to
      result = @obj.__send__(sym, *args, &block)
      puts "    #{result}" unless sym == :respond_to? or sym == :read_file
      puts "    #{result.length}" if sym == :read_file
      result
    rescue => e
      puts "    #{e.inspect}"
      puts "    #{e.backtrace}"
      raise $?
    end
  end
end

root = BUCKET != nil ? SBucketDir.new(nil, BUCKET) : SBucketsDir.new
s3fsr = MethodLogger.new(S3fsr.new(root))
FuseFS.set_root s3fsr
FuseFS.mount_under MOUNT #, "allow_other"
FuseFS.run

