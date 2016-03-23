module UploadHelper

  def delete_empty_dirs

    path = File.expand_path(store_dir, root)
    Dir.delete(path)

    path = File.expand_path(base_store_dir, root)
    Dir.delete(path)

  rescue SystemCallError
    true # nothing, the dir is not empty
  end

end
