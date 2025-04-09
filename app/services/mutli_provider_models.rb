class MultiProviderModels
  def initialize
    @chat = RubyLLM.chat(model: "gpt-4o-mini") # pass the parameters here :)
  end

  def analyze_product(product)
    # Add a system prompt to give it context for better results.
    @chat.add_message role: :system, content: "You are a Product Hunt expert. Always include examples in your responses and explain them line by line."

    prompt = <<~PROMPT
      You are a product analyst expert specialized in evaluating digital products and services. 
      You have deep knowledge of market trends, user experience, and business models. 
      Your analysis should be structured, data-driven, and actionable.

      Here is a product to analyze: #{product}

      Please follow this process:
      1. Identify the key features and unique selling points
      2. Evaluate the market potential and target audience
      3. Analyze pricing strategy and business model
      4. Assess technical implementation and scalability
      5. Provide specific recommendations for improvement

      Format your response in clear sections with bullet points where appropriate. 
      Be concise but thorough in your analysis.
    PROMPT

    @chat.ask(prompt)
  end
end