# frozen_string_literal: true

module PublicActivity

  if not defined? ::PG::ConnectionBad
    module ::PG
      class ConnectionBad < Exception; end
    end
  end
  if not defined? Mysql2::Error::ConnectionError
    module Mysql2
      module Error
        class ConnectionError < Exception; end
      end
    end
  end
  
  module ORM
    module ActiveRecord
      # The ActiveRecord model containing
      # details about recorded activity.
      class Activity < ::ActiveRecord::Base
        include Renderable
        self.table_name = PublicActivity.config.table_name
        self.abstract_class = true

        # Define polymorphic association to the parent
        belongs_to :trackable, polymorphic: true, optional: true
        belongs_to :owner,     polymorphic: true, optional: true
        belongs_to :recipient, polymorphic: true, optional: true

        # Serialize parameters Hash
        begin
          if table_exists?
            serialize :parameters, Hash unless [:json, :jsonb, :hstore].include?(columns_hash['parameters'].type)
          else
            warn("[WARN] table #{name} doesn't exist. Skipping PublicActivity::Activity#parameters's serialization")
          end
        rescue ::ActiveRecord::NoDatabaseError => e
          warn("[WARN] database doesn't exist. Skipping PublicActivity::Activity#parameters's serialization")
        rescue ::PG::ConnectionBad => e
          warn("[WARN] couldn't connect to database. Skipping PublicActivity::Activity#parameters's serialization")
        rescue Mysql2::Error::ConnectionError
          warn("[WARN] couldn't connect to database. Skipping PublicActivity::Activity#parameters's serialization")
        end

        if ::ActiveRecord::VERSION::MAJOR < 4 || defined?(ProtectedAttributes)
          attr_accessible :key, :owner, :parameters, :recipient, :trackable
        end
      end
    end
  end
end
