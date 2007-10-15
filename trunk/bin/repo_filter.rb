
module Unwind

  class RepoFilter

    include Enumerable

    def initialize(backing)
      @backing = backing
      @filters = {}
    end

    def set_repo_filter(repo, filter)
      @filters[repo.id] = filter
    end

    def each
      @backing.each do |revision|
        filter = @filters[revision.repo.id]
        if ( filter )
          r = apply_repo_filter( revision )
          yield revision if r
        else
          yield revision
        end
      end  
    end

    def apply_repo_filter(revision)
      r = revision
    
      r 
    end

  end
end
