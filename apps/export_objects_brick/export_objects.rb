module GoodData::Bricks

  class ExportObjectsBrick < GoodData::Bricks::Brick

    def version
      "0.0.1"
    end

    def call(params)

      uris = params["export_object_uris"]
      fail "You need to specify a uris to be downloaded. Since currently ruby executors do not support strucutured parameters it has to be a string in a format \"345,346,781\" Where the numbers are ids of the object to be exported. Either Reports or Dashboards" if uris.nil? || uris.empty?

      uris = uris.is_a?(String) ? uris.split(',').map {|id| Integer(id)} : uris
      objs = uris.map {|id| GoodData::MdObject[id]}
      exportables = objs.find_all {|obj| ["report", "projectDashboard"].include?(obj.raw_data.keys.first)}.map do |exportable|
        case exportable.raw_data.keys.first
        when "report"
          GoodData::Report.new(exportable.raw_data)
        when "projectDashboard"
          GoodData::Dashboard.new(exportable.raw_data)
        end
      end

      exportables.each do |exportable|
        if exportable.is_a?(GoodData::Report)
          path = exportable.obj_id
          File.open(path, 'w') do |f|
            f.write(exportable.export(:pdf))
            (params["gdc_files_to_upload"] ||= []) << {:path => path}
          end
        else
          num_of_tabs = exportable.tabs.length
          num_of_tabs.times do |i|
            path = "#{exportable.obj_id}_#{i}"
            File.open(path, 'w') do |f|
              f.write(exportable.export(:pdf, :tab => exportable.tabs_ids[i]))
              (params["gdc_files_to_upload"] ||= []) << {:path => path}
            end
          end
        end
      end
    end

  end
end
