
module Unwind

  class ParentNodeCreator
    include Enumerable
   
    def initialize(db, backing)
      @db = db
      @backing = backing
      @db.execute "CREATE TABLE 
                     paths ( 
                       path STRING );"
    end

    def add_dir(path)
      return if has_dir(path)
      $logfile.puts "add dir #{path}"
      @db.execute "INSERT INTO paths (path) VALUES ( '#{path}' );"
    end

    def delete_dir(path)
      $logfile.puts "delete dir #{path}"
      @db.execute "DELETE FROM paths WHERE path = '#{path}' OR path LIKE '#{path}/%';"
    end

    def copy_dir(from_path, to_path)
      $logfile.puts "copydir #{to_path} from #{from_path}"
      paths = @db.execute "SELECT path FROM paths WHERE path LIKE '#{from_path}%';" 
      paths.each do |path|
        new_path = path['path'].sub( /^#{from_path}/, to_path )
        @db.execute "INSERT INTO paths ( path ) VALUES ( '#{new_path}' );"
        $logfile.puts "copydir:add #{new_path} from #{path['path']}"
      end
    end

    def has_dir(path)
      result = @db.execute "SELECT path FROM paths WHERE path = '#{path}';"
      #$logfile.puts "exists #{!result.empty?} #{path}"
      ! result.empty?
    end


    def each
      @backing.each do |revision|
        $logfile.puts "Revision: #{revision.repo.path} #{revision.revision_number}"
        #$logfile.puts revision.inspect
        #PP::pp( revision.inspect, $logfile )
        @db.execute( "BEGIN TRANSACTION;" );
        inject_parent_nodes(revision)
        #$stderr.puts "COMMIT"
        @db.execute( "COMMIT;" );
        yield revision
      end
    end

    def inject_parent_nodes(revision)
      #return revision
      new_nodes = []
      revision.nodes.each_with_index do |node,i|
        $logfile.puts "node: #{node.action} #{node.path} #{node.copyfrom_path}"
        skip_add = false
        add_nodes = []
        if ( node.action == 'replace' && node.kind == 'dir' )
          delete_dir( node.path )
          add_dir( node.path )
        elsif ( node.action == 'add' && ( node.kind == 'dir' || node.copyfrom_path != nil ) )
          $logfile.puts "#{node.path} copyfrom: #{node.copyfrom_path}"
          if ( node.copyfrom_path )
            copy_dir( node.copyfrom_path, node.path )
          else
            if ( has_dir( node.path ) )
              skip_add = true
            else
              add_dir( node.path )
            end
          end
        elsif ( node.action == 'delete' )
            delete_dir( node.path )
        end
        if ( node.action == 'delete' ) 
          delete_dir( node.path )
        end
        cur = File.dirname( node.path )
        while ( cur != '.' && ! has_dir( cur ) )
          $logfile.puts "inject parent #{cur} for #{node.path}"
          add_nodes.unshift( Node.new( revision.in_stream, { 'Node-path'=>cur, 'Node-kind'=>'dir', 'Node-action'=>'add' }, nil ) )
          add_dir( cur )
          cur = File.dirname( node.path )
        end
        
        #if ( i == 0 || add_others )
        new_nodes << add_nodes
        #end
        if ( skip_add )
          $logfile.puts "skipping #{node.path}"
        else
          new_nodes << node 
        end
      end
      revision.nodes = new_nodes.flatten
    end
  end
end
