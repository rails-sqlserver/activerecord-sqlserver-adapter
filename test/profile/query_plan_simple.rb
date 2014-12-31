=begin

Query Plan Simple
=================
Author: Ken Collins
Date: May 22, 2011
Summary: Benchmark simple cached query plan reuse in SQL Server.

System Information
------------------
    Operating System:    Mac OS X 10.6.7 (10J869)
    CPU:                 Quad-Core Intel Xeon 2.66 GHz
    Processor Count:     4
    Memory:              24 GB
    ruby 1.8.7 (2011-02-18 patchlevel 334) [i686-darwin10.6.0], MBARI 0x6770, Ruby Enterprise Edition 2011.03

"Simple - Query Plan Reuse" is up to 58% faster over  repetitions
-----------------------------------------------------------------

    Simple - Query Plan Reuse    0.20799994468689 secs    Fastest
    Simple - Dynamic SQL         0.49638819694519 secs    58% Slower

=end

require 'rubygems'
require 'bundler'
Bundler.setup
require 'tiny_tds'
require 'bench_press'

extend BenchPress

author 'Ken Collins'
summary 'Benchmark simple cached query plan reuse in SQL Server.'
reps 500

@client = TinyTds::Client.new host: 'mc2008', username: 'rails'


measure "Simple - Dynamic SQL" do
  @client.execute("SELECT TOP(1) * FROM [posts] WHERE [id] = #{rand(1000000)}").do
end

measure "Simple - Query Plan Reuse" do
  @client.execute("EXEC sp_executesql N'SELECT TOP(1) * FROM [posts] WHERE [id] = @0', N'@0 int', @0 = #{rand(1000000)}").do
end
