module HstoreTranslate
  module Translates
    module ActiveRecordWithHstoreTranslate
      def respond_to?(symbol, include_all = false)
        return true if parse_translated_attribute_accessor(symbol)
        super(symbol, include_all)
      end

      def method_missing(method_name, *args)
        translated_attr_name, locale, assigning = parse_translated_attribute_accessor(method_name)

        return super(method_name, *args) unless translated_attr_name

        if assigning
          write_hstore_translation(translated_attr_name, args.first, locale)
        else
          read_hstore_translation(translated_attr_name, locale)
        end
      end
    end
  end
end
