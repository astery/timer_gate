require './boot.rb'
require './config.rb'

module Timer
  class User < ActiveRecord::Base
    has_many :doings

    def entity
      Entity.new(self)
    end

    class Entity < Grape::Entity
      expose :name
    end
  end

  class Doing < ActiveRecord::Base
    belongs_to :user
    has_many :timestamps

    def entity
      Entity.new(self)
    end

    class Entity < Grape::Entity
      expose :user, :subject, :timestamps, :complete_time
    end

    def last_started_timestamp
      Timestamp.where(doing: self).last_started
    end

    def stop_last_started_timestamp
      lst = last_started_timestamp
      lst.try(:stop)
      lst
    end

    # Caclulate time for periods
    def calc_time

    end
  end

  class Timestamp < ActiveRecord::Base
    belongs_to :doing
    scope :last_started, -> { where(stopped_at: nil).order("id asc").first }

    before_create :start

    def entity
      Entity.new(self)
    end

    class Entity < Grape::Entity
      expose :user, :doing, :started_at, :stopped_at
    end

    def start(time=nil)
      self.started_at = time || DateTime.now
      save unless new_record?
    end

    def stop(time=nil)
      self.stopped_at = time || DateTime.now
      save unless new_record?
    end
  end

  class API < Grape::API
    format :json

    helpers do
      def current_user
        @current_user ||= User.find_by_name(params[:user_name])
      end

      def authenticate!
        error!('401 Unauthorized', 401) unless current_user
      end
    end
    
    params do
      requires :user_name, type: String
    end
    post :login do
      User.find_by_name params[:user_name]
    end

    params do
      requires :user_name, type: String
    end
    post :signup do
      User.create(name: params[:user_name])
    end

    resource :users do
      get do
        User.all
      end

      post :create do
        User.create(name: params[:name])
      end
    end

    resource "/:user_name", requirements: { doing_id: /^[A-z][A-z0-9]+/ } do

      resource :doings do
        before do
          authenticate!
        end

        get do
          Doing.where(user: current_user)
        end

        post :create do
          Doing.find_or_create_by_subject_and_user_id(params[:subject], current_user.id)
        end

        resource ":doing_id", requirements: { doing_id: /[0-9]+/ } do
          before do
            @doing = Doing.includes(:timestamps).find_by(id: params[:doing_id], user: current_user)
          end

          get do
            present @doing
          end

          get :start do
            @doing.stop_last_started_timestamp
            @doing.timestamps.create
          end

          get :stop do
            @doing.stop_last_started_timestamp
          end

          desc "Sum of all closed(stopped) timestamps"
          get :complete_time do
            @doing.complete_time
          end

          resource :timestamps do
            get do
              present @doing.timestamps
            end

            post :create do
              @doing.timstamps.create({
                                 started_at: params[:started_at],
                                 stopped_at: params[:stopped_at] })
            end
          end
        end
      end
    end

  end
end

run Timer::API
