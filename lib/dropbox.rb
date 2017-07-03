require 'dropbox_api'

require_relative 'filesys'

module Dropbox
  @@dbx_client = nil

  module_function

  extend CloudFileSysBase

  def filesys_type
    "DBX:".black.on_light_cyan
  end

  def client
    @@dbx_client ||= DropboxApi::Client.new(DROPBOX_TOKEN)
  end

  def account
    client.get_current_account.to_hash
  end

  def metadata_compat(orig)
    return nil if orig.nil?
    orig = orig.to_hash if orig.class != Hash
    orig["sharing_info"] = {} if orig["sharing_info"].nil?
    meta = {
      "size" => orig["size"], # Technically incorrect, size doesn't exist in v2
      "bytes" => orig["size"],
      "path" => orig["path_display"],
      "is_dir" => orig[".tag"] == "folder",
      "is_deleted" => orig[".tag"] == "deleted",
      "rev" => orig["rev"],
      "read_only" => orig["sharing_info"]["read_only"],
      "parent_shared_folder_id" => orig["sharing_info"]["parent_shared_folder_id"],
      "modifier" => orig["sharing_info"]["modified_by"]
      # hash, icon, root, mime_type don't exist
      # TODO: thumb_exists, photo_info, video_info, shared_folder
    }
    meta
  end

  # FIXME: broken, but is this even neccessary with the new API gem?
  def with_retry(&block)
#   tries ||= DROPBOX_NO_OF_RETRIES
    yield
# rescue StandardError => ex
#   if ex.http_response.is_a? Net::HTTPServiceUnavailable
#     sleep(DROPBOX_RETRY_DELAY + DROPBOX_NO_OF_RETRIES - tries)
#     retry unless (tries -= 1).zero?
#   else
#     raise ex
#   end
  end

  def download(dropbox_path, local_path)
    dropbox_path = normalize_path(dropbox_path)
    log_download(dropbox_path, local_path)
    contents = ""
    file = with_retry do
      contents = ""
      client.download dropbox_path do |chunk|
        contents << chunk
      end
    end
    metadata = file.to_hash
    FileUtils.mkdir_p(File.dirname(local_path))
    File.open(local_path, 'w') {|f| f.write(contents) }
    raise "File size mismatch" unless metadata['size'] == File.size(local_path)
    metadata_compat(metadata) # small change in API, we have confirmation here also that size match!
  rescue Exception => ex
    error "Download failed: %s." % ex.message
    nil
  end

  def upload(local_path, dropbox_path)
    dropbox_path = normalize_path(dropbox_path)
    log_upload(local_path, dropbox_path)
    commit = DropboxApi::Metadata::CommitInfo.new(
      "path" => dropbox_path,
      "mode" => :add # NOTE: Will not overwrite existing file if exists
    )
    cursor = nil
    File.open(local_path) do |f|
      chunk = f.read(16 * 1024)
      cursor = client.upload_session_start(chunk)
      # HACK: We have to keep the offset ourselves, as the lib doesn't in 1.3.2
      offset = chunk.bytesize
      while chunk = f.read(16 * 1024)
        cursor.instance_variable_set(:@offset, offset)
        client.upload_session_append_v2(cursor, chunk)
        offset += chunk.bytesize
      end
      cursor.instance_variable_set(:@offset, offset)
    end
    metadata_compat(client.upload_session_finish(cursor, commit))
  rescue Exception => ex
    error "Upload failed: %s." % ex.message
    nil
  end

  def normalize_path(path)
    path = path.join("/") if path.is_a? Array
    path = "/" + path if path[0] != '/'
    path
  end

  def find(dropbox_path)
    dropbox_path = normalize_path(dropbox_path)
    meta = with_retry do
      client.get_metadata(dropbox_path)
    end
    # return nil if meta && meta['is_deleted']
    metadata_compat(meta)
  rescue Exception
    nil
  end

  def cp(dropbox_src_path, dropbox_dst_path, overwrite = true)
    dropbox_src_path = normalize_path(dropbox_src_path)
    dropbox_dst_path = normalize_path(dropbox_dst_path)
    rm(dropbox_dst_path, false) if overwrite
    log_cp(dropbox_src_path, dropbox_dst_path)
    meta = with_retry do
      client.copy(dropbox_src_path, dropbox_dst_path)
    end
    metadata_compat(meta)
  rescue Exception => ex
    error "Copy failed: %s" % ex.message
    nil
  end

  def mv(dropbox_src_path, dropbox_dst_path, overwrite = true)
    dropbox_src_path = normalize_path(dropbox_src_path)
    dropbox_dst_path = normalize_path(dropbox_dst_path)
    rm(dropbox_dst_path, false) if overwrite
    log_mv(dropbox_src_path, dropbox_dst_path)
    meta = with_retry do
      client.move(dropbox_src_path, dropbox_dst_path)
    end
    metadata_compat(meta)
  rescue Exception => ex
    error "Move failed: %s." % ex.message
    nil
  end

  def rm(dropbox_path, notify_on_missing = false)
    dropbox_path = normalize_path(dropbox_path)
    log_rm(dropbox_path) unless notify_on_missing
    meta = with_retry do
      client.delete(dropbox_path)
    end
    meta = metadata_compat(meta)
    meta["is_deleted"] = true # tag is not set to deleted when returned here
    meta
  rescue Exception
    nil
  end

  # Direct link
  # FIXME
  def dl(dropbox_path)
    with_retry do
      client.media(dropbox_path)
    end
  rescue Exception => ex
    error "URL failed: %s." % ex.message
    nil
  end

  # Thumbnail of the image
  # FIXME
  def thb(dropbox_path, size)
    with_retry do
      client.get_thumbnail(dropbox_path, "size" => size)
    end
  rescue Exception => ex
    error "Thumbnail failed: %s." % ex.message
    nil
  end

  def mkdir(dropbox_path)
    meta = with_retry do
      client.create_folder(dropbox_path)
    end
    metadata_compat(meta)
  rescue Exception => ex
    error "Make dir failed: %s." % ex.message
    nil
  end
end
