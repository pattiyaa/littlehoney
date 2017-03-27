Deface::Override.new(
  :virtual_path => 'spree/products/show',
  :name => 'add_link_to_mark_product_as_favorite',
  :insert_before => "div[itemprop='description']",
  :text => %Q{<% if spree_user_signed_in? && spree_current_user.has_favorite_product?(@product.id) %>
      <%= link_to  favorite_product_path(:id => @product.id), :method => :delete, :remote => true, :class => 'favorite_link' do %>
          <i class="fa fa-heart" aria-hidden="true"></i>
        <% end %>
    <% else %>
      <%= link_to  favorite_products_path(:id => @product.id), :method => :post, :remote => spree_user_signed_in?, :class => 'favorite_link' do %>
        <i class="fa fa-heart-o" aria-hidden="true"></i>
      <%end%>
    <% end %>}
)

