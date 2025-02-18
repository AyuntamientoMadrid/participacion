class Proposal::Exporter
  require "csv"
  include JsonExporter

  def initialize(proposals)
    @proposals = proposals
  end

  def model
    Proposal
  end
  
  def to_csv
    CSV.generate(headers: true) do |csv|
      csv << headers
      @proposals.each { |proposal| csv << csv_values(proposal) }
    end
  end

  private

    def json_values(proposal)
      {
        id: proposal.id,
        title: proposal.title,
        summary: strip_tags(proposal.summary),
        description: strip_tags(proposal.description)
      }
    end
    
    def headers
      [
        I18n.t("admin.proposals.index.list.id"),
        I18n.t("admin.proposals.index.list.title"),
        I18n.t("admin.proposals.index.list.author"),
        I18n.t("admin.proposals.index.list.summary"),
        I18n.t("admin.proposals.index.list.description"),
      ]
    end

    def csv_values(proposal)
      [
        proposal.id.to_s,
        proposal.title,
        proposal.author.email,
        proposal.summary,
        proposal.description
      ]
    end

end