# First step of attaching a photo: reserves a blob and returns where to upload
# its bytes. The client PUTs the file to direct_upload.url with
# direct_upload.headers, then sends signed_id as recipe[photo].
#
# The uploader's id is stored on the blob so only they can attach it.
class Api::V1::DirectUploadsController < Api::V1::BaseController
  include ActiveStorage::SetCurrent

  rate_limit to: 30, within: 1.minute, with: -> { render_rate_limited }

  def create
    attributes = params.expect(blob: [:filename, :byte_size, :checksum, :content_type])
    errors = upload_errors(attributes)
    return render json: {errors: errors}, status: :unprocessable_entity if errors.any?

    blob = ActiveStorage::Blob.create_before_direct_upload!(
      filename: attributes[:filename], byte_size: attributes[:byte_size].to_i, checksum: attributes[:checksum],
      content_type: attributes[:content_type], metadata: {uploader_id: Current.user.id}
    )
    render json: {
      signed_id: blob.signed_id,
      direct_upload: {url: blob.service_url_for_direct_upload, headers: blob.service_headers_for_direct_upload}
    }, status: :created
  end

  private

  def upload_errors(attributes)
    errors = {}
    errors[:filename] = ["can't be blank"] if attributes[:filename].blank?
    errors[:checksum] = ["can't be blank"] if attributes[:checksum].blank?
    unless attributes[:content_type].in?(Recipe::PHOTO_CONTENT_TYPES)
      errors[:content_type] = ["must be image/jpeg, image/png or image/webp"]
    end
    unless attributes[:byte_size].to_i.between?(1, Recipe::PHOTO_MAX_BYTES)
      errors[:byte_size] = ["must be between 1 byte and 10 MB"]
    end
    errors
  end
end
