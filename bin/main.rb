module Unwind

  def self.main(config_path)
    $logfile = File.open( "merge.log", 'w' )
    config_script = File.read( config_path )
    config = eval config_script


    repos = config.source_configs.collect{|s| Repository.open( s.repo_path )}

    loader = Unwind::DumpLoader.new(repos)

    pipeline = PipelineBuilder.build( config, loader.db, loader.repositories )

    #pp pipeline

    #return -1


    begin
      loader.load
      writer = Unwind::DumpWriter.new( pipeline )
      writer.write
    rescue Exception => e 
      $stderr.puts "load cancelled"
      $stderr.puts e.message
      $stderr.puts e.backtrace
    ensure
      loader.close
    end

    #source = DbRevisionSource.new( loader.db, loader.repositories )
    #source = DumpFilter.new( source )
#
#    source = PathRewritingFilter.new( source )
#    source.rewrite( 'trunk/:module', ':module/trunk' )
#    source.rewrite( 'trunk', 'mobicents/trunk', true )
#    source.rewrite( 'tags/:tag/mobicents', 'mobicents/tags/:tag' )
#    source.rewrite( 'tags/:tag', 'mobicents/tags/:tag' )
#    source.rewrite( 'branches/:user/:module', ':module/branches/:user' )
#    source.rewrite( 'branches/:user', 'mobicents/branches/:user' )
#
#    source = ParentNodeCreator.new( loader.db, source )
#
#    source = DumpFilter.new( source )
#    source.exclude( /^trunk/ )
#    source.exclude( /^branches/ )
#    source.exclude( /^tags/ )
#    source.include( /.*/ )
#
#
#    #source.each do |s|
#      #
#    #end
  end
end

$logfile = nil
