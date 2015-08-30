setwd('/Users/ivanliu/Downloads/kaggle/Coupon-Purchase-Prediction')
rm(list=ls());gc()
# list all data
system("ls ../data/en/")
system("head ../data/en/*.csv")
# read in all the input data
c_area_train <- read.csv("../data/en/coupon_area_test_en.csv")
c_area_test <- read.csv("../data/en/coupon_area_train_en.csv")
c_detail_train <- read.csv("../data/en/coupon_detail_train_en.csv")
c_list_train <- read.csv("../data/en/coupon_list_train_en.csv")
c_list_test <- read.csv("../data/en/coupon_list_test_en.csv")
plocation <- read.csv("../data/en/prefecture_locations_en.csv")
ulist <- read.csv("../data/en/user_list_en.csv")

# purchase to valid period
# purchase location / coupon location
# Merge dataset
df <- merge(c_detail_train, c_list_train); dim(df); dim(c_detail_train); dim(c_list_train)
df <- merge(df, ulist); dim(df)
