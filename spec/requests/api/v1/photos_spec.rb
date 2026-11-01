require "rails_helper"

RSpec.describe "API recipe photos", type: :request do
  let(:user) { create(:user) }
  let(:headers) { {Authorization: "Bearer #{create(:session, user: user).token}"} }
  let(:photo) { file_fixture("photo.png").binread }

  def blob_params(content_type: "image/png", byte_size: photo.bytesize)
    {blob: {filename: "photo.png", byte_size: byte_size, checksum: Digest::MD5.base64digest(photo), content_type: content_type}}
  end

  # Runs the client's two upload steps and returns the blob's signed_id.
  def upload_photo(as: headers)
    post api_v1_direct_uploads_path, params: blob_params, headers: as, as: :json
    expect(response).to have_http_status(:created)
    signed_id, direct_upload = response.parsed_body.values_at("signed_id", "direct_upload")

    put direct_upload["url"], params: photo, headers: direct_upload["headers"]
    expect(response).to have_http_status(:no_content)
    signed_id
  end

  describe "POST /api/v1/direct_uploads" do
    it "requires authentication" do
      post api_v1_direct_uploads_path, params: blob_params, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns a signed id and upload instructions, recording the uploader" do
      post api_v1_direct_uploads_path, params: blob_params, headers: headers, as: :json

      body = response.parsed_body
      expect(body["signed_id"]).to be_present
      expect(body["direct_upload"]["url"]).to include("/rails/active_storage/disk/")
      expect(body["direct_upload"]["headers"]).to include("Content-Type" => "image/png")
      expect(ActiveStorage::Blob.find_signed(body["signed_id"]).metadata["uploader_id"]).to eq(user.id)
    end

    it "rejects unsupported types and oversized files" do
      post api_v1_direct_uploads_path, headers: headers, as: :json,
        params: blob_params(content_type: "application/pdf", byte_size: Recipe::PHOTO_MAX_BYTES + 1)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"].keys).to contain_exactly("content_type", "byte_size")
      expect(ActiveStorage::Blob.count).to eq(0)
    end
  end

  describe "attaching to a recipe" do
    it "creates a recipe with a photo" do
      signed_id = upload_photo
      post api_v1_recipes_path, params: {recipe: {title: "Toast", servings: 1, photo: signed_id}}, headers: headers, as: :json

      expect(response).to have_http_status(:created)
      photo_json = response.parsed_body["photo"]
      expect(photo_json["thumbnail_url"]).to include("/rails/active_storage/representations/")
      expect(photo_json["url"]).to include("/rails/active_storage/representations/")
    end

    it "shows photos to other users" do
      recipe = create(:recipe, user: user)
      patch api_v1_recipe_path(recipe), params: {recipe: {photo: upload_photo}}, headers: headers, as: :json

      get api_v1_recipes_path, headers: {Authorization: "Bearer #{create(:session).token}"}
      expect(response.parsed_body["recipes"].first["photo"]).to include("thumbnail_url", "url")
    end

    it "replaces and removes a photo" do
      recipe = create(:recipe, user: user)
      patch api_v1_recipe_path(recipe), params: {recipe: {photo: upload_photo}}, headers: headers, as: :json
      first_blob = recipe.reload.photo.blob

      patch api_v1_recipe_path(recipe), params: {recipe: {photo: upload_photo}}, headers: headers, as: :json
      expect(recipe.reload.photo.blob).not_to eq(first_blob)

      patch api_v1_recipe_path(recipe), params: {recipe: {photo: nil}}, headers: headers, as: :json
      expect(response.parsed_body["photo"]).to be_nil
      expect(recipe.reload.photo).not_to be_attached
    end

    it "keeps the photo when it isn't sent" do
      recipe = create(:recipe, user: user)
      patch api_v1_recipe_path(recipe), params: {recipe: {photo: upload_photo}}, headers: headers, as: :json
      patch api_v1_recipe_path(recipe), params: {recipe: {title: "Renamed"}}, headers: headers, as: :json
      expect(recipe.reload.photo).to be_attached
    end

    it "accepts re-sending the recipe's current photo" do
      recipe = create(:recipe, user: user)
      signed_id = upload_photo
      patch api_v1_recipe_path(recipe), params: {recipe: {photo: signed_id}}, headers: headers, as: :json
      patch api_v1_recipe_path(recipe), params: {recipe: {photo: signed_id}}, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
    end

    it "rejects another user's upload" do
      someone_elses = upload_photo(as: {Authorization: "Bearer #{create(:session).token}"})
      post api_v1_recipes_path, params: {recipe: {title: "Toast", servings: 1, photo: someone_elses}}, headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to eq("errors" => {"photo" => ["is invalid"]})
      expect(Recipe.count).to eq(0)
    end

    it "rejects a photo already attached to another recipe" do
      signed_id = upload_photo
      first = create(:recipe, user: user)
      patch api_v1_recipe_path(first), params: {recipe: {photo: signed_id}}, headers: headers, as: :json

      second = create(:recipe, user: user)
      patch api_v1_recipe_path(second), params: {recipe: {photo: signed_id}}, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(second.reload.photo).not_to be_attached
    end

    it "rejects an invalid signed id" do
      post api_v1_recipes_path, params: {recipe: {title: "Toast", servings: 1, photo: "nonsense"}}, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to eq("errors" => {"photo" => ["is invalid"]})
    end
  end
end
