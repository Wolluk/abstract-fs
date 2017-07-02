require_relative 'filesys'

require 'mime/types'
# This is API implemetnation of local filsystem for dropbox like API
# LOCAL_STORAGE is a reference in the config file that tells where local files are storred
DBX_TIME_FORMAT = "%a, %d %b %Y %H:%M:%S %z"

module LocalFS
  module_function

  extend CloudFileSysBase

  def filesys_type
    "LFS:".light_cyan
  end

  def account
    { type: 'Local File System' }
  end

  def local2path(storage_path)
    normalize_path(File.join(DROPBOX_SPACE_ROOT, normalize_path(storage_path).gsub(/^#{normalize_path(LOCAL_STORAGE)}/i, '')))
  end

  def path2local(dropbox_path)
    File.join(LOCAL_STORAGE, normalize_path(dropbox_path).gsub(/^#{normalize_path(DROPBOX_SPACE_ROOT)}/i, ''))
  end

  def path2url(dropbox_path)
    File.join(LOCAL_STORAGE_URL,normalize_path(dropbox_path).gsub(/^#{normalize_path(DROPBOX_SPACE_ROOT)}/i, ''))
  end

  def file_metadata(dropbox_path)
    storage_path = path2local(dropbox_path)
    if File.exists?(storage_path)
      mime = MIME::Types.type_for(storage_path)
      mime = (mime.first.simplified if (mime && mime.first)) || ""
      meta = {
        'bytes' => File.size(storage_path),
        'read_only' => !File.writable?(storage_path),
        'path' => dropbox_path,
        'thumb_exists'=> false,
        'modified'=> File.mtime(storage_path).strftime(DBX_TIME_FORMAT),
        'size'=> File.size(storage_path),
        'is_dir'=> File.directory?(storage_path),
        'root'=> 'localfs',
        'mime_type'=> mime,
        'client_mtime' => File.mtime(storage_path).strftime(DBX_TIME_FORMAT),
        'craeted' => File.ctime(storage_path).strftime(DBX_TIME_FORMAT),
        'client_ctime' => File.ctime(storage_path).strftime(DBX_TIME_FORMAT),
      }

      meta['contents'] = []
      Dir.glob(File.join('storage_path','*')).each do |f|
        fm = file_metadata(File.join(dropbox_path, File.basename(f)))
        meta['contents'] << (fm)
      end if File.directory?(storage_path)

      meta
    else
      nil
    end
  end

  def download(dropbox_path,local_path)
    dropbox_path = normalize_path(dropbox_path)
    storage_path = path2local(dropbox_path)
    log_download(dropbox_path, local_path)
    if File.exists?(storage_path)
      FileUtils.mkdir_p(File.dirname(local_path))
      FileUtils.cp(storage_path, local_path)
      file_metadata(dropbox_path)
    else
      raise "File #{storage_path} does not exists."
    end
  rescue Exception => ex
    error "Download failed: %s." % ex.message
    nil
  end

  def upload(local_path, dropbox_path)
    dropbox_path = normalize_path(dropbox_path)
    storage_path = path2local(dropbox_path)
    log_upload(local_path, dropbox_path)
    if File.exists?(local_path)
      FileUtils.mkdir_p(File.dirname(storage_path))
      FileUtils.cp(local_path, storage_path)
      file_metadata(dropbox_path)
    else
      raise "File #{local_path} does not exists."
    end
  rescue Exception => ex
    error "Upload failed: %s." % ex.inspect
    nil
  end



  def find(dropbox_path)
    file_metadata(dropbox_path)
  end

  def cp(dropbox_src_path,dropbox_dst_path, overwrite = true)
    dropbox_src_path = normalize_path(dropbox_src_path)
    dropbox_dst_path = normalize_path(dropbox_dst_path)
    rm(dropbox_dst_path, false) if overwrite
    log_cp(dropbox_src_path, dropbox_dst_path)
    FileUtils.mkdir_p(File.dirname(path2local(dropbox_dst_path)))
    FileUtils.cp(path2local(dropbox_src_path), path2local(dropbox_dst_path))
    file_metadata(dropbox_dst_path)
  rescue Exception => ex
    error "Copy failed: %s" % ex.message
    nil
  end

  def mv(dropbox_src_path,dropbox_dst_path, overwrite = true)
    dropbox_src_path = normalize_path(dropbox_src_path)
    dropbox_dst_path = normalize_path(dropbox_dst_path)
    rm(dropbox_dst_path, false) if overwrite
    log_mv(dropbox_src_path, dropbox_dst_path)
    FileUtils.mkdir_p(File.dirname(path2local(dropbox_dst_path)))
    FileUtils.mv(path2local(dropbox_src_path), path2local(dropbox_dst_path))
    file_metadata(dropbox_dst_path)
  rescue Exception => ex
    error "Move failed: %s." % ex.message
    nil
  end

  def rm(dropbox_path, notify_on_missing = true)
    dropbox_path = normalize_path(dropbox_path)
    log_rm(dropbox_path) unless notify_on_missing
    storage_path = path2local(dropbox_path)
    if File.exists?(storage_path)
      meta = file_metadata(dropbox_path)
      meta['is_deleted'] = true
      FileUtils.rm_rf(storage_path)
      meta
    else
      nil
    end
  rescue Exception => ex
    if notify_on_missing || !ex.http_response.kind_of?(Net::HTTPNotFound)
      error "Remove failed: %s." % ex.message
    end
    nil
  end

  # Direct link
  def dl(dropbox_path)
    path2url(dropbox_path)
  end

  # Thumbnail of the image
  def thb(dropbox_path, size)
    storage_path = path2local(dropbox_path)
    log "THB: %s" % storage_path
    thumbnail = `convert "#{storage_path}" -thumbnail #{THUMBNAIL_SIZE_PX}x#{THUMBNAIL_SIZE_PX} -quality #{THUMBNAIL_QUALITY} jpg:-`
    thumbnail
  rescue Exception => ex
    error "Thumbnail failed: %s." % ex.message
    nil
  end

  def mkdir(dropbox_path)
    dropbox_path=normalize_path(dropbox_path)
    FileUtils.mkdir_p(path2local(dropbox_path))
    file_metadata(dropbox_path)
  rescue Exception => ex
    error "Make dir failed: %s." % ex.message
    nil
  end

  def prune(path)
    Dir.glob(File.join(path, '**/*'))
      .select { |d| File.directory? d }
      .select { |d| (Dir.entries(d) - %w[ . .. ]).empty? }
      .each do |d|
        log "Prune: %s" % d
        Dir.rmdir(d)
      end
      .count
  end

  def prune_local_folder(dropbox_path)
    dropbox_path=normalize_path(dropbox_path)
    path = path2local(dropbox_path)
    while prune(path) > 0 do
    end
  end

end
