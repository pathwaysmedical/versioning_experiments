begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"
  # use 4.2 since it begins jsonb support

  gem "sequel", "~> 4.4"
  gem "pg"
  gem "minitest"
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


require "sequel"
require "logger"

`createdb -O #{db_config[:username]} #{db_config[:database]}`

DB = Sequel.connect(
  "postgres://"\
  "#{db_config[:username]}/"\
  "#{db_config[:password]}@"\
  "#{db_config[:host]}/"\
  "#{db_config[:database]}"
)

at_exit do
  DB.disconnect

  `dropdb #{db_config[:database]}`
end

require "minitest/autorun"


class SequelTest < MiniTest::Test
end
