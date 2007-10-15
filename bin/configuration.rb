
#!/usr/bin/env ruby

require 'pp'
require 'stringio'
require 'strscan'
require 'rubygems'
require 'sqlite'

module Unwind
  class Configuration

    attr_reader :output_path
    attr_reader :source_configs
    attr_reader :output_config
  
    def initialize(output_path, opts={}, &block) 
      @source_configs = []
      @output_config = OutputConfig.new( output_path )
      begin
        instance_eval &block if block
      rescue Exception => e
        $stderr.puts "Configuration error:"
        $stderr.puts e.message
        $stderr.puts e.backtrace
      end
    end
  
    def source(path, &block)
      @source_configs << SourceConfig.new(path, &block)
    end

    def output(&block)
      @output_config.configure( &block )
    end
  
    class SourceConfig
  
      attr_reader :repo_path
      attr_reader :rules
      attr_reader :rewrites
    
      def initialize(repo_path, opts={}, &block) 
        @repo_path = repo_path
        @rules = []
        @rewrites = []
        instance_eval &block if block
      end

      def configure(&block)
        instance_eval &block if block
      end
  
      def rewrite(input_pattern, output_pattern, copyfrom_only=false)
        @rewrites << PathRewritingFilter::RewriteRule.new( input_pattern, output_pattern, copyfrom_only )
      end

      def include(regexp)
        @rules << PathFilter::IncludeRule.new( regexp )
      end

      def exclude(regexp)
        @rules << PathFilter::ExcludeRule.new( regexp )
      end
    end
  
    class OutputConfig
      attr_reader :rules
      attr_reader :output_path
      def initialize(output_path, &block)
        @output_path = output_path
        @rules = []
        instance_eval &block if block
      end

      def configure(&block)
        instance_eval &block if block
      end

      def include(regexp)
        @rules << PathFilter::IncludeRule.new( regexp )
      end

      def exclude(regexp)
        @rules << PathFilter::ExcludeRule.new( regexp )
      end
    end
    
  end
end
