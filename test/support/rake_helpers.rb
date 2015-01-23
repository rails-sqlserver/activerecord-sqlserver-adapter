
SQLSERVER_HELPER = 'test/cases/helper_sqlserver.rb'
SQLSERVER_COERCED = 'test/cases/coerced_tests.rb'

def env_ar_test_files
  return unless ENV['TEST_FILES_AR'] && !ENV['TEST_FILES_AR'].empty?
  @env_ar_test_files ||= begin
    ENV['TEST_FILES_AR'].split(',').map { |file|
      File.join ARTest::SQLServer.root_activerecord, file.strip
    }.sort
  end
end

def env_test_files
  return unless ENV['TEST_FILES'] && !ENV['TEST_FILES'].empty?
  @env_test_files ||= ENV['TEST_FILES'].split(',').map(&:strip)
end

def sqlserver_cases
  @sqlserver_cases ||= Dir.glob('test/cases/*_test_sqlserver.rb')
end

def ar_cases
  @ar_cases ||= begin
    all_cases = Dir.glob("#{ARTest::SQLServer.root_activerecord}/test/cases/**/*_test.rb")
    adapters_cases = Dir.glob("#{ARTest::SQLServer.root_activerecord}/test/cases/adapters/**/*_test.rb")
    (all_cases - adapters_cases).sort
  end
end

def test_files
  return env_ar_test_files.unshift(SQLSERVER_HELPER) if env_ar_test_files
  return env_test_files if env_test_files
  if ENV['ONLY_SQLSERVER']
    sqlserver_cases
  elsif ENV['ONLY_ACTIVERECORD']
    [SQLSERVER_HELPER] + (ar_cases + [SQLSERVER_COERCED])
  else
    [SQLSERVER_HELPER] + (ar_cases + [SQLSERVER_COERCED] + sqlserver_cases)
  end
end
