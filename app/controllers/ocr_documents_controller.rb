class OcrDocumentsController < ApplicationController
  # Deshabilitar la protección CSRF para la API
  protect_from_forgery with: :null_session, only: [ :new, :create, :show ]

  def new
    @ocr_document = OcrDocument.new
  end

  def create
    @ocr_document = OcrDocument.new(document_params)

    if @ocr_document.save
      # procesar el OCR en segundo plano
      OcrProcessingJob.perform_later(@ocr_document.id)
      redirect_to @ocr_document, notice: "El documento se cargó correctamente y está siendo procesado."
    else
      render :new
    end
  end

  def show
    @ocr_document = OcrDocument.find(params[:id])
    @ocr_text = @ocr_document.extracted_text
    @raw_text = @ocr_document.raw_extracted_text
    
    # si no tiene categoría, clasificarlo
    if @ocr_document.category.blank?
      @category = DocumentClassifierService.classify(@ocr_document)
    else
      @category = @ocr_document.category
    end
    
    # obtener entidades extraídas o extraerlas si no existen
    @entities = @ocr_document.llm_metadata&.dig("extracted_entities")
    if @entities.blank?
      @entities = @ocr_document.extract_entities
    end
    
    respond_to do |format|
      format.html 
      format.json { 
        render json: { 
          text: @ocr_text, 
          raw_text: @raw_text,
          analysis: @ocr_document.description,
          category: @category,
          entities: @entities
        } 
      }
    end
  end

  def ask
    @ocr_document = OcrDocument.find(params[:id])
    question = params[:question]
    
    if question.blank?
      respond_to do |format|
        format.html { redirect_to @ocr_document, alert: "Por favor, ingresa una pregunta." }
        format.json { render json: { error: "Pregunta requerida" }, status: :bad_request }
      end
      return
    end
    
    chat = RubyLLM.chat
    
    context = <<~CONTEXT
      CONTENIDO DEL DOCUMENTO:
      #{@ocr_document.extracted_text}
      
      ANÁLISIS PREVIO:
      #{@ocr_document.description}
    CONTEXT
    
    chat.add_system_message("Eres un asistente especializado en responder preguntas sobre documentos escaneados. Usa solo la información proporcionada en el contexto. Si la respuesta no está en el contexto, indica que no puedes encontrar esa información.")
    chat.add_user_message("CONTEXTO: #{context}\n\nPREGUNTA: #{question}")
    
    response = chat.complete
    answer = response.content
    
    respond_to do |format|
      format.html {
        @question = question
        @answer = answer
        render :show
      }
      format.json { render json: { question: question, answer: answer } }
    end
  end

  private

  def document_params
    params.require(:ocr_document).permit(:title, :file)
  end
end
