require 'fileutils'

require_relative 'test_helper.rb'

class CloudTest < Test::Unit::TestCase
  DROPBOX_ROOT = DROPBOX_SPACE_ROOT
  def setup

  end

  def teardown

  end

  def test_is_remote_or_local
      assert_false  Cloud.remote?(File.join(LOCAL_STORAGE, 'Test', 'file.txt'))
      assert_true   Cloud.remote?(File.join(CLOUD_DROPBOX, 'Test', 'file.txt'))
  end

  def test_remote_operations
    input = File.expand_path("../fixtures/duck.jpg", __FILE__)

    output_1 = File.join(CLOUD_DROPBOX, "Test/duck-go.jpg")
    output_2 = File.join(CLOUD_DROPBOX, "Test/duck-go-away.jpg")
    output_3 = File.join(CLOUD_DROPBOX, "Test/duck-go-back.jpg")

    assert_equal 99445, Cloud.upload(input, output_1)['bytes']
    assert_not_nil Cloud.mv(output_1, output_2)
    assert_not_nil Cloud.cp(output_2, output_3)
    assert_nil Cloud.find(output_1)
    assert_equal 99445, Cloud.find(output_3)['bytes']
    assert_equal 99445, Cloud.find(output_2)['bytes']
    assert_equal true, Cloud.rm(File.join(CLOUD_DROPBOX, "Test"))['is_deleted']
  end

  def test_multithreaded_operations
    in_dir = File.expand_path("../fixtures", __FILE__)
    in_duck_jpg = File.join(in_dir, "duck.jpg")
    in_duck_png = File.join(in_dir, "duck.png")
    in_duck_psd = File.join(in_dir, "duck.psd") # Test large files

    test_dir = File.expand_path("../tmp", __FILE__)
    FileUtils.mkdir_p(test_dir)
    out1 = File.join(CLOUD_DROPBOX, "par/duck.jpg")
    out2 = File.join(CLOUD_DROPBOX, "par/duck.png")
    out3 = File.join(CLOUD_DROPBOX, "par/duck.psd")
    local1 = File.join(test_dir, "duck.jpg");
    local2 = File.join(test_dir, "duck.png");
    local3 = File.join(test_dir, "duck.psd");

    threads = []
    threads << Thread.new {
      assert_equal 99445, Cloud.upload(in_duck_jpg, out1)['bytes'];
      assert_equal 99445, Cloud.download(out1, local1)['bytes'];
    }
    threads << Thread.new {
      assert_equal 301579, Cloud.upload(in_duck_png, out2)['bytes'];
      assert_equal 301579, Cloud.download(out2, local2)['bytes'];
    }
    threads << Thread.new {
      assert_equal 1_598_534, Cloud.upload(in_duck_psd, out3)['bytes'];
      assert_equal 1_598_534, Cloud.download(out3, local3)['bytes'];
    }
    threads.each { |t| t.join }

    assert_true FileUtils.compare_file(in_duck_jpg, local1)
    assert_true FileUtils.compare_file(in_duck_png, local2)
    assert_true FileUtils.compare_file(in_duck_psd, local3)
    FileUtils.rm_rf(test_dir)
  end

  def test_local_operations
    tmp_path = File.expand_path("../fixtures/duck.jpg", __FILE__)
    output_1 = File.join(LOCAL_STORAGE, "duck-go.jpg")
    output_2 = File.join(LOCAL_STORAGE, "duck-go-away.jpg")
    output_3 = File.join(LOCAL_STORAGE, "duck-go-back.jpg")

    assert_equal 99445, Cloud.upload(tmp_path, output_1)['bytes']
    assert_not_nil Cloud.mv(output_1, output_2)
    assert_not_nil Cloud.cp(output_2, output_3)
    assert_nil Cloud.find(output_1)
    assert_equal 99445, Cloud.find(output_3)['bytes']
    assert_equal 99445, Cloud.find(output_2)['bytes']
    assert_equal true, Cloud.rm(File.join(LOCAL_STORAGE))['is_deleted']
  end

  def test_local_vs_remote
    tmp_path = File.expand_path("../fixtures/duck.jpg", __FILE__)

    output_1 = File.join(LOCAL_STORAGE, "duck-go.jpg")
    output_2 = File.join(CLOUD_DROPBOX, "duck-go-away.jpg")
    output_3 = File.join(LOCAL_STORAGE, "duck-go-back.jpg")


    assert_equal 99445, Cloud.upload(tmp_path, output_1)['bytes']
    assert_not_nil Cloud.mv(output_1, output_2)
    assert_not_nil Cloud.cp(output_2, output_3)
    assert_not_nil Cloud.mv(output_2, output_1)

    assert_nil Cloud.find(output_2)
    assert_equal 99445, Cloud.find(output_1)['bytes']
    assert_equal 99445, Cloud.find(output_3)['bytes']

    assert_equal true, Cloud.rm(File.join(CLOUD_DROPBOX))['is_deleted']
    assert_equal true, Cloud.rm(File.join(LOCAL_STORAGE))['is_deleted']
  end


end
