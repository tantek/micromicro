module MicroMicro
  module Parsers
    class UrlPropertyParser < BasePropertyParser
      HTML_ATTRIBUTES_MAP = {
        'href'   => %w[a area link],
        'src'    => %w[audio iframe img source video],
        'poster' => %w[video],
        'data'   => %w[object]
      }.freeze

      EXTENDED_HTML_ATTRIBUTES_MAP = {
        'title' => %w[abbr],
        'value' => %w[data input]
      }.freeze

      # @see http://microformats.org/wiki/microformats2-parsing#parsing_a_u-_property
      # @see http://microformats.org/wiki/microformats2-parsing#parse_an_img_element_for_src_and_alt
      #
      # @return [String, Hash{Symbol => String}]
      def value
        @value ||= begin
          return resolved_value unless node.matches?('img[alt]')

          {
            value: resolved_value,
            alt: node['alt'].strip
          }
        end
      end

      private

      # @return [String, nil]
      def attribute_value
        self.class.attribute_value_from(node, HTML_ATTRIBUTES_MAP)
      end

      # @return [String, nil]
      def extended_attribute_value
        self.class.attribute_value_from(node, EXTENDED_HTML_ATTRIBUTES_MAP)
      end

      # @return [String]
      def resolved_value
        @resolved_value ||= Absolutely.to_abs(base: node.document.url, relative: unresolved_value.strip)
      end

      # @return [String]
      def unresolved_value
        attribute_value || value_class_pattern_value || extended_attribute_value || Document.text_content_from(node)
      end

      # @return [String, nil]
      def value_class_pattern_value
        ValueClassPatternParser.new(node).value
      end
    end
  end
end
