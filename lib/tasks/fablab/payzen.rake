# frozen_string_literal: true

# Stripe relative tasks
namespace :fablab do
  namespace :payzen do

    # example: rails fablab:payzen:replay_payment_success[54a35f3f6fdd729ac72b6da0,53,57,3,2317,2022-04-27T14:30:34.000+02:00,2022-04-27T17:00:34.000+02:00]
    # to find the parameters, search the logs, example:
    # Started POST "/api/payzen/confirm_payment" for 93.27.29.108 at 2022-04-04 20:26:12 +0000
    # Processing by API::PayzenController#confirm_payment as JSON 
    # Parameters: {"cart_items"=>{"customer_id"=>53, "items"=>[{"reservation"=>{"reservable_id"=>57, "reservable_type"=>"Event", "slots_attributes"=>[{"start_at"=>"2022-04-27T14:30:34.000+02:00", "end_at"=>"2022-04-27T17:00:34.000+02:00", "availability_id"=>2317, "offered"=>false}], "nb_reserve_places"=>3, "tickets_attributes"=>[]}}], "payment_method"=>"card"}, "order_id"=>"704cc55e23f00ac3d238d8de", "payzen"=>{"cart_items"=>{"customer_id"=>53, "items"=>[{"reservation"=>{"reservable_id"=>57, "reservable_type"=>"Event", "slots_attributes"=>[{"start_at"=>"2022-04-27T14:30:34.000+02:00", "end_at"=>"2022-04-27T17:00:34.000+02:00", "availability_id"=>2317, "offered"=>false}], "nb_reserve_places"=>3, "tickets_attributes"=>[]}}], "payment_method"=>"card"}, "order_id"=>"704cc55e23f00ac3d238d8de"}}
    desc 'replay PayzenController#on_payment_success for a given event'
    task :replay_on_payment_success, [:gateway_item_id, :user_id, :event_id, :nb_reserve_places, :availability_id, :slot_start_at, :slot_end_at] => :environment do |_task, args|
      ActiveRecord::Base.logger = Logger.new STDOUT

      gateway_item_id, gateway_item_type = args.gateway_item_id, 'PayZen::Order'

      ActionController::Parameters.permit_all_parameters = true
      params = ActionController::Parameters.new({
        "cart_items" =>
          { "customer_id" => args.user_id, 
            "items" => [
              {"reservation" =>
                { "reservable_id" => args.event_id, "reservable_type" => "Event", 
                  "slots_attributes" =>[
                    {"start_at" => args.slot_start_at, "end_at" => args.slot_end_at, "availability_id" => args.availability_id, "offered" => false}
                  ], 
                  "nb_reserve_places" => args.nb_reserve_places.to_i, "tickets_attributes" =>[]
                }
              }
            ], 
            "payment_method"=>"card"}, 
            "order_id"=> gateway_item_id, 
          }
        )

      current_user = User.find(args.user_id)
      cart_service = CartService.new(current_user)
      cart = cart_service.from_hash(params[:cart_items])
      res = cart.build_and_save(gateway_item_id, gateway_item_type)
    end
  end
end