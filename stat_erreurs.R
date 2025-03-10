library(mvMORPH)

### première idée: simuler un brownien, fitter suivant le modèle brownien et faire un boxplot des erreurs

## paramètres du brownien simulé

# variance
sigma <- matrix(R,nrow = 2)

# moyenne (ancetre)
mu = c(1,1)

# dérive
b <- c(1,2)

## paramètres pour l'estimation
C <- vcv(tree)
invC<-solve(C)
Un <- matrix(rep(1,104),ncol = 1)

## simulations sans dérive:
sim <- mvSIM(tree = tree, nsim = 10000, model = "BM1", param = list(sigma = sigma, theta = mu))

err <- NULL
err_mu1 <- NULL
err_mu2 <- NULL
err_norm <- NULL
mu1 <- NULL
mu2 <- NULL

for(i in 1:10000){
  
  y <- sim[[i]] # simulation n°i
  mu_est <- solve(t(Un)%*%invC%*%Un)%*%t(Un)%*%invC%*%y #estimateur de mu (ancêtre)
  mu1[i] <- mu_est[1]
  mu2[i] <- mu_est[2]
  err_mu1[i] <- (mu[1] - mu_est[1]) # écart sur la première composante
  err_mu2[i] <- (mu[2] - mu_est[2]) # écart sur la deuxième composante
  err[i]<- sqrt(sum((mu - mu_est)^2)) # 'erreur globale"
  err_norm[i] <- sqrt((sum((mu-mu_est)^2))) / sqrt(sum(mu^2)) #erreur normalisée en norme 2
  
}
summary(mu1)
summary(mu2)

boxplot(err_norm)

# erreur globale
err_moy <- mean(err)
err_min <- err_moy - 1.96*sqrt(var(err)/10000)
err_max <- err_moy + 1.96*sqrt(var(err)/10000)
c(err_min,err_moy,err_max) # intervalle de confiance ?

# erreur sur la première composante
err_mu1_moy <- mean(err_mu1)
err_mu1_min <- err_mu1_moy - 1.96*sqrt(var(err_mu1)/10000)
err_mu1_max <- err_mu1_moy + 1.96*sqrt(var(err_mu1)/10000)
c(err_mu1_min, err_mu1_moy, err_mu1_moy)

# erreur sur la deuxième composante
err_mu2_moy <- mean(err_mu2)
err_mu2_min <- err_mu2_moy - 1.96*sqrt(var(err_mu2)/10000)
err_mu2_max <- err_mu2_moy + 1.96*sqrt(var(err_mu2)/10000)
c(err_mu2_min,err_mu2_moy,err_mu2_max)

## représentations graphique
# boxplot des erreurs
boxplot(err,main = "Boxplot des erreurs d'estimation",range = 1,ylim = c(-1,6))

boxplot(err_norm)

boxplot(err_mu1)
boxplot(err_mu2)

summary(err_mu1)
summary(err_mu2)

# boxplot des estimations
boxplot(mu1)

boxplot(mu2)


## même principe avec le modèle brownien avec dérive
T <- matrix(diag(C),ncol=1)
X <- cbind(Un,T)

simd <- mvSIM(tree = tree, nsim = 10000 , model = "BM1", param = list(sigma = sigma, theta = mu, trend = b))

err_mu1d <- NULL
err_mu2d <- NULL
mu1d <- NULL
mu2d <- NULL

for(i in 1:10000){
  y <- simd[[i]]
  theta <- solve(t(X)%*%invC%*%X)%*%t(X)%*%invC%*%y
  mu1d[i] <- theta[1,1]
  mu2d[i] <- theta[1,2]
  err_mu1d[i] <- (mu1d[i] - mu[1])^2
  err_mu2d[i] <- (mu2d[i] - mu[2])^2
}

## boxplot des erreurs
boxplot(err_mu1d)
boxplot(err_mu2d)

## boxplot des estimations
boxplot(mu1d)
boxplot(mu2d)

summary(mu1d)

### deuxième idée : simuler un brownien, fitter suivant un modèle brownien, avec et sans dérive. Compter le nombre
### de fois où l'AIC donne le 'bon' modèle

T <- matrix(diag(C))
X <- cbind(Un,T)

sim <- mvSIM(tree = tree, nsim = 1000, model = "BM1", param = list(sigma = sigma, theta = mu))

AIC1 <- NULL
AIC1d <- NULL

for(i in 1:1000){
  Y <- sim[[i]]
  mut <- solve(t(Un)%*%invC%*%Un)%*%t(Un)%*%invC%*%Y
  R <- 1/103*t(Y-Un%*%mut)%*%invC%*%(Y-Un%*%mut)
  theta <- solve(t(X)%*%invC%*%X)%*%t(X)%*%invC%*%Y
  R_d <- 1/102*t(Y)%*%invC%*%(Y-X%*%theta)

  L_hat <- -104*log(2*pi)-104/2*log(det(R))-log(det(C)) -1/2* sum(diag(solve(R)%*%t(Y-Un%*%mut)%*%solve(C)%*%(Y-Un%*%mut)))
  L_hat_d <- -104*log(2*pi)-104/2*log(det(R_d))-log(det(C)) -1/2* sum(diag(solve(R_d)%*%t(Y-X%*%theta)%*%solve(C)%*%(Y-X%*%theta)))
  AIC1[i] <- -2*L_hat + 2*6
  AIC1d[i] <- -2*L_hat_d + log(104)*8
}
## compter le nombre de fois où l'AIC est plus petit pour le modèle sans dérive
s <- 0
for(i in 1:1000){
  if(AIC1[i]<=AIC1d[i]){
    s = s+1
  }
}
s # l'AIC semble toujours meilleur pour le modèle sans dérive (c'est rassurant)


## pareil en faisant l'inverse, simulation avec dérive
simd <- mvSIM(tree = tree, nsim = 1000, model = "BM1", param = list(sigma = sigma, theta = mu, trend = c(1,2)))

AIC2 <- NULL
AIC2d <- NULL


for(i in 1:1000){
  Y <- sim[[i]]
  mut <- solve(t(Un)%*%invC%*%Un)%*%t(Un)%*%invC%*%Y
  R <- 1/103*t(Y-Un%*%mut)%*%invC%*%(Y-Un%*%mut)
  theta <- solve(t(X)%*%invC%*%X)%*%t(X)%*%invC%*%Y
  R_d <- 1/102*t(Y)%*%invC%*%(Y-X%*%theta)
  
  L_hat <- -104*log(2*pi)-104/2*log(det(R))-log(det(C)) -1/2* sum(diag(solve(R)%*%t(Y-Un%*%mut)%*%solve(C)%*%(Y-Un%*%mut)))
  L_hat_d <- -104*log(2*pi)-104/2*log(det(R_d))-log(det(C)) -1/2* sum(diag(solve(R_d)%*%t(Y-X%*%theta)%*%solve(C)%*%(Y-X%*%theta)))
  AIC2[i] <- -2*L_hat + 2*6
  AIC2d[i] <- -2*L_hat_d + log(104)*8
}

s <- 0
for(i in 1:1000){
  if(AIC2[i] <= AIC2d[i]){
    s = s + 1
  }
}
s # l'AIC semble toujours meilleur pour le modèle avec dérive (c'est rassurant)



# ### simuler un brownien avec les paramètres estimés
# simul <- mvSIM(tree = tree, nsim = 1, model = "BM1", param = list(sigma = R, theta = mut))
# simul
# Y
# 
# c(mean((Y - simul)[,1]),mean((Y-simul)[,2]))



######################################################################################
### simuler avec un OU et comparer avec les estimateur avec et sans dérive du Brownien
## paramètres
A <- matrix(c(0.1,0,0,0.1),nrow = 2)
B <- c(0.5,0.5)

## simulation
simOU <- mvSIM(tree,nsim = 1000, model = "OU1", param = list(sigma = sigma, theta = mu, alpha = A, beta = B))


## estimation sous brownien sans dérive
estim1 <- NULL
estim2 <- NULL
estim <- list()
for(i in 1:1000){
  estim[[i]]<-solve(t(Un)%*%invC%*%Un)%*%t(Un)%*%invC%*%simOU[[i]]
  estim1[i] <- estim[[i]][1]
  estim2[i] <- estim[[i]][2]
}

## estimation moyenne sans dérive
c(mean(estim1),mean(estim2))

estim_moy <- c(mean(estim1),mean(estim2))



## estimation sous brownien avec dérive
estimd1 <- NULL
estimd2 <- NULL
estimd <- list()

for(i in 1:1000){
  estimd[[i]] <- solve(t(X)%*%invC%*%X)%*%t(X)%*%invC%*%simOU[[i]]
  estimd1[i] <- estimd[[i]][1,1]
  estimd2[i] <- estimd[[i]][1,2]
}


## estimation moyenne avec dérive
estimd_moy <- c(mean(estimd1),mean(estimd2))

estim_moy
estimd_moy

## les deux modèles semblent être robustes sous modèle OU





### simulation avec un arbre quelconque
tree_sim <- pbtree(n=1000,type  = "continuous")
tree_sim <- pbtree(b = 1, d = 0.25 ,n=104,type = "continuous")

sim_bm <- mvSIM(tree = tree_sim, nsim = 1, model = "BM1", param = list(sigma = sigma, theta = c(1,1)))

solve(t(Un)%*%invC%*%Un)%*%t(Un)%*%invC%*%sim_bm

sim_bm <- mvSIM(tree = tree_sim, nsim = 1000, model = "BM1", param = list(sigma = sigma, theta = c(1,1)))

C <- vcv(tree_sim)
invC <- solve(C)
n <- length(tree_sim$tip.label)
Un <- matrix(rep(1,n), ncol = 1)

mu_hat <- list()
mu1_hat <- NULL
mu2_hat <- NULL

for(i in 1:1000){
  mu_hat[[i]]<-solve(t(Un)%*%invC%*%Un)%*%t(Un)%*%invC%*%sim_bm[[i]]
  mu1_hat <- mu_hat[[i]][1]
  mu2_hat <- mu_hat[[i]][2]
}
c(mean(mu1_hat),mean(mu2_hat))
## les estimations ne semblent plus bonnes...



## idée: faire un graphique de la valeur estimée en fonction du nombre de feuilles
mu_hat <- list()
mu_garb <- matrix(0,nrow = 1000,ncol = 2)
mu1_hat <- NULL
mu2_hat <- NULL
err1 <- NULL
err2 <- NULL
for(i in 10:500){
  # simuler l'arbre et le brownien
  tree_sim <- rtree(n=i,equiprob = FALSE) #on augmente le nb de feuilles de l'arbre à chaque itération
  sim_bm <- mvSIM(tree = tree_sim, nsim = 1000, model = "BM1", param = list(sigma = sigma, theta = mu))
  ## paramètres d'estimation
  n<-length(tree_sim$tip.label)
  C <- vcv(tree_sim)
  invC<-solve(C)
  Un<-matrix(rep(1,i),ncol = 1)
  # calculer 1000 estimations
  for(j in 1:1000){
    mu_garb[j,] <- solve(t(Un)%*%invC%*%Un)%*%t(Un)%*%invC%*%sim_bm[[j]]
  }
  
  # estimation moyenne pour un arbre à i feuilles
  mu_hat[[i]] <- c(mean(mu_garb[,1]),mean(mu_garb[,2]))
  
  mu1_hat[i] <- mu_hat[[i]][1]
  err1[i] <- mu[1] - mu1_hat[i]
  
  mu2_hat[i] <- mu_hat[[i]][2]
  err2[i] <- mu[2] - mu2_hat[i]
  
}
library(dplyr)
par(mfrow=c(1,2))
plot(x = 10:500, y = cummean(mu1_hat[10:500]), type = 'l')
plot(x = 10:500, y = cummean(mu2_hat[10:500]), type = 'l')

plot(x = 10:500, y = mu1_hat[10:500],type = "l")
plot(x = 10:500, y = mu2_hat[10:500],type = "l")

plot(err1[10:500], type = 'l')
plot(err2[10:500], type = 'l')

boxplot(err1)
boxplot(err2)

boxplot(mu1_hat[10:500])
boxplot(mu2_hat[20:500])


#################################################
## boxplots sur des arbres de tailles différentes
#################################################

### arbre à 10 feuilles
tree10 <- rtree(n=10,equiprob = FALSE)
MB10 <- mvSIM(tree = tree10, nsim = 10000, model = "BM1", param = list(sigma = sigma, theta = mu))
C10 <- vcv(tree10)
U10 <- matrix(rep(1,10),ncol = 1)
invC10 <- solve(C10)
mu10 <- list()
mu1_10 <- NULL
mu2_10 <- NULL
for(i in 1:10000){
  mu10[[i]] <- solve(t(U10)%*%invC10%*%U10)%*%t(U10)%*%invC10%*%MB10[[i]]
  mu1_10[i] <- mu10[[i]][1]
  mu2_10[i] <- mu10[[i]][2]
}



### arbre à 50 feuilles
tree50 <- rtree(n = 50, equiprob = FALSE)
MB50 <- mvSIM(tree = tree50, nsim = 10000, model = "BM1", param = list(sigma = sigma, theta = mu))
C50 <- vcv(tree50)
U50 <- matrix(rep(1,50),ncol = 1)
invC50 <- solve(C50)
mu50 <- list()
mu1_50 <- NULL
mu2_50 <- NULL
for(i in 1:10000){
  mu50[[i]] <- solve(t(U50)%*%invC50%*%U50)%*%t(U50)%*%invC50%*%MB50[[i]]
  mu1_50[i] <- mu50[[i]][1]
  mu2_50[i] <- mu50[[i]][2]
}


### arbre à 100 feuilles
tree100 <- rtree(n = 100, equiprob = FALSE)
MB100 <- mvSIM(tree = tree100, nsim = 10000, model = "BM1", param = list(sigma = sigma, theta = mu))
C100 <- vcv(tree100)
U100 <- matrix(rep(1,100),ncol = 1)
invC100 <- solve(C100)
mu100 <- list()
mu1_100 <- NULL
mu2_100 <- NULL
for(i in 1:10000){
  mu100[[i]] <- solve(t(U100)%*%invC100%*%U100)%*%t(U100)%*%invC100%*%MB100[[i]]
  mu1_100[i] <- mu100[[i]][1]
  mu2_100[i] <- mu100[[i]][2]
}


### arbre à 150 feuilles
tree150 <- rtree(n = 150, equiprob = FALSE)
MB150 <- mvSIM(tree = tree150, nsim = 10000, model = "BM1", param = list(sigma = sigma, theta = mu))
C150 <- vcv(tree150)
U150 <- matrix(rep(1,150),ncol = 1)
invC150 <- solve(C150)
mu150 <- list()
mu1_150 <- NULL
mu2_150 <- NULL
for(i in 1:10000){
  mu150[[i]] <- solve(t(U150)%*%invC150%*%U150)%*%t(U150)%*%invC150%*%MB150[[i]]
  mu1_150[i] <- mu150[[i]][1]
  mu2_150[i] <- mu150[[i]][2]
}


### arbre à 200 feuilles
tree200 <- rtree(n = 200, equiprob = FALSE)
MB200 <- mvSIM(tree = tree200, nsim = 10000, model = "BM1", param = list(sigma = sigma, theta = mu))
C200 <- vcv(tree200)
U200 <- matrix(rep(1,200),ncol = 1)
invC200 <- solve(C200)
mu200 <- list()
mu1_200 <- NULL
mu2_200 <- NULL
for(i in 1:10000){
  mu200[[i]] <- solve(t(U200)%*%invC200%*%U200)%*%t(U200)%*%invC200%*%MB200[[i]]
  mu1_200[i] <- mu200[[i]][1]
  mu2_200[i] <- mu200[[i]][2]
}


### arbre à 500 feuilles
# tree500 <- rtree(n = 500, equiprob = FALSE)
# MB500 <- mvSIM(tree = tree500, nsim = 1000, model = "BM1", param = list(sigma = sigma, theta = mu))
# C500 <- vcv(tree500)
# U500 <- matrix(rep(1,500),ncol = 1)
# invC500 <- solve(C500)
# mu500 <- list()
# mu1_500 <- NULL
# mu2_500 <- NULL
# for(i in 1:1000){
#   mu500[[i]] <- solve(t(U500)%*%invC500%*%U500)%*%t(U500)%*%invC500%*%MB500[[i]]
#   mu1_500[i] <- mu500[[i]][1]
#   mu2_500[i] <- mu500[[i]][2]
# }


### arbre à 1000 feuilles
# tree1000 <- rtree(n=1000, equiprob = FALSE)
# MB1000 <- mvSIM(tree = tree1000, nsim = 1000, model = "BM1", param = list(sigma = sigma, theta = mu))
# C1000 <- vcv(tree1000)
# U1000 <- matrix(rep(1,1000),ncol = 1)
# invC1000 <- solve(C1000)
# mu1000 <- list()
# mu1_1000 <- NULL
# mu2_1000 <- NULL
# for(i in 1:1000){
#   mu1000[[i]] <- solve(t(U1000)%*%invC1000%*%U1000)%*%t(U1000)%*%invC1000%*%MB1000[[i]]
#   mu1_1000[i] <- mu1000[[i]][1]
#   mu2_1000[i] <- mu1000[[i]][2]
# }


# data_mu1 <- data.frame(cbind(mu1_10,mu1_50,mu1_100,mu1_500,mu1_1000))
data_mu1 <- data.frame(cbind(mu1_10,mu1_50,mu1_100,mu1_150,mu1_200))
boxplot(data_mu1)

data_mu2 <- data.frame(cbind(mu2_10,mu2_50,mu2_100,mu2_500,mu2_1000))
boxplot(data_mu2)

## La variance diminue tout le temps sauf pour l'arbre à 1000 feuilles

#################################################
#################################################
## estimation moyenne sur un arbre de 500 feuille

tree_sim <- rtree(n=500,equiprob = FALSE)
mb_sim <- mvSIM(tree = tree_sim, nsim = 1000, model = "BM1", param = list(sigma = sigma, theta = mu))

mu_hat <- list()
mu1_hat <- NULL
mu2_hat <- NULL

C <- vcv(tree_sim)
invC <- solve(C)
Un <- matrix(rep(1,length(tree_sim$tip.label)),ncol = 1)

for(i in 1:500){
  mu_hat[[i]] <- solve(t(Un)%*%invC%*%Un)%*%t(Un)%*%invC%*%mb_sim[[i]]
  mu1_hat[i] <- mu_hat[[i]][1]
  mu2_hat[i] <- mu_hat[[i]][2]
}

c(mean(mu1_hat), mean(mu2_hat))

tree_sim <- rtree(n = 500, equiprob = FALSE)#, min = 0, max = 20)
mb_sim <- mvSIM(tree = tree_sim, nsim = 1, model = "BM1", param = list(sigma = sigma, theta = mu))

C <- vcv(tree_sim)
invC <- solve(C)
Un <- matrix(rep(1, length(tree_sim$tip.label)),ncol = 1)

solve(t(Un)%*%invC%*%Un)%*%t(Un)%*%invC%*%mb_sim

str(tree_sim)

par(mfrow = c(1,2))
plot(tree,show.tip.label = FALSE)
plot(tree_sim,show.tip.label = FALSE)
