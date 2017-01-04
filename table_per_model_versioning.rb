require_relative "activerecord_setup"

# iid = "immutable id"
# we reload the model every time so the iid gets returned
# TODO: how can we avoid this gotcha?

ActiveRecord::Schema.define do
  create_table :foos, force: true do |t|
    t.string :_iid
    t.string :_event

    t.string :content

    t.timestamps
  end

  execute "CREATE SEQUENCE foos_iid_seq;"
  execute "ALTER TABLE foos ALTER COLUMN _iid SET DEFAULT nextval('foos_iid_seq');"
end

class VersionedModel
  def initialize(model)
    @model = model
  end

  def create(args, iid = nil)
    params = args.merge(
      _event: "create",
    )

    params.merge(_iid: iid) unless iid.nil?


    @model.create(params).reload
  end

  def find(iid)
    all.find_by(_iid: iid)
  end

  def update(instance, args)
    @model.create(args.merge(
      _event: "update",
      _iid: instance._iid
    )).reload
  end

  def draft(args, instance = nil)
    params = args.merge(
      _event: "draft",
    )

    params = params.merge(_iid: instance._iid) unless instance.nil?

    @model.create(params).reload
  end

  def destroy(instance)
    # unlike the other event types, 'destroy' stores the model as it was
    # before the event

    @model.create(instance.attributes.except("created_at", "updated_at", "id").merge(
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
    @model.
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

    assert_equal(foo, Foo.find(foo._iid))
  end

  def test_update
    foo = Foo.create(
      content: "initial content"
    )

    updated_foo = Foo.update(
      foo,
      { content: "some updated content" }
    )

    assert_equal(updated_foo, Foo.find(updated_foo._iid))
  end

  def test_draft
    foo = Foo.create(
      content: "initial content"
    )
    drafted_foo = Foo.draft(
      { content: "some drafted content" },
      foo
    )
    assert_equal(foo, Foo.find(drafted_foo._iid))
  end

  def test_accept_draft
    drafted_foo = Foo.draft(
      { content: "some drafted content" }
    )

    accepted = Foo.accept(
      drafted_foo,
      drafted_foo.attributes.except("created_at", "updated_at", "id")
    )

    assert_equal(accepted, Foo.find(accepted._iid))
  end

  def test_destroy
    foo = Foo.create(
      content: "initial content"
    )
    Foo.destroy(foo)
    assert_equal(nil, Foo.find(foo._iid))
  end
end
