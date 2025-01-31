# frozen_string_literal: true
namespace :db do
  using Seedbank::DSL
  override_dependency = []

  namespace :seed do
    # Create seed tasks for all the seeds in seeds_path and add them to the dependency
    # list along with the original db/seeds.rb.
    common_dependencies = seed_tasks_matching(Seedbank.matcher)

    # Only add the original seeds if db/seeds.rb exists.
    if original_seeds_file
      define_seed_task original_seeds_file, :original
      common_dependencies.unshift('db:seed:original')
    end

    override_dependency += common_dependencies

    # Glob through the directories under seeds_path and create a task for each adding it to the dependency list.
    # Then create a task for the environment
    directories = Set.new
    glob_seed_files_matching('**/**').map { |file| directories << File.dirname(file) }.uniq

    directories.each do |directory|
      subdirectory = directory.gsub(/#{Seedbank.seeds_root}\/?/, '')
      next if subdirectory.blank?

      subdirectory_dependencies = seed_tasks_matching(subdirectory, '**', Seedbank.matcher)
      if subdirectory_dependencies.any?
        desc "Load the seed data from db/seeds/#{subdirectory}/#{Seedbank.matcher}."
        task subdirectory.tr('/', ':') => subdirectory_dependencies

        override_dependency << "db:seed:#{subdirectory}"
      end
    end
  end

  # Override db:seed to run all the common and environments seeds plus the original db:seed.
  desc %(Load the seed data from db/seeds.rb, db/seeds/#{Seedbank.matcher} and db/seeds/**/#{Seedbank.matcher}.)
  override_seed_task seed: override_dependency
end
