class AddTitleOcrDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :ocr_documents, :title, :string
  end
end
