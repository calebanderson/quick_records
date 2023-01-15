module QuickRecords
  class Railtie < ::Rails::Railtie
    config.after_initialize do
      Object.include(QuickRecords)

      ReloaderHooks.register(prepend: true, &QuickRecords.method(:reload))
    end
  end
end
