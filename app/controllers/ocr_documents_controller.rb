class OcrDocumentsController < ApplicationController
  def create
    doc = OcrDocument.new(file: params[:file]) # crea un nuevo OcrDocument con el archivo recibido

    if doc.save
      doc.proccess_ocr
      
      render json: {id: doc.id, status: "Procesando...", url: ocr_document_path(doc)} # envia el id del documento creado y la url para acceder al documento
    else
      render json: {error: "Error al guardar el documento"}, status: :unprocessable_entity
    end
  end

  def show
    doc = OcrDocument.find(params[:id]) # busca el documento por su id
    render json: {text: doc.extracted_text} # envia el texto extraido
  end
end
