require "fluent/plugin/filter"
require 'json'

module Fluent
  module Plugin
    class RegexpSplitterFilter < Fluent::Plugin::Filter
      SEPERATOR = ".".freeze
      Fluent::Plugin.register_filter("regexp_splitter", self)

      config_param :regexp_key, :string, default: 'kubernetes.annotations.fluentdPattern'
      config_param :default_pattern, :string, default: '^(?<message>.*)$'
      config_param :default_key, :string, default: 'log'

      def filter(tag, time, record)
        if record.key?(@default_key) == false
          record
        else
          record=split_json(record)
          record=parse_pattern(record)
          record
        end
      end

      private
      def split_json record
        begin
          if record[@default_key].chr == "{"
            dict=JSON.parse(record[@default_key])
            record=record.merge(dict)
          end
        rescue
        end
        record
      end

      def parse_pattern record
        pattern_string=record.dig(*steps_from(@regexp_key))
        pattern=Regexp.new("#{pattern_string != nil ? "#{pattern_string}|" : ""}#{@default_pattern}")
        pattern.match(record[@default_key]).named_captures.merge(record)
      end

      def steps_from path
        path.split(SEPERATOR).collect{|step| "#{step}"}
      end
    end
  end
end
