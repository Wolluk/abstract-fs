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

    output_1 = File.join(CLOUD_DROPBOX, "RemoteTest", "duck-go.jpg")
    output_2 = File.join(CLOUD_DROPBOX, "RemoteTest", "duck-go-away.jpg")
    output_3 = File.join(CLOUD_DROPBOX, "RemoteTest", "duck-go-back.jpg")

    assert_equal 99445, Cloud.upload(input, output_1)['bytes']
    assert_not_nil Cloud.mv(output_1, output_2)
    assert_not_nil Cloud.cp(output_2, output_3)
    assert_nil Cloud.find(output_1)
    assert_equal 99445, Cloud.find(output_3)['bytes']
    assert_equal 99445, Cloud.find(output_2)['bytes']
    assert_equal true, Cloud.rm(File.join(CLOUD_DROPBOX, "RemoteTest"))['is_deleted']
  end

  def test_multithreaded_operations
    thread_count = 100
    in_dir = File.expand_path("../fixtures", __FILE__)
    in_duck_jpg = File.join(in_dir, "duck.jpg")
    test_dir = File.expand_path("../fixtures/tmp", __FILE__)
    threads = []

    FileUtils.mkdir_p(test_dir)
    thread_count.times do |t|
      threads << Thread.new do
        out = File.join(CLOUD_DROPBOX, "par/duck-#{t}.jpg")
        local = File.join(test_dir, "duck-#{t}.jpg");
        assert_equal 99445, Cloud.upload(in_duck_jpg, out)['bytes']
        assert_equal 99445, Cloud.download(out, local)['bytes']
        assert_true FileUtils.compare_file(in_duck_jpg, local)
      end
    end
    threads.each { |t| t.join }
    FileUtils.rm_rf(test_dir)
  end

  def test_local_operations
    tmp_path = File.expand_path("../fixtures/duck.jpg", __FILE__)
    output_1 = File.join(LOCAL_STORAGE, "Local", "duck-go.jpg")
    output_2 = File.join(LOCAL_STORAGE, "Local", "duck-go-away.jpg")
    output_3 = File.join(LOCAL_STORAGE, "Local", "duck-go-back.jpg")

    assert_equal 99445, Cloud.upload(tmp_path, output_1)['bytes']
    assert_not_nil Cloud.mv(output_1, output_2)
    assert_not_nil Cloud.cp(output_2, output_3)
    assert_nil Cloud.find(output_1)
    assert_equal 99445, Cloud.find(output_3)['bytes']
    assert_equal 99445, Cloud.find(output_2)['bytes']
    assert_equal true, Cloud.rm(File.join(LOCAL_STORAGE, "Local"))['is_deleted']
  end

  def test_local_vs_remote
    tmp_path = File.expand_path("../fixtures/duck.jpg", __FILE__)

    output_1 = File.join(LOCAL_STORAGE, "LocalRemote", "duck-go.jpg")
    output_2 = File.join(CLOUD_DROPBOX, "LocalRemote", "duck-go-away.jpg")
    output_3 = File.join(LOCAL_STORAGE, "LocalRemote", "duck-go-back.jpg")


    assert_equal 99445, Cloud.upload(tmp_path, output_1)['bytes']
    assert_not_nil Cloud.mv(output_1, output_2)
    assert_not_nil Cloud.cp(output_2, output_3)
    assert_not_nil Cloud.mv(output_2, output_1)

    assert_nil Cloud.find(output_2)
    assert_equal 99445, Cloud.find(output_1)['bytes']
    assert_equal 99445, Cloud.find(output_3)['bytes']

    assert_equal true, Cloud.rm(File.join(CLOUD_DROPBOX, "LocalRemote"))['is_deleted']
    assert_equal true, Cloud.rm(File.join(LOCAL_STORAGE, "LocalRemote"))['is_deleted']
  end


end
