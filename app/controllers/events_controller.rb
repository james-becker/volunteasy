class EventsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show, :search, :my_events]
  skip_after_action :verify_authorized, only: [:index, :show, :search]
  skip_before_action :authenticate_user!, except: [:destroy] # (For now)
  skip_after_action :verify_authorized, except: [:destroy] # (For now)
  after_action :verify_policy_scoped, only: [:index], unless: :skip_pundit?

  before_action :set_event, only: [:show, :edit, :update, :destroy]

  def search
    @event = Event.new
    session[:search_results] = params[:address]
    @events = policy_scope(Event)

    if params[:event][:tags].present?
      tags_list = params[:event][:tags].select { |i| i.present? }

      @events = @events.where("tags @> ?", "{#{tags_list.join(",")}}")

    else
      @events = @events.all
    end

    # Kaw thot krap, pom mai dai puut pasa falangse krap
    # Chai pasa angrit thaonan krap, korp khun krap
    if params[:event][:address].present?
      @events = @events.where("address ILIKE ?", "%#{params[:event][:address]}%")

      # ILIKE ne prend pas en compte la casse

      @events_today = @events.where('start_time = ?', Date.today).order(start_time: :asc)

       # .paginate(:per_page => 10, :page => params[:page])

       @events_tomorrow = @events.where('start_time = ?', 1.days.from_now).order(start_time: :asc)

       @events_this_week = @events.where('start_time BETWEEN ? AND ?', 2.days.from_now, Date.today.end_of_week.to_time).order(start_time: :asc)

       @events_next_week = @events.where('start_time BETWEEN ? AND ?', Date.today.end_of_week.to_time, Date.today.end_of_week.to_time + 6.days).order(start_time: :asc)
       @events_later = @events.where('start_time > ?', Date.today.end_of_week.to_time + 6.days).order(start_time: :asc)
     end
   end

# def get_events_in_week_or_month
#   if params[:events_in] =='week'
#     start_date_of_time_period = 2.days.from_now
#     end_date_of_time_period = Date.today.end_of_week
#   else
#     start_date_of_time_period = Date.today.beginning_of_month
#     end_date_of_time_period = Date.today.end_of_month
#   end





# def update
#         @cart = current_cart
#         @cart_item = @cart.cart_items.find_by(product_id: params[:id])
#         if @cart_item.product.storage >= cart_item_params[:quantity].to_i
#             @cart_item.update(cart_item_params)
#             redirect_to carts_path
#         else
#             redirect_to carts_path, alert: "exceed the storage"
#         end

# end




def my_events
  @user = User.find(params[:user_id])
  authorize @user

  @past_events_attended = past_events_attendee(@user)
  @current_events_attended = current_events_attendee(@user)
  @past_events_managed = past_events_manager(@user)
  @current_events_managed = current_events_manager(@user)
end

def show
#     juliette's push
#     @attending = @event.participants.all
#     tags_list = @event.tags
#     @similar_events = Event.where("tags @> ?", "{#{tags_list.join(",")}}")
    @participants = @event.participants.all

    # Spots Left
    if (@event.capacity - @event.participants.size) <= 0
      @spots_left = 0
    else
      @spots_left = @event.capacity - @event.participants.size
    end


    @organizer_name = @event.organizer.first_name << " " << @event.organizer.last_name

    # @registration = Registration.where(participant_id: current_user.id).where(event_id: @event.id)

    # Tagging
    tags_list = @event.tags
    @similar_events = Event.where("tags @> ?", "{#{tags_list.join(",")}}")
end

def new
  @event = Event.new
  authorize @event
end

def edit
end

def create
  @event = Event.new(event_params)
  @event.organizer_id = current_user.id
  authorize @event

  if @event.save
    redirect_to @event, notice: 'Event was successfully created.'
  else
    render :new
  end
end

def update
  if @event.update(event_params)
    redirect_to @event, notice: 'Event was successfully updated.'
  else
    render :edit
  end
end

def destroy
  @event.destroy
  redirect_to events_url, notice: 'Event was successfully destroyed.'
end

private
    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params[:id])
      authorize @event
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def event_params
      params.require(:event).permit(:name, :organization, :start_time, :end_time, :address, :capacity, :tags, :source_event_id, photos: [])
    end

    def past_events_manager(user)
      user.events.where("end_time < ?", DateTime.now)
    end

    def current_events_manager(user)
      user.events.where("end_time > ?", DateTime.now)
    end

    def past_events_attendee(user)
      user.events_as_participant.where("end_time < ?", DateTime.now)
    end

    def current_events_attendee(user)
      user.events_as_participant.where("end_time > ?", DateTime.now)
    end


end

