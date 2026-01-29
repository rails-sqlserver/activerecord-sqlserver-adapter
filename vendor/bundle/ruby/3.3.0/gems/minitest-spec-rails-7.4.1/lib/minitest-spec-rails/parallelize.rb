
# HACK: stolen and altered from https://github.com/blowmage/minitest-rails/pull/218/files
# Which was referenced in https://github.com/metaskills/minitest-spec-rails/issues/94

module MiniTestSpecRails
  ##
  # This module is a placeholder for all the Test classes created using the
  # spec DSL. Normally all classes are created but not assigned to a constant.
  # This module is where constants will be created for these classes.
  module SpecTests #:nodoc:
  end
end

module Kernel #:nodoc:
  alias describe_before_minitest_spec_constant_fix describe
  private :describe_before_minitest_spec_constant_fix
  def describe *args, &block
    cls = describe_before_minitest_spec_constant_fix(*args, &block)
    cls_const = "Test__#{cls.name.to_s.split(/\W/).reject(&:empty?).join('_'.freeze)}"
    if block.source_location
      source_path, line_num = block.source_location
      source_path = Pathname.new(File.expand_path(source_path)).relative_path_from(Rails.root).to_s
      source_path = source_path.split(/\W/).reject(&:empty?).join("_".freeze)
      cls_const += "__#{source_path}__#{line_num}"
    end
    cls_const += "_1" while MiniTestSpecRails::SpecTests.const_defined? cls_const
    MiniTestSpecRails::SpecTests.const_set cls_const, cls
    cls
  end
end
