create index ix_sale_product on SALES (productID);
-- creating this index because of searching by Products

create index ix_product_material on PRODUCTS (MaterialID);
-- creating this index because of searching by Materials

create index ix_sale_client on SALES (clientId);
-- creating this index because of searching by Clients

--creating a synonym
create synonym Comp for PROVIDERS.nameComp;