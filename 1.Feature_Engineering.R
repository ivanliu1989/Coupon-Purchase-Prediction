setwd('/Users/ivanliu/Downloads/kaggle/Coupon-Purchase-Prediction')
rm(list=ls());gc()
# list all data
system("ls ../data/en/")
system("head ../data/en/*.csv")
### 1.read in all the input data
# c_area_train <- read.csv("../data/en/coupon_area_test_en.csv")
# c_area_test <- read.csv("../data/en/coupon_area_train_en.csv")
c_detail_train <- read.csv("../data/en/coupon_detail_train_en.csv") # residential location (SMALL_AREA_NAME) | 19,368
c_list_train <- read.csv("../data/en/coupon_list_train_en.csv") # shop location (SMALL_AREA_NAME) | 19,413
c_list_test <- read.csv("../data/en/coupon_list_test_en.csv") # shop location (SMALL_AREA_NAME)
ulist <- read.csv("../data/en/user_list_en.csv") # Residential Prefecture (PREF_NAME)
log <- read.csv("../data/raw/coupon_visit_train.csv")

# purchase to valid period
# purchase location / coupon location

### 2.Merge dataset
# train <- merge(c_detail_train, c_list_train); dim(train); dim(c_detail_train); dim(c_list_train) #, all.y = T
# train <- merge(train, ulist); dim(train); dim(ulist)

# train + log
log_df <- log[,c(1,2,5,6,8)]
log_df$I_DATE <- as.POSIXlt(log_df$I_DATE, format = "%Y-%m-%d")
log_train <- aggregate(PURCHASE_FLG~VIEW_COUPON_ID_hash + USER_ID_hash + PURCHASEID_hash, data=log_df, FUN=max)
log_train_dt <- aggregate(as.numeric(as.Date(I_DATE), format = "%Y-%m-%d")~VIEW_COUPON_ID_hash + USER_ID_hash + PURCHASEID_hash, data=log_df, FUN=max)
library("zoo")
log_train_dt[,4] <- as.Date(log_train_dt[,4], format = "%Y-%m-%d");
log_train <- merge(log_train, log_train_dt)
names(log_train) <- c('COUPON_ID_hash', 'USER_ID_hash', 'PURCHASEID_hash', 'PURCHASE_FLG', 'I_Date')

# merge train
train <- merge(log_train, c_list_train); dim(train); dim(log_train); dim(c_list_train) #, all.y = T
train <- merge(train, ulist); dim(train); dim(ulist)


# test
test1 <- do.call(rbind, lapply(1:100,FUN=function(i){
    ulist$COUPON_ID_hash <- c_list_test[i,'COUPON_ID_hash']
    test_df <- merge(ulist, c_list_test[i,])
    print(i)
    return(test_df)
}))
test2 <- do.call(rbind, lapply(101:200,FUN=function(i){
    ulist$COUPON_ID_hash <- c_list_test[i,'COUPON_ID_hash']
    test_df <- merge(ulist, c_list_test[i,])
    print(i)
    return(test_df)
}))
test3 <- do.call(rbind, lapply(201:nrow(c_list_test),FUN=function(i){
    ulist$COUPON_ID_hash <- c_list_test[i,'COUPON_ID_hash']
    test_df <- merge(ulist, c_list_test[i,])
    print(i)
    return(test_df)
}))
test <- rbind(test1,test2,test3)

### 3.Combine All Raw datasets
train$flag <- 0; test$flag <- 1
train <- train[,-which(names(train) %in% c('PURCHASEID_hash'))]
test$I_Date <- as.POSIXlt('2012-06-24', format = "%Y-%m-%d")
test$PURCHASE_FLG <- 0
dim(train);dim(test)

all <- rbind(train,test);dim(all)
save(all, file='../data/model_based_data.RData')

### 4.Geographic features
rm(list=ls());gc()
load('../data/model_based_data.RData')
plocation <- read.csv("../data/en/prefecture_locations_en.csv")
# en_ken (shop prefecture) | en_pref (customer prefecture)
library(geosphere)
distance <- do.call(rbind, lapply(1:nrow(plocation), FUN=function(i){
    dist <- do.call(rbind, lapply(1:nrow(plocation), FUN=function(j){
        d <- c(as.character(plocation[i,1]), as.character(plocation[j,1]), distCosine(plocation[i,3:2], plocation[j,3:2])/1000)
        return(d)
    }))
    return(dist)
}))
names(distance) <- c('en_pref','en_ken', 'distance_km')
all_loc <- merge(all, distance, all.x)

### 5.Dropout/New customers
dropout <- ulist[which(as.POSIXlt(ulist$WITHDRAW_DATE, format = "%Y-%m-%d") <= as.POSIXlt("2012-06-30", format = "%Y-%m-%d")),]
newregister <- ulist[which(as.POSIXlt(ulist$REG_DATE, format = "%Y-%m-%d") > as.POSIXlt("2012-06-24", format = "%Y-%m-%d")),]

### 6.Save cleaned dataset
save(train, test, dropout, newregister, file='model_based_data.RData')