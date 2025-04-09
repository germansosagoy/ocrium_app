class OcrProcessingJob < ApplicationJob
    queue_as :default

    def perform(ocr_document_id)
        ocr_document = OcrDocument.find_by(id: ocr_document_id)
        return unless ocr_document

        ocr_document.process_ocr

        #clasificar el doc automaticamente
        DocumentClassifierService.classify(ocr_document)

        #extraer las entidades
        ocr_document.extract_entities
    end
end