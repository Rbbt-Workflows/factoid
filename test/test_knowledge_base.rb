require File.expand_path(File.dirname(__FILE__) + '/test_helper')
require 'knowledge_base'

KnowledgeBase::KNOWLEDGE_BASE_DIR.replace Rbbt.tmp.knowledge_base.find(:user)

class TestKnowledgeBase < Test::Unit::TestCase
  def setup
    tmpfile = TmpFile.tmp_file
    @kb = KnowledgeBase.new :test
    @kb.directory = tmpfile
  end

  def teardown
    FileUtils.rm_rf @kb.directory
  end

  def test_add_integer
    @kb.define :test_integer, :integer

    assert_equal nil, @kb.test_integer

    @kb.set_test_integer 1

    assert_equal 1, @kb.test_integer
  end

  def test_add_array
    @kb.define :test_array, :array

    assert_equal nil, @kb.test_array

    @kb.set_test_array %w(a b)

    assert_equal %w(a b), @kb.test_array
  end

  def test_add_with_tag
    key1 = 'test_key'
    key2 = 'test_key2'
    @kb.define :test_key_array, :array

    assert_equal nil, @kb.test_key_array(key1)

    @kb.set_test_key_array key1, %w(a b)

    assert_equal %w(a b), @kb.test_key_array(key1)

    assert_equal nil, @kb.test_key_array(key2)

    @kb.set_test_key_array key2, %w(c d)

    assert_equal %w(c d), @kb.test_key_array(key2)
    assert_equal %w(a b), @kb.test_key_array(key1)

  end
end
