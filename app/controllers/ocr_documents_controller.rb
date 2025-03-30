class OcrDocumentsController < ApplicationController
  # Deshabilitar la protección CSRF para las acciones de la API
  protect_from_forgery with: :null_session, only: [ :new, :create, :show ]

  def new
    @ocr_document = OcrDocument.new
  end

  def create
    @ocr_document = OcrDocument.new(document_params)

    if @ocr_document.save
      @ocr_document.process_ocr # Ejecutar OCR después de guardar
      redirect_to @ocr_document, notice: "El documento se subió y procesó correctamente."
    else
      render :new
    end
  end

  def show
    @ocr_document = OcrDocument.find(params[:id])
    @ocr_text = @ocr_document.extracted_text

    respond_to do |format|
      format.html # Para vistas HTML
      format.json { render json: { text: @ocr_text } } # Para API
    end
  end

  private

  def document_params
    params.require(:ocr_document).permit(:file)
  end
end
