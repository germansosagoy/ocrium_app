class AddDescriptionToOcrDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :ocr_documents, :description, :text
  end
end
