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
  gem "activesupport", "4.0.13"
end

require "active_record"
require "active_support"
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
    all.find_by(_uuid: uuid)
  end

  def update(instance, args)
    model.create(args.merge(
      _event: "update",
      _uuid: instance._uuid
    ))
  end

  def draft(instance, args)
    model.create(args.merge(
      _event: "draft",
      _uuid: instance._uuid
    ))
  end

  def destroy(instance)
    # unlike the other event types, 'destroy' stores the model as it was
    # before the event

    model.create(instance.attributes.except("created_at", "updated_at", "id").merge(
      _event: "destroy",
      _uuid: instance._uuid
    ))
  end

  def all
    scope = model.
      where("#{table_name}._uuid NOT IN (select _uuid from #{table_name} where _event = 'destroy')").
      where("#{table_name}._event != 'draft'")

    case ActiveRecord::Base.connection
    when ActiveRecord::ConnectionAdapters::SQLite3Adapter
      scope.group("#{table_name}._uuid").
        having("#{table_name}.created_at = MAX(#{table_name}.created_at)")
    when ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
      scope.select("DISTINCT ON(#{table_name}._uuid) *").
        order("#{table_name}._uuid, #{table_name}.created_at DESC")
    end
  end

  def table_name
    model.table_name
  end

  def method_missing(m, *args, &block)
    model.send(m, *args, &block)
  end
end

module VersionedModel
  def versioned
    @versioned ||= ModelVersioning.new(self)
  end
end

class Entity < ActiveRecord::Base
  extend VersionedModel
end

class VersioningTest < Minitest::Test
  def test_create
    entity = Entity.versioned.create(
      content: "initial content"
    )

    assert_equal(entity, Entity.versioned.find(entity._uuid))
  end

  def test_update
    entity = Entity.versioned.create(
      content: "initial content"
    )
    updated_entity = Entity.versioned.update(
      entity,
      { content: "some updated content" }
    )

    assert_equal(updated_entity, Entity.versioned.find(updated_entity._uuid))
  end

  def test_draft
    entity = Entity.versioned.create(
      content: "initial content"
    )
    drafted_entity = Entity.versioned.draft(
      entity,
      { content: "some drafted content" }
    )
    assert_equal(entity, Entity.versioned.find(drafted_entity._uuid))
  end

  def test_destroy
    entity = Entity.versioned.create(
      content: "initial content"
    )
    Entity.versioned.destroy(entity)
    assert_equal(nil, Entity.versioned.find(entity._uuid))
  end
end
