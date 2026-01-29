require "test_helper"

class ResultTest < TinyTds::TestCase
  describe "Basic query and result" do
    before do
      @@current_schema_loaded ||= load_current_schema
      @client = new_connection
      @query1 = "SELECT 1 AS [one]"
    end

    it "has included Enumerable" do
      assert TinyTds::Result.ancestors.include?(Enumerable)
    end

    it "responds to #each" do
      result = @client.execute(@query1)
      assert result.respond_to?(:each)
    end

    it "returns all results for #each with no block" do
      result = @client.execute(@query1)
      data = result.each
      row = data.first
      assert_instance_of Array, data
      assert_equal 1, data.size
      assert_instance_of Hash, row, "hash is the default query option"
    end

    it "returns all results for #each with a block yielding a row at a time" do
      result = @client.execute(@query1)
      data = result.each do |row|
        assert_instance_of Hash, row, "hash is the default query option"
      end
      assert_instance_of Array, data
    end

    it "allows successive calls to each returning the same data" do
      result = @client.execute(@query1)
      data = result.each
      result.each
      assert_equal data.object_id, result.each.object_id
      assert_equal data.first.object_id, result.each.first.object_id
    end

    it "returns hashes with string keys" do
      result = @client.execute(@query1)
      row = result.each(as: :hash, symbolize_keys: false).first
      assert_instance_of Hash, row
      assert_equal ["one"], row.keys
      assert_equal ["one"], result.fields
    end

    it "returns hashes with symbol keys" do
      result = @client.execute(@query1)
      row = result.each(as: :hash, symbolize_keys: true).first
      assert_instance_of Hash, row
      assert_equal [:one], row.keys
      assert_equal [:one], result.fields
    end

    it "returns arrays with string fields" do
      result = @client.execute(@query1)
      row = result.each(as: :array, symbolize_keys: false).first
      assert_instance_of Array, row
      assert_equal ["one"], result.fields
    end

    it "returns arrays with symbol fields" do
      result = @client.execute(@query1)
      row = result.each(as: :array, symbolize_keys: true).first
      assert_instance_of Array, row
      assert_equal [:one], result.fields
    end

    it "allows sql concat + to work" do
      rollback_transaction(@client) do
        @client.execute("DELETE FROM [datatypes]").do
        @client.execute("INSERT INTO [datatypes] ([char_10], [varchar_50]) VALUES ('1', '2')").do
        result = @client.execute("SELECT TOP (1) [char_10] + 'test' + [varchar_50] AS [test] FROM [datatypes]").each.first["test"]
        _(result).must_equal "1         test2"
      end
    end

    it "must be able to turn :cache_rows option off" do
      result = @client.execute(@query1)
      local = []
      result.each(cache_rows: false) do |row|
        local << row
      end
      assert local.first, "should have iterated over each row"
      assert_equal [], result.each, "should not have been cached"
      assert_equal ["one"], result.fields, "should still cache field names"
    end

    it "must be able to get the first result row only" do
      load_current_schema
      big_query = "SELECT [id] FROM [datatypes]"
      one = @client.execute(big_query).each(first: true)
      many = @client.execute(big_query).each
      assert many.size > 1
      assert one.size == 1
    end

    it "copes with no results when using first option" do
      data = @client.execute("SELECT [id] FROM [datatypes] WHERE [id] = -1").each(first: true)
      assert_equal [], data
    end

    it "must delete, insert and find data" do
      rollback_transaction(@client) do
        text = "test insert and delete"
        @client.execute("DELETE FROM [datatypes] WHERE [varchar_50] IS NOT NULL").do
        @client.execute("INSERT INTO [datatypes] ([varchar_50]) VALUES ('#{text}')").do
        row = @client.execute("SELECT [varchar_50] FROM [datatypes] WHERE [varchar_50] IS NOT NULL").each.first
        assert row
        assert_equal text, row["varchar_50"]
      end
    end

    it "must insert and find unicode data" do
      rollback_transaction(@client) do
        text = "😍"
        @client.execute("DELETE FROM [datatypes] WHERE [nvarchar_50] IS NOT NULL").do
        @client.execute("INSERT INTO [datatypes] ([nvarchar_50]) VALUES (N'#{text}')").do
        row = @client.execute("SELECT [nvarchar_50] FROM [datatypes] WHERE [nvarchar_50] IS NOT NULL").each.first
        assert_equal text, row["nvarchar_50"]
      end
    end

    it "must delete and update with affected rows support and insert with identity support in native sql" do
      rollback_transaction(@client) do
        text = "test affected rows sql"
        @client.execute("DELETE FROM [datatypes]").do
        afrows = @client.execute("SELECT @@ROWCOUNT AS AffectedRows").each.first["AffectedRows"]
        _(["Fixnum", "Integer"]).must_include afrows.class.name
        @client.execute("INSERT INTO [datatypes] ([varchar_50]) VALUES ('#{text}')").do
        pk1 = @client.execute(@client.identity_sql).each.first["Ident"]
        _(["Fixnum", "Integer"]).must_include pk1.class.name, "we it be able to CAST to bigint"
        @client.execute("UPDATE [datatypes] SET [varchar_50] = NULL WHERE [varchar_50] = '#{text}'").do
        afrows = @client.execute("SELECT @@ROWCOUNT AS AffectedRows").each.first["AffectedRows"]
        assert_equal 1, afrows
      end
    end

    it "has a #do method that cancels result rows and returns affected rows natively" do
      rollback_transaction(@client) do
        text = "test affected rows native"
        count = @client.execute("SELECT COUNT(*) AS [count] FROM [datatypes]").each.first["count"]
        deleted_rows = @client.execute("DELETE FROM [datatypes]").do
        assert_equal count, deleted_rows, "should have deleted rows equal to count"
        inserted_rows = @client.execute("INSERT INTO [datatypes] ([varchar_50]) VALUES ('#{text}')").do
        assert_equal 1, inserted_rows, "should have inserted row for one above"
        updated_rows = @client.execute("UPDATE [datatypes] SET [varchar_50] = NULL WHERE [varchar_50] = '#{text}'").do
        assert_equal 1, updated_rows, "should have updated row for one above"
      end
    end

    it "allows native affected rows using #do to work under transaction" do
      rollback_transaction(@client) do
        text = "test affected rows native in transaction"
        @client.execute("BEGIN TRANSACTION").do
        @client.execute("DELETE FROM [datatypes]").do
        inserted_rows = @client.execute("INSERT INTO [datatypes] ([varchar_50]) VALUES ('#{text}')").do
        assert_equal 1, inserted_rows, "should have inserted row for one above"
        updated_rows = @client.execute("UPDATE [datatypes] SET [varchar_50] = NULL WHERE [varchar_50] = '#{text}'").do
        assert_equal 1, updated_rows, "should have updated row for one above"
      end
    end

    it "has an #insert method that cancels result rows and returns IDENTITY natively" do
      rollback_transaction(@client) do
        text = "test scope identity rows native"
        @client.execute("DELETE FROM [datatypes] WHERE [varchar_50] = '#{text}'").do
        @client.execute("INSERT INTO [datatypes] ([varchar_50]) VALUES ('#{text}')").do
        sql_identity = @client.execute(@client.identity_sql).each.first["Ident"]
        native_identity = @client.execute("INSERT INTO [datatypes] ([varchar_50]) VALUES ('#{text}')").insert
        assert_equal sql_identity + 1, native_identity
      end
    end

    it "returns bigint for #insert when needed" do
      return if sqlserver_azure? # We can not alter clustered index like this test does.
      # 'CREATE TABLE' command is not allowed within a multi-statement transaction
      # and and sp_helpindex creates a temporary table #spindtab.
      rollback_transaction(@client) do
        seed = 9223372036854775805
        @client.execute("DELETE FROM [datatypes]").do
        id_constraint_name = @client.execute("EXEC sp_helpindex [datatypes]").detect { |row| row["index_keys"] == "id" }["index_name"]
        @client.execute("ALTER TABLE [datatypes] DROP CONSTRAINT [#{id_constraint_name}]").do
        @client.execute("ALTER TABLE [datatypes] DROP COLUMN [id]").do
        @client.execute("ALTER TABLE [datatypes] ADD [id] [bigint] NOT NULL IDENTITY(1,1) PRIMARY KEY").do
        @client.execute("DBCC CHECKIDENT ('datatypes', RESEED, #{seed})").do
        identity = @client.execute("INSERT INTO [datatypes] ([varchar_50]) VALUES ('something')").insert
        assert_equal seed, identity
      end
    end

    it "must be able to begin/commit transactions with raw sql" do
      rollback_transaction(@client) do
        @client.execute("BEGIN TRANSACTION").do
        @client.execute("DELETE FROM [datatypes]").do
        @client.execute("COMMIT TRANSACTION").do
        count = @client.execute("SELECT COUNT(*) AS [count] FROM [datatypes]").each.first["count"]
        assert_equal 0, count
      end
    end

    it "must be able to begin/rollback transactions with raw sql" do
      load_current_schema
      @client.execute("BEGIN TRANSACTION").do
      @client.execute("DELETE FROM [datatypes]").do
      @client.execute("ROLLBACK TRANSACTION").do
      count = @client.execute("SELECT COUNT(*) AS [count] FROM [datatypes]").each.first["count"]
      _(count).wont_equal 0
    end

    it "has a #fields accessor with logic default and valid outcome" do
      result = @client.execute(@query1)
      _(result.fields).must_equal ["one"]
      result.each
      _(result.fields).must_equal ["one"]
    end

    it "always returns an array for fields for all sql" do
      result = @client.execute("USE [tinytdstest]")
      _(result.fields).must_equal []
      result.do
      _(result.fields).must_equal []
    end

    it "returns fields even when no results are found" do
      no_results_query = "SELECT [id], [varchar_50] FROM [datatypes] WHERE [varchar_50] = 'NOTFOUND'"
      # Fields before each.
      result = @client.execute(no_results_query)
      _(result.fields).must_equal ["id", "varchar_50"]
      result.each
      _(result.fields).must_equal ["id", "varchar_50"]
      # Each then fields
      result = @client.execute(no_results_query)
      result.each
      _(result.fields).must_equal ["id", "varchar_50"]
    end

    it "allows the result to be canceled before reading" do
      result = @client.execute(@query1)
      result.cancel
      @client.execute(@query1).each
    end

    it "works in tandem with the client when needing to find out if client has sql sent and result is canceled or not" do
      # Default state.
      @client = TinyTds::Client.new(connection_options)
      _(@client.sqlsent?).must_equal false
      _(@client.canceled?).must_equal false
      # With active result before and after cancel.
      result = @client.execute(@query1)
      _(@client.sqlsent?).must_equal true
      _(@client.canceled?).must_equal false
      result.cancel
      _(@client.sqlsent?).must_equal false
      _(@client.canceled?).must_equal true
      assert result.cancel, "must be safe to call again"
      # With each and no block.
      @client.execute(@query1).each
      _(@client.sqlsent?).must_equal false
      _(@client.canceled?).must_equal false
      # With each and block.
      @client.execute(@query1).each do |row|
        _(@client.sqlsent?).must_equal true, "when iterating over each row in a block"
        _(@client.canceled?).must_equal false
      end
      _(@client.sqlsent?).must_equal false
      _(@client.canceled?).must_equal false
      # With each and block canceled half way thru.
      count = @client.execute("SELECT COUNT([id]) AS [count] FROM [datatypes]").each[0]["count"]
      assert count > 10, "since we want to cancel early for test"
      result = @client.execute("SELECT [id] FROM [datatypes]")
      index = 0
      result.each do |row|
        break if index > 10
        index += 1
      end
      _(@client.sqlsent?).must_equal true
      _(@client.canceled?).must_equal false
      result.cancel
      _(@client.sqlsent?).must_equal false
      _(@client.canceled?).must_equal true
      # With do method.
      @client.execute(@query1).do
      _(@client.sqlsent?).must_equal false
      _(@client.canceled?).must_equal true
      # With insert method.
      rollback_transaction(@client) do
        @client.execute("INSERT INTO [datatypes] ([varchar_50]) VALUES ('test')").insert
        _(@client.sqlsent?).must_equal false
        _(@client.canceled?).must_equal true
      end
      # With first
      @client.execute("SELECT [id] FROM [datatypes]").each(first: true)
      _(@client.sqlsent?).must_equal false
      _(@client.canceled?).must_equal true
    end

    it "use same string object for hash keys" do
      data = @client.execute("SELECT [id], [bigint] FROM [datatypes]").each
      assert_equal data.first.keys.map { |r| r.object_id }, data.last.keys.map { |r| r.object_id }
    end

    it "has properly encoded column names with symbol keys" do
      col_name = "öäüß"
      begin
        @client.execute("DROP TABLE [test_encoding]").do
      rescue
        nil
      end
      @client.execute("CREATE TABLE [dbo].[test_encoding] ( [id] int NOT NULL IDENTITY(1,1) PRIMARY KEY, [#{col_name}] [nvarchar](10) NOT NULL )").do
      @client.execute("INSERT INTO [test_encoding] ([#{col_name}]) VALUES (N'#{col_name}')").do
      result = @client.execute("SELECT [#{col_name}] FROM [test_encoding]")
      row = result.each(as: :hash, symbolize_keys: true).first
      assert_instance_of Symbol, result.fields.first
      assert_equal col_name.to_sym, result.fields.first
      assert_instance_of Symbol, row.keys.first
      assert_equal col_name.to_sym, row.keys.first
    end

    it "allows #return_code to work with stored procedures and reset per sql batch" do
      assert_nil @client.return_code
      result = @client.execute("EXEC tinytds_TestReturnCodes")
      assert_equal [{"one" => 1}], result.each
      assert_equal 420, @client.return_code
      assert_equal 420, result.return_code
      result = @client.execute("SELECT 1 as [one]")
      result.each
      assert_nil @client.return_code
      assert_nil result.return_code
    end

    it "with LOGINPROPERTY function" do
      v = @client.execute("SELECT LOGINPROPERTY('sa', 'IsLocked') as v").first["v"]
      _(v).must_equal 0
    end

    describe "with multiple result sets" do
      before do
        @empty_select = "SELECT 1 AS [rs1] WHERE 1 = 0"
        @double_select = "SELECT 1 AS [rs1]
                          SELECT 2 AS [rs2]"
        @triple_select_1st_empty = "SELECT 1 AS [rs1] WHERE 1 = 0
                                    SELECT 2 AS [rs2]
                                    SELECT 3 AS [rs3]"
        @triple_select_2nd_empty = "SELECT 1 AS [rs1]
                                    SELECT 2 AS [rs2] WHERE 1 = 0
                                    SELECT 3 AS [rs3]"
        @triple_select_3rd_empty = "SELECT 1 AS [rs1]
                                    SELECT 2 AS [rs2]
                                    SELECT 3 AS [rs3] WHERE 1 = 0"
      end

      it "handles a command buffer with double selects" do
        result = @client.execute(@double_select)
        result_sets = result.each
        assert_equal 2, result_sets.size
        assert_equal [{"rs1" => 1}], result_sets.first
        assert_equal [{"rs2" => 2}], result_sets.last
        assert_equal [["rs1"], ["rs2"]], result.fields
        assert_equal result.each.object_id, result.each.object_id, "same cached rows"
        # As array
        result = @client.execute(@double_select)
        result_sets = result.each(as: :array)
        assert_equal 2, result_sets.size
        assert_equal [[1]], result_sets.first
        assert_equal [[2]], result_sets.last
        assert_equal [["rs1"], ["rs2"]], result.fields
        assert_equal result.each.object_id, result.each.object_id, "same cached rows"
      end

      it "yields each row for each result set" do
        data = []
        result_sets = @client.execute(@double_select).each { |row| data << row }
        assert_equal data.first, result_sets.first[0]
        assert_equal data.last, result_sets.last[0]
      end

      it "works from a stored procedure" do
        results1, results2 = @client.execute("EXEC sp_helpconstraint '[datatypes]'").each
        assert_equal [{"Object Name" => "[datatypes]"}], results1
        constraint_info = results2.first
        assert constraint_info.key?("constraint_keys")
        assert constraint_info.key?("constraint_type")
        assert constraint_info.key?("constraint_name")
      end

      describe "using :empty_sets TRUE" do
        before do
          close_client
          @old_query_option_value = TinyTds::Client.default_query_options[:empty_sets]
          TinyTds::Client.default_query_options[:empty_sets] = true
          @client = new_connection
        end

        after do
          TinyTds::Client.default_query_options[:empty_sets] = @old_query_option_value
        end

        it "handles a basic empty result set" do
          result = @client.execute(@empty_select)
          assert_equal [], result.each
          assert_equal ["rs1"], result.fields
        end

        it "includes empty result sets by default - using 1st empty buffer" do
          result = @client.execute(@triple_select_1st_empty)
          result_sets = result.each
          assert_equal 3, result_sets.size
          assert_equal [], result_sets[0]
          assert_equal [{"rs2" => 2}], result_sets[1]
          assert_equal [{"rs3" => 3}], result_sets[2]
          assert_equal [["rs1"], ["rs2"], ["rs3"]], result.fields
          assert_equal result.each.object_id, result.each.object_id, "same cached rows"
          # As array
          result = @client.execute(@triple_select_1st_empty)
          result_sets = result.each(as: :array)
          assert_equal 3, result_sets.size
          assert_equal [], result_sets[0]
          assert_equal [[2]], result_sets[1]
          assert_equal [[3]], result_sets[2]
          assert_equal [["rs1"], ["rs2"], ["rs3"]], result.fields
          assert_equal result.each.object_id, result.each.object_id, "same cached rows"
        end

        it "includes empty result sets by default - using 2nd empty buffer" do
          result = @client.execute(@triple_select_2nd_empty)
          result_sets = result.each
          assert_equal 3, result_sets.size
          assert_equal [{"rs1" => 1}], result_sets[0]
          assert_equal [], result_sets[1]
          assert_equal [{"rs3" => 3}], result_sets[2]
          assert_equal [["rs1"], ["rs2"], ["rs3"]], result.fields
          assert_equal result.each.object_id, result.each.object_id, "same cached rows"
          # As array
          result = @client.execute(@triple_select_2nd_empty)
          result_sets = result.each(as: :array)
          assert_equal 3, result_sets.size
          assert_equal [[1]], result_sets[0]
          assert_equal [], result_sets[1]
          assert_equal [[3]], result_sets[2]
          assert_equal [["rs1"], ["rs2"], ["rs3"]], result.fields
          assert_equal result.each.object_id, result.each.object_id, "same cached rows"
        end

        it "includes empty result sets by default - using 3rd empty buffer" do
          result = @client.execute(@triple_select_3rd_empty)
          result_sets = result.each
          assert_equal 3, result_sets.size
          assert_equal [{"rs1" => 1}], result_sets[0]
          assert_equal [{"rs2" => 2}], result_sets[1]
          assert_equal [], result_sets[2]
          assert_equal [["rs1"], ["rs2"], ["rs3"]], result.fields
          assert_equal result.each.object_id, result.each.object_id, "same cached rows"
          # As array
          result = @client.execute(@triple_select_3rd_empty)
          result_sets = result.each(as: :array)
          assert_equal 3, result_sets.size
          assert_equal [[1]], result_sets[0]
          assert_equal [[2]], result_sets[1]
          assert_equal [], result_sets[2]
          assert_equal [["rs1"], ["rs2"], ["rs3"]], result.fields
          assert_equal result.each.object_id, result.each.object_id, "same cached rows"
        end
      end

      describe "using :empty_sets FALSE" do
        before do
          close_client
          @old_query_option_value = TinyTds::Client.default_query_options[:empty_sets]
          TinyTds::Client.default_query_options[:empty_sets] = false
          @client = new_connection
        end

        after do
          TinyTds::Client.default_query_options[:empty_sets] = @old_query_option_value
        end

        it "handles a basic empty result set" do
          result = @client.execute(@empty_select)
          assert_equal [], result.each
          assert_equal ["rs1"], result.fields
        end

        it "must not include empty result sets by default - using 1st empty buffer" do
          result = @client.execute(@triple_select_1st_empty)
          result_sets = result.each
          assert_equal 2, result_sets.size
          assert_equal [{"rs2" => 2}], result_sets[0]
          assert_equal [{"rs3" => 3}], result_sets[1]
          assert_equal [["rs2"], ["rs3"]], result.fields
          assert_equal result.each.object_id, result.each.object_id, "same cached rows"
          # As array
          result = @client.execute(@triple_select_1st_empty)
          result_sets = result.each(as: :array)
          assert_equal 2, result_sets.size
          assert_equal [[2]], result_sets[0]
          assert_equal [[3]], result_sets[1]
          assert_equal [["rs2"], ["rs3"]], result.fields
          assert_equal result.each.object_id, result.each.object_id, "same cached rows"
        end

        it "must not include empty result sets by default - using 2nd empty buffer" do
          result = @client.execute(@triple_select_2nd_empty)
          result_sets = result.each
          assert_equal 2, result_sets.size
          assert_equal [{"rs1" => 1}], result_sets[0]
          assert_equal [{"rs3" => 3}], result_sets[1]
          assert_equal [["rs1"], ["rs3"]], result.fields
          assert_equal result.each.object_id, result.each.object_id, "same cached rows"
          # As array
          result = @client.execute(@triple_select_2nd_empty)
          result_sets = result.each(as: :array)
          assert_equal 2, result_sets.size
          assert_equal [[1]], result_sets[0]
          assert_equal [[3]], result_sets[1]
          assert_equal [["rs1"], ["rs3"]], result.fields
          assert_equal result.each.object_id, result.each.object_id, "same cached rows"
        end

        it "must not include empty result sets by default - using 3rd empty buffer" do
          result = @client.execute(@triple_select_3rd_empty)
          result_sets = result.each
          assert_equal 2, result_sets.size
          assert_equal [{"rs1" => 1}], result_sets[0]
          assert_equal [{"rs2" => 2}], result_sets[1]
          assert_equal [["rs1"], ["rs2"]], result.fields
          assert_equal result.each.object_id, result.each.object_id, "same cached rows"
          # As array
          result = @client.execute(@triple_select_3rd_empty)
          result_sets = result.each(as: :array)
          assert_equal 2, result_sets.size
          assert_equal [[1]], result_sets[0]
          assert_equal [[2]], result_sets[1]
          assert_equal [["rs1"], ["rs2"]], result.fields
          assert_equal result.each.object_id, result.each.object_id, "same cached rows"
        end
      end
    end

    unless sqlserver_azure?
      describe "Complex query with multiple results sets but no actual results" do
        let(:backup_file) { 'C:\\Users\\Public\\tinytdstest.bak' }

        after { File.delete(backup_file) if File.exist?(backup_file) }

        it "must not cancel the query until complete" do
          @client.execute("BACKUP DATABASE tinytdstest TO DISK = '#{backup_file}'").do
        end
      end
    end

    describe "when casting to native ruby values" do
      it "returns fixnum for 1" do
        value = @client.execute("SELECT 1 AS [fixnum]").each.first["fixnum"]
        assert_equal 1, value
      end

      it "returns nil for NULL" do
        value = @client.execute("SELECT NULL AS [null]").each.first["null"]
        assert_nil value
      end
    end

    describe "with data type" do
      describe "char max" do
        before do
          @big_text = "x" * 2_000_000
          @old_textsize = @client.execute("SELECT @@TEXTSIZE AS [textsize]").each.first["textsize"].inspect
          @client.execute("SET TEXTSIZE #{(@big_text.length * 2) + 1}").do
        end

        it "must insert and select large varchar_max" do
          insert_and_select_datatype :varchar_max
        end

        it "must insert and select large nvarchar_max" do
          insert_and_select_datatype :nvarchar_max
        end
      end
    end

    describe "when shit happens" do
      it "copes with nil or empty buffer" do
        assert_raises(TypeError) { @client.execute(nil) }
        assert_equal [], @client.execute("").each
      end

      describe "using :message_handler option" do
        let(:messages) { [] }

        before do
          close_client
          @client = new_connection message_handler: proc { |m| messages << m }
        end

        after do
          messages.clear
        end

        it "has a message handler that responds to call" do
          assert @client.message_handler.respond_to?(:call)
        end

        it "calls the provided message handler when severity is 10 or less" do
          (1..10).to_a.each do |severity|
            messages.clear
            msg = "Test #{severity} severity"
            state = rand(1..255)
            @client.execute("RAISERROR(N'#{msg}', #{severity}, #{state})").do
            m = messages.first
            assert_equal 1, messages.length, "there should be one message after one raiserror"
            assert_equal msg, m.message, "message text"
            assert_equal severity, m.severity, "message severity" unless severity == 10 && m.severity.to_i == 0
            assert_equal state, m.os_error_number, "message state"
          end
        end

        it "calls the provided message handler for `print` messages" do
          messages.clear
          msg = "hello"
          @client.execute("PRINT '#{msg}'").do
          m = messages.first
          assert_equal 1, messages.length, "there should be one message after one print statement"
          assert_equal msg, m.message, "message text"
        end

        it "must raise an error preceded by a `print` message" do
          messages.clear
          action = lambda { @client.execute("EXEC tinytds_TestPrintWithError").do }
          assert_raise_tinytds_error(action) do |e|
            assert_equal "hello", messages.first.message, "message text"

            assert_equal "Error following print", e.message
            assert_equal 16, e.severity
            assert_equal 50000, e.db_error_number
          end
        end

        it "calls the provided message handler for each of a series of `print` messages" do
          messages.clear
          @client.execute("EXEC tinytds_TestSeveralPrints").do
          assert_equal ["hello 1", "hello 2", "hello 3"], messages.map { |e| e.message }, "message list"
        end

        it "should flush info messages before raising error in cases of timeout" do
          @client = new_connection timeout: 1, message_handler: proc { |m| messages << m }
          action = lambda { @client.execute("print 'hello'; waitfor delay '00:00:02'").do }
          messages.clear
          assert_raise_tinytds_error(action) do |e|
            assert_match %r{timed out}i, e.message, "ignore if non-english test run"
            assert_equal 6, e.severity
            assert_equal 20003, e.db_error_number
            assert_equal "hello", messages.first&.message, "message text"
          end
        end

        it "should print info messages before raising error in cases of timeout" do
          @client = new_connection timeout: 1, message_handler: proc { |m| messages << m }
          action = lambda { @client.execute("raiserror('hello', 1, 1) with nowait; waitfor delay '00:00:02'").do }
          messages.clear
          assert_raise_tinytds_error(action) do |e|
            assert_match %r{timed out}i, e.message, "ignore if non-english test run"
            assert_equal 6, e.severity
            assert_equal 20003, e.db_error_number
            assert_equal "hello", messages.first&.message, "message text"
          end
        end
      end

      it "must not raise an error when severity is 10 or less" do
        (1..10).to_a.each do |severity|
          @client.execute("RAISERROR(N'Test #{severity} severity', #{severity}, 1)").do
        end
      end

      it "raises an error when severity is greater than 10" do
        action = lambda { @client.execute("RAISERROR(N'Test 11 severity', 11, 1)").do }
        assert_raise_tinytds_error(action) do |e|
          assert_equal "Test 11 severity", e.message
          assert_equal 11, e.severity
          assert_equal 50000, e.db_error_number
        end
      end
    end
  end

  protected

  def assert_followup_query
    result = @client.execute(@query1)
    assert_equal 1, result.each.first["one"]
  end

  def insert_and_select_datatype(datatype)
    rollback_transaction(@client) do
      @client.execute("DELETE FROM [datatypes] WHERE [#{datatype}] IS NOT NULL").do
      id = @client.execute("INSERT INTO [datatypes] ([#{datatype}]) VALUES (N'#{@big_text}')").insert
      found_text = find_value id, datatype
      flunk "Large #{datatype} data with a length of #{@big_text.length} did not match found text with length of #{found_text.length}" unless @big_text == found_text
    end
  end
end
