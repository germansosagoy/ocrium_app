class OcrDocument < ApplicationRecord
    has_one_attached :file # asociamos ActiveStorage para el manejo de archivos

    # método para procesar el archivo OCR después de que se guarda el documento
    def process_ocr
      return unless file.attached?

      begin
        Rails.logger.info "Iniciando procesamiento OCR para el archivo: #{file.filename}"
        # obtener la ruta temporal del archivo
        file_path = ActiveStorage::Blob.service.send(:path_for, file.key)
        Rails.logger.info "Ruta del archivo: #{file_path}"
        # chequear si el archivo existe
        unless File.exist?(file_path)
          Rails.logger.error "El archivo no existe en la ruta especificada"
          return
        end

        # hashparámetros de Tesseract para mejor reconocimiento
        options = {
          lang: 'spa+eng',
          psm: 6, 
          oem: 3, 
        }

        # crear instancia de Rtesseract con la ruta del archivo y opciones
        image = RTesseract.new(file_path, options)
        extracted_text = image.to_s.strip
        
        Rails.logger.info "Texto extraído: #{extracted_text.truncate(100)}"
        
        if extracted_text.present?
          self.raw_extracted_text = extracted_text
          
          # 2. acá corregimos el texto con RubyLLM
          corrected_text = correct_ocr_text(extracted_text)
          
          # 3. analizar el texto corregido
          description = analyze_text(corrected_text)
          
          # 4. actualizar el documento
          update(
            raw_extracted_text: extracted_text,
            extracted_text: corrected_text, 
            description: description
          )
        else
          Rails.logger.warn "No se pudo extraer texto del documento"
          update(
            extracted_text: "No se pudo extraer texto del documento", 
            description: "No se pudo analizar el documento"
          )
        end
      rescue => e
        Rails.logger.error "Error durante el procesamiento OCR: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        update(
          extracted_text: "Error durante el procesamiento OCR: #{e.message}", 
          description: "Error durante el análisis del documento"
        )
      end
    end

    def extract_entities
      return {} if extracted_text.blank?
      
      begin
        chat = RubyLLM.chat
        
        prompt = <<~PROMPT
          Extrae las siguientes entidades del texto OCR si están presentes:
          
          - nombres_personas: Lista de nombres de personas mencionadas
          - fechas: Todas las fechas en formato ISO (YYYY-MM-DD) cuando sea posible
          - numeros_telefonicos: Números telefónicos detectados
          - correos_electronicos: Direcciones de email
          - montos: Cantidades monetarias con su divisa
          - lugares: Referencias a lugares o direcciones
          
          Responde SOLO en formato JSON válido sin explicaciones adicionales. 
          Si una categoría no tiene valores, devuelve un array vacío para esa categoría.
          
          TEXTO:
          #{extracted_text}
        PROMPT
        
        chat.add_user_message(prompt)
        response = chat.complete
        
        # parsear la respuesta como JSON
        begin
          entities = JSON.parse(response.content)
          # guardar entidades en el campo de la metadata
          self.llm_metadata ||= {}
          self.llm_metadata["extracted_entities"] = entities
          self.save
          
          entities
        rescue JSON::ParserError => e
          Rails.logger.error "Error al parsear la respuesta JSON: #{e.message}"
          {}
        end
      rescue => e
        Rails.logger.error "Error extrayendo entidades: #{e.message}"
        {}
      end
    end

    def correct_ocr_text(text)
      return text if text.blank?
      
      begin
        chat = RubyLLM.chat
        
        prompt = <<~PROMPT
          Eres un especialista en corregir errores comunes de OCR.
          
          Corrige el siguiente texto extraído mediante OCR. Arregla:
          1. Errores ortográficos evidentes
          2. Caracteres mal reconocidos (como '0' por 'O', '1' por 'I', etc.)
          3. Palabras juntas o separadas incorrectamente
          4. Formato y puntuación
          
          Mantén el mismo significado y estructura. No añadas información que no esté presente.
          
          TEXTO OCR:
          #{text}
        PROMPT
        
        chat.add_user_message(prompt)
        response = chat.complete
        
        response.content
      rescue => e
        Rails.logger.error "Error corrigiendo texto OCR: #{e.message}"
        text 
      end
    end

    private

    def analyze_text(text)
      lines = text.split("\n").map(&:strip).reject(&:empty?)
      analysis = []
      
      # buscar el nombre
      if lines.first.present?
        analysis << "Nombre: #{lines.first}"
      end
      
      # buscar ubicacion 
      location_line = lines.find { |line| line.match?(/(calle|avenida|ciudad|dirección|address|street|city)/i) }
      if location_line
        analysis << "Ubicación: #{location_line}"
      end
      
      # buscar títulos o roles
      role_line = lines.find { |line| line.match?(/(desarrollador|ingeniero|developer|engineer|analista|analyst)/i) }
      if role_line
        analysis << "Rol/Título: #{role_line}"
      end
      
      # buscar experiencia
      experience_line = lines.find { |line| line.match?(/(\d+\s*años|\d+\s*years|experience|experiencia)/i) }
      if experience_line
        analysis << "Experiencia: #{experience_line}"
      end
      
      # si no se encontró información especifica, generar un resumen
      if analysis.empty?
        summary = lines.first(3).join("\n")
        analysis << "Resumen: #{summary}"
      end
      
      analysis.join("\n\n")
    end
end
