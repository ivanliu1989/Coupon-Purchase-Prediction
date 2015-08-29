setwd('/Users/ivanliu/Downloads/kaggle/Coupon-Purchase-Prediction')
rm(list=ls());gc()
#read in all the input data
cpdtr <- read.csv("../data/en/coupon_detail_train_en.csv")
cpltr <- read.csv("../data/en/coupon_list_train_en.csv")
cplte <- read.csv("../data/en/coupon_list_test_en.csv")
ulist <- read.csv("../data/en/user_list_en.csv")

#making of the train set
train <- merge(cpdtr,cpltr)
train <- train[,c("COUPON_ID_hash","USER_ID_hash",
                  "en_genre","DISCOUNT_PRICE",
                  "USABLE_DATE_MON","USABLE_DATE_TUE","USABLE_DATE_WED","USABLE_DATE_THU",
                  "USABLE_DATE_FRI","USABLE_DATE_SAT","USABLE_DATE_SUN","USABLE_DATE_HOLIDAY",
                  "USABLE_DATE_BEFORE_HOLIDAY","en_ken","en_small_area")]
#combine the test set with the train
cplte$USER_ID_hash <- "dummyuser"
cpchar <- cplte[,c("COUPON_ID_hash","USER_ID_hash",
                   "en_genre","DISCOUNT_PRICE",
                   "USABLE_DATE_MON","USABLE_DATE_TUE","USABLE_DATE_WED","USABLE_DATE_THU",
                   "USABLE_DATE_FRI","USABLE_DATE_SAT","USABLE_DATE_SUN","USABLE_DATE_HOLIDAY",
                   "USABLE_DATE_BEFORE_HOLIDAY","en_ken","en_small_area")]

train <- rbind(train,cpchar)
#NA imputation
train[is.na(train)] <- 1
#feature engineering (binning the price into different buckets)
train$DISCOUNT_PRICE <- cut(train$DISCOUNT_PRICE,breaks=c(-0.01,0,1000,10000,50000,100000,Inf),labels=c("free","cheap","moderate","expensive","high","luxury"))
#convert the factors to columns of 0's and 1's
train <- cbind(train[,c(1,2)],model.matrix(~ -1 + .,train[,-c(1,2)]))

#separate the test from train
test <- train[train$USER_ID_hash=="dummyuser",]
test <- test[,-2]
train <- train[train$USER_ID_hash!="dummyuser",]

#data frame of user characteristics
uchar <- aggregate(.~USER_ID_hash, data=train[,-1],FUN=mean)

#calculation of cosine similairties of users and coupons
score = as.matrix(uchar[,2:ncol(uchar)]) %*% t(as.matrix(test[,2:ncol(test)]))
#order the list of coupons according to similairties and take only first 10 coupons
uchar$PURCHASED_COUPONS <- do.call(rbind, lapply(1:nrow(uchar),FUN=function(i){
    purchased_cp <- paste(test$COUPON_ID_hash[order(score[i,], decreasing = TRUE)][1:10],collapse=" ")
    return(purchased_cp)
}))

#make submission
uchar <- merge(ulist, uchar, all.x=TRUE)
submission <- uchar[,c("USER_ID_hash","PURCHASED_COUPONS")]
write.csv(submission, file="cosine_sim.csv", row.names=FALSE)
