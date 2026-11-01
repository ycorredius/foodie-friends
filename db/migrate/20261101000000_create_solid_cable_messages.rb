# Solid Cable shares the primary database (like Solid Cache), so its table is
# created by a regular migration. Replaces an older solid_cable_messages table
# that lacked the channel_hash column required by solid_cable 3.x.
class CreateSolidCableMessages < ActiveRecord::Migration[8.0]
  def up
    drop_table :solid_cable_messages, if_exists: true

    create_table :solid_cable_messages do |t|
      t.binary :channel, limit: 1024, null: false
      t.binary :payload, limit: 536870912, null: false
      t.datetime :created_at, null: false
      t.integer :channel_hash, limit: 8, null: false

      t.index :channel
      t.index :channel_hash
      t.index :created_at
    end
  end

  def down
    drop_table :solid_cable_messages
  end
end
