module MicroMicro
  class Property
    PROPERTY_PARSERS_MAP = {
      'dt' => Parsers::DateTimePropertyParser,
      'e'  => Parsers::EmbeddedMarkupPropertyParser,
      'p'  => Parsers::PlainTextPropertyParser,
      'u'  => Parsers::UrlPropertyParser
    }.freeze

    IMPLIED_PROPERTY_PARSERS_MAP = {
      'name'  => Parsers::ImpliedNamePropertyParser,
      'photo' => Parsers::ImpliedPhotoPropertyParser,
      'url'   => Parsers::ImpliedUrlPropertyParser
    }.freeze

    attr_reader :name, :prefix

    # @param node [Nokogiri::XML::Element]
    # @param context [Nokogiri::XML::Element]
    # @param name [String]
    # @param prefix [String<dt, e, p, u>]
    # @param implied [Boolean]
    def initialize(node, context = nil, name:, prefix:, implied: false)
      @node = node
      @context = context
      @name = name
      @prefix = prefix
      @implied = implied
    end

    # @return [Boolean]
    def implied?
      implied
    end

    # @return [Boolean]
    def item_node?
      @item_node ||= begin
        return false if implied?

        Item.item_node?(node)
      end
    end

    # @return [String, Hash, MicroMicro::Item]
    def value
      @value ||= begin
        return parser.value unless item_node?

        item.value = item_value

        item
      end
    end

    # @return [Boolean]
    def value?
      value.present?
    end

    # @param context [Nokogiri::XML::NodeSet, Nokogiri::XML::Element]
    # @param node_set [Nokogiri::XML::NodeSet]
    # @return [Nokogiri::XML::NodeSet]
    def self.nodes_from(context, node_set = Nokogiri::XML::NodeSet.new(context.document, []))
      context.each { |node| nodes_from(node, node_set) } if context.is_a?(Nokogiri::XML::NodeSet)

      if context.is_a?(Nokogiri::XML::Element) && !Document.ignore_node?(context)
        node_set << context if property_node?(context)

        nodes_from(context.element_children, node_set) unless Item.item_node?(context)
      end

      node_set
    end

    # @param node [Nokogiri::XML::Element]
    # @return [Boolean]
    def self.property_node?(node)
      types_from(node).any?
    end

    # @param node [Nokogiri::XML::Element]
    # @return [Array<Array(String, String)>]
    #
    # @example
    #   node = Nokogiri::HTML('<a href="https://sixtwothree.org" class="p-name u-url">Jason Garber</a>').at_css('a')
    #   MicroMicro::Property.types_from(node) #=> [['p', 'name'], ['u', 'url']]
    def self.types_from(node)
      node.classes.select { |token| token.match?(/^(?:dt|e|p|u)(?:\-[0-9a-z]+)?(?:\-[a-z]+)+$/) }.map { |token| token.split(/\-/, 2) }.uniq
    end

    private

    attr_reader :context, :implied, :node

    # @return [MicroMicro::Item, nil]
    def item
      @item ||= begin
        return unless item_node?

        Item.new(node)
      end
    end

    def item_value
      return unless item_node?

      obj_by_prefix = case prefix
                      when 'p' then item.properties.find_by(:name, 'name')
                      when 'e' then item
                      when 'u' then item.properties.find_by(:name, 'url')
                      end

      (obj_by_prefix || parser).value
    end

    def parser
      @parser ||= begin
        return IMPLIED_PROPERTY_PARSERS_MAP[name].new(node) if implied?

        PROPERTY_PARSERS_MAP[prefix].new(node, context)
      end
    end
  end
end