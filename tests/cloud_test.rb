require_relative 'test_helper.rb'

class CloudTest < Test::Unit::TestCase
  DROPBOX_ROOT = DROPBOX_SPACE_ROOT
  def setup

  end

  def teardown

  end

  def test_is_remote_or_local
      assert_false  Cloud.remote?(File.join(LOCAL_STORAGE,'Test','file.txt'))
      assert_true   Cloud.remote?(File.join(CLOUD_DROPBOX,'Test','file.txt'))
  end

  def test_remote_operations
    tmp_path = File.expand_path("../fixtures/duck.jpg", __FILE__)
    output_1 = File.join(CLOUD_DROPBOX,"duck-go.jpg")
    output_2 = File.join(CLOUD_DROPBOX,"duck-go-away.jpg")
    output_3 = File.join(CLOUD_DROPBOX,"duck-go-back.jpg")

    assert_equal 99445, Cloud.upload(tmp_path,output_1)['bytes']
    assert_not_nil Cloud.mv(output_1, output_2)
    assert_not_nil Cloud.cp(output_2, output_3)
    assert_nil Cloud.find(output_1)
    assert_equal 99445, Cloud.find(output_3)['bytes']
    assert_equal 99445, Cloud.find(output_2)['bytes']
    assert_equal true, Cloud.rm(File.join(CLOUD_DROPBOX))['is_deleted']
  end

  def test_local_operations
    tmp_path = File.expand_path("../fixtures/duck.jpg", __FILE__)
    output_1 = File.join(LOCAL_STORAGE,"duck-go.jpg")
    output_2 = File.join(LOCAL_STORAGE,"duck-go-away.jpg")
    output_3 = File.join(LOCAL_STORAGE,"duck-go-back.jpg")

    assert_equal 99445, Cloud.upload(tmp_path,output_1)['bytes']
    assert_not_nil Cloud.mv(output_1, output_2)
    assert_not_nil Cloud.cp(output_2, output_3)
    assert_nil Cloud.find(output_1)
    assert_equal 99445, Cloud.find(output_3)['bytes']
    assert_equal 99445, Cloud.find(output_2)['bytes']
    assert_equal true, Cloud.rm(File.join(LOCAL_STORAGE))['is_deleted']
  end

  def test_local_vs_remote
    tmp_path = File.expand_path("../fixtures/duck.jpg", __FILE__)

    output_1 = File.join(LOCAL_STORAGE,"duck-go.jpg")
    output_2 = File.join(CLOUD_DROPBOX,"duck-go-away.jpg")
    output_3 = File.join(LOCAL_STORAGE,"duck-go-back.jpg")


    assert_equal 99445, Cloud.upload(tmp_path,output_1)['bytes']
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
