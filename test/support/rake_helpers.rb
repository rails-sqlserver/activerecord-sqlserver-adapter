
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
    Dir.glob("#{ARTest::SQLServer.root_activerecord}/test/cases/**/*_test.rb").reject{ |x| x =~ /\/adapters\// }.sort
  end
end

def test_files
  if env_ar_test_files
    [SQLSERVER_HELPER] + env_ar_test_files
  elsif env_test_files
    env_test_files
  elsif ENV['ONLY_SQLSERVER']
    sqlserver_cases
  elsif ENV['ONLY_ACTIVERECORD']
    [SQLSERVER_HELPER] + (ar_cases + [SQLSERVER_COERCED])
  else
    [SQLSERVER_HELPER] + (ar_cases + [SQLSERVER_COERCED] + sqlserver_cases)
  end
end
