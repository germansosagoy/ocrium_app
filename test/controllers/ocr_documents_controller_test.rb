require "test_helper"

class OcrDocumentsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get ocr_documents_create_url
    assert_response :success
  end

  test "should get show" do
    get ocr_documents_show_url
    assert_response :success
  end
end
