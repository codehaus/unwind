
module Unwind

  class DumpFilter

    include Enumerable

    def initialize()
      puts "LLLLLL"
      @index   = 0
      @next = nil
      @rules = []
    end

    def include(regexp)
      @rules << IncludeRule.new( regexp )
    end

    def exclude(regexp)
      @rules << ExcludeRule.new( regexp )
    end

    def <<(rule)
      @rules << rule
    end

    def filter_rules(revision)
      included_nodes = []
      if ( @rules.empty? )
        return revision
      end
      for node in revision.nodes
        for rule in @rules
          case (rule)
            when IncludeRule
              included_nodes << node if rule.match?( node.path )
              #$stderr.puts "include: #{node.path}"
              break
            when ExcludeRule
              if rule.match?( node.path )
                #$stderr.puts "exclude: #{node.path}"
                break
              end
          end
        end
      end
      for node in revision.nodes
        if ( node.copyfrom_path )
          okay = false
          if @rules.empty?
            okay = true
          else
            for rule in @rules
              case (rule)
                when IncludeRule
                  if rule.match?(node.copyfrom_path)
                    okay = true
                    break
                  end
                when ExcludeRule
                  if rule.match?(node.copyfrom_path)
                    okay = false
                    break
                  end
              end
            end
          end
          $stderr.puts "Revision #{revision.revision_number}: Error: #{node.path} copyfrom excluded #{node.copyfrom_path}" unless okay
        end
      end
      if ( included_nodes.empty? )
        return nil
      end
      revision.nodes = included_nodes
      revision
    end

    class IncludeRule
      def initialize(regexp)
        @regexp = regexp
      end
      def match?(path)
        @regexp.match( path )
      end
    end

    class ExcludeRule
      def initialize(regexp)
        @regexp = regexp
      end
      def match?(path)
        @regexp.match( path )
      end
    end
    
    
  end

end
