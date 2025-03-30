class OcrDocument < ApplicationRecord
    has_one_attached :file # asociamos ActiveStorage para el manejo de archivos

    # método para procesar el archivo OCR después de que se guarda el documento
    def process_ocr
      return unless file.attached? # verificar si el archivo está presente

      file_path = ActiveStorage::Blob.service.send(:path_for, file.key) # obtener la ruta del archivo
      image = RTesseract.new(file_path) # crear una instancia de RTesseract con la ruta del archivo
      image.to_s
    end
end
