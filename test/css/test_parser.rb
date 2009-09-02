# -*- coding: utf-8 -*-

require "helper"

module CSSPool
  module CSS
    class TestParser < CSSPool::TestCase
      class MethodCatcher
        attr_reader :calls

        def initialize
          @calls = []
        end

        def method_missing name, *args
          @calls << [name, args]
        end
      end

      def setup
        super
        @doc = MethodCatcher.new
        @parser = Class.new(CSSPool::CSS::Tokenizer) {
          attr_accessor :document
          def initialize doc
            @document = doc
          end
        }.new(@doc)
      end

      def test_declaration_ident
        assert_decl 'background', ['red'], 'div { background: red; }'
        assert_decl 'background', %w{red green},'div { background: red green; }'
      end

      def test_ruleset_div_attribute_recurses
        assert_attribute 'div[a]:foo { }'
        assert_attribute 'div:foo[a] { }'
        assert_attribute 'div#foo[a] { }'
        assert_attribute 'div.foo[a] { }'
        assert_attribute 'div.foo[a] { }'
      end

      def test_additional_selectors_pseudo
        assert_additional_selector(
          { Selectors::PseudoClass => 'foo' }, ':foo { }')
        assert_additional_selector(
          { Selectors::PseudoClass => 'foo(' }, ':foo() { }')
        assert_additional_selector(
          { Selectors::PseudoClass => 'foo(' }, ':foo(a) { }')
      end

      def test_additional_selectors_id
        assert_additional_selector({ Selectors::Id => '#foo' }, '#foo { }')
      end

      def test_additional_selectors_class
        assert_additional_selector({ Selectors::Class => 'foo' }, '.foo { }')
      end

      def test_ruleset_multiple_selectors
        assert_attribute '.foo, bar, #baz { }'
        sels = args_for(:start_selector).first
        assert_equal 3, sels.length
        sels.each do |sel|
          assert_instance_of Selector, sel
        end
      end

      def test_ruleset_class_no_name
        assert_attribute '.foo { }'
      end

      def test_ruleset_id_no_name
        assert_attribute '#foo { }'
      end

      def test_ruleset_div_pseudo_function_with_arg
        assert_attribute 'div:foo(bar) { }'
      end

      def test_ruleset_div_pseudo_function
        assert_attribute 'div:foo() { }'
      end

      def test_ruleset_div_pseudo
        assert_attribute 'div:foo { }'
      end

      def test_ruleset_div_attribute_dashmatch_string
        assert_attribute 'div[a |= "b"] { }'
      end

      def test_ruleset_div_attribute_dashmatch_ident
        assert_attribute 'div[a |= b] { }'
      end

      def test_ruleset_div_attribute_includes_ident
        assert_attribute 'div[a ~= b] { }'
      end

      def test_ruleset_div_attribute_includes_string
        assert_attribute 'div[a ~= "b"] { }'
      end

      def test_ruleset_div_attribute_equals_string
        assert_attribute 'div[a = "b"] { }'
      end

      def test_ruleset_div_attribute_equals_ident
        assert_attribute 'div[a = b] { }'
      end

      def test_ruleset_div_attribute_exists
        assert_attribute 'div[a] { }'
      end

      def test_ruleset_div_class
        assert_attribute 'div.foo { }'
      end

      def test_ruleset_div_hash
        assert_attribute 'div#foo { }'
      end

      def test_ruleset_div
        assert_attribute 'div { }'
      end

      def test_ruleset_star
        assert_attribute '* { }'
      end

      {
        ' '   => :s,
        ' > ' => :>,
        ' + ' => :+
      }.each do |combo, sym|
        define_method(:"test_combo_#{sym}") do
          assert_attribute "div #{combo} p  a { }"

          sel = args_for(:start_selector).first.first
          assert_equal 3, sel.simple_selectors.length
          assert_equal [nil, sym, :s],
            sel.simple_selectors.map { |x| x.combinator }
        end
      end

      def test_import
        @parser.scan_str '@import "foo";'
        assert_equal [:import_style, [[], 'foo']], @doc.calls[1]
      end

      def test_import_medium
        @parser.scan_str '@import "foo" page;'
        assert_equal [:import_style, [['page'], 'foo']], @doc.calls[1]
      end

      def test_import_medium_multi
        @parser.scan_str '@import "foo" page, print;'
        assert_equal [:import_style, [['page', 'print'], 'foo']], @doc.calls[1]
      end

      def test_start_stop
        @parser.scan_str "@import 'foo';"
        assert_equal [:start_document, []], @doc.calls.first
        assert_equal [:end_document, []], @doc.calls.last
      end

      def test_charset
        @parser.scan_str '@charset "UTF-8";'
        assert_equal [:charset, ['UTF-8', {}]], @doc.calls[1]
      end

      def assert_attribute css
        @parser.document = MethodCatcher.new
        @parser.scan_str css
        assert_equal :start_selector, @parser.document.calls[1].first
        assert_equal :end_selector, @parser.document.calls[2].first
      end

      def assert_decl name, values, css
        @parser.document = MethodCatcher.new
        @parser.scan_str css
        assert_equal :start_selector, @parser.document.calls[1].first
        assert_equal :property, @parser.document.calls[2].first
        assert_equal :end_selector, @parser.document.calls[3].first

        property = @parser.document.calls[2][1]
        assert_equal name, property.first

        assert_equal values, property[1].map { |x| x.value }
      end

      def doc; @parser.document end
      def args_for s; doc.calls.find { |x| x.first == s }[1] end

      def assert_additional_selector things, css
        @parser.document = MethodCatcher.new
        @parser.scan_str css
        args = @parser.document.calls.find { |x|
          x.first == :start_selector
        }[1]

        ss = args.first.first.simple_selectors.first

        assert_equal things.keys.length, ss.additional_selectors.length
        things.each do |klass, name|
          assert_instance_of klass, ss.additional_selectors.first
          assert_equal name, ss.additional_selectors.first.name
        end
      end

    end
  end
end