require "helper"
require "fluent/plugin/filter_regexp_splitter.rb"
require "test/plugin/test_utilities.rb"

class RegexpSplitterFilterTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  test 'JSON' do
    d = create_driver(basic_config)
    time = event_time
    d.run do
      d.feed('filter.test', time, {
         "log"=>'{"log":"abc", "test":"test"}'
        })
    end

    assert_equal({
      "log"=>"abc",
      "message"=>"abc",
      "test"=>"test"
      }, d.filtered_records[0])
  end
end
