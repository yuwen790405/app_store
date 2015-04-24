# encoding: utf-8

module GoodData::Bricks
  class ExecuteBrick < GoodData::Bricks::Brick
    def call(params)
      logger = params['GDC_LOGGER']
      metadata = params["metadata_wrapper"]
      downloader = params["csv_downloader_wrapper"]
      raise Exception, "The schedule parameters must contain ID of the downloader" if !params.include?("ID")
      metadata.set_source_context(params["ID"], {}, downloader)
      downloader.connect
      downloader.load_data_structure_file
      downloader.number_of_manifest_in_one_run.times do |i|
        puts "Starting processing number #{i + 1}"
        downloader.load_last_unprocessed_manifest
        entities = metadata.get_downloader_entities_ids
        entities.each do |entity|
          downloader.load_metadata(entity)
          downloader.download_entity_data(entity)
        end
        previous_batch = downloader.finish_load
        if (!previous_batch.nil?)
          downloader.prepare_next_load(previous_batch)
        else
          break
        end
      end
    end
  end
end
