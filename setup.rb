begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"
  gem "activerecord", "4.0.13"
  gem "pg"
end

db_config = {
  adapter: "postgresql",
  encoding: "unicode",
  pool: 5,
  host: "localhost",
  database: "pathways_test_denormalization",
  username: `id -un`.strip,
  password: "",
}

at_exit do
  ActiveRecord::Base.connection.disconnect!

  `dropdb #{db_config[:database]}`
end

require "active_record"
require "minitest/autorun"
require "logger"
require "securerandom"

# Ensure backward compatibility with Minitest 4
Minitest::Test = MiniTest::Unit::TestCase unless defined?(Minitest::Test)

`createdb -O #{db_config[:username]} #{db_config[:database]}`

ActiveRecord::Base.establish_connection(db_config)
ActiveRecord::Base.logger = Logger.new(STDOUT)
