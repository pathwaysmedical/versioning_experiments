require_relative "activerecord_setup"

# eid = "entity id"

# TODO: how to avoid reloading the model after create so the eid gets returned

ActiveRecord::Schema.define do
  create_table :foos, force: true do |t|
    t.string :_eid
    t.string :_event

    t.string :content

    t.timestamps
  end

  execute "CREATE SEQUENCE foos_eid_seq;"
  execute "ALTER TABLE foos ALTER COLUMN _eid SET DEFAULT nextval('foos_eid_seq');"
end

class VersionedModel
  def initialize(model)
    @model = model
  end

  def create(args, eid = nil)
    params = args.merge(
      _event: "create",
    )

    params.merge(_eid: eid) unless eid.nil?


    @model.create(params).reload
  end

  def find(eid)
    all.find_by(_eid: eid)
  end

  def update(instance, args)
    @model.create(args.merge(
      _event: "update",
      _eid: instance._eid
    )).reload
  end

  def draft(args, instance = nil)
    params = args.merge(
      _event: "draft",
    )

    params = params.merge(_eid: instance._eid) unless instance.nil?

    @model.create(params).reload
  end

  def destroy(instance)
    # unlike the other event types, 'destroy' stores the model as it was
    # before the event

    @model.create(instance.attributes.except("created_at", "updated_at", "id").merge(
      _event: "destroy",
      _eid: instance._eid
    )).reload
  end

  def accept(draft, args)
    existing_instance = find(draft._eid)

    if existing_instance.nil?
      create(args, draft._eid).reload
    else
      update(existing_instance, args).reload
    end
  end

  def all
    @model.
      where(
        "#{table_name}._eid NOT IN (SELECT _eid FROM #{table_name} "\
        "WHERE #{table_name}._event = 'destroy')"
      ).joins(
        "LEFT JOIN (SELECT DISTINCT ON(_eid) _eid, id FROM #{table_name} "\
        "WHERE #{table_name}._event != 'draft' "\
        "ORDER BY #{table_name}._eid, #{table_name}.created_at DESC) "\
        " AS t1 ON t1.id = #{table_name}.id"
      )
  end

  def table_name
    @model.table_name
  end

  def method_missing(m, *args, &block)
    @model.send(m, *args, &block)
  end
end

class FooVersion < ActiveRecord::Base
  self.table_name = "foos"
end

Foo = VersionedModel.new(FooVersion)

class VersioningTest < Minitest::Test
  def setup
    FooVersion.destroy_all
  end

  def test_create
    foo = Foo.create(
      content: "initial content"
    )

    assert_equal(foo, Foo.find(foo._eid))
  end

  def test_update
    foo = Foo.create(
      content: "initial content"
    )

    updated_foo = Foo.update(
      foo,
      { content: "some updated content" }
    )

    assert_equal(updated_foo, Foo.find(updated_foo._eid))
  end

  def test_draft
    foo = Foo.create(
      content: "initial content"
    )
    drafted_foo = Foo.draft(
      { content: "some drafted content" },
      foo
    )
    assert_equal(foo, Foo.find(drafted_foo._eid))
  end

  def test_accept_draft
    drafted_foo = Foo.draft(
      { content: "some drafted content" }
    )

    accepted = Foo.accept(
      drafted_foo,
      drafted_foo.attributes.except("created_at", "updated_at", "id")
    )

    assert_equal(accepted, Foo.find(accepted._eid))
  end

  def test_destroy
    foo = Foo.create(
      content: "initial content"
    )
    Foo.destroy(foo)
    assert_equal(nil, Foo.find(foo._eid))
  end
end
