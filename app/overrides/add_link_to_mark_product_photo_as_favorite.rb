Deface::Override.new(
  :virtual_path => 'spree/products/_photos',
  :name => 'add_link_to_mark_product_photo_as_favorite',
  :insert_before => "a[itemprop='photos']",
  :text => %Q{<% if spree_user_signed_in? && spree_current_user.has_favorite_product?(@product.id) %>
      <%= link_to  favorite_product_path(:id => @product.id), :method => :delete, :remote => true, :class => 'favorite_link', :id => @product.id  do %>
          <i class="fa fa-heart" aria-hidden="true"></i>
        <% end %>
    <% else %>
      <%= link_to  favorite_products_path(:id => @product.id), :method => :post, :remote => spree_user_signed_in?, :class => 'favorite_link',  :id => @product.id  do %>
        <i class="fa fa-heart-o" aria-hidden="true"></i>
      <%end%>
    <% end %>}
)
