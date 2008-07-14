ActiveRecord::Schema.define do
  create_table :table_with_real_columns, :force => true do |t|
    t.column :real_number, :real
  end
  
  create_table :defaults, :force => true do |t|
    # NOTE: These are the other columns from the postgresql specific schema
    # however, there aren't any tests for them yet, so no point creating them.
    # modified_date date default CURRENT_DATE,
    # modified_date_function date default now(),
    # fixed_date date default '2004-01-01',
    # modified_time timestamp default CURRENT_TIMESTAMP,
    # modified_time_function timestamp default now(),
    # fixed_time timestamp default '2004-01-01 00:00:00.000000-00',
    # char1 char(1) default 'Y',
    # char2 character varying(50) default 'a varchar field',
    # char3 text default 'a text field',
    
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
end