class AddRawExtractedTextToOcrDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :ocr_documents, :raw_extracted_text, :text
    add_column :ocr_documents, :llm_metadata, :json
  end
end
