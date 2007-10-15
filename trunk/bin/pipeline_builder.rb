
module Unwind
  class PipelineBuilder

    attr_reader :pipeline

    def initialize(config, db, repositories)
      @config = config
      @db = db
      @pipeline = nil
      build
    end

    def build
      source = DbRevisionSource.new( @db, @repositories )
      source = Filterer.new( source )

      @config.source_configs.each do |config|
        filter = DumpFilter.new()
        for rule in config.rules do
          filter << rule
        end
        source.set_filter( config.repo_path, filter )
      end

      source = Filterer.new( source )

      @config.source_configs.each do |config|
        filter = PathRewritingFilter.new()
        for rule in config.rules do
          filter << rule
        end
        source.set_filter( config.repo_path, filter )
      end

      source = ParentNodeCreator.new( @db, source )

      source = Filterer.new( source )

      filter = DumpFilter.new()
      for rule in @config.output_config.rules do
        filter << rule
      end
      source.set_default_filter( filter )
 
      @pipeline = source

    end

    def self.build(config, db, repositories)
      PipelineBuilder.new( config, db, repositories ).pipeline
    end

  end
end
