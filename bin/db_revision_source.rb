module Unwind
  class DbRevisionSource
  
    attr_reader :repositories
    include Enumerable
  
    def initialize(db,repositories)
      @repositories = repositories
      @db = db
    end
  
    def each()
      each_db_row do |row|
        revision = @repositories[row['repo'].to_i].read_revision_at( row['pos'].to_i )  
        yield revision
      end
    end

    def each_db_row()
      @db.execute "SELECT repo, rev, pos, ts FROM revisions ORDER BY ts ASC, rev ASC" do |revision|
        yield revision
      end
    end
  
  end
end
