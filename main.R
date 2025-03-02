library(caret)
library(ROCR)
library(AUC)

print("1. Cargar datos en R")
print("====================")

data <- read.csv("tic-tac-toe.data.txt", header = FALSE)

names(data) <- c("top_left", "top_mid", "top_right",
                 "mid_left", "mid_mid", "mid_right",
                 "bot_left", "bot_mid", "bot_right",
                 "Class")

missing_vals <- sum(is.na(data))
cat("Numero de valores faltantes:", missing_vals, "\n")


set.seed(12345)

print("2. Partir datos en train y test")
print("===============================")
trainIndex <- createDataPartition(data$Class, p = 0.7, list = FALSE)
trainData <- data[trainIndex, ]
testData <- data[-trainIndex, ]

cat("Proporcion en entrenamiento:\n")
print(prop.table(table(trainData$Class)))
cat("Proporcion en test:\n")
print(prop.table(table(testData$Class)))

print("3. Entrenamiento usando validacion cruzada")
print("==========================================")
control <- trainControl(method = "repeatedcv", number = 10, repeats = 1, classProbs = TRUE)

model_nb   <- train(Class ~ ., data = trainData, method = "nb",        trControl = control)
model_dt   <- train(Class ~ ., data = trainData, method = "rpart",     trControl = control)
model_nn   <- train(Class ~ ., data = trainData, method = "nnet",      trControl = control, trace = FALSE)
model_knn  <- train(Class ~ ., data = trainData, method = "knn",       trControl = control)
model_svm  <- train(Class ~ ., data = trainData, method = "svmLinear", trControl = control)

results <- resamples(list(NB = model_nb, DecisionTree = model_dt,
                          NeuralNet = model_nn, KNN = model_knn,
                          SVM = model_svm))
summary(results)

pred_nb  <- predict(model_nb, newdata = testData)
pred_dt  <- predict(model_dt, newdata = testData)
pred_nn  <- predict(model_nn, newdata = testData)
pred_knn <- predict(model_knn, newdata = testData)
pred_svm <- predict(model_svm, newdata = testData)


testData$Class <- factor(testData$Class, levels = c("negative", "positive"))

pred_nb <- factor(pred_nb, levels = levels(testData$Class))
pred_dt <- factor(pred_dt, levels = levels(testData$Class))
pred_nn <- factor(pred_nn, levels = levels(testData$Class))
pred_knn <- factor(pred_knn, levels = levels(testData$Class))
pred_svm <- factor(pred_svm, levels = levels(testData$Class))

eval_nb <- postResample(pred_nb, testData$Class)
eval_dt  <- postResample(pred_dt,  testData$Class)
eval_nn  <- postResample(pred_nn,  testData$Class)
eval_knn <- postResample(pred_knn, testData$Class)
eval_svm <- postResample(pred_svm, testData$Class)

cat("Naive Bayes:\n");  print(eval_nb)
cat("Decision Tree:\n"); print(eval_dt)
cat("Neural Network:\n"); print(eval_nn)
cat("KNN:\n");          print(eval_knn)
cat("SVM:\n");  print(eval_svm)
