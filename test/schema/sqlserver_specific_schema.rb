ActiveRecord::Schema.define do
  
  create_table :table_with_real_columns, :force => true do |t|
    t.column :real_number, :real
  end
  
  create_table :defaults, :force => true do |t|
    t.column :positive_integer, :integer, :default => 1
    t.column :negative_integer, :integer, :default => -1
    t.column :decimal_number, :decimal, :precision => 3, :scale => 2, :default => 2.78
  end
  
  create_table :string_defaults, :force => true do |t|
    t.column :string_with_null_default, :string, :default => nil
    t.column :string_with_pretend_null_one, :string, :default => 'null'
    t.column :string_with_pretend_null_two, :string, :default => '(null)'
    t.column :string_with_pretend_null_three, :string, :default => 'NULL'
    t.column :string_with_pretend_null_four, :string, :default => '(NULL)'
  end
  
  create_table :sql_server_chronics, :force => true do |t|
    t.column :date,       :date
    t.column :time,       :time
    t.column :datetime,   :datetime
    t.column :timestamp,  :timestamp
  end
  
  create_table(:fk_test_has_fks, :force => true) { |t| t.column(:fk_id, :integer, :null => false) }
  create_table(:fk_test_has_pks, :force => true) { }
  execute <<-ADDFKSQL
    ALTER TABLE fk_test_has_fks 
    ADD CONSTRAINT FK__fk_test_has_fk_fk_id
    FOREIGN KEY (#{quote_column_name('fk_id')}) 
    REFERENCES #{quote_table_name('fk_test_has_pks')} (#{quote_column_name('id')})
  ADDFKSQL
  
  
end
