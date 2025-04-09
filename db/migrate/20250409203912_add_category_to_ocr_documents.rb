class AddCategoryToOcrDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :ocr_documents, :category, :string
  end
end
