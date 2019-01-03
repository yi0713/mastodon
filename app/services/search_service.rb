# frozen_string_literal: true

class SearchService < BaseService
  attr_accessor :query, :account, :limit, :resolve

  def call(query, limit, resolve = false, account = nil)
    @query   = query.strip
    @account = account
    @limit   = limit
    @resolve = resolve

    default_results.tap do |results|
      if url_query?
        results.merge!(url_resource_results) unless url_resource.nil?
      elsif query.present?
        results[:accounts] = perform_accounts_search! if account_searchable?
        results[:statuses] = perform_statuses_search! if full_text_searchable?
        results[:hashtags] = perform_hashtags_search! if hashtag_searchable?
      end
    end
  end

  private

  def perform_accounts_search!
    AccountSearchService.new.call(query, limit, account, resolve: resolve)
  end

  def perform_statuses_search!
    statuses = StatusesIndex.filter(terms: { searchable_by: [account.id, 1, 2510, 2529, 2531, 4305, 8618, 13238, 13525, 17661, 18737, 25969, 26986, 27935, 33745, 33878, 35120, 41177, 44147, 51748, 53296]})
                            .query(match: { 'text.stemmed': { query: query, operator: 'and'}})
                            .order(created_at: { order: 'desc' })
                            .limit(limit)
                            .objects
                            .compact

    statuses.reject { |status| StatusFilter.new(status, account).filtered? }
  rescue Faraday::ConnectionFailed
    []
  end

  def perform_hashtags_search!
    Tag.search_for(query.gsub(/\A#/, ''), limit)
  end

  def default_results
    { accounts: [], hashtags: [], statuses: [] }
  end

  def url_query?
    query =~ /\Ahttps?:\/\//
  end

  def url_resource_results
    { url_resource_symbol => [url_resource] }
  end

  def url_resource
    @_url_resource ||= ResolveURLService.new.call(query, on_behalf_of: @account)
  end

  def url_resource_symbol
    url_resource.class.name.downcase.pluralize.to_sym
  end

  def full_text_searchable?
    return false unless Chewy.enabled?
    !account.nil? && !((query.start_with?('#') || query.include?('@')) && !query.include?(' '))
  end

  def account_searchable?
    !(query.include?('@') && query.include?(' '))
  end

  def hashtag_searchable?
    !query.include?('@')
  end
end
