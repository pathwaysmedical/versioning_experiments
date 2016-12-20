require_relative "setup"

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

  def create(args, uuid = SecureRandom.uuid)
    model.create(args.merge(
      _event: "create",
      _uuid: uuid
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

  def draft(args, instance = nil)
    model.create(args.merge(
      _event: "draft",
      _uuid: (instance.nil? ? SecureRandom.uuid : instance._uuid)
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

  def accept(draft, args)
    existing_instance = find(draft._uuid)

    if existing_instance.nil?
      create(args, draft._uuid)
    else
      update(existing_instance, args)
    end
  end

  def all
    model.
      where(
        "#{table_name}._uuid NOT IN (SELECT _uuid FROM #{table_name} "\
        "WHERE #{table_name}._event = 'destroy')"
      ).joins(
        "LEFT JOIN (SELECT DISTINCT ON(_uuid) _uuid, id FROM #{table_name} "\
        "WHERE #{table_name}._event != 'draft' "\
        "ORDER BY #{table_name}._uuid, #{table_name}.created_at DESC) "\
        " AS t1 ON t1.id = #{table_name}.id"
      )
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
      { content: "some drafted content" },
      entity
    )
    assert_equal(entity, Entity.versioned.find(drafted_entity._uuid))
  end

  def test_accept_draft
    drafted_entity = Entity.versioned.draft(
      { content: "some drafted content" }
    )

    accepted = Entity.versioned.accept(
      drafted_entity,
      drafted_entity.attributes.except("created_at", "updated_at", "id")
    )

    assert_equal(accepted, Entity.versioned.find(accepted._uuid))
  end

  def test_destroy
    entity = Entity.versioned.create(
      content: "initial content"
    )
    Entity.versioned.destroy(entity)
    assert_equal(nil, Entity.versioned.find(entity._uuid))
  end
end
