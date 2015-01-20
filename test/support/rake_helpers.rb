
SQLSERVER_TEST_HELPER = 'test/cases/helper_sqlserver.rb'

def env_ar_test_files
  return unless ENV['AR_TEST_FILES'] && !ENV['AR_TEST_FILES'].empty?
  @env_ar_test_files ||= begin
    files = ENV['AR_TEST_FILES'].split(',').map do |file|
      File.join ARTest::SQLServer.root_activerecord, file.strip
    end
    files.sort.unshift(SQLSERVER_TEST_HELPER)
  end
end

def env_test_files
  return unless ENV['TEST_FILES'] && !ENV['TEST_FILES'].empty?
  @env_test_files ||= ENV['TEST_FILES'].split(',').map(&:strip)
end

def sqlserver_cases
  @sqlserver_cases ||= Dir.glob('test/cases/**/*_test_sqlserver.rb') - [SQLSERVER_TEST_HELPER]
end

def ar_cases
  @ar_cases ||= begin
    all_cases = Dir.glob("#{ARTest::SQLServer.root_activerecord}/test/cases/**/*_test.rb")
    adapters_cases = Dir.glob("#{ARTest::SQLServer.root_activerecord}/test/cases/adapters/**/*_test.rb")
    (all_cases - adapters_cases).sort.unshift(SQLSERVER_TEST_HELPER)
  end
end

def test_files
  return env_ar_test_files if env_ar_test_files
  return env_test_files if env_test_files
  if ENV['SQLSERVER_ONLY']
    sqlserver_cases
  elsif ENV['ACTIVERECORD_ONLY']
    ar_cases
  else
    sqlserver_cases + ar_cases
  end
end

