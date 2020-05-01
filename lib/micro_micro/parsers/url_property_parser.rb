module MicroMicro
  module Parsers
    class UrlPropertyParser < BasePropertyParser
      # @see microformats2 Parsing Specification section 1.3.2
      # @see http://microformats.org/wiki/microformats2-parsing#parsing_a_u-_property
      HTML_ATTRIBUTES_MAP = {
        'href'   => %w[a area link],
        'src'    => %w[audio iframe img source video],
        'poster' => %w[video],
        'data'   => %w[object]
      }.freeze

      # @see microformats2 Parsing Specification section 1.3.2
      # @see http://microformats.org/wiki/microformats2-parsing#parsing_a_u-_property
      EXTENDED_HTML_ATTRIBUTES_MAP = {
        'title' => %w[abbr],
        'value' => %w[data input]
      }.freeze

      # @see microformats2 Parsing Specification section 1.5
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

      # @return [String]
      def resolved_value
        @resolved_value ||= Absolutely.to_abs(base: node.document.url, relative: unresolved_value.strip)
      end

      # @return [String]
      def unresolved_value
        @unresolved_value ||= begin
          HTML_ATTRIBUTES_MAP.each do |attribute, names|
            return node[attribute] if names.include?(node.name) && node[attribute]
          end

          return value_class_pattern_parser.value if value_class_pattern_parser.value?

          EXTENDED_HTML_ATTRIBUTES_MAP.each do |attribute, names|
            return node[attribute] if names.include?(node.name) && node[attribute]
          end

          serialized_node.text
        end
      end

      # @return [MicroMicro::Parsers::ValueClassPatternParser]
      def value_class_pattern_parser
        @value_class_pattern_parser ||= ValueClassPatternParser.new(node)
      end
    end
  end
end
