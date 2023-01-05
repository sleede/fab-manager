export interface FileType {
  id?: number|string,
  attachment?: File,
  attachment_files?: FileList,
  attachment_name?: string,
  attachment_url?: string,
  _destroy?: boolean
}

export interface ImageType extends FileType {
  is_main?: boolean
}
