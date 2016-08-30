class UsersController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show, :clean_show]

  def show

    @message = Message.new
    @user = User.find(params[:id])

    @items = []

    @user.messages.each do |message|

      @items << {
        class: message.class,
        instance: message,
        created_at: message.created_at
      }
    end

    @user.requests.each do |request|

      service = request.service

      if service.class == Ride

        ride = service

        if ride.start_address

          start_address = ride.start_address

          @items << {
            class: start_address.class,
            instance: start_address,
            to_or_from: "from",
            created_at: start_address.created_at
          }
        end

        if ride.end_address

          end_address = ride.end_address

          @items << {
            class: end_address.class,
            instance: end_address,
            to_or_from: "to",
            created_at: end_address.created_at
          }
        end
      end
    end

    @user.requests.each do |request|

      @items << {
        class: request.class,
        instance: request,
        created_at: request.created_at
      }

    end

    @items = @items.sort_by { |item| item[:created_at] }

    # @messages = Message.where(user: @user).order("created_at ASC")
  end

  def clean_show
    @message = Message.new
    # TODO - Set this to an actual user
    @user = User.all.last

    respond_to do |format|
      if @message.save
        format.html { redirect_to interface_path(@message)}
        format.js
      else
        format.html { render 'clean_show'}
        format.js
      end
    end
  end


  def index
    @users = User.where.not('phone_number' => nil).order("created_at DESC")
  end
end
