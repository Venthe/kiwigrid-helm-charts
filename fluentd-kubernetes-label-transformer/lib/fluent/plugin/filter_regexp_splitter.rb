require "fluent/plugin/filter"
require 'json'

module Fluent
  module Plugin
    class RegexpSplitterFilter < Fluent::Plugin::Filter
      SEPERATOR = ".".freeze
      Fluent::Plugin.register_filter("regexp_splitter", self)

      config_param :regexp_key, :string, default: 'kubernetes.annotations.fluentdPattern'
      config_param :rewrite_key, :string, default: 'kubernetes.annotations.fluentdRewrite'
      config_param :default_pattern, :string, default: '^(?<message>.*)$'
      config_param :default_key, :string, default: 'log'

      def filter(tag, time, record)
        if record.key?(@default_key) == false
          record
        else
          record=split_json(record)
          record=parse_pattern(record)
          record=rewrite_keys(record)
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

      def rewrite_keys record
        begin
          rewrite_string=record.dig(*steps_from(@rewrite_key))
          if not rewrite_string.nil? and not rewrite_string.empty?
            rewrite_array=rewrite_string.split(",").each do |it|
              actions = it.split(":")
              original_key=actions[0]
              new_key=actions[1]
              action=actions[2]
              if not action.nil? and not action.empty?
                if action.downcase == "l"
                  record[original_key]=record[original_key].downcase
                elsif action.downcase == "u"
                  record[original_key]=record[original_key].upcase
                else
                  raise "Unsupported transform"
                end
              end
              if not new_key.nil? and not new_key.empty?
                record[new_key]=record[original_key]
                record.delete(original_key)
              end
            end
          end
        rescue
        end
        record
      end

      def steps_from path
        path.split(SEPERATOR).collect{|step| "#{step}"}
      end
    end
  end
end
