module Fog
  module Cloud
    # Base module for common methods
    module Base
      def data_attr(data)
        ::JSON.parse(data.to_json)
      end
    end
  end
end
