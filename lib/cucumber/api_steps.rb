require 'jsonpath'

World(Rack::Test::Methods)

Given /^I send and accept (XML|JSON)$/ do |type|
  page.driver.header 'Accept', "text/#{type.downcase}"
  page.driver.header 'Content-Type', "text/#{type.downcase}"
end

When /^I authenticate as the user "([^"]*)" with the password "([^"]*)"$/ do |user, pass|
  page.driver.authorize(user, pass)
end

When /^I send a (GET|POST|PUT|DELETE) request (?:for|to) "([^"]*)" (?:with the following:)?$/ do |request_type, path, body|
  if body.present?
    page.driver.send(request_type.downcase.to_sym, path, body)
  else
    page.driver.send(request_type.downcase.to_sym, path)
  end
end

Then /^show me the response$/ do
  p page.driver.last_response
end

Then /^the response status should be "([^"]*)"$/ do |status|
  if page.respond_to? :should
    page.driver.last_response.status.should == status.to_i
  else
    assert_equal status.to_i, page.driver.last_response.status
  end
end

Then /^the JSON response should (not)?\s?have "([^"]*)" with the text "([^"]*)"$/ do |negative, json_path, text|
  json    = JSON.parse(page.driver.last_response.body)
  results = JsonPath.new(json_path).on(json).to_a.map(&:to_s)
  if page.respond_to?(:should)
    if negative.present?
      results.should_not include(text)
    else
      results.should include(text)
    end
  else
    if negative.present?
      assert !results.include?(text)
    else
      assert results.include?(text)
    end
  end
end

Then /^the XML response should have "([^"]*)" with the text "([^"]*)"$/ do |xpath, text|
  parsed_response = Nokogiri::XML(last_response.body)
  elements = parsed_response.xpath(xpath)
  if page.respond_to?(:should)
    elements.should_not be_empty, "could not find #{xpath} in:\n#{last_response.body}"
    elements.find { |e| e.text == text }.should_not be_nil, "found elements but could not find #{text} in:\n#{elements.inspect}"
  else
    assert !elements.empty?, "could not find #{xpath} in:\n#{last_response.body}"
    assert elements.find { |e| e.text == text }, "found elements but could not find #{text} in:\n#{elements.inspect}"
  end
end
