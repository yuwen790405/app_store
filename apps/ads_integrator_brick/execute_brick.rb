module GoodData::Bricks

  class ExecuteBrick < GoodData::Bricks::Brick

    def call(params)
      logger = params['GDC_LOGGER']
      metadata = params['metadata_wrapper']
      ads_wrapper = params['ads_storage_wrapper']
      raise Exception, "The schedule ID parameter need to be filled" if !params.include?("ID")
      metadata.set_integrator_context(params["ID"])
      ads_wrapper.connect
      # Lets check if the ADS gem is in batch mode or in entity mode
      integration_mode = ads_wrapper.get_mode
      if (integration_mode == :entity)
        entities = metadata.get_integrator_entities_ids
        entities.each do |entity_name|
          ads_wrapper.load_entity(entity_name)
        end
      elsif (integration_mode == :batch)
        batches = ads_wrapper.get_integration_batches
        batches.each do |batch_identification|
          ads_wrapper.load_batch(batch_identification)
        end
      else
        fail "Unknown integration mode"
      end
    end
  end
end