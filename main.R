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

print("4. Mostrar matrices de confusion y aniadir el AUC a la tabla de accuracy y kappa")
print("================================================================================")

cm_nb <- confusionMatrix(pred_nb, testData$Class)
cm_dt <- confusionMatrix(pred_dt, testData$Class)
cm_nn <- confusionMatrix(pred_nn, testData$Class)
cm_knn <- confusionMatrix(pred_knn, testData$Class)
cm_svm <- confusionMatrix(pred_svm, testData$Class)

print("Matrices de confusion")
cat("Naive Bayes:\n");  print(cm_nb$table)
cat("Decision Tree:\n"); print(cm_dt$table)
cat("Neural Network:\n"); print(cm_nn$table)
cat("KNN:\n");          print(cm_knn$table)
cat("SVM:\n");  print(cm_svm$table)

calcular_auc <- function(model, testData) {
  prob <- predict(model, newdata = testData, type = "prob")
  roc_obj <- roc(prob$positive, testData$Class)
  auc_val <- auc(roc_obj)
  return(auc_val)
}

auc_nb  <- calcular_auc(model_nb,  testData)
auc_dt  <- calcular_auc(model_dt,  testData)
auc_nn  <- calcular_auc(model_nn,  testData)
auc_knn <- calcular_auc(model_knn, testData)
auc_svm <- calcular_auc(model_svm, testData)

print("Tabla con accuracy, kappa y auc")
resultados_test <- data.frame(
  Modelo = c("Naive Bayes", "Decision Tree", "Neural Network", "Nearest Neighbour", "SVM (linear)"),
  Accuracy = c(eval_nb[1], eval_dt[1], eval_nn[1], eval_knn[1], eval_svm[1]),
  Kappa = c(eval_nb[2], eval_dt[2], eval_nn[2], eval_knn[2], eval_svm[2]),
  AUC = c(auc_nb, auc_dt, auc_nn, auc_knn, auc_svm)
)
print(resultados_test)

print("5. Representar curvas ROC")
trazar_roc <- function(model, testData, color) {
  # 5. a) recalculamos las predicciones con el parámetro prob
  prob <- predict(model, newdata = testData, type = "prob")
  # 5. b) creamos el objeto predicción
  pred <- prediction(prob$positive, testData$Class)
  # 5. c) calculamos TPR y FPR
  perf <- performance(pred, "tpr", "fpr")
  # 5. d) Dibujamos la curva
  plot(perf, col = color, lwd = 2, add = TRUE)
}

prob_nb <- predict(model_nb, newdata = testData, type = "prob")
pred_nb <- prediction(prob_nb$positive, testData$Class)
perf_nb <- performance(pred_nb, "tpr", "fpr")
plot(perf_nb, col = "blue", lwd = 2,
     main = "Curva ROC",
     xlab = "False Positive Rate", ylab = "True Positive Rate")

trazar_roc(model_dt,  testData, "red")
trazar_roc(model_nn,  testData, "green")
trazar_roc(model_knn, testData, "orange")
trazar_roc(model_svm, testData, "purple")

legend("bottomright", legend = c("Naive Bayes", "Decision Tree", "Neural Network",
                                 "KNN", "SVM (linear)"),
       col = c("blue", "red", "green", "orange", "purple"), lwd = 2)
