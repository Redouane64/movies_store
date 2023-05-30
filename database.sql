create database movies_store;

create schema store;

create table store.customers(
    id uniqueidentifier primary key,
    first_name nvarchar(64) not null,
    last_name nvarchar(64) not null,
    date_of_birth date not null,
    gender nvarchar(8) not null,
    email nvarchar(255) not null unique,
    /* it is possible to use Rules here as well */
    constraint check_gender check (gender in('male', 'female'))
);

create table store.genres(
    /* id here represent text name for a genre */
    id nvarchar(255) not null unique,
);

create table store.movies(
    id uniqueidentifier primary key,
    title nvarchar(255) not null,
    description nvarchar(255) not null,
    release_year int null,
    genre_id nvarchar(255) not null references store.genres(id),
);

create table store.ratings(
    customer_id uniqueidentifier not null references store.customers(id),
    movie_id uniqueidentifier not null references store.movies(id),
    comment nvarchar(512) null,
    created_at datetime default getdate(),
);

alter table store.customers
add member_since datetime not null default getdate();

alter table store.ratings
add primary key (customer_id, movie_id);

/* orders */
create table store.orders(
    id uniqueidentifier primary key,
    customer_id uniqueidentifier not null references store.customers(id),
    created_at datetime not null default getdate(),
);

create table store.order_items(
    order_id uniqueidentifier not null references store.orders(id),
    item_id uniqueidentifier not null references store.movies(id),
    quantity int not null default 1,
    primary key (order_id, item_id),
    constraint quantity_is_not_zero check (quantity > 0),
);

/* collections */
create table store.collections(
    id uniqueidentifier primary key default newid(),
    customer_id uniqueidentifier not null references store.customers(id),
    updated_at datetime not null default getdate(),
    name nvarchar(64) not null,
    description nvarchar(512) null,
);

create table store.collection_movies(
    collection_id uniqueidentifier not null references store.collections(id),
    movie_id uniqueidentifier not null references  store.movies(id),
);

/* stored procedure to fetch movies ordered by a customer */
create procedure store.get_ordered_movies_by_customer_id
    as
    begin
        select
            m.title,
            m.description,
            m.genre_id,
            m.release_year,
            created_at as order_at
        from store.orders
        left join store.order_items oi on orders.id = oi.order_id
        left join store.movies m on oi.item_id = m.id
    end


alter table store.ratings
add rating int not null;

/* select top 10 movies based on their average rating */
create procedure store.get_top_ten_movies
    as
    begin
        select id, title, description, release_year, average_rating as rating from (
            select top (10)
                m.id,
                m.title,
                m.release_year,
                m.description,
                avg(r.rating) as average_rating
            from store.ratings r
                   left join store.movies m on m.id = r.movie_id
            group by m.id
            order by average_rating) as top_ten
    end

/* example sp execution */
exec store.get_top_ten_movies;