module GoodData::Bricks

  class ExecuteBrick < GoodData::Bricks::Brick

    def call(params)
      logger = params['GDC_LOGGER']
      metadata = params["metadata_wrapper"]
      salesforce_downloader = params["salesforce_downloader_wrapper"]
      raise Exception, "You need to specify ID of the downloader" if !params.include?("ID")
      metadata.set_source_context(params["ID"],{},salesforce_downloader)
      salesforce_downloader.connect
      entities =  metadata.get_downloader_entities_ids
      entities.each do |entity|
        salesforce_downloader.load_metadata(entity)
        salesforce_downloader.download_entity_data(entity)
      end
    end
  end
end