STDOUT.sync = true

require "open-uri"
require "json"
require "net/http"
require "logger"
require "parallel"
require "retriable"
require "uri"
require_relative "./bestgems_api"
require_relative "./rubygems_api"

class PutGemDetail
  def initialize(bestgems_api_base:, api_key:)
    @bestgems_api_base, @api_key = bestgems_api_base, api_key
  end

  def api_key
    @api_key
  end

  def logger
    @logger ||= Logger.new(STDOUT)
  end

  def execute
    import_gem_detail
  end

  def process_gem(gem_name)
    logger.info(gem_name: gem_name)

    info = retry_with { rubygems_api.info(gem_name) }

    unless info
      logger.error(type: :fetch_info_failed, gem_name: gem_name)

      return
    end

    retry_with { bestgems_api.put_detail(info) }
    retry_with { bestgems_api.put_dependencies(info) }

    versions = retry_with { rubygems_api.versions(gem_name) }

    unless versions
      logger.error(type: :fetch_versions_failed, gem_name: gem_name)

      return
    end

    retry_with { bestgems_api.put_versions(gem_name, versions) }

    owners = retry_with { rubygems_api.owners(gem_name) }

    unless owners
      logger.error(type: :fetch_owners_failed, gem_name: gem_name)

      return
    end

    retry_with { bestgems_api.put_owners(gem_name, owners) }
  rescue => e
    @logger.error(type: :process_gem, gem_name: gem_name, error_class: e.class.name, error_message: e.message)

    return
  end

  def import_gem_detail
    logger.info("import_gem_detail")

    page = 1

    loop do
      logger.info(page)

      gems = retry_with { bestgems_api.gems(page) }

      break unless gems.count > 0

      Parallel.each(gems, in_processes: 2) do |gem|
        process_gem(gem["name"])
      end

      page += 1
    end
  end

  def retry_with
    Retriable.retriable(tries: 20) do
      begin
        yield
      rescue => e
        @logger.warn(error_class: e.class.name, error_message: e.message)

        raise
      end
    end
  end

  def bestgems_api
    @bestgems_api ||= BestGemsApi.new(@bestgems_api_base, @api_key)
  end

  def rubygems_api
    @rubygems_api ||= RubyGemsApi.new
  end
end

PutGemDetail.new(bestgems_api_base: ARGV[0], api_key: ARGV[1]).execute
