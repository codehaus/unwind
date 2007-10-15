module Unwind
  class DumpLoader
  
    attr_reader :db
    attr_reader :repositories
    include Enumerable
  
    def initialize(repos=[])
      @repos = repos
      @repositories = {}
      @db = SQLite::Database.new( "svnmerge.db", 0644 )
      @db.results_as_hash = true
      @db.execute "CREATE TABLE 
                     repos ( 
                       id INTEGER, 
                       path STRING );"
      @db.execute "CREATE TABLE 
                     revisions ( 
                       repo INTEGER, 
                       rev INTEGER, 
                       pos INTEGER, 
                       ts INTEGER );"
      @db.execute "CREATE TABLE
                     nodes (
                       repo INTEGER,
                       rev INTEGER,
                       path STRING );"
    end
  
    def each()
      @db.execute "SELECT repo, rev, pos, ts FROM revisions ORDER BY ts ASC, rev ASC" do |revision|
        yield revision
      end
    end
  
    def load()
      for repo in @repos
        load_repo( repo )
        $stderr.puts "load #{repo.path}"
        repo.each do |revision|
          load_revision( revision )
        end
      end
    end

    def load_repo(repository)
      @db.execute "BEGIN TRANSACTION;"
      @db.execute "INSERT INTO
                     repos (
                       id,
                       path
                     ) VALUES (
                       #{repository.id},
                       '#{repository.path}'
                     );"
      @repositories[repository.id] = repository
      @db.execute "COMMIT;"
    end
  
    def load_revision(revision)
      $stderr.puts "#{revision.repo.path} #{revision.revision_number} #{revision.date.to_i}"
      @db.execute "BEGIN TRANSACTION;"
      @db.execute "INSERT INTO
                     revisions ( 
                       repo, 
                       rev, 
                       pos,
                       ts
                     ) VALUES ( 
                       #{revision.repo.id},  
                       #{revision.revision_number}, 
                       #{revision.pos}, 
                       #{revision.date.to_i}
                     )"
      revision.nodes.each do |node|
        @db.execute "INSERT INTO
                       nodes (
                         repo,
                         rev,
                         path
                       ) VALUES (
                         #{revision.repo.id},
                         #{revision.revision_number},
                         '#{node.path}'
                       )"
      end
      @db.execute "COMMIT;"
    end
  
    def close
      @db.close if @db
      @db = nil
    end
  
  end
end
