#!/usr/bin/env ruby

require 'pp'
require 'stringio'
require 'strscan'
require 'rubygems'
require 'sqlite'

module Unwind
  class Config

    attr_reader :output_path
    attr_reader :repo_configs
  
    def initialize(output_path, opts={}, &block) 
      @output_path = output_path
      @repo_configs = []
      instance_eval &block if block
    end
  
    def repo(path, &block)
      r = RepoConfig.new(path, &block)
      @repo_configs << r
    end
  
    class RepoConfig
  
      attr_reader :repo_path
      attr_reader :repo_path
      attr_reader :input_config
      attr_reader :output_config
  
      attr_reader :repo
      
    
      def initialize(repo_path, opts={}, &block) 
        @repo_path = repo_path
        @repo = Unwind::Repository.open( @repo_path )
        @next_revision = nil
        instance_eval &block if block
      end
  
      def peek_next_revision
        ensure_next_revision
        @next_revision
      end
  
      def consume_next_revision
        ensure_next_revision
        r = @next_revision
        @next_revision = nil
        r
      end
  
      def ensure_next_revision
        return if @next_revision
        find_next_revision
      end
  
      def find_next_revision
        r = nil
        @next_revision = nil
        while ( r == nil )
          r = @repo.read_revision
          break unless r
          r = apply_input_config(r)
          r = apply_output_config(r) if r
        end
        @next_revision = r 
      end
  
      def apply_input_config(revision)
        apply_excludes(revision, @input_config.excludes)
        apply_rewrites(revision)
      end
  
      def apply_output_config(revision)
        apply_excludes(revision, @output_config.excludes)
      end
  
      def apply_rewrites(revision)
        for node in revision.nodes
          for rewrite in @input_config.rewrites
            p = rewrite.try_match( node.path )
            if ( p )
              node.path = p
              break
            end
          end
        end
        revision
      end
  
      def apply_excludes(revision, excludes)
        return revision if excludes.empty?
        new_nodes = []
        for node in revision.nodes
          excluded = false
          for exclude in excludes 
            if ( ( node.path =~ /^#{exclude}$/) )
              excluded = true
              break
            end
          end 
          if ( ! excluded )
            new_nodes << node
          end
        end
        if ( new_nodes.empty? )
          return nil
        end
        revision.nodes = new_nodes
        revision
      end
  
      def input(&block)
        @input_config = InputConfig.new(&block)
      end
    
      def output(&block)
        @output_config = OutputConfig.new(&block)
      end
  
      class InputConfig
        attr_reader :excludes
        attr_reader :rewrites
  
        def initialize(&block)
          @excludes = []
          @rewrites = []
          instance_eval &block if block
        end
        def rewrite(input_pattern, output_pattern)
          r = Rewrite.new( input_pattern, output_pattern)
          @rewrites << r
        end
        def exclude(input_pattern)
          @excludes << input_pattern
        end
  
        class Rewrite
          SEGMENT = /:[a-zA-Z][a-zA-Z0-9_]*/
          attr_reader :input_pattern
          attr_reader :output_pattern
  
          attr_reader :input_regexp
  
          def initialize(input_pattern, output_pattern)
            @input_pattern  = input_pattern
            @output_pattern = output_pattern
            create_input_regexp
          end
  
          def create_input_regexp
            @input_replacements = {}
            scanner = StringScanner.new( @input_pattern )
            regexp_str = ''
            i = 0
            while ( ( m = scanner.scan_until( SEGMENT ) ) != nil )
              i += 1
              regexp_str += scanner.pre_match
              regexp_str += '([^/]+)'
              @input_replacements[ scanner.matched ] = i
              scanner = StringScanner.new( scanner.post_match )
            end
            if ( scanner.post_match )
              ( regexp_str += scanner.post_match ) 
            elsif ( i == 0 )
              regexp_str = @input_pattern
            end
            @input_regexp = /^#{regexp_str}/
            #pp @input_regexp
            #pp @input_replacements
            @input_regexp
          end
  
          def try_match(path)
            if ( m = ( @input_regexp.match( path ) ) )
              replacement = output_pattern
              @input_replacements.each do |key,index|
                replacement.gsub!( key, m[index] )  
              end
              path.gsub( m[0], replacement )
            else
              nil
            end
          end
  
        end
      end
  
      class OutputConfig
        attr_reader :excludes
        def initialize(&block)
          @excludes = []
          instance_eval &block if block
        end
        def exclude(output_pattern)
          @excludes << output_pattern
        end
      end
    
    end
  end
end
