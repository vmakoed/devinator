module ApplicationHelper
  def sanitize_url(url)
    return nil if url.blank?

    uri = URI.parse(url)
    # Only allow http and https protocols
    if uri.scheme.in?(%w[http https])
      url
    else
      nil
    end
  rescue URI::InvalidURIError
    nil
  end
end
