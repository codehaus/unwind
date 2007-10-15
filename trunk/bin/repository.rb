module Unwind
  class Repository
    attr_reader :id
    attr_reader :path
    attr_reader :uuid
  
    @repo_counter = 0
  
    def self.next_repo_sequence
      s = @repo_counter
      @repo_counter += 1
      s  
    end
  
    def self.open(path)
      repo = Repository.new( path )
      repo.open
      repo
    end
  
    def initialize(path)
      @path = path
      @id = Repository.next_repo_sequence
    end
  
    def open
      @in = File.open( path, 'r' )
      read_header
    end
  
    def read_header
      version_line = @in.readline
      if ( ! version_line =~ /SVN-fs-dump-format-version: 2/ )
        throw "SVN dump format must be version 2"
      end
      @in.readline
      uuid_line = @in.readline
      if ( uuid_line =~ /UUID: (.*)$/ )
        @uuid = $1
      else
        throw "Invalid or missing UUID"
      end
      @in.readline
    end

    def each 
      while ( ( revision = read_revision ) != nil )
        yield revision if block_given?
      end
    end
  
    def revisions
      while ( ( revision = read_revision ) != nil )
        yield revision if block_given?
      end
    end
  
    def read_revision
      return nil if @in.eof?
      pos = @in.pos
      revision_line            = @in.readline
      if ( revision_line =~ /Revision-number: ([0-9]+)$/ )
        revision_number = $1
      else
        throw "Invalid revision number: #{revision_line}"
      end
      prop_content_length_line = @in.readline
      content_length_line      = @in.readline
      @in.readline
      if ( ! ( prop_content_length_line =~ /Prop-content-length: ([0-9]+)/ ) )
        throw "Invalid prop content length"
      end
      prop_content_length = $1.to_i
      props = Unwind.read_props( @in, prop_content_length )
      @in.readline
      if ( ! ( content_length_line =~ /Content-length: ([0-9]+)/ ) ) 
        throw "Invalid content-length" 
      end
      content_length = $1.to_i
      payload_length = content_length - prop_content_length 
      revision = Revision.new( self, 
                               @in, 
                               pos,
                               revision_number, 
                               props )
      revision
    end

    def read_revision_at(pos)
      orig_pos = @in.pos
      @in.pos = pos
      r = read_revision
      @in.pos = orig_pos
      r
    end
  end
end
