module Recurly
  class XML
    class << self
      def cast el
        return if el.attribute 'nil'

        if el.attribute 'type'
          type = el.attribute('type').value
        end

        case type
          when 'array'    then el.elements.map { |e| XML.cast e }
          when 'boolean'  then el.text == 'true'
          when 'date'     then Date.parse el.text
          when 'datetime' then DateTime.parse el.text
          when 'float'    then el.text.to_f
          when 'integer'  then el.text.to_i
        else
          # FIXME: Move some of this logic to Resource.from_xml?
          [el.name, type].each do |name|
            next unless name
            resource_name = Helper.classify name
            if Recurly.const_defined? resource_name, false
              return Recurly.const_get(resource_name, false).from_xml el
            end
          end
          if el.elements.empty?
            el.text
          else
            Hash[el.elements.map { |e| [e.name, XML.cast(e)] }]
          end
        end
      end

      def filter text
        xml = XML.new text
        xml.each do |el|
          el = XML.new el
          case el.name
          when "number"
            text = el.text.to_s
            last = text[-4, 4]
            el.text = "#{text[0, text.length - 4].to_s.gsub(/\d/, '*')}#{last}"
          when "verification_value"
            el.text = el.text.to_s.gsub(/\d/, '*')
          end
        end
        xml.to_s
      end
    end

    attr_reader :root

    def initialize xml
      @root = xml.is_a?(String) ? super : xml
    end

    # Adds an element to the root.
    def add_element name, value = nil
      value = value.respond_to?(:xmlschema) ? value.xmlschema : value.to_s
      XML.new super(name, value)
    end

    # Iterates over the root's elements.
    def each_element xpath = nil
      return enum_for :each_element unless block_given?
      super
    end

    # Returns the root's name.
    def name
      super
    end

    # Returns an XML string.
    def to_s
      super
    end
  end
end

if defined? Nokogiri
  if RUBY_VERSION < "2.1.0"
    raise <<-MSG

      You are attempting to use an insecure version of
      nokogiri on an insecure version of ruby. Please see
      the documentation on supported versions for more information:
      https://github.com/recurly/recurly-client-ruby#supported-versions

    MSG
  else
    require 'recurly/xml/nokogiri'
  end
else
  require 'recurly/xml/rexml'
end
