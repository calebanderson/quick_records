require 'quick_records/version'
require 'quick_records/interpreter'
require 'quick_records/record_store'
require 'quick_records/stored_record'
require 'quick_records/railtie'

module QuickRecords
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
    def clear
      RecordStore.clear
    end
    alias clear! clear

    def reload
      RecordStore.reload!
    end
    alias reload! reload

    def with_reload_hook(&block)
      @reloading ? block.call : _with_reload_hook(&block)
    end

    private

    def _with_reload_hook
      @reloading = true
      yield
    ensure
      @reloading = false
      RecordStore.reloaded
    end
  end

  def clear_record_stores
    QuickRecords.clear
  end
  alias clear_stores clear_record_stores

  def reload_record_stores
    QuickRecords.reload
  end

  def method_missing(method_name, *args, &block)
    catch(:not_handled) do
      return QuickRecords::Interpreter.record_finder(method_name, &block)
    end
    super
  rescue => e
    e.backtrace.shift # Remove this from the backtrace
    raise e
  end

  def respond_to_missing?(method_name, *)
    return true if super
    return false unless [ID_HELPER_REGEX, GREEDY_KLASS_REGEX, GREEDY_ACTION_REGEX].any?(&method_name.method(:match))

    catch(:not_handled) do
      QuickRecords::Interpreter.record_finder(method_name)
      return true
    end
    false
  end
end
