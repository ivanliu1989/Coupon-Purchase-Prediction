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
plocation <- read.csv("../data/en/prefecture_locations_en.csv")
ulist <- read.csv("../data/en/user_list_en.csv") # Residential Prefecture (PREF_NAME)

# purchase to valid period
# purchase location / coupon location
### 2.Merge dataset
train <- merge(c_detail_train, c_list_train); dim(train); dim(c_detail_train); dim(c_list_train) #, all.y = T
train <- merge(train, ulist); dim(train); dim(ulist)

test <- do.call(rbind, lapply(1:nrow(c_list_test),FUN=function(i){
    ulist$COUPON_ID_hash <- c_list_test[i,'COUPON_ID_hash']
    test_df <- merge(ulist, c_list_test[i,])
    print(i)
    return(test_df)
}))

for (i in 1:nrow(c_list_test)){
    if(i==1){
        ulist$COUPON_ID_hash <- c_list_test[i,'COUPON_ID_hash']
        test <- merge(ulist, c_list_test[i,])  
    }else{
        ulist$COUPON_ID_hash <- c_list_test[i,'COUPON_ID_hash']
        test_df <- merge(ulist, c_list_test[i,])  
        test <- rbind(test, test_df)
        print(i)
    }
}

### 3.Geographic features

### 4.Dropout/New customers
dropout <- ulist[which(as.POSIXlt(ulist$WITHDRAW_DATE, format = "%Y-%m-%d") <= as.POSIXlt("2012-06-30", format = "%Y-%m-%d")),]
newregister <- ulist[which(as.POSIXlt(ulist$REG_DATE, format = "%Y-%m-%d") > as.POSIXlt("2012-06-24", format = "%Y-%m-%d")),]

### 5.Save cleaned dataset
save(train, test, dropout, newregister, file='model_based_data.RData')