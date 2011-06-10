module ARTest
  
  class << self
    
    def config
      @config ||= {
        
        'default_connection' => 'dblib',
        
        'connections' => {
          
          'dblib' => {
            'arunit' => {
              'adapter'     => 'sqlserver',
              'mode'        => 'dblib',
              'dataserver'  => ENV['ACTIVERECORD_UNITTEST_DATASERVER'],
              'username'    => ENV['ACTIVERECORD_UNITTEST_USER'] || 'rails',
              'password'    => ENV['ACTIVERECORD_UNITTEST_PASS'] || '',
              'database'    => 'activerecord_unittest',
              'appname'     => 'SQLServerAdptrUnit',
              'azure'       => !ENV['ACTIVERECORD_UNITTEST_AZURE'].nil?
            },
            'arunit2' => {
              'adapter'     => 'sqlserver',
              'mode'        => 'dblib',
              'dataserver'  => ENV['ACTIVERECORD_UNITTEST_DATASERVER'],
              'username'    => ENV['ACTIVERECORD_UNITTEST_USER'] || 'rails',
              'password'    => ENV['ACTIVERECORD_UNITTEST_PASS'] || '',
              'database'    => 'activerecord_unittest2',
              'appname'     => 'SQLServerAdptrUnit2',
              'azure'       => !ENV['ACTIVERECORD_UNITTEST_AZURE'].nil?
            }
          },
          
          'odbc' => {
            'arunit' => {
              'adapter'     => 'sqlserver',
              'mode'        => 'ODBC',
              'host'        => 'localhost',
              'username'    => 'rails',
              'dsn'         => ENV['ACTIVERECORD_UNITTEST_DSN'] || 'activerecord_unittest',
              'database'    => 'activerecord_unittest'
            },
            'arunit2' => {
              'adapter'     => 'sqlserver',
              'mode'        => 'ODBC',
              'host'        => 'localhost',
              'username'    => 'rails',
              'dsn'         => ENV['ACTIVERECORD_UNITTEST2_DSN'] || 'activerecord_unittest2',
              'database'    => 'activerecord_unittest2'
            }
          }
          
        }
      }
    end
    
  end
end
