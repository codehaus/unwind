require 'md5'

module Unwind
  class DumpWriter

    attr_reader :out

    def initialize(revision_source,output_path)
      @revision_source = revision_source
      if ( output_path )
        @out = File.open( output_path, 'w' )
      else
        @out = $stdout
      end
      @revision_map = {}
    end
  
    def write
      @global_rev = 1
      write_prolog
      @revision_source.each do |revision|
        write_revision( revision )
      end
    end 
  
    def write_prolog
      out.puts "SVN-fs-dump-format-version: 2"
      out.puts ""
      out.puts "UUID: #{uuid}"
      out.puts ""
    end

    def uuid
      md5 = MD5.hexdigest( Time.now.to_s )
      "#{md5[0,8]}-#{md5[8,4]}-#{md5[12,4]}-#{md5[16,4]}-#{md5[20,12]}"
    end

    def write_zero_revision(first_revision)
      zero_ts = (first_revision.date - 1).xmlschema(6)
      out.puts "Revision-number: 0"
      out.puts "Prop-content-length: 56"
      out.puts "Content-length: 56"
      out.puts ""
      out.puts "K 8"
      out.puts "svn:date"
      out.puts "V 27"
      out.puts "#{zero_ts}"
      out.puts "PROPS-END"
      out.puts ""
    end
  
    def write_revision(revision)
      revision_number = @global_rev
      if ( revision_number == 1 )
        write_zero_revision(revision)
      end
      $logfile.puts "dump revision: #{revision_number}"
      @revision_map[ [ revision.repo.id, revision.revision_number ] ]  = revision_number
      @global_rev += 1
  
      $stderr.puts "Write revision: #{revision_number}"
      out.puts "Revision-number: #{revision_number}"
      out.puts "Prop-content-length: #{revision.props.text.length}"
      out.puts "Content-length: #{revision.props.text.length}"
      out.puts ""
      out.puts revision.props.text
      out.puts ""
      for node in revision.nodes do
        out.puts "Node-path: #{node.path}\n"
        out.puts "Node-kind: #{node.kind}\n" if node.kind
        out.puts "Node-action: #{node.action}\n"
        if ( node.props )
          out.puts "Prop-content-length: #{node.props.text.length}"
        end
        if ( node.action != 'delete' ) 
          if ( node.text_content_length ) 
            out.puts "Text-content-length: #{node.text_content_length}\n"
            out.puts "Text-content-md5: #{node.text_content_md5}\n"
          end
          out.puts "Content-length: #{node.content_length}\n"
        end
        if ( node.copyfrom_rev )
          real_copyfrom_rev = @revision_map[ [ revision.repo.id, node.copyfrom_rev ] ]
          out.puts "Node-copyfrom-rev: #{real_copyfrom_rev}\n"
          out.puts "Node-copyfrom-path: #{node.copyfrom_path}\n"
        end
        out.puts ""
        if ( node.props )
          out.puts node.props.text
        end
        if ( node.text_content_length ) 
          out.puts node.text_content
        end
        out.puts ""
        out.puts ""
        out.flush
      end
      out.flush
    end
  
  end
end
