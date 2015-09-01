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

object.size(training)/1024/1024/1024
rm(test,train, inTraining, dropout, newregister)

### modeling
# library(doMC)
# registerDoMC(cores = 2)

training$PURCHASE_FLG <- as.factor(training$PURCHASE_FLG)
levels(training$PURCHASE_FLG) <- c('No','Yes')

# model settings
fitControl <- trainControl(method = "none", # adaptive_cv
                           number = 10, #10
                           #                            repeats = 1, #5
                           classProbs = TRUE,
                           summaryFunction = twoClassSummary,
                           # allowParallel = TRUE,
                           selectionFunction = 'best'#,
                           #                            adaptive = list(min = 4, #10
                           #                                            alpha = 0.05,
                           #                                            method = "BT",
                           #                                            complete = TRUE)
)
# grid
# Grid <-  expand.grid(interaction.depth = 6,
#                      n.trees = 300,
#                      shrinkage = 0.01#,
#                      #n.minobsinnode = 20
# )
# Grid <- expand.grid(mtry = 17) #rf
Grid <- expand.grid(size = 9, decay = 0.5) #nnet
# Grid <- expand.grid(fL = 3, usekernel = 0.9) #nb
# Grid <- expand.grid(nlter) #LogitBoost
# train
set.seed(8)
fit <- train(PURCHASE_FLG ~ .,
             data = training[,-c(1,2)],
             method = "nnet", 
             trControl = fitControl,
             # preProc = c("pca"), #"center", "scale"
             # tuneLength = 6, #8
             verbose = TRUE,
             tuneGrid = Grid,
             metric = "ROC")

# feature importance
featImp <- varImp(fit, scale = FALSE)
featImp

# model performance
ggplot(fit)

# predict
pred <- predict(fit, newdata = validation, type = "prob")

# save model
gbmFit <- fit
save(gbmFit, file='../trained_models.RData')
