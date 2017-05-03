module ActiveRecordSqlServerAdapter
  module Jdbc
    class Dataset
      include Enumerable

      OPTS = {}.freeze

      def synchronize(&block)
        @cache_mutex.synchronize(&block)
      end

      # The database related to this dataset. This is the Database instance that
      # will execute all of this dataset's queries.
      attr_reader :db

      # The hash of options for this dataset, keys are symbols.
      attr_reader :opts

      # Constructs a new Dataset instance with an associated database.
      # Datasets are usually constructed by invoking the Database#fetch method:
      #
      #   DB.fetch('SELECT 1=1 AS a')
      def initialize(db)
        @db = db
        @opts = {}
        @cache_mutex = Mutex.new
        @cache = {}
      end

      # Define a hash value such that datasets with the same class, DB, and opts
      # will be considered equal.
      def ==(o)
        o.is_a?(self.class) && db == o.db && opts == o.opts
      end

      # Alias for ==
      def eql?(o)
        self == o
      end

      # Define a hash value such that datasets with the same class, DB, and opts,
      # will have the same hash value.
      def hash
        [self.class, db, opts].hash
      end

      # Returns a string representation of the dataset including the class name
      # and the corresponding SQL select statement.
      def inspect
        "#<#{self.class.name}: #{sql.inspect}>"
      end

      def sql
        opts[:sql]
      end

      # The dataset options that require the removal of cached columns
      # if changed.
      COLUMN_CHANGE_OPTS = [:sql].freeze

      TRUE_FREEZE = RUBY_VERSION >= '2.4'

      # On Ruby 2.4+, use clone(:freeze=>false) to create clones, because
      # we use true freezing in that case, and we need to modify the opts
      # in the frozen copy.
      #
      # On Ruby <2.4, just use Object#clone directly, since we don't
      # use true freezing as it isn't possible.
      if TRUE_FREEZE
        # Save original clone implementation, as some other methods need
        # to call it internally.
        alias _clone clone
        private :_clone

        # Returns a new clone of the dataset with the given options merged.
        # If the options changed include options in COLUMN_CHANGE_OPTS, the cached
        # columns are deleted.  This method should generally not be called
        # directly by user code.
        def clone(opts = OPTS)
          c = super(:freeze=>false)
          c.opts.merge!(opts)
          unless opts.each_key{|o| break if COLUMN_CHANGE_OPTS.include?(o)}
            c.clear_columns_cache
          end
          c.freeze if frozen?
          c
        end
      else
        # :nocov:
        def clone(opts = OPTS) # :nodoc:
          c = super()
          c.opts.merge!(opts)
          unless opts.each_key{|o| break if COLUMN_CHANGE_OPTS.include?(o)}
            c.clear_columns_cache
          end
          c.freeze if frozen?
          c
        end
        # :nocov:
      end

      # Set the db, opts, and cache for the copy of the dataset.
      def initialize_copy(c)
        @db = c.db
        @opts = Hash[c.opts]
        if cols = c.cache_get(:_columns)
          @cache = {:_columns=>cols}
        else
          @cache = {}
        end
      end

      def with_sql(sql, opts=OPTS)
        clone(opts.merge(:sql => sql))
      end

      def each(options=OPTS)
        fetch_rows(opts[:sql], opts.merge(options)){|r| yield r}
        self
      end

      alias :all :entries

      # Correctly return rows from the database and return them as hashes.
      def fetch_rows(sql, opts=OPTS, &block)
        db.execute(sql){|result| process_result_set(result, opts, &block)}
        self
      end

      # Split out from fetch rows to allow processing of JDBC result sets
      # that don't come from issuing an SQL string.
      def process_result_set(result, opts=OPTS)
        meta = result.getMetaData
        if fetch_size = opts[:fetch_size]
          result.setFetchSize(fetch_size)
        end

        converters = []
        self.columns = meta.getColumnCount.times.map do |i|
          col = i + 1
          converters << TypeConverter::MAP[meta.getColumnType(col)]
          meta.getColumnLabel(col)
        end

        fetch_as_array = opts[:as] == :array
        while result.next
          row = fetch_as_array ? [] : {}
          _columns.each_with_index do |column, i|
            k = fetch_as_array ? i : column
            col = i+1
            row[k] = converters[i].call(result, col, opts)
          end
          yield row
        end
      ensure
        result.close
      end

      # Returns the columns in the result set in order as an array of symbols.
      # If the columns are currently cached, returns the cached value. Otherwise,
      # a SELECT query is performed to retrieve a single row in order to get the columns.
      #
      #   DB.fetch('SELECT 1 AS a, 2 AS b').columns
      #   # => [:a, :b]
      def columns
        _columns || columns!
      end

      # Ignore any cached column information and perform a query to retrieve
      # a row in order to get the columns.
      #
      #   dataset = DB.fetch('SELECT 1 AS a, 2 AS b')
      #   dataset.columns!
      #   # => [:a, :b]
      def columns!
        ds = clone(opts.merge(:sql => "SELECT TOP 1 [T1].* FROM (#{opts[:sql]}) \"T1\""))
        ds.each{break}

        if cols = ds.cache[:_columns]
          self.columns = cols
        else
          []
        end
      end

      protected

      # Access the cache for the current dataset.  Should be used with caution,
      # as access to the cache is not thread safe without a mutex if other
      # threads can reference the dataset.  Symbol keys prefixed with an
      # underscore are reserved for internal use.
      attr_reader :cache

      # Retreive a value from the dataset's cache in a thread safe manner.
      def cache_get(k)
        synchronize{@cache[k]}
      end

      # Set a value in the dataset's cache in a thread safe manner.
      def cache_set(k, v)
        synchronize{@cache[k] = v}
      end

      # Clear the columns hash for the current dataset.  This is not a
      # thread safe operation, so it should only be used if the dataset
      # could not be used by another thread (such as one that was just
      # created via clone).
      def clear_columns_cache
        @cache.delete(:_columns)
      end

      # The cached columns for the current dataset.
      def _columns
        cache_get(:_columns)
      end

      private

      # Set the columns for the current dataset.
      def columns=(v)
        cache_set(:_columns, v)
      end
    end
  end
end
