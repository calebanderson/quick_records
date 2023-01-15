require "quick_records/version"
require "quick_records/interpreter"
require "quick_records/record_store"
require "quick_records/stored_record"
require "quick_records/railtie"

module QuickRecords
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
end
