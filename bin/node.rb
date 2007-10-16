module Unwind
  class Node
    attr_accessor :path
    attr_reader :kind
    attr_reader :action
    attr_reader :props
    attr_reader :text_content_length
    attr_reader :text_content_md5
    attr_reader :copyfrom_rev
    attr_accessor :copyfrom_path
  
    def initialize(in_stream, headers, props)
      @in     = in_stream
      @pos    = headers['Text-content-position']
      @path   = headers['Node-path']
      @kind   = headers['Node-kind']
      @action = headers['Node-action']
  
      @props  = props
  
      @text_content_length = headers['Text-content-length']
      @text_content_md5    = headers['Text-content-md5']
  
      @copyfrom_rev  = headers['Node-copyfrom-rev'] 
      @copyfrom_path = sanitize( headers['Node-copyfrom-path'] )
      #$logfile.puts "Node.new( action: #{action}, path:#{@path}, copyfrom: #{@copyfrom_path})"
    end

    def sanitize(path)
      return nil unless path
      new_path = nil
      new_path = path[1,path.length-1] if ( path[0,1] == '/' )
      new_path ||= path
      $logfile.puts "sanitize #{path} to #{new_path}"
      new_path
    end
  
    def in_stream
      @in
    end
  
    def content_length
      len = ( text_content_length ? text_content_length.to_i : 0 ) + ( props ? props.text.length : 0 )
    end
  
    def text_content
      old_pos = @in.pos
      @in.seek( @pos )
      text = @in.read( text_content_length.to_i )
      @in.seek( old_pos )
      text
    end
  end
end
