require 'singleton'

module QuickRecords
  class RecordStore < Hash
    include Singleton
    include ActiveSupport::Configurable
    config_accessor :lookup_logic

    class << self
      delegate :delete, to: :instance

      def clear
        [self, *subclasses].each { |store| store.instance.clear }
      end

      def reload!
        QuickRecords.with_reload_hook do
          [self, *subclasses].each do |store|
            # Making sure to not use a copy of the values since they
            # can be updated via duplicate records.
            store.instance.keys.each { |k| store.instance[k].reload! }
          end
        end
      end

      def reloaded
        RecordStore.subclasses.each do |store|
          store.instance.values.each(&:spoil)
        end
      end

      def update_record(new_record)
        return if new_record.nil?

        instance.transform_values! { |r| r.same_record?(new_record) ? new_record : r }
      end

      def [](scope)
        instance.fetch(scope.to_sql) do |sql|
          record = lookup_logic[scope] || break
          instance[sql] = record.extend(StoredRecord).spoil
        end
      end
    end
  end

  class RandomRecordStore < RecordStore
    self.lookup_logic = ->(scope) { scope.offset(rand(scope.count)).first }
  end

  class FirstRecordStore < RecordStore
    self.lookup_logic = ->(scope) { scope.first }
  end
end
