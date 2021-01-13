#################################
## Ce package contient les fonctions necessaires à l'étude des ratings pour le triathlon.
## Les fonctions ont été généralisées au maximum pour rendre leur utilisation fonctionnelle pour n'importe quel sport.
## Néanmoins, des modifications du code peuvent être nécessaire pour l'adapter à votre utilisation et vos données.
#################################

library(PlayerRatings)
library(lubridate)

#################################
# Conversion de course à duel ---------------------------------------------

#Cette fonction a pour but de crée une dataframe de duels, à partir d'une dataframe de résultats de course
races_to_duel <- function(races,level=F,race_name=F,delta_time=F,period=NA){
  races$Athlete <- as.character(races$Athlete)
  
  if(race_name){
    races$Race_name <- as.character(races$Race_name)
  }
  #On crée une dataframe intermédiaire pour diminuer le temps de calcul et ne pas devoir
  #appeler à chaque fois une dataframe très longue (cela augmenterait fortement la complexité temporelle)
  df_inter<- data.frame(Event_nb=rep(NA,1000),Period=rep(NA,1000),Athlete1=rep(NA,1000),Athlete2=rep(NA,1000),Result=rep(NA,1000),Coef=rep(NA,1000),Delta_time=rep(NA,1000), Race_name =rep(NA,1000))
  
  #la dataframe finale
  df_fin=NULL
  
  #Initialisation
  Event_nb=0
  line=1
  Date='0000-00-00'
  #On crée une table de correspondance année/mois/période de temps (pour Glicko et Stephenson)
  if(!is.na(period)){
    
    #On recuper les années des mois des premieres et dernieres course de la dataframe
    first_year=as.integer(substr(races$Date[1],1,4))
    first_month=as.integer(substr(races$Date[1],6,7))
    last_year=as.integer(substr(races$Date[nrow(races)],1,4))
    last_month=as.integer(substr(races$Date[nrow(races)],6,7))
    
    #On calcule le nombre de mois passés
    nb_month=last_month-first_month+12*(last_year-first_year)+1
    
    #On initialise la table de correspondance
    table_month=data.frame(Year=rep(NA,nb_month),Month=rep(NA,nb_month),Period=NA)
    
    #On remplie la table de correspondance, ainsi avec une 'period' égale à 3, les 3 premiers
    #mois de compétions auront pour Période :1, puis les 3 mois suivants auront pour Période :2
    year=first_year
    month=first_month
    for (i in 1:nb_month){
      table_month[i,]<- c(year,month,(i+period-1)%/%period)
      if(month==12){
        month=1
        year=year+1
      }
      else{month=month+1}
    }
  }
  
  #On parcoure toutes les lignes de la dataframe 
  for (i in 1:nrow(races)){
    
    #Si on souhaite utiliser Elo 2K (poids différent en fonction de l'importance de la compétition)
    if (level){
      #Si 'Level' est renseigné comme 'High' alors le coef du duel est de 2, sinon il est de 1
      if(races$Level[i] =='High'){
        coef=2
      }
      else{coef=1}
    }
    else{coef=1}
    
    #Ici on regarde si on arrive à un 1er de classement, ce qui signifie qu'on est sur une nouvelle course
    #On stock la ligne du premier dans la variable first et Event_nb augmente de 1
    if (!is.na(races$Position[i])){
      
      if (races$Position[i]==1){
        
        first<- i
        Event_nb <- Event_nb +1
        
        #Ici on empeche Event_nb d'augmenter de 1 si la course rencontrée ne comporte qu'un participant,
        #ce qui n'apporterait aucun duel
        if (i>1){
          if (!is.na(races$Position[i-1])){
            if (races$Position[i-1]==1){
              Event_nb <- Event_nb - 1
            }
          }
        }
      }
    }
    
    if (i != first){
      
      #On parcoure tous les participants arrivés avant i, c'est pourquoi on va de first à i-1
      for (k in first:(i-1)){
        
        #Avec ce if on considère qu'il ya duel quand la perdonne arrivée avant nous a finit la course
        #Si 2 participants n'ont pas finit la course, alors ils ont tous les 2 perdu contre tous
        #ceux qui ont terminé la course, mais on ne considère pas de duel entre eux
        if(!is.na(races$Position[k])){
          
          #On stocke le nom de tous les athlètes
          Athlete1 <- races$Athlete[k]
          Athlete2 <- races$Athlete[i]
          
          #Si on a choisi l'option race_name alors on stock aussi le nom de la course
          if(race_name){
            Race_name <- races$Race_name[i]
          }
          else{Race_name=NA}
          
          #Si on a choisi l'option delta_time alors on calcul l'écart de temps à l'arrivée
          #entre les 2 athlètes (utilisé seulement dans Elo_time)
          if(delta_time){
            if(!is.na(races$Time[i])){
              Delta_time <- races$Time[i] - races$Time[k]
            }
            else{Delta_time<- NA}
          }
          else{ Delta_time <- NA }
          
          #Si on a entré une période (utilisé par glicko et stephenson)
          if(!is.na(period)){
            if (as.character(races$Date[i])!=Date){
              year=as.integer(substr(races$Date[i],1,4))
              month=as.integer(substr(races$Date[i],6,7))
              tab = table_month[table_month$Year==year,]
              tab = tab[tab$Month==month,]
              #On regarde dans la table de correspondance quelle période correspond au 
              #mois et à l'année de la course
              Period=tab[1,3]
            }
          }
          else{Period=NA}
          
          #On stock les informations du duel dans la dataframe intermédiaire
          df_inter[line,] <- c(Event_nb,Period,Athlete1,Athlete2,1,coef,Delta_time,Race_name)
          
          #On passe à la ligne suivante
          line <- line +1
          
          #Si on arrive à la fin de la dataframe intermédiaire, alors on l'ajoute à la
          #dataframe finale et on réinitialise la dataframe intermédiaire
          if (line==1000){
            line <- 1
            df_fin<- rbind(df_fin,df_inter)
            df_inter <- data.frame(Event_nb=rep(NA,1000),Period=rep(NA,1000),Athlete1=rep(NA,1000),Athlete2=rep(NA,1000),Result=rep(NA,1000),Coef=rep(NA,1000),Delta_time=rep(NA,1000), Race_name =rep(NA,1000))
            
          }
        }
      }
    }
    if (i%%100==0){
      print(i)
    }
  }
  
  # On ajoute la dernière dataframe intermédiaire à la dataframe finale
  df_fin<- rbind(df_fin,df_inter)
  
  #Puis on supprime les lignes non remplies ajoutées par la dataframe intermediaire
  df_fin <- df_fin[!is.na(df_fin$Event_nb),]
  
  #Si ces options ne sont pas cochées, alors on retire les variables correspondantes de la 
  #dataframe finale
  if(level==F){
    df_fin = df_fin[,-which(colnames(df_fin)=='Coef')]
  }
  
  if(delta_time==F){
    df_fin = df_fin[,-which(colnames(df_fin)=='Delta_time')]
  }
  
  if(race_name==F){
    df_fin = df_fin[,-which(colnames(df_fin)=='Race_name')]
  }
  
  if(is.na(period)){
    df_fin = df_fin[,-which(colnames(df_fin)=='Period')]
  }
  
  #On retourne la dataframe finale
  return(df_fin)
}

#################################

#################################
# Optimisation Elo -----------------------------------------------------

#Fonction utilisée dans optim_elo, qui nous renvoit la prédiction (entre 0 et 1) pour un duel de A contre B
#Si cette fonction renvoit 0.75 alors A a 3 chances sur 4 de battre B
Prediction <- function(id1,id2,week,df){
  #print('ok')
  Score1 <- df[id1,week+1]
  Score2 <- df[id2,week+1]
  if (Score1==Score2){
    return(NA)
  }
  else {
    return(1/(1+10^(-(Score1-Score2)/400)))
  }
}

#Calcule le logloss avec y le résultat (0 ou 1) et la prédiction p (entre 0 et 1)
logloss <- function(y,p){
  -(y*log10(p)+(1-y)*log10((1-p)))
}

#Cette fonction prend une valeur de K, une dataframe de duels pour construire un classement, et une 
#dataframe de duels où l'on va calculer le pourcentage de duels bien prédits
#Cette fonction est utilisée dans optim_elo, ne pas l'utiliser seule
test_elo <- function(K,combats,tests_combats){
  # On calcule le classement sur tous les 'combats' avec le paramètre 'K'
  elo_all <- elo(combats,init=1500,kfac=K,history=T)
  
  # On conserve les scores à la fin de chaque période dans une dataframe df_hist
  df_hist <- as.data.frame(elo_all$history[,,1])
  df_hist <- cbind(rownames(df_hist),rep(1500,nrow(df_hist)),df_hist)
  rownames(df_hist) <- c(1:nrow(df_hist))
  colnames(df_hist)[1] <- 'Player'
  colnames(df_hist)[2] <- '0'
  
  #On initialise le compteur de combats et de bonne prédicitons
  countcombats <- 0  
  goodpred <- 0
  
  #On parcoure tous les combats tests
  for (i in 1:nrow(tests_combats)){
    
    # On recupere les lignes des deux combattants dans l'historique des scores df_hist
    id1 <- which(df_hist$Player==tests_combats$Athlete1[i])
    id2 <- which(df_hist$Player==tests_combats$Athlete2[i])
    
    # On calcule la prédiciton
    p <- Prediction(id1,id2,tests_combats$Event_nb[i],df_hist)
    
    # Si elle est NA, c'est à dire si les combattants ont le même score avant le combats, 
    # alors on ne rentre pas dans la boucle
    if (is.na(p)==F){
      y=tests_combats$Result[i]
      countcombats <- countcombats + 1 # On rajoute 1 au compteur de combats
      if(p>0.5 & y>0.5){ goodpred <- goodpred+1} #Si bien prédit alors on ajoute 1 au compteur de bonnes prédictions
      if(p<0.5 & y<0.5){ goodpred <- goodpred+1}
    }
    
  }
  # On retourne le pourcentage de bonnes prédicitons
  return(goodpred/countcombats*100)
}

#Cette fonction prend en argument une liste de duels et les valeurs correspondant au Event_nb pour la partie 
#validation et pour la partie test. Elle nous print le K optimisé, ie qui minimise la fonction d'erreur
#logloss pour les duels dans la période de validation. Ainsi que les pourcentages de duels bien prédits
#avec le K optimisé, dans la période de validation et dans la période de test

#IMPORTANT : la dataframe combats_to_analyse doit contenir 4 variables : 
# Event_nb : le numéro de l'evenement, dans l'ordre croissant de 1 jusqu'au nbre de compétitions 
# Athlete1 : le nom de l'athlete 1
# Athlete2 : le nom de l'athlete 2
# Result : 1 si athlète 1 gagne, 0 si il perd, 0.5 si match nul
optim_elo <- function(combats_to_analyse,start_validation,end_validation,start_test,end_test){
  combats_to_analyse<- combats_to_analyse[,c('Event_nb','Athlete1','Athlete2','Result')]
  
  #On s'assure que ces deux variables sont bien numériques pr eviter les erreurs plus tard
  combats_to_analyse$Event_nb <- as.numeric(combats_to_analyse$Event_nb)
  combats_to_analyse$Result <- as.numeric(combats_to_analyse$Result)
  
  # On crée une dataframe des combats utilisés pour la validation
  combats_for_validation <- combats_to_analyse[combats_to_analyse$Event_nb %in% c(start_validation:end_validation),]
  
  #On initialise la barre de progression
  inc <<-0
  pb <- txtProgressBar(min=0,max=50,style=3)
  
  # On définie la fonction que l'on va passer dans la fonction optim pour optimiser le K
  err_elo_fun <- function(K){
    
    #On update la barre de progression
    inc<<-inc+1
    setTxtProgressBar(pb,inc)
    
    # On calcule les ratings sur tous nos combats (avec history=T on garde l'historique des scores de chacuns)
    elo_all <- elo(combats_to_analyse,init=1500,kfac=K,history=T)
    
    # On stock les scores à la fin de chaque période : on crée un historique des scores
    # et on le met en forme
    df_hist <- as.data.frame(elo_all$history[,,1])
    df_hist <- cbind(rownames(df_hist),rep(1500,nrow(df_hist)),df_hist)
    rownames(df_hist) <- c(1:nrow(df_hist))
    colnames(df_hist)[1] <- 'Player'
    colnames(df_hist)[2] <- '0'
    
    # On initialise le compeur de combats et la somme des logloss
    countcombats <- 0  
    sumloss <- 0
    
    #On parcoure tous les combats de la dataframe validation pour calculer le logloss
    for (i in 1:nrow(combats_for_validation)){
      
      # On recupere les lignes des deux combattants dans l'historique des scores df_hist
      id1 <- which(df_hist$Player==combats_for_validation$Athlete1[i])
      id2 <- which(df_hist$Player==combats_for_validation$Athlete2[i])
      
      # On calcule la prédiciton
      p <- Prediction(id1,id2,combats_for_validation$Event_nb[i],df_hist)
      
      # Si les scores sont égaux, prédiction renvoie NA -> alors on ne compte pas le combats
      if (is.na(p)){
        floss <- 0
      }
      else {
        y=combats_for_validation$Result[i] # On récupere le résultat du combat
        floss <- logloss(y,p) # On calcule le résultat de logloss
        countcombats <- countcombats + 1 # On rajoute 1 au compteur de combats
      }
      sumloss <- sumloss+floss # On actualise la somme des logloss
    }
    return(sumloss/countcombats) # On retourne la moyenne des logloss
  }
  
  # On cherche le K optimal, en mettant 20 comme valeur initiale 
  Optimisation <- optim(20,err_elo_fun,method="BFGS")
  
  setTxtProgressBar(pb,50)
  # On recupere le K optimal
  Kopt <- Optimisation$par
  
  #On recupere le resultat de la moyenne des logloss avec le K optimisé
  logloss <- Optimisation$value
  
  #On print les données
  print(paste("K optimal :",Kopt))
  print(paste('logloss :',logloss))
  
  # On calcule le pourcentage de bonnes prédicitons pour la validation
  good_pred <- test_elo(Kopt,combats_to_analyse,combats_for_validation)
  # On le print
  print(paste('Correct classification rate of validation :',good_pred))
  
  #On fait pareil pour la partie test
  combats_for_test <- combats_to_analyse[combats_to_analyse$Event_nb %in% c(start_test:end_test),]
  good_pred <- test_elo(Kopt,combats_to_analyse,combats_for_test)
  print(paste('Correct classification rate of test :',good_pred))
}

#################################

#################################
# Optimisation Glicko -----------------------------------------------------

#Fonction utilisée dans optim_glicko, qui nous renvoit la prédiction (entre 0 et 1) pour un duel de A contre B
#Si cette fonction renvoit 0.75 alors A a 3 chances sur 4 de battre B
#On utilise la formule donnée par glicko dans son papier
Prediction_with_dev <- function(id1,id2,week,rating,deviance,games_not_playing,c, RDinit){
  Score1 <- rating[id1,week+1]
  Score2 <- rating[id2,week+1]
  dev1 <- deviance[id1,week+1]
  dev2 <- deviance[id2,week+1] 
  gnp1 <- games_not_playing[id1,week+1] + 1
  gnp2 <- games_not_playing[id2,week+1] + 1
  dev1 <- min(sqrt((dev1^2)+gnp1*c^2),RDinit)
  dev2 <- min(sqrt((dev2^2)+gnp2*c^2),RDinit)
  if (Score1==Score2){
    return(NA)
  }
  else {
    q <- log(10)/400
    g <- 1/(sqrt(1 + 3*(q^2)*sqrt((dev1^2)+(dev2^2))/(pi^2)))
    return(1/(1+10^(-g*(Score1-Score2)/400)))
  }
}


#Cette fonction prend une valeur de sig et c, une dataframe de duels pour construire un classement, et une 
#dataframe de duels où l'on va calculer le pourcentage de duels bien prédits
#Cette fonction est utilisée dans optim_glicko, ne pas l'utiliser seule
test_glicko <- function(sigandcval, combats,tests_combats){
  sig <- sigandcval[1]
  cval <- sigandcval[2]
  
  # On calcule le classement sur tous les 'combats' avec les parametres donnés
  glicko_all <- glicko(combats,init=c(1500,sig),cval=cval,history=T,rdmax=sig)
  
  # On stock les scores à la fin de chaque période : on crée un historique des scores
  # et on le met en forme
  rating <- as.data.frame(glicko_all$history[,,1])
  rating <- cbind(rownames(rating),rep(1500,nrow(rating)),rating)
  rownames(rating) <- c(1:nrow(rating))
  colnames(rating)[1] <- 'Player'
  colnames(rating)[2] <- '0'
  
  # On stock les Rating Deviations à la fin de chaque période : on crée un historique des RD et on le
  # met en forme (utilisé dans le calcul de p : prédiction de victoire de Athlete1 contre Ahlete2)
  deviance <- as.data.frame(glicko_all$history[,,2])
  deviance <- cbind(rownames(deviance),rep(sig,nrow(deviance)),deviance)
  rownames(deviance) <- c(1:nrow(deviance))
  colnames(deviance)[1] <- 'Player'
  colnames(deviance)[2] <- '0'
  
  # On stock le nombre de période sans avoir participé, à la fin de chaque période
  # Utilisé dans le calcul de p : prédiction de victoire de Athlete1 contre Ahlete2
  games_not_playing <- as.data.frame(glicko_all$history[,,4])
  games_not_playing <- cbind(rownames(games_not_playing),
                             rep(0,nrow(games_not_playing)),games_not_playing)
  rownames(games_not_playing) <- c(1:nrow(games_not_playing))
  colnames(games_not_playing)[1] <- 'Player'
  colnames(games_not_playing)[2] <- '0'
  
  #On initialise le compteur de combats et de bonne prédicitons
  countcombats <- 0  
  goodpred <- 0
  
  #On parcoure tous les combats tests
  for (i in 1:nrow(tests_combats)){
    
    # On recupere les lignes des deux combattants dans l'historique des scores df_hist
    id1 <- which(rating$Player==tests_combats$Athlete1[i])
    id2 <- which(rating$Player==tests_combats$Athlete2[i])
    
    # On calcule la prédiciton
    p <- Prediction_with_dev(id1,id2,tests_combats$Period[i],rating,deviance,games_not_playing,cval,sig)
    
    # Si elle est NA, c'est à dire si les combattants ont le même score avant le combats, 
    # alors on ne rentre pas dans la boucle
    if (is.na(p)){
      floss <- 0
    }
    else {
      y=tests_combats$Result[i]
      countcombats <- countcombats + 1 # On rajoute 1 au compteur de combats
      if(p>0.5 & y==1){ goodpred <- goodpred+1} #Si bien prédit alors on ajoute 1 au compteur de bonnes prédictions
      if(p<0.5 & y==0){ goodpred <- goodpred+1}
    }
  }
  # On retourne le pourcentage de bonnes prédicitons
  return(goodpred/countcombats)
}


#Cette fonction prend en argument une liste de duels et les valeurs correspondant aux périodes pour la partie 
#validation et pour la partie test. Elle nous print les parametres glicko optimisés, ie qui minimisent la fonction d'erreur
#logloss pour les duels dans la période de validation. Ainsi que les pourcentages de duels bien prédits
#avec les parametres optimisé, dans la période de validation et dans la période de test

#IMPORTANT : la dataframe combats_to_analyse doit contenir 4 variables : 
# Period : indique dans quelle période le combat a eu lieu 
# Athlete1 : le nom de l'athlete 1
# Athlete2 : le nom de l'athlete 2
# Result : 1 si athlète 1 gagne, 0 si il perd, 0.5 si match nul
optim_glicko <- function(combats_to_analyse,start_validation,end_validation,start_test,end_test){
  #On ne garde que les variables intéressantes
  combats_to_analyse<- combats_to_analyse[,c('Period','Athlete1','Athlete2','Result')]
  
  #Si il n'y a aucun duel dans une période donnée, alors on ajoute un combat match nul, qui ne changera 
  # en rien l'optimisation, ceci afin d'éviter des erreurs avec les fonctions du package PlayerRatings
  for (k in 1:max(as.numeric(combats_to_analyse$Period))){
    if (k %in% combats_to_analyse$Period==F){
      combats_to_analyse <- rbind(combats_to_analyse,c(k,'Chloe Gobe','Matteo Benaud',0.5))
    }
  }
  #On remet les duels en ordre
  combats_to_analyse <- combats_to_analyse[order(as.numeric(combats_to_analyse$Period)),]
  
  #On s'assure que ces deux variables sont bien numériques pr eviter les erreurs plus tard
  combats_to_analyse$Period <- as.numeric(combats_to_analyse$Period)
  combats_to_analyse$Result <- as.numeric(combats_to_analyse$Result)
  
  # On crée une dataframe des combats utilisés pour la validation
  combats_for_validation <- combats_to_analyse[combats_to_analyse$Period %in% c(start_validation:end_validation),]
  
  #On initialise la barre de progression
  inc <<-0
  pb <- txtProgressBar(min=0,max=300,style=3)
  
  # On définie la fonction que l'on va passer dans la fonction optim pour optimiser les parametres glicko
  err_glicko_fun <- function(sigandcval){
    #On update la barre de progression
    inc<<-inc+1
    setTxtProgressBar(pb,inc)
    
    sig <- sigandcval[1]
    cval <- sigandcval[2]
    
    # On calcule les ratings sur tous nos combats (avec history=T on garde l'historique des scores de chacuns)
    glicko_all <- glicko(combats_to_analyse,init=c(1500,sig),cval=cval,history=T,rdmax=sig)
    
    # On stock les scores à la fin de chaque période : on crée un historique des scores
    # et on le met en forme
    rating <- as.data.frame(glicko_all$history[,,1])
    rating <- cbind(rownames(rating),rep(1500,nrow(rating)),rating)
    rownames(rating) <- c(1:nrow(rating))
    colnames(rating)[1] <- 'Player'
    colnames(rating)[2] <- '0'
    
    # On stock les Rating Deviations à la fin de chaque période : on crée un historique des RD et on le
    # met en forme (utilisé dans le calcul de p : prédiction de victoire de Athlete1 contre Ahlete2)
    deviance <- as.data.frame(glicko_all$history[,,2])
    deviance <- cbind(rownames(deviance),rep(sig,nrow(deviance)),deviance)
    rownames(deviance) <- c(1:nrow(deviance))
    colnames(deviance)[1] <- 'Player'
    colnames(deviance)[2] <- '0'
    
    # On stock le nombre de période sans avoir participé, à la fin de chaque période
    # Utilisé dans le calcul de p : prédiction de victoire de Athlete1 contre Ahlete2
    games_not_playing <- as.data.frame(glicko_all$history[,,4])
    games_not_playing <- cbind(rownames(games_not_playing),
                               rep(0,nrow(games_not_playing)),games_not_playing)
    rownames(games_not_playing) <- c(1:nrow(games_not_playing))
    colnames(games_not_playing)[1] <- 'Player'
    colnames(games_not_playing)[2] <- '0'
    
    # On initialise le compeur de combats et la somme des logloss
    countcombats <- 0  
    sumloss <- 0
    
    #On parcoure tous les combats de la dataframe validation pour calculer le logloss
    for (i in 1:nrow(combats_for_validation)){
      # On recupere les lignes des deux combattants dans l'historique des scores 
      id1 <- which(rating$Player==combats_for_validation$Athlete1[i])
      id2 <- which(rating$Player==combats_for_validation$Athlete2[i])
      
      # On calcule la prédiciton
      p <- Prediction_with_dev(id1,id2,combats_for_validation$Period[i],rating,deviance,games_not_playing,cval,sig)
      
      # Si les scores sont égaux, prédiction renvoie NA -> alors on ne compte pas le combats
      if (is.na(p)){
        floss <- 0
      }
      else {
        y=combats_for_validation$Result[i] # On récupere le résultat du combat
        floss <- logloss(y,p) # On calcule le résultat de logloss
        countcombats <- countcombats + 1 # On rajoute 1 au compteur de combats
      }
      sumloss <- sumloss+floss # On actualise la somme des logloss
    }
    return(sumloss/countcombats) # On retourne la moyenne des logloss
  }
  
  # On cherche les parametres optimaux, en mettant 300 et 20 comme valeurs initiales 
  Optimisation <- optim(par =c(300,20),fn=err_glicko_fun,lower = c(0.1,0),method='L-BFGS-B')
  
  setTxtProgressBar(pb,300)
  # On recupere les parametres optimaux
  Kopt <- Optimisation$par
  
  #On recupere le resultat de la moyenne des logloss avec les parametres optimisés
  logloss <- Optimisation$value
  
  #On print les données
  print(paste("Sig_opt optimal :",Kopt[1]))
  print(paste("c_opt optimal :",Kopt[2]))
  print(paste("logloss :",logloss))
  
  # On calcule le pourcentage de bonnes prédicitons pour la validation
  good_pred <- test_glicko(Kopt,combats_to_analyse,combats_for_validation)
  # On le print
  print(paste('Correct classification rate of validation :',good_pred))
  
  #On fait pareil pour la partie test
  combats_for_test <- combats_to_analyse[combats_to_analyse$Period %in% c(start_test:end_test),]
  good_pred <- test_glicko(Kopt,combats_to_analyse,combats_for_test)
  print(paste('Correct classification rate of test :',good_pred))
}



#################################

#################################
# Opimisation Stephenson --------------------------------------------------
test_stephenson <- function(params, combats,tests_combats){
  sig <- params[1]
  cval <- params[2]
  beta <- params[3]
  lambda <- params[4]
  # On calcule le classement sur tous les 'combats' avec les parametres donnés
  steph_all <- steph(combats,init=c(1500,sig),bval=beta,cval=cval,lambda=lambda,hval=0,history=T,rdmax=sig)
  
  # On stock les scores à la fin de chaque période : on crée un historique des scores
  # et on le met en forme
  rating <- as.data.frame(steph_all$history[,,1])
  rating <- cbind(rownames(rating),rep(1500,nrow(rating)),rating)
  rownames(rating) <- c(1:nrow(rating))
  colnames(rating)[1] <- 'Player'
  colnames(rating)[2] <- '0'
  
  # On stock les Rating Deviations à la fin de chaque période : on crée un historique des RD et on le
  # met en forme (utilisé dans le calcul de p : prédiction de victoire de Athlete1 contre Ahlete2)
  deviance <- as.data.frame(steph_all$history[,,2])
  deviance <- cbind(rownames(deviance),rep(sig,nrow(deviance)),deviance)
  rownames(deviance) <- c(1:nrow(deviance))
  colnames(deviance)[1] <- 'Player'
  colnames(deviance)[2] <- '0'
  
  # On stock le nombre de période sans avoir participé, à la fin de chaque période
  # Utilisé dans le calcul de p : prédiction de victoire de Athlete1 contre Ahlete2
  games_not_playing <- as.data.frame(steph_all$history[,,4])
  games_not_playing <- cbind(rownames(games_not_playing),
                             rep(0,nrow(games_not_playing)),games_not_playing)
  rownames(games_not_playing) <- c(1:nrow(games_not_playing))
  colnames(games_not_playing)[1] <- 'Player'
  colnames(games_not_playing)[2] <- '0'
  
  #On initialise le compteur de combats et de bonne prédicitons
  countcombats <- 0  
  goodpred <- 0
  #On parcoure tous les combats tests
  for (i in 1:nrow(tests_combats)){
    
    # On recupere les lignes des deux combattants dans l'historique des scores df_hist
    id1 <- which(rating$Player==tests_combats$Athlete1[i])
    id2 <- which(rating$Player==tests_combats$Athlete2[i])
    
    # On calcule la prédiciton
    p <- Prediction_with_dev(id1,id2,tests_combats$Period[i],rating,deviance,games_not_playing,cval,sig)
    
    # Si elle est NA, c'est à dire si les combattants ont le même score avant le combats, 
    # alors on ne rentre pas dans la boucle
    if (is.na(p)){
      floss <- 0
    }
    else {
      y=tests_combats$Result[i]
      countcombats <- countcombats + 1 # On rajoute 1 au compteur de combats
      if(p>0.5 & y==1){ goodpred <- goodpred+1} #Si bien prédit alors on ajoute 1 au compteur de bonnes prédictions
      if(p<0.5 & y==0){ goodpred <- goodpred+1}
    }
  }
  # On retourne le pourcentage de bonnes prédicitons
  return(goodpred/countcombats)
}

optim_stephenson <- function(combats_to_analyse,start_validation,end_validation,start_test,end_test){
  #On ne garde que les variables intéressantes
  combats_to_analyse<- combats_to_analyse[,c('Period','Athlete1','Athlete2','Result')]
  
  #Si il n'y a aucun duel dans une période donnée, alors on ajoute un combat match nul, qui ne changera 
  # en rien l'optimisation, ceci afin d'éviter des erreurs avec les fonctions du package PlayerRatings
  for (k in 1:max(as.numeric(combats_to_analyse$Period))){
    if (k %in% combats_to_analyse$Period==F){
      combats_to_analyse <- rbind(combats_to_analyse,c(k,'Chloe Gobe','Matteo Benaud',0.5))
    }
  }
  #On remet les duels en ordre
  combats_to_analyse <- combats_to_analyse[order(as.numeric(combats_to_analyse$Period)),]
  
  #On s'assure que ces deux variables sont bien numériques pr eviter les erreurs plus tard
  combats_to_analyse$Period <- as.numeric(combats_to_analyse$Period)
  combats_to_analyse$Result <- as.numeric(combats_to_analyse$Result)
  
  # On crée une dataframe des combats utilisés pour la validation
  combats_for_validation <- combats_to_analyse[combats_to_analyse$Period %in% c(start_validation:end_validation),]
  
  #On initialise la barre de progression
  inc <<-0
  pb <- txtProgressBar(min=0,max=300,style=3)
  # On définie la fonction que l'on va passer dans la fonction optim pour optimiser les parametres glicko
  err_stephenson_fun <- function(params){
    
    #On update la barre de progression
    inc<<-inc+1
    setTxtProgressBar(pb,inc)
    #print("ok")
    sig <- params[1]
    cval <- params[2]
    beta <- params[3]
    lambda <- params[4]
    
    # On calcule les ratings sur tous nos combats (avec history=T on garde l'historique des scores de chacuns)
    steph_all <- steph(combats_to_analyse,init=c(1500,sig),bval=beta,cval=cval,lambda=lambda,hval=0,history=T,rdmax=sig)
    
    # On stock les scores à la fin de chaque période : on crée un historique des scores
    # et on le met en forme
    rating <- as.data.frame(steph_all$history[,,1])
    rating <- cbind(rownames(rating),rep(1500,nrow(rating)),rating)
    rownames(rating) <- c(1:nrow(rating))
    colnames(rating)[1] <- 'Player'
    colnames(rating)[2] <- '0'
    
    # On stock les Rating Deviations à la fin de chaque période : on crée un historique des RD et on le
    # met en forme (utilisé dans le calcul de p : prédiction de victoire de Athlete1 contre Ahlete2)
    deviance <- as.data.frame(steph_all$history[,,2])
    deviance <- cbind(rownames(deviance),rep(sig,nrow(deviance)),deviance)
    rownames(deviance) <- c(1:nrow(deviance))
    colnames(deviance)[1] <- 'Player'
    colnames(deviance)[2] <- '0'
    
    # On stock le nombre de période sans avoir participé, à la fin de chaque période
    # Utilisé dans le calcul de p : prédiction de victoire de Athlete1 contre Ahlete2
    games_not_playing <- as.data.frame(steph_all$history[,,4])
    games_not_playing <- cbind(rownames(games_not_playing),
                               rep(0,nrow(games_not_playing)),games_not_playing)
    rownames(games_not_playing) <- c(1:nrow(games_not_playing))
    colnames(games_not_playing)[1] <- 'Player'
    colnames(games_not_playing)[2] <- '0'
    
    # On initialise le compeur de combats et la somme des logloss
    countcombats <- 0  
    sumloss <- 0
    
    #On parcoure tous les combats de la dataframe validation pour calculer le logloss
    for (i in 1:nrow(combats_for_validation)){
      # On recupere les lignes des deux combattants dans l'historique des scores 
      id1 <- which(rating$Player==combats_for_validation$Athlete1[i])
      id2 <- which(rating$Player==combats_for_validation$Athlete2[i])
      
      # On calcule la prédiciton
      p <- Prediction_with_dev(id1,id2,combats_for_validation$Period[i],rating,deviance,games_not_playing,cval,sig)
      
      
      # Si les scores sont égaux, prédiction renvoie NA -> alors on ne compte pas le combats
      if (is.na(p)){
        floss <- 0
      }
      else {
        y=combats_for_validation$Result[i] # On récupere le résultat du combat
        floss <- logloss(y,p) # On calcule le résultat de logloss
        countcombats <- countcombats + 1 # On rajoute 1 au compteur de combats
      }
      sumloss <- sumloss+floss # On actualise la somme des logloss
    }
    return(sumloss/countcombats) # On retourne la moyenne des logloss
  }
  
  # On cherche les parametres optimaux, en mettant 300/30/0.5/0.5 comme valeurs initiales 
  Optimisation <- optim(par =c(300,30,0.05,0.05),fn=err_stephenson_fun,lower = c(0.1,0,0,0),method='L-BFGS-B')
  
  setTxtProgressBar(pb,300)
  # On recupere les parametres optimaux
  Kopt <- Optimisation$par
  
  #On recupere le resultat de la moyenne des logloss avec les parametres optimisés
  logloss <- Optimisation$value
  
  #On print les données
  print(paste("Sig_opt optimal :",Kopt[1]))
  print(paste("c_opt optimal :",Kopt[2]))
  print(paste("beta_opt optimal :",Kopt[3]))
  print(paste("lambda_opt optimal :",Kopt[4]))
  print(paste("logloss :",logloss))
  
  # On calcule le pourcentage de bonnes prédicitons pour la validation
  good_pred <- test_stephenson(Kopt,combats_to_analyse,combats_for_validation)
  # On le print
  print(paste('Correct classification rate of validation :',good_pred))
  
  #On fait pareil pour la partie test
  combats_for_test <- combats_to_analyse[combats_to_analyse$Period %in% c(start_test:end_test),]
  good_pred <- test_stephenson(Kopt,combats_to_analyse,combats_for_test)
  print(paste('Correct classification rate of test :',good_pred))
}



#################################

#################################
# Ranking loss ------------------------------------------------------------

#Cette fonction mesure l'écart moyen de classement pour les 10 premiers de la course avec elo
ranking_loss_elo <- function(K,combats,courses,start_test,end_test){
  
  #On s'assure que les variables soient dans le bon format pour éviter les erreurs
  combats$Event_nb <- as.numeric(combats$Event_nb)
  combats$Result <-   as.numeric(combats$Result)
  
  #On crée une dataframe des combats sur lesquels on mesure l'écart de classement
  tests_combats <- combats[combats$Event_nb %in% c(start_test:end_test),]
  
  # On calcule le classement sur tous les 'combats' avec le paramètre 'K'
  elo_all <- elo(combats[,c('Event_nb','Athlete1','Athlete2','Result')],init=1500,kfac=K,history=T)
  
  # On conserve les scores à la fin de chaque période dans une dataframe df_hist
  df_hist <- as.data.frame(elo_all$history[,,1])
  df_hist <- cbind(rownames(df_hist),rep(1500,nrow(df_hist)),df_hist)
  rownames(df_hist) <- c(1:nrow(df_hist))
  colnames(df_hist)[1] <- 'Player'
  colnames(df_hist)[2] <- '0'
  
  # On initialise le compteur
  erreur=c()
  
  # On parcoure toutes les courses
  for (period in start_test:end_test){
    #On recupere le nom de la course en question
    race_name <- combats[combats$Event_nb==period,]
    race_name <- race_name$Race_name[1]
    
    #On ne garde que la course en question
    run_result <- courses[courses$Race_name==race_name,]
    #On recupere les athlètes
    Athletes <- as.vector(run_result$Athlete)
    
    #On recupere le classement des athlètes concernés
    Classement <- df_hist[df_hist$Player %in% Athletes,c(1,period+1)]
    #On l'ordonne par prdre de points décroissants
    Classement <- Classement[order(Classement[,2], decreasing=T),]
    #Si il y a plus de 10 athlètes on ne garde que les 10 premiers
    if(length(Athletes)>10){
      Athletes <- Athletes[c(1:10)]
    }
    #On calcule l'écart de classement
    for (i in 1:length(Athletes)){
      rank = which(Classement[,1]==Athletes[i])
      erreur = c(erreur,abs(rank-i))
    }
  }
  #On retourne la moyenne
  print(paste("moyenne d'écart au classement",mean(erreur)))
  print(paste("mediane d'écart au classement",median(erreur)))
  return(erreur)
}

#Cette fonction mesure l'écart moyen de classement pour les 10 premiers de la course avec glicko
ranking_loss_glicko <- function(params,combats,courses,start_test,end_test){
  
  #Si il n'y a aucun duel dans une période donnée, alors on ajoute un combat match nul, qui ne changera 
  # en rien le ranking loss, ceci afin d'éviter des erreurs avec les fonctions du package PlayerRatings
  for (k in 1:max(as.numeric(combats$Period))){
    if (k %in% combats$Period==F){
      combats <- rbind(combats,c(NA,k,'Chloe Gobe','Matteo Benaud',0.5,NA))
    }
  }
  combats$Period <- as.numeric(combats$Period)
  combats$Result <- as.numeric(combats$Result)
  
  sig <- params[1]
  cval <- params[2]
  # On calcule le classement sur tous les 'combats' avec les parametres
  glicko_all <- glicko(combats[,c('Period','Athlete1','Athlete2','Result')],init=c(1500,sig),cval=cval,history=T,rdmax=sig)
  
  # On conserve les scores à la fin de chaque période dans une dataframe df_hist
  df_hist <- as.data.frame(glicko_all$history[,,1])
  df_hist <- cbind(rownames(df_hist),rep(1500,nrow(df_hist)),df_hist)
  rownames(df_hist) <- c(1:nrow(df_hist))
  colnames(df_hist)[1] <- 'Player'
  colnames(df_hist)[2] <- '0'
  
  # On initialise le compteur
  erreur=c()
  
  # On parcoure toutes les courses
  for (period in start_test:end_test){
    #On recupere le nom de la course en question
    reducted <- combats[combats$Event_nb==period,]
    race_name <- reducted$Race_name[1]
    
    #On recupere la periode correspondante
    mois <- reducted$Period[1]
    
    #On ne garde que la course en question
    run_result <- courses[courses$Race_name==race_name,]
    #On recupere les athlètes
    Athletes <- as.vector(run_result$Athlete)
    
    #On recupere le classement des athlètes concernés
    Classement <- df_hist[df_hist$Player %in% Athletes,c(1,mois+1)]
    #On l'ordonne par prdre de points décroissants
    Classement <- Classement[order(Classement[,2], decreasing=T),]
    #Si il y a plus de 10 athlètes on ne garde que les 10 premiers
    if(length(Athletes)>10){
      Athletes <- Athletes[c(1:10)]
    }
    #On calcule l'écart de classement
    for (i in 1:length(Athletes)){
      rank = which(Classement[,1]==Athletes[i])
      erreur = c(erreur,abs(rank-i))
    }
  }
  #On retourne la moyenne
  print(paste("moyenne d'écart au classement",mean(erreur)))
  print(paste("mediane d'écart au classement",median(erreur)))
  return(erreur)
}


#Cette fonction mesure l'écart moyen de classement pour les 10 premiers de la course avec stephenson
ranking_loss_steph <- function(params,combats,courses,start_test,end_test){
  
  #Si il n'y a aucun duel dans une période donnée, alors on ajoute un combat match nul, qui ne changera 
  # en rien le logloss, ceci afin d'éviter des erreurs avec les fonctions du package PlayerRatings
  for (k in 1:max(as.numeric(combats$Period))){
    if (k %in% combats$Period==F){
      combats <- rbind(combats,c(NA,k,'Chloe Gobe','Matteo Benaud',0.5,NA))
    }
  }
  #On s'assure que les données soient sous le bon format
  combats$Period <- as.numeric(combats$Period)
  combats$Result <- as.numeric(combats$Result)
  
  #On calcule le classement avec les parametre donnés
  sig <- params[1]
  cval <- params[2]
  beta <- params[3]
  lambda <- params[4]
  steph_all <- steph(combats[,c('Period','Athlete1','Athlete2','Result')],init=c(1500,sig),bval=beta,cval=cval,lambda=lambda,hval=0,history=T,rdmax=sig)
  
  # On conserve les scores à la fin de chaque période dans une dataframe df_hist
  df_hist <- as.data.frame(steph_all$history[,,1])
  df_hist <- cbind(rownames(df_hist),rep(1500,nrow(df_hist)),df_hist)
  rownames(df_hist) <- c(1:nrow(df_hist))
  colnames(df_hist)[1] <- 'Player'
  colnames(df_hist)[2] <- '0'
  
  # On initialise le compteur
  erreur=c()
  
  # On parcoure toutes les courses
  for (period in start_test:end_test){
    #On recupere le nom de la course en question
    reducted <- combats[combats$Event_nb==period,]
    race_name <- reducted$Race_name[1]
    
    mois <- reducted$Period[1]
    
    #On ne garde que la course en question
    run_result <- courses[courses$Race_name==race_name,]
    #On recupere les athlètes
    Athletes <- as.vector(run_result$Athlete)
    
    #On recupere le classement des athlètes concernés
    Classement <- df_hist[df_hist$Player %in% Athletes,c(1,mois+1)]
    #On l'ordonne par prdre de points décroissants
    Classement <- Classement[order(Classement[,2], decreasing=T),]
    #Si il y a plus de 10 athlètes on ne garde que les 10 premiers
    if(length(Athletes)>10){
      Athletes <- Athletes[c(1:10)]
    }
    #On calcule l'écart de classement
    for (i in 1:length(Athletes)){
      rank = which(Classement[,1]==Athletes[i])
      erreur = c(erreur,abs(rank-i))
    }
  }
  #On retourne la moyenne
  print(paste("moyenne d'écart au classement",mean(erreur)))
  print(paste("mediane d'écart au classement",median(erreur)))
  return(erreur)
}

#################################

#################################
# Classement avant une course ---------------------------------------------

#Elaborer le classement stephenson avant une course
classement_stephenson <- function(Participants,Courses_en_stock,sig=61.56,cval=4.649,beta=6.614,lambda=3.716){
  duels <- races_to_duel(Courses_en_stock,period=1)
  duels$Period <- as.numeric(duels$Period)
  duels$Result <- as.numeric(duels$Result)
  steph_all <- steph(duels[,c(-1)],init=c(1500,sig),bval=beta,cval=cval,lambda=lambda,hval=0,history=T,rdmax=sig)$ratings
  steph_all <- steph_all[steph_all$Player %in% Participants,c('Player','Rating')]
}


#################################