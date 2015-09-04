library(recommenderlab)
# generate rating data
m <- matrix(
  sample(
    c(as.numeric(0:5), NA), 50,
    replace = TRUE, prob = c(rep(.4 / 6,6),.6)
  ), ncol = 10,
  dimnames = list(
    user = paste("u", 1:5, sep = ''),
    item = paste("i", 1:10, sep ='')
  )
)
m

# convert to ratingMatrix
r <- as(m, 'realRatingMatrix')
as(r, 'dgCMatrix')
identical(as(r,'matrix'),m)
as(r, 'list') # convert to a list of users with their ratings
as(r, 'data.frame') # suited for writing rating data to a file

# Normalization
r
