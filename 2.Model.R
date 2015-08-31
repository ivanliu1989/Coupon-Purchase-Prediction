setwd('/Users/ivanliu/Downloads/kaggle/Coupon-Purchase-Prediction')
rm(list=ls());gc()
load('../data/2_model_based_train_test_drop_new.RData')

### split train-validation
library(caret)
set.seed(888)
inTraining <- createDataPartition(train$PURCHASE_FLG, p = .75, list = FALSE)
validation <- train[-inTraining,]
training <- train[inTraining,]
dim(validation);dim(training)

### modeling
library(doMC)
registerDoMC(cores = 4)

training$PURCHASE_FLG <- as.factor(training$PURCHASE_FLG)
levels(training$PURCHASE_FLG) <- c('No','Yes')

# model settings
fitControl <- trainControl(method = "adaptive_cv",
                           number = 10,
                           repeats = 5,
                           classProbs = TRUE,
                           summaryFunction = twoClassSummary,
                           allowParallel = TRUE,
                           # selectionFunction = 'best',
                           adaptive = list(min = 10,
                                           alpha = 0.05,
                                           method = "BT",
                                           complete = TRUE))
# grid
Grid <-  expand.grid(interaction.depth = c(1, 5, 9),
                     n.trees = (1:30)*50,
                     shrinkage = 0.1,
                     n.minobsinnode = 20)
# train
set.seed(8)
fit <- train(PURCHASE_FLG ~ .,
             data = training[,-c(1,2)],
             method = "gbm",
             trControl = fitControl,
             # preProc = c("center", "scale"),
             tuneLength = 8,
             verbose = TRUE,
             metric = "ROC")

# feature importance
featImp <- varImp(fit, scale = FALSE)
featImp

# model performance
ggplot(fit)