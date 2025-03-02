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