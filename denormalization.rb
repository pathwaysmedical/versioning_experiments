require_relative "setup"

########## MAIN ###############

ActiveRecord::Schema.define do
  create_table :entities, force: true do |t|
    t.string :_uuid
    t.string :_event

    t.string :content

    t.timestamps
  end
end
