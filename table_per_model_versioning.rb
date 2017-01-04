require_relative "activerecord_setup"

# iid = "immutable id"
# we reload the model every time so the iid gets returned
# TODO: how can we avoid this gotcha?

ActiveRecord::Schema.define do
  create_table :entities, force: true do |t|
    t.string :_iid
    t.string :_event

    t.string :content

    t.timestamps
  end

  execute "CREATE SEQUENCE entities_iid_seq;"
  execute "ALTER TABLE entities ALTER COLUMN _iid SET DEFAULT nextval('entities_iid_seq');"
end

class ModelVersioning
  attr_reader :model

  def initialize(model)
    @model = model
  end

  def create(args, iid = nil)
    params = args.merge(
      _event: "create",
    )

    params.merge(_iid: iid) unless iid.nil?


    model.create(params).reload
  end

  def find(iid)
    all.find_by(_iid: iid)
  end

  def update(instance, args)
    model.create(args.merge(
      _event: "update",
      _iid: instance._iid
    )).reload
  end

  def draft(args, instance = nil)
    params = args.merge(
      _event: "draft",
    )

    params = params.merge(_iid: instance._iid) unless instance.nil?

    model.create(params).reload
  end

  def destroy(instance)
    # unlike the other event types, 'destroy' stores the model as it was
    # before the event

    model.create(instance.attributes.except("created_at", "updated_at", "id").merge(
      _event: "destroy",
      _iid: instance._iid
    )).reload
  end

  def accept(draft, args)
    existing_instance = find(draft._iid)

    if existing_instance.nil?
      create(args, draft._iid).reload
    else
      update(existing_instance, args).reload
    end
  end

  def all
    model.
      where(
        "#{table_name}._iid NOT IN (SELECT _iid FROM #{table_name} "\
        "WHERE #{table_name}._event = 'destroy')"
      ).joins(
        "LEFT JOIN (SELECT DISTINCT ON(_iid) _iid, id FROM #{table_name} "\
        "WHERE #{table_name}._event != 'draft' "\
        "ORDER BY #{table_name}._iid, #{table_name}.created_at DESC) "\
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
  def setup
    Entity.destroy_all
  end

  def test_create
    entity = Entity.versioned.create(
      content: "initial content"
    )

    assert_equal(entity, Entity.versioned.find(entity._iid))
  end

  def test_update
    entity = Entity.versioned.create(
      content: "initial content"
    )

    updated_entity = Entity.versioned.update(
      entity,
      { content: "some updated content" }
    )

    assert_equal(updated_entity, Entity.versioned.find(updated_entity._iid))
  end

  def test_draft
    entity = Entity.versioned.create(
      content: "initial content"
    )
    drafted_entity = Entity.versioned.draft(
      { content: "some drafted content" },
      entity
    )
    assert_equal(entity, Entity.versioned.find(drafted_entity._iid))
  end

  def test_accept_draft
    drafted_entity = Entity.versioned.draft(
      { content: "some drafted content" }
    )

    accepted = Entity.versioned.accept(
      drafted_entity,
      drafted_entity.attributes.except("created_at", "updated_at", "id")
    )

    assert_equal(accepted, Entity.versioned.find(accepted._iid))
  end

  def test_destroy
    entity = Entity.versioned.create(
      content: "initial content"
    )
    Entity.versioned.destroy(entity)
    assert_equal(nil, Entity.versioned.find(entity._iid))
  end
end
