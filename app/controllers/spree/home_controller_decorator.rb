module Spree
  HomeController.class_eval do
    def sale
      @products = Product.find(:all, :order => "updated_at desc", :limit => 10)
    end
  end
end