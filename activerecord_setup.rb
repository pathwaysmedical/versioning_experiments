begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"
  # use 4.2 since it begins jsonb support
  gem "activerecord", "~> 4.2"
  gem "activesupport", "~> 4.2"
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
require "active_support"
require "minitest/autorun"
require "logger"


`createdb -O #{db_config[:username]} #{db_config[:database]}`

ActiveRecord::Base.establish_connection(db_config)
ActiveRecord::Base.logger = Logger.new(STDOUT)
