module Spree
  class OrdersController < Spree::StoreController
    before_action :check_authorization
    rescue_from ActiveRecord::RecordNotFound, with: :render_404
    helper 'spree/products', 'spree/orders'

    respond_to :html

    before_action :assign_order_with_lock, only: :update
    skip_before_action :verify_authenticity_token, only: [:populate]

    def show
      @order = Order.includes(line_items: [variant: [:option_values, :images, :product]], bill_address: :state, ship_address: :state).find_by_number!(params[:id])
    end

    def update
      
      if @order.contents.update_cart(order_params)
        respond_with(@order) do |format|
          format.html do
            if params.has_key?(:checkout)
              @order.next if @order.cart?
              redirect_to checkout_state_path(@order.checkout_steps.first)
            else
              redirect_to cart_path
            end
          end
        end
      else
        respond_with(@order)
      end
    end

    # Shows the current incomplete order from the session
    def edit
      @order = current_order || Order.incomplete.
                                  includes(line_items: [variant: [:images, :option_values, :product]]).
                                  find_or_initialize_by(guest_token: cookies.signed[:guest_token])
      ## START
      product=[]
      quantity=[]
      msg=[]
      discounted_total_price=0
      discounted_price =0
      if @order.line_items.present?
        #Check all product item 
        @order.line_items.each do |item|
          if product.include?(item.product.id)
            q = quantity[product.index(item.product.id)];
            quantity[product.index(item.product.id)] = q+item.quantity
          else
            product.push(item.product.id)
            quantity.push(item.quantity)
          end
        end
        # Check each item if meet  whole sale rules
        @order.adjustments =[]
        isSameDiscount=0
        isSameDiscountCL=[]
        discountCL=[]
        discountPCL =[]
        productNameCL=[]
        @order.line_items.each do |key,item|
          isInrange = 0

          targetIndex=product.index(item.product.id)
          
          isSameDiscount = (item.product.variants.all?{ |v| ( (item.product.master.volume_prices.map{|v| v.amount} ==[]) && (v.volume_prices.map{|v| v.amount.to_i}==[])) || (v.volume_prices.map{|v| v.amount} ==  item.product.variants[0].volume_prices.map{|v| v.amount})})
          isSameDiscountCL[targetIndex] = isSameDiscount
          productNameCL[targetIndex] = item.product.name
          
          q=quantity[product.index(item.product.id)]
          item_quantity =item.quantity
          p=item.variant.price
          d=[]
          if item.variant.volume_prices.present?
            
            #  vol = item.product.master.volume_prices[0]
             
             name=item.variant.name + item.variant.options_text
             v=item.variant.volume_prices
             
             d=checkValumePrice(v,q,item_quantity,p,targetIndex,name,@order,isSameDiscount)
            
          elsif item.product.master.volume_prices.present?
             name=item.variant.name 
             v=item.product.master.volume_prices
             d= checkValumePrice(v,q,item_quantity,p,targetIndex,name,@order,isSameDiscount)
          end
    
          discountCL[targetIndex]  = !discountCL[targetIndex].nil? ? discountCL[targetIndex]+ d[:discountPerLineItem] : d[:discountPerLineItem]
          discountPCL[targetIndex] = d[:discountPerP]

        end
        
        isSameDiscountCL.each_with_index  do |check,index|
          if check
            msg = Spree.t(:wholesale_discount)+productNameCL[index]+ Spree.t(:discount_per_item, number: discountPCL[index] ) 
            adj = @order.adjustments.create!(amount: discountCL[index], label: msg, state: 'open',included: 0 ,order_id: @order.id)
          end
        end
        
        
        @order.adjustment_total = @order.adjustments.sum("amount")
        @order.total = @order.item_total+ @order.adjustment_total 
        @order.save
        
      end
      ## END
      
      associate_user
    end

   

    # Adds a new item to the order (creating a new order if none already exists)
    def populate
      order    = current_order(create_order_if_necessary: true)
      variant  = Spree::Variant.find(params[:variant_id])
      quantity = params[:quantity].to_i
      options  = params[:options] || {}

      # 2,147,483,647 is crazy. See issue #2695.
      if quantity.between?(1, 2_147_483_647)
        begin
          
          order.contents.add(variant, quantity, options)
        rescue ActiveRecord::RecordInvalid => e
          error = e.record.errors.full_messages.join(", ")
        end
      else
        error = Spree.t(:please_enter_reasonable_quantity)
      end

      if error
        flash[:error] = error
        redirect_back_or_default(spree.root_path)
      else
        respond_with(order) do |format|
          format.html { redirect_to cart_path }
        end
      end
    end

    def populate_redirect
      flash[:error] = Spree.t(:populate_get_error)
      redirect_to('/cart')
    end

    def empty
      if @order = current_order
        @order.empty!
      end

      redirect_to spree.cart_path
    end

    def accurate_title
      if @order && @order.completed?
        Spree.t(:order_number, number: @order.number)
      else
        Spree.t(:shopping_cart)
      end
    end

    def check_authorization
      order = Spree::Order.find_by_number(params[:id]) || current_order

      if order
        authorize! :edit, order, cookies.signed[:guest_token]
      else
        authorize! :create, Spree::Order
      end
    end

    private

      def order_params
        if params[:order]
          params[:order].permit(*permitted_order_attributes)
        else
          {}
        end
      end

      def assign_order_with_lock
        @order = current_order(lock: true)
        unless @order
          flash[:error] = Spree.t(:order_not_found)
          redirect_to root_path and return
        end
      end
     # check value price per line item and create order adjustment
    def checkValumePrice(volume_prices,quantity,item_quantity,item_price,targetIndex,name,order,isSameDiscount)
      
      discounted_total_price=0
      discounted_price=0
      discount =0
      
      volume_prices.each do |vol|
        
          discounted_price=0
          discount =0
          if vol.open_ended? 
             
              start = (vol.range[1,vol.range.length-3]).to_i
              isInrange = quantity.between?(start,2_147_483_647)
          else
              
              isInrange = (eval vol.range).include?(quantity)
          end
                
          if isInrange

            discount = (vol.amount - item_price)
            
            discounted_price= discount*item_quantity
            
            if !isSameDiscount
              msg = name + Spree.t(:discount_per_item, number: discount ) 
              order.adjustments.create!(amount: discounted_price, label: Spree.t(:wholesale_discount)+ msg , state: 'open',included: 0 ,order_id: @order.id)
            end
            break
          else
            discount =0
            discounted_price =0
          end

      end
     
      {:discountPerP => discount, :discountPerLineItem => discounted_price}
    end
  end
end
