module Unwind
  class Revision
    attr_reader :repo
    attr_reader :pos
  
    attr_reader :revision_number
    attr_reader :props
  
    attr_accessor :nodes
    attr_accessor :date

    def initialize(repo,
                   in_stream, 
                   pos,
                   revision_number, 
                   props)
      @repo            = repo
      @in              = in_stream
      @pos             = pos
      @revision_number = revision_number
      @props           = props
      @date = Time.parse( props['svn:date'] )
  
      @nodes = []
      read_nodes
    end
  
    def in_stream
      @in
    end
  
    def read_nodes
      while ( ( node = read_node ) != nil )
        @nodes << node
      end
    end
  
    def read_node
      return nil if @in.eof?
      pos = @in.pos
      next_line = @in.readline
      if ( ! ( next_line =~ /Node-path: (.*)$/ ) ) 
        @in.seek( pos )
        return nil
      end
      node_header_lines = [ next_line.chomp ]
      while ( ( line = @in.readline.chomp ) != '' )
        node_header_lines << line
      end
      node_headers = {}
      node_header_lines.each do |line|
        key, value = line.split(':')
        node_headers[key.strip] = value.strip
      end
      #pp node_headers
      skip_double = false
      if ( node_headers['Prop-content-length'] )
        props = Unwind.read_props( @in, node_headers[ 'Prop-content-length' ].to_i )
      end
  
      if ( node_headers['Text-content-length'] )
        node_headers['Text-content-position'] = @in.pos
        @in.seek( @in.pos + node_headers[ 'Text-content-length' ].to_i )
      end
 
      while ( ! @in.eof? )
        pos = @in.pos
        if ( @in.readline.chomp != '' )
          @in.seek( pos )
          break
        end
      end
      Node.new( self, @in, node_headers, props )
    end
  end
end
