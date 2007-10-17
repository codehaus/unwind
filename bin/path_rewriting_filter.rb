
module Unwind

  class PathRewritingFilter

    include Enumerable

    def initialize()
      @rules = []
    end
        
    def rewrite(input_pattern, output_pattern, copyfrom_only=false)
      @rules << RewriteRule.new(input_pattern, output_pattern, copyfrom_only)
    end

    def <<(rule)
      @rules << rule
    end

    
    def filter(revision)
      for node in revision.nodes
        filter_node( node )
      end
      revision
    end

    def filter_node(node)
      for rule in @rules
        if ( ! rule.copyfrom_only )
          if ( ( p = rule.try_match( node.path ) ) != nil )
            #$logfile.puts "path rewrite #{node.path} to #{p}"
            node.path = p
            break
          end
        end
      end 
      if ( node.copyfrom_path )
        #$logfile.puts "copyfrom path: #{node.copyfrom_path}"
        for rule in @rules
          #$logfile.puts "  copyfrom test #{rule.input_pattern}"
          if ( ( p = rule.try_match( node.copyfrom_path ) ) != nil )
            #$logfile.puts "copyfrom rewrite #{node.copyfrom_path} to #{p}"
            node.copyfrom_path = p
            break
          end
        end
      end
    end


    class RewriteRule
      SEGMENT = /:[a-zA-Z][a-zA-Z0-9_]*/
      attr_reader :input_pattern
      attr_reader :output_pattern
      attr_reader :copyfrom_only

      attr_reader :input_regexp

      def initialize(input_pattern, output_pattern, copyfrom_only=false)
        @input_pattern  = input_pattern
        @output_pattern = output_pattern
        @copyfrom_only  = copyfrom_only
        create_input_regexp
      end

      def create_input_regexp
        @input_replacements = {}
        scanner = StringScanner.new( @input_pattern )
        regexp_str = ''
        i = 0
        remainder = ''
        while ( ( m = scanner.scan_until( SEGMENT ) ) != nil )
          i += 1
          regexp_str += scanner.pre_match
          regexp_str += '([^/]+)'
          @input_replacements[ scanner.matched ] = i
          remainder = scanner.post_match
          scanner = StringScanner.new( scanner.post_match )
        end
        if ( m != nil )
          ( regexp_str += scanner.post_match ) 
        elsif ( remainder && remainder != '' )
          ( regexp_str += remainder )
        elsif ( i == 0 )
          regexp_str = @input_pattern
        end
        @input_regexp = /^#{regexp_str}/
        @input_regexp
      end

      def try_match(path)
        if ( m = ( @input_regexp.match( path ) ) )
          replacement = @output_pattern.dup
          #$logfile.puts "#{path} matched against #{@input_regexp} #{@input_pattern} begin replacement with #{@output_pattern}:"
          #PP::pp( self, $logfile )
          @input_replacements.each do |key,index|
            #$logfile.puts "    replace within #{replacement}"
            replacement.gsub!( key, m[index] )  
            #$logfile.puts "    replace #{key} with m[#{index}] (#{m[index]}) -> #{replacement}"
          end
          #path.gsub( m[0], replacement )
          new_path = replacement + path[m[0].length .. -1]
          #$logfile.puts "#{path} matched against #{@input_regexp} #{@input_pattern} replaces to #{new_path}"
          new_path
        else
          nil
        end
      end

    end
  end
end
