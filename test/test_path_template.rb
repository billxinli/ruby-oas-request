require "minitest/autorun"
require "oas_request"

class PathTemplateTest < Minitest::Test
  def test_path_templates
    assert_equal OASRequest::PathTemplate.template("/pets/{petId}", {}), "/pets/%7BpetId%7D"
    assert_equal OASRequest::PathTemplate.template("/pets/{petId}", {petId: "foo"}), "/pets/foo"
    assert_equal OASRequest::PathTemplate.template("/{entity}/{petId}", {entity: "pets", petId: "foo"}), "/pets/foo"
  end
end
