## Clear The Enviornment
rm(list = ls(all = T))

### Set The Current Working Directory
setwd("C:\\Users\\dell\\Documents\\Kaggle\\lending-club-loan-data")

##Library
library(VIM)
library(dplyr)
library(tidyr)
library(tidyverse)
library(ggthemes)
library(ggplot2)
library(corrplot)
library(GGally)
library(DT)
library(caret)
library(rpart)
library(randomForest)
library(glmnet)

## Reading the data
loan = read.csv(file = "loan.csv", header = T, sep = ',')

## Print dimensions
dim(loan)

## Print column names
colnames(loan)

## Checking structure
str(loan)

## Checking summary
summary(loan)

## Duplicate rows
sum(duplicated(loan))

## Missing Values
colSums(is.na(loan))

## Data Cleaning
# Removing columns which has more than 10% missing values
loan_cleaned <- loan[, -which(colMeans(is.na(loan)) > 0.1)] 
# Removing redundant columns
loan_cleaned <- within(loan_cleaned, rm('member_id', 'id', 'url', 'emp_title', 'title','zip_code','tot_coll_amt', 'tot_cur_bal', 'total_rev_hi_lim'))
# Removing columns which has no significance in decision making
loan_cleaned <- loan_cleaned[, -c(2,3,13,28,29,30,31,32,33,34,35,36,37,38,40,43)]
dim(loan_cleaned)
colnames(loan_cleaned)

## Converting Data Types
loan_cleaned$term <- as.factor(loan_cleaned$term)
loan_cleaned$grade <- as.factor(loan_cleaned$grade)
loan_cleaned$emp_length <- as.factor(loan_cleaned$emp_length)
loan_cleaned$home_ownership <- as.factor(loan_cleaned$home_ownership)
loan_cleaned$verification_status <- as.factor(loan_cleaned$verification_status)
loan_cleaned$loan_status <- as.factor(loan_cleaned$loan_status)
loan_cleaned$application_type <- as.factor(loan_cleaned$application_type)
loan_cleaned$pymnt_plan <- as.factor(loan_cleaned$pymnt_plan)
loan_cleaned$initial_list_status <- as.factor(loan_cleaned$initial_list_status)
loan_cleaned$earliest_cr_line <- parse_date(loan_cleaned$earliest_cr_line,format =  "%b-%Y")
loan_cleaned$last_credit_pull_d <- parse_date(loan_cleaned$last_credit_pull_d,format =  "%b-%Y")

## Data Preparation
# Checking loan status
options(repr.plot.width=6, repr.plot.height=4)

loan_status.pct <- loan_cleaned %>% group_by(loan_status) %>% 
  dplyr::summarise(count=n()) %>% mutate(pct=count/sum(count))

ggplot(loan_status.pct, aes(x=reorder(loan_status, pct), y=pct, colour=loan_status, fill=loan_status)) +
  geom_bar(stat="identity",aes(color = I('black')), size = 0.1)+ coord_flip()+ 
  theme(legend.position = "none")+ xlab("Percent") + ylab("Loan_Status")

## Data Cleaning
loan_cleaned <- filter(loan_cleaned, loan_cleaned$loan_status == "Fully Paid" | loan_cleaned$loan_status == "Charged Off")
loan_cleaned <- mutate(loan_cleaned, binary_status=as.numeric(ifelse(loan_cleaned$loan_status %in% c('Current' , 'Issued' , 'Fully Paid'), 1, 0)))
barplot(table(loan_cleaned$loan_outcome) , col = 'green')
head(loan_cleaned)



## EXPLORATORY DATA ANALYSIS


# UNIVARIATE ANALYSIS
# Univariate analysis on Categorical variables
options(repr.plot.width=5, repr.plot.height=3)
#i. Term
loan_cleaned %>% group_by(term) %>% dplyr::summarise(count=n()) %>% mutate(pct=count/sum(count))%>% 
  ggplot(aes(x = term, y = pct)) + geom_bar(stat = "identity", fill = "darkred", aes(color = I('black')), size = 0.1)+xlab("Term") + 
  ylab("Percent")+ theme_few()
#Number of loans issued for 36 months are more

#ii. Grade
loan_cleaned %>% group_by(grade) %>% dplyr::summarise(count=n()) %>% mutate(pct=count/sum(count))%>% 
  ggplot(aes(x = reorder(grade,-pct), y = pct)) + geom_bar(stat = "identity", fill = "darkred", aes(color = I('black')), size = 0.1) + 
  xlab("Grade") + ylab("Percent")+ theme_few()
#Grade B accounts for 30% of the loans

#iii. Employment Length
loan_cleaned %>% group_by(emp_length) %>% dplyr::summarise(count=n()) %>% mutate(pct=count/sum(count))%>% 
  ggplot(aes(x = reorder(emp_length, pct), y = pct)) + geom_bar(stat = "identity", fill = "darkred", aes(color = I('black')), size = 0.1) + 
  xlab("Length of employment") + ylab("Percent")+coord_flip()+ theme_few()

#iv. Home Ownership
loan_cleaned %>% group_by(home_ownership) %>% dplyr::summarise(count=n()) %>% 
  mutate(pct=count/sum(count))%>% 
  ggplot(aes(x = reorder(home_ownership, -pct), y = pct)) + geom_bar(stat = "identity", fill = "darkred", aes(color = I('black')), size = 0.1) + 
  xlab("Home Ownership") + ylab("Percent")+ theme_few()
#Rent and mortgage home owners account for 90% of loans

options(repr.plot.width=4, repr.plot.height=4)
#v. Verification Status
loan_cleaned %>% group_by(verification_status) %>% dplyr::summarise(count=n()) %>% 
  mutate(pct=count/sum(count))%>% 
  ggplot(aes(x = reorder(verification_status, -pct), y = pct)) + 
  geom_bar(stat = "identity", fill = "darkred", aes(color = I('black')), size = 0.1)+xlab("Verification Status") + ylab("Percent")+ theme_few()

#vi. Purpose
loan_cleaned %>% group_by(purpose) %>% dplyr::summarise(count=n()) %>% mutate(pct=count/sum(count))%>% 
  ggplot(aes(x = reorder(purpose, pct), y = pct)) + geom_bar(stat = "identity", fill = "darkred", aes(color = I('black')), size = 0.1) + 
  xlab("Purpose of Loan") + ylab("Percent")+ coord_flip()+theme_few()
#debt consolidation accounts for 60% of the loans borrowed

options(repr.plot.width=6, repr.plot.height=6)
#vii. State
loan_cleaned %>% group_by(addr_state) %>% dplyr::summarise(count=n()) %>% mutate(pct=count/sum(count))%>% 
  ggplot(aes(x = reorder(addr_state, pct), y = pct)) + geom_bar(stat = "identity", fill = "darkred", aes(color = I('white')), size = 0.1) + 
  xlab("State Wise Loan") + ylab("Percent")+ coord_flip()+theme_few()
#loans applied in CA are more



## Analysing the distribution of continous variables
loan_cleaned %>% keep(is.numeric) %>% gather() %>%  ggplot(aes(value)) + 
  facet_wrap(~ key, scales = "free") +
  geom_histogram(bins=20, color= "black", fill= "#3399FF")



# SEGMENTED UNIVARIATE ANALYSIS:
# Good Loan and Bad Loan

loan_cleaned$loan_status=ifelse(loan_cleaned$loan_status %in% c('Current' , 'Issued' , 'Fully Paid'), 'Good Loan', 'Bad Loan')

options(repr.plot.width=6, repr.plot.height=4)
#i. Term and Loan Status
ggplot(loan_cleaned, aes(x =term, fill = loan_status)) + geom_bar(stat='count', position='fill', aes(color = I('black')), size = 0.1) + 
  labs(x = 'Term') + 
  ylab("Percent of default Vs No default") +theme_few()
#Loans with 60 months term get defaulted more as compared to 36 months term

#ii. Grade and Loan Status
ggplot(loan_cleaned, aes(x = grade, fill = loan_status)) + geom_bar(stat='count', position='fill', aes(color = I('black')), size = 0.1) + 
  labs(x = 'Grade') + scale_fill_discrete(name="Loan_Status") +theme_few()
#Default increases with increase in Grade from A-G, A means lowest risk of loan default and G means higher risk of loan default

#iii. Employee length and Loan Status
ggplot(filter(loan_cleaned, emp_length != 'n/a'), aes(x =emp_length, fill = loan_status)) + 
  geom_bar(stat='count', position='fill', aes(color = I('black')), size = 0.1) +labs(x = 'emp_length') + 
  scale_fill_discrete(name="Loan_Status") + 
  theme(axis.text.x = element_text(angle = 45, vjust = 0.8, hjust=1))

#length of employment doesn't seems to have much impact on loan status

#iv. Home Ownership and Loan Status
ggplot(loan_cleaned, aes(x =home_ownership, fill = loan_status)) + 
  geom_bar(stat='count', position='fill', aes(color = I('black')), size = 0.1) +labs(x = 'home_ownership') +
  scale_fill_discrete(name="Loan_Status") +theme_few()
#The default rate in Own, rent and mortgage home status is almost same

#v. Verification Status and Loan Status
ggplot(loan_cleaned, aes(x =verification_status, fill = loan_status)) + 
  geom_bar(stat='count', position='fill', aes(color = I('black')), size = 0.1) +labs(x = 'Verification_status',  
                                                                                     y="Percent of default Vs No default") +
  theme_few()
#The default rate in verified category is slightly more than non verified categories

#vi. Purpose of Loan and Loan Status
loan_cleaned %>% group_by(purpose) %>% summarise(default.pct = (1-sum(binary_status)/n())) %>% 
  ggplot(aes(x = reorder(purpose, default.pct), y = default.pct)) +
  geom_bar(stat = "identity", fill =  "coral", aes(color = I('black')), size = 0.1)+coord_flip()+xlab("Purpose") + ylab("default percent")+ 
  theme_few()

options(repr.plot.width=6, repr.plot.height=8)

#vii. State and Loan Status
state.status <- loan_cleaned %>% group_by(addr_state) %>% 
  summarise(default.pct = (1-sum(binary_status)/n()))
ggplot(state.status, aes(x = reorder(addr_state, default.pct), y = default.pct)) +
  geom_bar(stat = "identity", fill = "coral", aes(color = I('white')), size = 0.1)+coord_flip()+xlab("States") + ylab("default percent")+ 
  theme_few()

# Segmented Univariate analysis on Continous variables

options(repr.plot.width=6, repr.plot.height=4)
#i. Loan Amount and Loan Status
ggplot(loan_cleaned, aes(x= loan_amnt)) + geom_density(aes(fill = as.factor(loan_status)))+  
  xlab("Loan_amount")+theme_few()
#Incidences of loan default can be seen when the loan amount is above 10,000

#ii. Interest Rate and Loan Status
ggplot(loan_cleaned, aes(x= int_rate, fill = loan_status)) +
  geom_histogram(bins = 10, position = "fill", aes(color = I('black')), size = 0.1)+ 
  xlab("Interest Rate")+ 
  ylab("Percent of default Vs No default")+theme_few()
ggplot(loan_cleaned, aes(x = loan_status, y = int_rate, fill = loan_status)) + geom_boxplot()
#ii. High interest rate is definitely linked to more number of defaults except for few outliers




## BIVARIATE ANALYSIS
# Check for correlation
options(repr.plot.width=8, repr.plot.height=6)

corrplot(cor(loan_cleaned[,unlist(lapply(loan_cleaned, is.numeric))], use = "complete.obs"), 
         type = "lower", method = "number")


## Data modelling

# Select only the columns which has most significant effect 
loan = loan %>%
  select(loan_status , loan_amnt , int_rate , grade , emp_length , home_ownership , 
         annual_inc , term)
loan

# Correcting labels
loan = loan %>%
  filter(!is.na(annual_inc) , 
         !(home_ownership %in% c('NONE' , 'ANY')) , 
         emp_length != 'n/a')

# Converting to binary for modelling
loan = loan %>%
  mutate(loan_outcome = ifelse(loan_status %in% c('Current' , 'Issued' , 'Fully Paid') , 0, 1))

# Create the new dataset by filtering 0's and 1's in the loan_outcome column and remove loan_status column for the modelling
loan2 = loan %>%
  select(-loan_status) %>%
  filter(loan_outcome %in% c(0 , 1))

# Split dataset 
loan2$loan_outcome = as.numeric(loan2$loan_outcome)
idx = sample(dim(loan2)[1] , 0.75*dim(loan2)[1] , replace = F)
trainset = loan2[idx , ]
testset = loan2[-idx , ]

# Fit logistic regression
glm.model = glm(loan_outcome ~ . , trainset , family = binomial(link = 'logit'))
summary(glm.model)

# Prediction on test set
preds = predict(glm.model , testset , type = 'response')

# Checking accuracy
preds.for.30 = ifelse(preds > 0.3 , 1 , 0)
confusion_matrix_30 = table(Predicted = preds.for.30 , Actual = testset$loan_outcome)
confusion_matrix_30
# Comes out to be 79.3%

# Area Under Curve
library(pROC)
auc(roc(testset$loan_outcome , preds))
# comes out to be 69.3%

# Plot ROC curve
plot.roc(testset$loan_outcome , preds , main = "Confidence interval of a threshold" , percent = TRUE , 
         ci = TRUE , of = "thresholds" , thresholds = "best" , print.thres = "best" , col = 'blue')

# Decision tree
tree.model <- rpart(loan_outcome ~ ., data = trainset, method ="class",xval = 5)

p1<-as.character(predict(tree.model,testset,type = "class"))
confusionMatrix(p1,testset$loan_outcome)

# Random Forest
model.rf<-randomForest(as.factor(trainset$loan_outcome)~.,data = trainset,ntree=50,mtry=6,importance=T,na.action = na.omit)
model.rf
testset$predicted.response <- predict(model.rf ,testset)
confusionMatrix(data=testset$predicted.response,reference=testset$loan_outcome)