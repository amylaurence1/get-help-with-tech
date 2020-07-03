class ImportResponsibleBodiesService
  def import_local_authorities
    LocalAuthoritiesInEnglandRegister.entries.each do |entry|
      LocalAuthority
        .where(local_authority_eng: entry['local-authority-eng'])
        .first_or_create!(
          name: entry['name'],
          organisation_type: entry['local-authority-type'],
          local_authority_official_name: entry['official-name'],
        )
    end
  end

  def import_trusts
    GetInformationAboutSchools.trusts_entries.each do |entry|
      Trust
        .where(companies_house_number: entry['Companies House Number'])
        .first_or_create!(
          name: entry['Group Name'],
          organisation_type: Trust.organisation_types.key(entry['Group Type']),
        )
    end
  end
end
