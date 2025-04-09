class DocumentClassifierService
  CATEGORIES = [
    "CV/Currículum", 
    "Factura", 
    "Contrato", 
    "Formulario", 
    "Identificación personal",
    "Carta", 
    "Recibo", 
    "Informe", 
    "Otro"
  ]
  
  def self.classify(ocr_document)
    return "Sin clasificar" if ocr_document.extracted_text.blank?
    
    begin
      chat = RubyLLM.chat
      
      prompt = <<~PROMPT
        Clasifica el siguiente texto extraído por OCR en UNA de estas categorías:
        #{CATEGORIES.join(", ")}
        
        Responde SOLO con el nombre de la categoría, sin puntuación ni explicaciones adicionales.
        
        TEXTO:
        #{ocr_document.extracted_text.to_s.truncate(2000)}
      PROMPT
      
      chat.add_user_message(prompt)
      response = chat.complete
      
      category = response.content.strip
      
      # chequear que la categoria esté en nuestra lista
      if CATEGORIES.include?(category)
        ocr_document.update(category: category)
        category
      else
        ocr_document.update(category: "Otro")
        "Otro"
      end
    rescue => e
      Rails.logger.error "Error clasificando documento: #{e.message}"
      "Error de clasificación"
    end
  end
end
