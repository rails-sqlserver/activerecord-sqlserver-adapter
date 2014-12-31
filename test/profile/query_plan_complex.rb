=begin

Query Plan Complex
==================
Author: Ken Collins
Date: May 22, 2011
Summary: Benchmark complex cached query plan reuse in SQL Server.

System Information
------------------
    Operating System:    Mac OS X 10.6.7 (10J869)
    CPU:                 Quad-Core Intel Xeon 2.66 GHz
    Processor Count:     4
    Memory:              24 GB
    ruby 1.8.7 (2011-02-18 patchlevel 334) [i686-darwin10.6.0], MBARI 0x6770, Ruby Enterprise Edition 2011.03

"Simple - Query Plan Reuse" is up to 88% faster over  repetitions
-----------------------------------------------------------------

    Simple - Query Plan Reuse    0.230067014694214 secs    Fastest
    Simple - Dynamic SQL         1.99195981025696  secs    88% Slower

=end

require 'rubygems'
require 'bundler'
Bundler.setup
require 'tiny_tds'
require 'bench_press'

extend BenchPress

author 'Ken Collins'
summary 'Benchmark complex cached query plan reuse in SQL Server.'
reps 500

@client = TinyTds::Client.new host: 'mc2008', username: 'rails'


measure "Simple - Dynamic SQL" do
  sql = "
    SELECT TOP (1) [companies].id
    FROM [companies]
    LEFT OUTER JOIN [companies] [clients_using_primary_keys_companies] ON [clients_using_primary_keys_companies].[firm_name] = [companies].[name]
    AND [clients_using_primary_keys_companies].[type] IN (N'Client', N'SpecialClient', N'VerySpecialClient')
    WHERE [companies].[type] IN (N'Firm')
    AND [companies].[id] = #{rand(1000000)}
    GROUP BY [companies].id
    ORDER BY MIN(clients_using_primary_keys_companies.name)"
  @client.execute(sql).do
end

measure "Simple - Query Plan Reuse" do
  sql = "
    EXEC sp_executesql N'
      SELECT TOP (1) [companies].id
      FROM [companies]
      LEFT OUTER JOIN [companies] [clients_using_primary_keys_companies] ON [clients_using_primary_keys_companies].[firm_name] = [companies].[name]
      AND [clients_using_primary_keys_companies].[type] IN (N''Client'', N''SpecialClient'', N''VerySpecialClient'')
      WHERE [companies].[type] IN (N''Firm'')
      AND [companies].[id] = @0
      GROUP BY [companies].id
      ORDER BY MIN(clients_using_primary_keys_companies.name)',
    N'@0 int',
    @0 = #{rand(1000000)}"
  @client.execute(sql).do
end

