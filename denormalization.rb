require_relative "setup"

########## MAIN ###############

ActiveRecord::Schema.define do
  create_table :foos, force: true do |t|
    t.jsonb :bar_links
    t.jsonb :bin_link

    t.timestamps
  end

  create_table :bars, force: true do |t|
    t.timestamps
  end

  create_table :bins, force: true do |t|
    t.timestamps
  end
end

module DenormalizedAssociations
  def denormalized_has_many(associated_table_name)
    define_method associated_table_name do
      associated_table_name.
        to_s.
        classify.
        constantize.
        where(id: send("#{associated_table_name.to_s.singularize}_links").keys)
    end

    define_method "#{associated_table_name.to_s.singularize}_ids" do
      send("#{associated_table_name.to_s.singularize}_links").keys.map(&:to_i)
    end
  end

  def denormalized_belongs_to(associated_instance_name)
    define_method associated_instance_name do
      associated_instance_name.
        to_s.
        classify.
        constantize.
        find(send("#{associated_instance_name}_link").keys.first.to_i)
    end

    define_method "#{associated_instance_name.to_s.singularize}_id" do
      send("#{associated_instance_name}_link").keys.first.to_i
    end
  end
end

class ActiveRecord::Base
  extend DenormalizedAssociations
end

class Foo < ActiveRecord::Base
  denormalized_has_many :bars
  denormalized_belongs_to :bin
end

class Bar < ActiveRecord::Base
end

class Bin < ActiveRecord::Base
end

class DenormalizationTest < Minitest::Test
  def test_has_many
    5.times do
      Bar.create
    end

    foo = Foo.create(
      bar_links: {
        "1" => { "fruit" => "banana" },
        "2" => { "fruit" => "orange" }
      }
    )

    assert_equal(foo.bars.map(&:id), [1, 2])
    assert_equal(foo.bar_ids, [1, 2])
  end

  def test_belongs_to
    5.times do
      Bin.create
    end

    foo = Foo.create(
      bin_link: {
        "2" => { "vegetable" => "carrot" },
      }
    )

    assert_equal(foo.bin, Bin.find(2))
    assert_equal(foo.bin_id, 2)
  end
end
