# Store only a SHA-256 digest of each API token so a database leak doesn't
# expose usable credentials. Existing plaintext tokens can't be converted,
# so they are deleted (there are no users yet).
class StoreApiTokenDigests < ActiveRecord::Migration[8.0]
  def change
    reversible { |dir| dir.up { execute "DELETE FROM api_tokens" } }

    remove_column :api_tokens, :token, :string
    remove_column :api_tokens, :name, :string
    remove_column :api_tokens, :metada, :jsonb

    add_column :api_tokens, :token_digest, :string, null: false
    add_index :api_tokens, :token_digest, unique: true
    change_column_null :api_tokens, :expires_at, false
  end
end
