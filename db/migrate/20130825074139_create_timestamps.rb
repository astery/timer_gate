class CreateTimestamps < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
    end

    create_table :doings do |t|
      t.belongs_to :user
      t.string :subject
    end

    create_table :timestamps do |t|
      t.belongs_to :doing
      t.datetime :started_at
      t.datetime :stopped_at
    end
  end

  def up
    User.create(name: "astery")
  end
end
