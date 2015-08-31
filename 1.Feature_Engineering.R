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
plocation <- read.csv("../data/en/prefecture_locations_en.csv",stringsAsFactor=F)
# en_ken (shop prefecture) | en_pref (customer prefecture)
library(geosphere)
distance <- do.call(rbind, lapply(1:nrow(plocation), FUN=function(i){
    dist <- do.call(rbind, lapply(1:nrow(plocation), FUN=function(j){
        d <- c(as.character(plocation[i,1]), as.character(plocation[j,1]), distCosine(plocation[i,3:2], plocation[j,3:2])/1000)
        return(d)
    }))
    return(dist)
}))
distance <- as.data.frame(distance)
names(distance) <- c('en_pref','en_ken', 'distance_km')
distance$distance_km <- as.numeric(levels(distance$distance_km))[distance$distance_km]
all_loc <- merge(all, distance, all.x=T, by=c('en_pref','en_ken'))
all <- all_loc[,c(3:4,7:8,9:11,27:28,1:2,34,18:26,12:17,29:32,6,5,33)]
save(all, file='../data/model_based_data.RData')

### 5.Dropout/New customers
dropout <- ulist[which(as.POSIXlt(ulist$WITHDRAW_DATE, format = "%Y-%m-%d") <= as.POSIXlt("2012-06-30", format = "%Y-%m-%d")),]
newregister <- ulist[which(as.POSIXlt(ulist$REG_DATE, format = "%Y-%m-%d") > as.POSIXlt("2012-06-24", format = "%Y-%m-%d")),]

### 6.Sort/Generate Features
rm(list=ls());gc()
load('../data/model_based_data.RData')
# remove: en_small_area, DISPFROM, DISPEND, VALIDFROM, VALIDEND, REG_DATE, WITHDRAW_DATE, I_Date
# new feature: member_yr, holiday?, I_Date-DISPPERIOD
all <- all[,-which(names(all) %in% c('en_small_area', 'DISPFROM', 'DISPEND', 'VALIDFROM', 'VALIDEND', 'REG_DATE', 'WITHDRAW_DATE', 'I_Date'))]

### 7.Imputation
# en_pref, distance_km, USABLE_DATE_MON, - USABLE_DATE_BEFORE_HOLIDAY, VALIDPERIOD
all[,12:20][is.na(all[,12:20])] <- 1
all$distance_km[is.na(all$distance_km)] <- mean(all$distance_km, na.rm=T)
all$VALIDPERIOD[is.na(all$VALIDPERIOD)] <- mean(all$VALIDPERIOD, na.rm=T) # <<=====================IMPROVEMENT!!!! STRATIFIED IMPUTATION
for (i in 12:20){
    all[,i] <- as.factor(all[,i])
    print(i)
}

for(i in 1:(ncol(all)-2)){
    if(is.numeric(all[,i])){
        scaled = as.numeric(scale(all[,i]))
        all[,i] = scaled[1:nrow(all)]
        print(i)
    }
}
save(all, file='../data/model_based_data_impute_scale.RData')

### 8.One-hot Encoding
load('../data/model_based_data_impute_scale.RData')
head(all)
# options(na.action="na.fail")
all$en_pref <- as.character(all$en_pref)
all$en_pref[is.na(all$en_pref)] <- 'central'
all$en_pref <- as.factor(all$en_pref)
all_df <- cbind(all[,c(1,2)],
             model.matrix(~ -1 + .,all[,-c(1,2,5,6,7,11,21,22,24,25,26)]),
             all[,c(5,6,7,11,21,22,24)], all[,c(25,26)])

train <- all_df[which(all_df$flag == 0), -167]
test <- all_df[which(all_df$flag == 1), -167]
dim(train); dim(test)
### 9.Output cleaned dataset (train, validation, test)
save(train, test, dropout, newregister, file='../data/2_model_based_train_test_drop_new.RData')
