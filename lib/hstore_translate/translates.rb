module HstoreTranslate
  module Translates
    SUFFIX = "_translations".freeze

    def translates(*attrs)
      include InstanceMethods

      class_attribute :translated_attribute_names, :permitted_translated_attributes

      self.translated_attribute_names = attrs
      self.permitted_translated_attributes = [
        *self.ancestors
          .select {|klass| klass.respond_to?(:permitted_translated_attributes) }
          .map(&:permitted_translated_attributes),
        *attrs.product(I18n.available_locales)
          .map { |attribute, locale| :"#{attribute}_#{locale}" }
      ].flatten.compact

      attrs.each do |attr_name|
        serialize "#{attr_name}#{SUFFIX}", ActiveRecord::Coders::Hstore unless HstoreTranslate::native_hstore?

        define_method attr_name do
          read_hstore_translation(attr_name)
        end

        define_method "#{attr_name}=" do |value|
          write_hstore_translation(attr_name, value)
        end

        define_singleton_method "with_#{attr_name}_translation" do |value, locale = I18n.locale|
          quoted_translation_store = connection.quote_column_name("#{attr_name}#{SUFFIX}")
          where("#{quoted_translation_store} @> hstore(:locale, :value)", locale: locale, value: value)
        end
      end

      send(:prepend, ActiveRecordWithHstoreTranslate)
    end

    def translates?
      included_modules.include?(InstanceMethods)
    end
  end
end
