module QuickRecords
  module StoredRecord
    def spoil
      @__spoiled__ = true
      self
    end

    def same_record?(other)
      return self == other if id.nil?

      id == other.id && self.class.name == other.class.name
    end

    def reload!(*)
      return self unless @__spoiled__

      QuickRecords.with_reload_hook do
        # Have to load a fresh version of the class to reflect any changes
        self.class.name.constantize.find_by(id: id)&.tap do |reloaded|
          reloaded.extend(StoredRecord)
          RecordStore.subclasses.each { |store| store.update_record(reloaded) }
        end
      end
    end
  end
end
