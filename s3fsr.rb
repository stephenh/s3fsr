
require 'fusefs'
require 'aws/s3'

if ARGV.length != 2 then
  puts "Usage: bucketName directoryToMount"
  exit 1
end

BUCKET = ARGV[0]
MOUNT = ARGV[1]

S3ORGANIZER_DIR_SUFFIX = '_$folder$'
S3SYNC_DIR_CONTENTS = '{E40327BF-517A-46e8-A6C3-AF51BC263F59}'
S3SYNC_DIR_ETAG = 'd66759af42f282e1ba19144df2d405d0'
S3SYNC_DIR_LENGTH = 38
AWS::S3::Base.establish_connection!(:access_key_id => ENV['AWS_ACCESS_KEY_ID'], :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'])

class FFile
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
  def write stuff
    AWS::S3::S3Object.store @s3obj.key, stuff, @s3obj.bucket.name, @s3obj.about.to_headers
  end
  def delete
    AWS::S3::S3Object.delete @s3obj.key, @s3obj.bucket.name
    @parent.contentDeleted name
  end
  def size
    @s3obj.content_length
  end
  def touch
  end
end

class DDir
  def initialize(parent, key)
    @parent = parent
    @key = key
    @data = nil
  end
  def is_directory?
    true
  end
  def is_file?
    false
  end
  def contentDeleted name
    get_contents.delete_if { |i| i.name == name }
  end
  def createFile childKey, content
    AWS::S3::S3Object.store(childKey, content, BUCKET)
    get_contents << FFile.new(self, AWS::S3::S3Object.find(childKey, BUCKET))
  end
  def createDir childKey
    AWS::S3::S3Object.store(childKey, S3SYNC_DIR_CONTENTS, BUCKET)
    get_contents << DDir.new(self, childKey)
  end
  def delete
    AWS::S3::S3Object.delete @key, BUCKET
    @parent.contentDeleted name
  end
  def contents
    get_contents.collect { |i| i.name }
  end
  def get(name)
    get_contents.find { |i| i.name == name }
  end
  def name
    return '' if @key == ''
    strip_dollar_folder @key.split('/')[-1]
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
      puts "Loading #{name}..."
      @data = []
      bucket = AWS::S3::Bucket.find(BUCKET, :prefix => prefix, :delimiter => '/')
      bucket.objects.each do |s3obj|
        if (s3obj.content_length == S3SYNC_DIR_LENGTH.to_s and s3obj.etag == S3SYNC_DIR_ETAG) or s3obj.key.end_with? S3ORGANIZER_DIR_SUFFIX
          @data << DDir.new(self, s3obj.key)
        else
          @data << FFile.new(self, s3obj)
        end
      end
      bucket.common_prefixes.each do |prefix|
        hidden = DDir.new(self, prefix[0..-2])
        @data << hidden unless @data.find { |i| i.name == hidden.name }
      end
      puts "done"
      @data
    end
    def prefix
      return '' if @key == ''
      return strip_dollar_folder(@key) + '/'
    end
    def strip_dollar_folder str
      str.end_with?(S3ORGANIZER_DIR_SUFFIX) ? str[0..-10] : str
    end
end

class S3fsr
  def initialize
    @root = DDir.new(nil, '')
  end
  def contents(path)
    o = getObject(path)
    o == nil ? "" : o.contents
  end
  def directory?(path)
    o = getObject(path)
    o == nil ? false : o.is_directory?
  end
  def file?(path)
    o = getObject(path)
    o == nil ? false : o.is_file?
  end
  def executable?(path)
    false
  end
  def size(path)
    getObject(path).size
  end
  def read_file(path)
    getObject(path).value
  end
  def can_write?(path)
    o = getObject(path)
    if o != nil
      o.is_file?
    else
      d = getParentObject(path)
      d == nil ? false : d.is_directory?
    end
  end
  def write_to(path, data)
    o = getObject(path)
    if o != nil
      o.write data
    else
      d = getParentObject(path)
      if d != nil
        d.createFile(path[1..-1], data)
      end
    end
  end
  def can_delete?(path)
    o = getObject(path)
    o == nil ? false : o.is_file?
  end
  def delete(path)
    getObject(path).delete
  end
  def can_mkdir?(path)
    return false if getObject(path) != nil
    return true if getParentObject(path).is_directory?
    false
  end
  def mkdir(path)
    getParentObject(path).createDir(path[1..-1])
  end
  def can_rmdir?(path)
    return false if path == '/'
    return false unless getObject(path).is_directory?
    return true if getObject(path).contents.length == 0
    false
  end
  def rmdir(path)
    getObject(path).delete
  end
  def touch(path)
    getObject(path).touch
  end
  private
    def getParentObject(path)
      # path[1..-1] because '/'.split('/') -> ['']
      getObject('/' + (path[1..-1].split('/')[0..-2].join('/')))
    end
    def getObject(path)
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
      puts "#{sym}(#{args})" unless sym == :respond_to?
      result = @obj.__send__(sym, *args, &block)
      puts "    #{result}" unless sym == :respond_to?
      result
    rescue => e
      puts "    #{e.inspect}"
      puts "    #{e.backtrace}"
      raise $?
    end
  end
end

s3fsr = MethodLogger.new(S3fsr.new)
FuseFS.set_root s3fsr
FuseFS.mount_under MOUNT #, "allow_other"
FuseFS.run

