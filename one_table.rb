begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"
  gem "activerecord", "4.0.13"
  gem "sqlite3"
end

require "active_record"
require "minitest/autorun"
require "logger"
require "securerandom"

# Ensure backward compatibility with Minitest 4
Minitest::Test = MiniTest::Unit::TestCase unless defined?(Minitest::Test)

# This connection will do for database-independent bug reports.
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :entities, force: true do |t|
    t.string :_uuid
    t.string :_event

    t.string :content

    t.timestamps
  end
end

class ModelVersioning
  attr_reader :model

  def initialize(model)
    @model = model
  end

  def create(args)
    model.create(args.merge(
      _event: "create",
      _uuid: SecureRandom.uuid
    ))
  end

  def find(uuid)
    model.order(:created_at).find_by(_uuid: uuid)
  end

  def update(uuid, args)
    model.create(args.merge(
      _event: "update",
      _uuid: uuid
    ))
  end

  def draft(uuid, args)
    model.create(args.merge(
      _event: "create",
      _uuid: SecureRandom.uuid
    ))
  end

  def method_missing(m, *args, &block)
    model.send(m, *args, &block)
  end

  def destroy(uuid)
    model.create(find(uuid).attributes.merge(
      _event: "destroy",
      _uui: uuid
    ))
  end

  def all
    # TODO:
    # get the latest version for each uuid
    # so long as it's not 'destroy'
  end
end

# class InstanceVersioning
#   attr_reader :instance
#
#   def initialize(instance)
#     @instance = instance
#   end
# end

class VersionedModel < ActiveRecord::Base
  def self.versioned
    ModelVersioning.new(self)
  end

  # def versioned
  #   @versioned = InstanceVersioning.new(self)
  # end
end

class Entity < VersionedModel
end

class VersioningTest < Minitest::Test
  def test_association_stuff
    Entity.versioned.create(
      content: "initial content"
    )

    # TODO
  end
end
