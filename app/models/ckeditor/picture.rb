class Ckeditor::Picture < Ckeditor::Asset
  attr_accessor :data
  has_one_attached :storage_data

  validates :storage_data, file_content_type: { allow: /^image\/.*/ }, file_size: { less_than: 2.megabytes }

  def url_content
    url = root_url(ActionMailer::Base.default_url_options)
    "#{url}#{rails_representation_url(storage_data.variant(resize: "800>"), only_path: true)}"
  end

  def url_thumb
    rails_representation_url(storage_data.variant(resize: "118x100"), only_path: true)
  end
end
