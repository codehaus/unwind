
module Unwind
  class PathTracker
    def initialize(db)
      @db = db
      @db.execute "CREATE TABLE 
                     dir_paths ( 
                       ts            INTEGER,
                       path          TEXT,
                       action        TEXT
                     );"
      @func = 0
    end

    def each_path()
    end

    def add_path(path, as_of)
      #$stderr.puts "add_path(#{path})"
      db_execute( "
        INSERT INTO dir_paths (
          ts,
          path,
          action 
        ) 
        VALUES ( 
          #{as_of.to_i},
          '#{path}',
          'add'
        ) ;")
      #$stderr.puts "add_path(#{path}) => #{has_path(path, as_of)}"
      #$stdin.getc
    end

    def delete_path(path, as_of=Time.now)
      #$stderr.puts "delete_path(#{path})"

      #db_execute( debug_path_sql( path ), true )
      db_execute( "
        INSERT INTO dir_paths ( 
          ts,
          path,
          action 
        ) 
        #{generic_path_sql( "#{as_of.to_i}, path, 'del'", path, as_of, true )}
      ;", true )
      #db_execute( debug_path_sql( path ), true )
      #$stderr.puts "delete_path(#{path}) => #{has_path(path, as_of)}"
      #$stdin.getc
    end
    
    def copy_path(path, as_of, copyfrom_path, copyfrom_as_of)
      #$stderr.puts "copy_path(#{path}, #{as_of} FROM #{copyfrom_path}, #{copyfrom_as_of})"
             #'#{path}' || substr( path, #{copyfrom_path.length + 1}, length( path - #{copyfrom_path.length} ) )
            #'rewrite/' || inner_path, 

      #db_execute( 
        #generic_path_sql( 
          #"#{Time.at( as_of ).to_i}, path, length(path), inner_path, length(inner_path), rewrite_path, 'add'",
          #copyfrom_path, 
          #copyfrom_as_of, 
          #true,
          #'add',
          #path
        #), 
      #true )

      #db_execute( debug_path_sql( copyfrom_path ), true )

      db_execute( "
        INSERT INTO dir_paths (
          ts,
          path,
          action
        ) 
        #{generic_path_sql( "
              #{Time.at( as_of ).to_i}, 
              rewrite_path,
              'add'", 
            copyfrom_path, 
            copyfrom_as_of, 
            true,
            'add',
            path )}
      ;", true )

      #$stderr.puts( "SELECT and replace [#{copyfrom_path}](#{copyfrom_path.length}) with [#{path}](#{path.length})" )
      #rows = db_execute( 
        #generic_path_sql( "#{Time.at( as_of ).to_i}, path, rewrite_path, 'add'", 
          #copyfrom_path, 
          #copyfrom_as_of, 
          #true,
          #'add',
          #path ), true ) 
      #for row in rows do
        #PP::pp row, $stderr
        #db_execute( "
          #INSERT INTO dir_paths ( ts, path, action )
          #VALUES( #{as_of.to_i}, '#{row['rewrite_path']}', 'add' );
        #;", true )
      #end

      #db_execute( generic_path_sql( "ts, 'rewrite/' || path, 'add'", path, as_of ), true )
      db_execute( debug_path_sql( path ), true )
    end

    def has_path(path, as_of=Time.now)
      #$stderr.puts "has_path(#{path})"
      result = db_execute( "SELECT count(*) FROM ( #{path_exists_sql( path, as_of, false )} )", true )
      if ( result.nil? || result.empty? || result[0][0].nil? || result[0][0] == '0' )
        result = false
      else
        result = true
      end
      #$stderr.puts "has_path(#{path}) => #{result}"
      result 
    end

    def path_sql(path, as_of, include_subpaths)
      generic_path_sql( 'path, ts', path, as_of, include_subpaths )
    end

    def path_exists_sql(path, as_of, include_subpaths)
      generic_path_sql( 'path', path, as_of, include_subpaths )
    end

    def generic_path_sql(selection, path, as_of, include_subpaths, action='add', replace_prefix=nil)
      subpath_clause = ''
      ( subpath_clause = "OR path LIKE '#{path}/%'" ) if include_subpaths
      action_clause = ''
      action_clause = "WHERE dir_paths.action='#{action}'" if action
      replace_clause = ''
      ( replace_clause = ", ( '#{replace_prefix}' || substr( path, #{path.length + 1}, length( path ) - #{path.length} )  ) as rewrite_path" ) if replace_prefix
      "
      SELECT 
        #{selection}
      FROM 
        dir_paths
      JOIN (
        SELECT
          max(ts) as inner_ts,
          path    as inner_path
          #{replace_clause}
        FROM
          dir_paths
        WHERE
          ts <= #{as_of.to_i}
          AND ( 
            path = '#{path}'
            #{subpath_clause}
          )
        GROUP BY
          inner_path
       ) ON ( path = inner_path AND ts = inner_ts )
       WHERE
         dir_paths.action = '#{action}'
      "
    end

    def debug_path_sql(path)
      "
        SELECT * FROM dir_paths WHERE path = '#{path}' OR path LIKE '#{path}/%'
      "
    end

    def db_execute(sql, debug=false)
      if ( false && debug )
        $stderr.puts ""
        $stderr.puts "#### DEBUG #### DEBUG #### DEBUG #### DEBUG #####"
        $stderr.puts sql
        $stderr.puts "#### RESULTS #### RESULTS #### RESULTS #### RESULTS #####"
        $stderr.flush
      end
      results = []
      @db.execute( sql ) do |row|
        if ( false && debug ) 
          #PP::pp row, $stderr 
          $stderr.puts row.inspect
        end
        results << row
        yield row if block_given?
      end
      if ( false && debug )
        $stderr.puts "#### END #### END #### END #### END #####"
        $stderr.flush
      end
      #$stderr.puts "#{@db.changes} changes"
      results
    end

  end


end
