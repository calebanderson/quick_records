return unless defined?(ActiveRecord)

module QuickRecords
  module Interpreter
    ID_HELPER_REGEX = /^(?<klass>\w+?)_?(?<id>\d+)$/.freeze
    GREEDY_ACTION_REGEX =
      /^(?:(?<klass>\w+?)_?(?<action>first|last|(?:re)?(?:roll|rand(?:om)?))|\g<action>_?\g<klass>)$/.freeze
    GREEDY_KLASS_REGEX =
      /^(?:(?<klass>\w+)_?(?<action>first|last|(?:re)?(?:roll|rand(?:om)??))|\g<action>_?\g<klass>)$/.freeze
    RANDOM_ACTION = /^rand(om)?|roll$/.freeze
    RESET_RANDOM_ACTION = /^rerand(om)?|reroll$/.freeze

    def record_finder(method_name, &block)
      klass, action_or_id = _parse_finder_method(method_name)
      scope = block_given? ? klass.instance_exec(&block) : klass.all
      _find_record scope, action_or_id
    end

    class << self
      delegate :[], to: :custom_model_map

      def custom_model_map
        @custom_model_map ||= {}
      end
    end

    def _parse_finder_method(method_name)
      [ID_HELPER_REGEX, GREEDY_KLASS_REGEX, GREEDY_ACTION_REGEX].lazy.map do |regex|
        klass_name, action_or_id = method_name.match(regex)&.captures || next
        klass = _finder_klass(klass_name.to_s) || _finder_klass(klass_name.to_s.remove('_')) || next
        [klass, action_or_id]
      end.select(&:itself).first || throw(:not_handled)
    end

    def _finder_klass(klass_name)
      klass_name.classify.safe_constantize || _klass_mapping.find do |k, _|
        k === klass_name.remove('_') # rubocop:disable Style/CaseEquality
      end&.last&.classify&.safe_constantize
    end

    def _klass_mapping
      model_files = Dir['**/*.rb', base: 'app/models'].map { |f| f.delete_suffix('.rb') }.index_by(&:itself)
      custom_map = QuickRecords::Interpreter.custom_model_map
      # Custom keys come first and will not be overwritten
      _klass_comparison_map(custom_map).merge(_klass_comparison_map(model_files)) { |_key, old, _new| old }
    end

    def _klass_comparison_map(hash)
      hash = hash.dup
      regex_map = hash.extract!(*hash.keys.select { |k| k.is_a?(Regexp) })
      full_name_map = hash.transform_keys { |m| m.to_s.remove('_', '/') }
      base_name_map = hash.transform_keys { |m| m.to_s.remove('_', %r{^.+/}) }

      regex_map.merge(full_name_map).merge(base_name_map)
    end

    def _find_record(scope, action_or_id)
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

    def method_missing(method_name, *args, &block)
      catch(:not_handled) { return record_finder(method_name, &block) }

      super
    end

    def respond_to_missing?(method_name, *)
      [ID_HELPER_REGEX, GREEDY_KLASS_REGEX, GREEDY_ACTION_REGEX].any?(&method_name.method(:match?))
    end
  end
end
