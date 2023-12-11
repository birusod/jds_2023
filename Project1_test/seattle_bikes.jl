# Seattle Bike Counters:
# week-14

# Pkgs 
## Standard
using Downloads, Dates, Statistics

## Loaded
using CSV, DataFrames, CategoricalArrays
using Tidier, Chain


# Load Data

url_data = "https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2019/2019-04-02/bike_traffic.csv"
df_raw = CSV.File(Downloads.download(url_data)) |> DataFrame;

@glimpse(df_raw)
df_raw |> describe
df_raw |> nrow


# Data wrangling

df_raw
describe(df_raw, :eltype)
df_raw.crossing
df_raw.date

##  Date formatting
Date(df_raw.date[1], dateformat"mm/dd/yyyy H:M:S p")
DateTime(df_raw.date[1], dateformat"mm/dd/yyyy H:M:S p")
DateTime(df_raw.date[1], dateformat"mm/dd/yyyy H:M:S p") |> year
DateTime(df_raw.date[1], dateformat"mm/dd/yyyy H:M:S p") |> monthabbr

## reading with dateformat
dfmt = "mm/dd/yyyy H:M:S p"
CSV.File(Downloads.download(url_data), dateformat = dfmt) |> DataFrame

## parsing string to Int64, Float64 and missing

df_raw.bike_count[1]
df_raw.bike_count[1] |> typeof
parse(Int64, df_raw.bike_count[1])

typeof.(df_raw.bike_count[1:3])
parse.(Int64, df_raw.bike_count[1:3])

df_raw.ped_count[400]
df_raw.ped_count[1] |> typeof
parse(Int64, df_raw.ped_count[1])
replace(df_raw.ped_count[1], "NA" => missing)

df_raw.ped_count[426545:426555]
typeof.(df_raw.ped_count[426545:426555])
replace(df_raw.ped_count[426545:426555], "NA" => missing)
replace(df_raw.ped_count[426545:426555], "NA" => nothing)

parse.(Int64, ["1", "2", "3"])
tryparse.(Int64, ["1", "a", "3"])
replace(tryparse.(Int64, ["1", "a", "3"]), nothing  => missing)
replace(tryparse.(Int64, df_raw.ped_count[426545:426555]), nothing  => missing)

df_raw[!, "ped_count_int"] = replace(tryparse.(Int64, df_raw.ped_count), nothing  => missing)
df_raw[!, "bike_count_int"] = replace(tryparse.(Int64, df_raw.bike_count), nothing  => missing)
df_raw


dfmt = "mm/dd/yyyy H:M:S p"
df2  = CSV.File(
    Downloads.download(url_data), 
    dateformat = dfmt, 
    missingstring= "NA") |> DataFrame;

df2

## Final dataset with year, month day columns

df = @chain df2 begin
    @mutate(
        year  =  year(date),
        month  =  monthname(date),
        day  =  dayname(date),
        hour = hour(date))
    @rename(
        bike = bike_count, 
        ped =  ped_count)
end

# EDA

# yearly  bike  count:

combine(
    groupby(
        df,
        :year),
    :bike  => sum ∘ skipmissing  => :total
)

yearly_bikes_count = @chain df begin
    @group_by(year)
    @summarise(total = sum(skipmissing(bike)))
    @arrange(year)
    @mutate(year = categorical(year))
end

yearly_bikes_count


# montly  bike  count:
combine(
    groupby(df, :month),
    :bike => sum ∘ skipmissing => :total
)

monthname.(1:12)
monthly_bikes_count = @chain df begin
    @group_by(month)
    @summarise(total = sum(skipmissing(bike)))
    @mutate(month = categorical(
        month,
        levels  =  monthname.(1:12),
        ordered  = true))
end
monthly_bikes_count

# daily bike  count:
combine(
    groupby(df, :day),
    :bike => sum ∘ skipmissing => :total
)

dayname.(1:7)
daily_bikes_count = @chain df begin
    @group_by(day)
    @summarise(total = sum(skipmissing(bike)))
    @mutate(day = categorical(
        day,
        levels  =  dayname.(1:7),
        ordered  = true))
end
daily_bikes_count



dy = ["Wed", "Mon", "Tue", "Wed", "Mon", "Tue", "Fri"]
dy = CategoricalArray(dy)
dy
levels!(dy, ["Mon", "Tue", "Wed", "Fri"])


# Viz


ggplot(
    yearly_bikes_count, 
    aes(x = "year", y = "total")) + 
    geom_col()

ggplot(
    monthly_bikes_count, 
    aes(x = "month", y = "total")) + 
    geom_col()


ggplot(
    daily_bikes_count, 
    aes(x = "day", y = "total")) + 
    geom_col()