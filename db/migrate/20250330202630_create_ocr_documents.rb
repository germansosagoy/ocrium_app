class CreateOcrDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :ocr_documents do |t|
      t.string :file
      t.text :extracted_text

      t.timestamps
    end
  end
end
