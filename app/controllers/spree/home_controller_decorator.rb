module Spree
  HomeController.class_eval do
    def sale
      @products = Product.all
    end
  end
end