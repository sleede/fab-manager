json.array!(@do_docs) do |do_doc|
  json.extract! do_doc, :id, :name, :url
end
