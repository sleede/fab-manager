# Raised when total of reservation isn't equal to the total of stripe's invoice
class InvoiceTotalDifferentError < StandardError
end
