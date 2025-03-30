class OcrDocument < ApplicationRecord
    has_one_attached :file #Asociamos active storage para el manejo de archivos
    after_commit :proccess_ocr, on: :create #llamamos a process_ocr despues de guardar

    def proccess_ocr 
        return unless file.attached? # verificar si el archivo está present

        file_path = ActiveStorage::Blob.service.send(:path_for, file.key) #obtener la ruta del archivo
        self.extracted_text = Tesseract::Document.new(file_path).text # extraer el texto del archivo usando Tesseract
        save # guardar el texto extraido en la base de datos
    end
end