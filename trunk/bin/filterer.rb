
module Unwind

  class Filterer

    include Enumerable

    def initialize(backing)
      @backing = backing
      @filters = {}
      @default_filter = nil
    end

    def set_filter(repo_path, filter)
      @filters[repo_path] = filter
    end

    def set_default_filter(filter)
      @default_filter = filter
    end

    def repositories
      @backing.repositories
    end

    def each
      @backing.each do |revision|
        r = apply_filter( revision )
        yield revision if r
      end  
    end

    def apply_filter(revision)
      filter = @filters[ revision.repo.path ] || @default_filter
      return revision unless filter
      filter.filter( revision )
    end

  end
end
