export interface FileType {
  id?: number,
  attachment_name?: string,
  attachment_url?: string
}

export interface ImageType extends FileType {
  is_main?: boolean
}
