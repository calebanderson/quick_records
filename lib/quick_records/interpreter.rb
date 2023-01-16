module QuickRecords
  module Interpreter
    ID_HELPER_REGEX = /^(?<klass>\w+?)_?(?<id>\d+)$/.freeze
    RANDOM_ACTION = /^rand(om)?|roll$/.freeze
    RESET_RANDOM_ACTION = /^rerand(om)?|reroll$/.freeze

    GREEDY_ACTION_REGEX = %r{
      ^(?:(?<klass>\w+?)_?
      (?<action>first|last|(?:re)?(?:roll|rand(?:om)?))
      |\g<action>_?\g<klass>)$
    }x.freeze
    GREEDY_KLASS_REGEX = %r{
      ^(?:(?<klass>\w+)_?
      (?<action>first|last|(?:re)?(?:roll|rand(?:om)??))
      |\g<action>_?\g<klass>)$
    }x.freeze

    class << self
      delegate :[], :[]=, to: :custom_model_map

      def custom_model_map
        @custom_model_map ||= {}
      end

      def record_finder(method_name, &block)
        klass, action_or_id = parse_finder_method(method_name)
        scope = block_given? ? klass.instance_exec(&block) : klass.all
        find_record(scope, action_or_id)
      end

      def parse_finder_method(method_name)
        [ID_HELPER_REGEX, GREEDY_KLASS_REGEX, GREEDY_ACTION_REGEX].lazy.map do |regex|
          klass_name, action_or_id = method_name.match(regex)&.captures || next
          klass = finder_klass(klass_name.to_s) || finder_klass(klass_name.to_s.remove('_')) || next
          [klass, action_or_id]
        end.find(&:itself) || throw(:not_handled)
      end

      def finder_klass(klass_name)
        klass_name.classify.safe_constantize || klass_mapping.find do |k, _|
          k === klass_name.remove('_') # rubocop:disable Style/CaseEquality
        end&.last&.classify&.safe_constantize
      end

      def klass_mapping
        model_files = Dir['**/*.rb', base: 'app/models']
        model_hash = model_files.map { |f| f.delete_suffix('.rb') }.index_by(&:itself)
        # Custom keys come first and will not be overwritten
        file_map(custom_model_map).merge(file_map(model_hash)) { |_key, old, _new| old }
      end

      # Takes file paths and removes underscores and slashes to give namespaced and
      # non-namespaced versions of the filenames (and usually the classes they define)
      def file_map(hash)
        hash = hash.dup
        regex_map = hash.extract!(*hash.keys.select { |k| k.is_a?(Regexp) })
        full_name_map = hash.transform_keys { |m| m.to_s.remove('_', '/') }
        base_name_map = hash.transform_keys { |m| m.to_s.remove('_', %r{^.+/}) }

        regex_map.merge(full_name_map).merge(base_name_map)
      end

      def find_record(scope, action_or_id)
        case action_or_id
        when /^\d+$/ then FirstRecordStore[scope.where(id: action_or_id)]
        when 'first' then FirstRecordStore[scope]
        when 'last' then FirstRecordStore[scope.reverse_order]
        when RANDOM_ACTION then RandomRecordStore[scope]
        when RESET_RANDOM_ACTION
          RandomRecordStore.delete(scope.to_sql)
          RandomRecordStore[scope]
        end
      end
    end

    def method_missing(method_name, *args, &block)
      catch(:not_handled) do
        return QuickRecords::Interpreter.record_finder(method_name, &block)
      end
      super
    end

    def respond_to_missing?(method_name, *)
      [ID_HELPER_REGEX, GREEDY_KLASS_REGEX, GREEDY_ACTION_REGEX].any?(&method_name.method(:match?))
    end
  end
end
