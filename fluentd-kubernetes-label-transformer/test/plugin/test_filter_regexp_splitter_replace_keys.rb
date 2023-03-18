require "helper"
require "fluent/plugin/filter_regexp_splitter.rb"
require "test/plugin/test_utilities.rb"

class RegexpSplitterFilterTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  test 'Replace keys' do
    d = create_driver(basic_config)
    time = event_time
    d.run do
      d.feed('Replace keys', time, {
         "log"=>'{"level":"debug","ts":"2023-03-18T05:38:32.124Z","msg":"apply entry normal"}',
         "kubernetes" => {
          "annotations" => {
            "fluentdRewrite" => 'msg:message,level::u'
          }
         }
        })
    end

    assert_equal({
        "log"=>'{"level":"debug","ts":"2023-03-18T05:38:32.124Z","msg":"apply entry normal"}',
        "message"=>"apply entry normal",
        "level"=>"DEBUG",
        "ts"=>"2023-03-18T05:38:32.124Z",
          "kubernetes" => {
          "annotations" => {
            "fluentdRewrite" => 'msg:message,level::u'
          }
        }
      }, d.filtered_records[0])
  end
end
