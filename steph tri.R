library(ggplot2)
library(stringr)

demo_course <- read.csv2("/Users/ledanois/Desktop/FFTri/Rating/Production Matteo/tabH_pour_le_thibs.csv",sep=',')

demo_course[,-1]->demo_course
colnames(demo_course)<-c("Saison","Date_debut","Pays","Ville","Race_name","YOB", "NATIONALITY", "Athlete",
                        "START_NUMBER", "SWIM","T1","BIKE", "T2","RUN","Position","TOTAL_TIME","level",
                        "time")

demo_course$Distance<-NA
for( i in unique(demo_course$Race_name)){
  
  if(mean(demo_course[which(demo_course$Race_name == i),"time"],na.rm = T)/3600 < 1.30 ){
    demo_course[which(demo_course$Race_name == i),"Distance"]<-"Sprint Distance"
  }else if( mean(demo_course[which(demo_course$Race_name == i),"time"],na.rm = T)/3600 > 1.30 ){
    demo_course[which(demo_course$Race_name == i),"Distance"]<-"Standard Distance"
  }
  
}

demo_duels_M <- races_to_duel(demo_course[which(demo_course$Distance == "Standard Distance" ),], race_name = T,period=1)
demo_duels_S <- races_to_duel(demo_course[which(demo_course$Distance == "Sprint Distance" ),], race_name = T,period=1)

optim_stephenson(demo_duels_M,start_validation = 1,end_validation = 24,start_test = 25,end_test = 49)

unique(demo_duels_S[,"Athlete1"])->athleteS
unique(demo_duels_M[,"Athlete1"])->athleteM

classement_stephenson(Participants = athleteS,
                      Courses_en_stock = demo_course[which(demo_course$Distance == "Sprint Distance" ),] )->a
classement_stephenson(Participants = athleteM,
                      Courses_en_stock = demo_course[which(demo_course$Distance == "Standard Distance" ),] )->b

sig=61.56
cval=4.649
beta=6.614
lambda=3.716

demo_duels_S$Period <- as.numeric(demo_duels_S$Period)
demo_duels_S$Result <- as.numeric(demo_duels_S$Result)
steph(x=demo_duels_S[,-c(1,6)],init=c(1500,sig),bval=beta,cval=cval,lambda=lambda,hval=0,history=T,rdmax=sig) ->steph_a
steph_a$ratings[which(steph_a$ratings$Lag <= 12),]->steph_a$ratings

demo_duels_M$Period <- as.numeric(demo_duels_M$Period)
demo_duels_M$Result <- as.numeric(demo_duels_M$Result)
steph(x=demo_duels_M[,-c(1,6)],init=c(1500,sig),bval=beta,cval=cval,lambda=lambda,hval=0,history=T,rdmax=sig) ->steph_b
steph_b$ratings[which(steph_b$ratings$Lag <= 12),]->steph_b$ratings

demo_duels_S$Period <- as.numeric(demo_duels_S$Period)
demo_duels_S$Result <- as.numeric(demo_duels_S$Result)
  steph_all <- steph(x=duels[,-c(1,6)],init=c(1500,sig),bval=beta,cval=cval,lambda=lambda,hval=0,history=T,rdmax=sig)$ratings
  steph_all <- steph_all[steph_all$Player %in% Participants,c('Player','Rating')]

  
Participants<-steph_b$ratings$Player[c(1,2,5,7,12,17,22,26,31,34,38,42,45)]
  
steph_b$ratings[steph_b$ratings$Player %in% Participants,]->test
which(test$Player == "Jonas Schomburg GER 67535" )


prev<-function(object , participants ){

test<-as.data.frame(matrix(ncol = 4, nrow = 0))
for ( i in c(1:length(participants))){
  for ( f in c(1:length(participants))){
    
      data.frame(Period = ncol(object$history[,,])+1,
                 Athlete1 = participants[i],
                 Athlete2 = participants[f],
                 rat.Athlete2 = object$ratings[object$ratings$Player %in% participants[f],"Rating"])->test.bis
      rbind(test,test.bis)->test
      rm(test.bis)
      
  }
}

pvals <- predict(object, test)
cbind(test,pvals)->test

return(test)

}

prev(object = steph_b, participants = Participants)->grad

grad[which(grad$Athlete1 == "Jonas Schomburg GER 67535"),]->grad.bis

grad.bis[order(grad.bis$rat.Athlete2,decreasing = T),]->grad.bis
      
c(1:nrow(grad.bis))->place
cbind( place,grad.bis)->grad.bis

ggplot(grad.bis, aes(x = place, y = 1)) +
  geom_raster(position = "identity", aes(fill = abs(pvals-0.5)))+
  scale_x_continuous(breaks = c(1, 
                                seq(from = 0,to = max(grad.bis$place), by =5)[-1],
                                max(grad.bis$place))) +
  scale_fill_gradient(low = alpha("Red", alpha = 0.8), high = alpha("yellow", alpha = 0.5), na.value = NA,limit = c(0,0.5))+
  theme_void()+
  theme(
    axis.text.x = element_text( hjust = 0.5, colour = "Black"),
    legend.position = "none",
    legend.title   = element_blank(),
    plot.margin = margin(3,1,3,1, "cm")
    )
  
  
as.data.frame(steph_a$ratings)->base
base[base$Player %in% input$Startlist,c('Player','Rating')]->base
base$Course<-"Simulation"

as.data.frame(steph_b$ratings)->base
sum(as.numeric(rownames(base[base$Player %in% Participants,])[1:8]))/8


steph_a$history["Jan Frodeno GER 5692",,]->test
as.data.frame(test)->test
ggplotly(ggplot()+
  geom_path(data=test,aes(y = Rating, x = c(1:nrow(test))))+
  geom_ribbon(data=test, aes(ymin= Rating-Deviation, ymax=Rating+Deviation, x=c(1:nrow(test))), fill = "Blue", alpha =0.3)+
  scale_x_continuous(name = "Row")+
  theme_classic())


######## Niveau natation #########


demo_nat<-demo_course[,c("Saison","Date_debut","Pays","Ville","Race_name","YOB", "NATIONALITY", "Athlete",
               "START_NUMBER", "SWIM","level","Position","Distance")]

demo_nat.bis<-as.data.frame(matrix(nrow = 0, ncol= ncol(demo_nat)))
demo_nat$SWIM[which(demo_nat$SWIM== "00:00:00") ]<-NA
for( i in unique(demo_nat$Race_name)){
  
  rank(demo_nat$SWIM[which(demo_nat$Race_name == i) ],ties.method = "first",na.last = TRUE)->
    demo_nat$Position[which(demo_nat$Race_name == i) ]
  
  rangement<-demo_nat[which(demo_nat$Race_name == i), ]
  rangement[order(rangement$Position,na.last = T,decreasing = F),]->rangement
  
  
  rbind(demo_nat.bis,rangement)->demo_nat.bis
  rm(rangement)
  
}
rm(i)
demo_nat.bis->demo_nat
rm(demo_nat.bis)

Nat_duels_M <- races_to_duel(demo_nat[which(demo_nat$Distance == "Standard Distance" ),], race_name = T,period=1)
Nat_duels_S <- races_to_duel(demo_nat[which(demo_nat$Distance == "Sprint Distance" ),], race_name = T,period=1)


Nat_duels_S$Period <- as.numeric(Nat_duels_S$Period)
Nat_duels_S$Result <- as.numeric(Nat_duels_S$Result)
steph(x=Nat_duels_S[,-c(1,6)],init=c(1500,sig),bval=beta,cval=cval,lambda=lambda,hval=0,history=T,rdmax=sig) ->steph_nat_a
steph_nat_a$ratings[which(steph_nat_a$ratings$Lag <= 12),]->steph_nat_a$ratings

Nat_duels_M$Period <- as.numeric(Nat_duels_M$Period)
Nat_duels_M$Result <- as.numeric(Nat_duels_M$Result)
steph(x=Nat_duels_M[,-c(1,6)],init=c(1500,sig),bval=beta,cval=cval,lambda=lambda,hval=0,history=T,rdmax=sig) ->steph_nat_b
steph_nat_b$ratings[which(steph_nat_b$ratings$Lag <= 12),]->steph_nat_b$ratings

Participants<-steph_nat_b$ratings$Player[c(1,2,5,7,12,17,22,26,31,34,38,42,45)]

steph_nat_b$ratings[steph_nat_b$ratings$Player %in% Participants,]->test
test$Course<-1




ggplot()+
  geom_violin(data = test, aes(x = Course , y= Rating),trim = FALSE ,adjust = .5 )+
  geom_dotplot(data = test, aes(x = Course , y= Rating), binaxis='y', stackdir='center', fill = "Grey50")
  
steph_a$ratings$Player[which(str_detect(steph_a$ratings$Player,"FRA"))]->FRA.H

rbind(steph_a$ratings[which(steph_a$ratings$Player ==  FRA.H[1]),],
      steph_a$ratings[which(steph_a$ratings$Player ==  FRA.H[6]),])->test
test$Nat<-"FRA"

ggplot(data=test, aes( x = Nat , y = Rating, fill=Player ))+
  geom_bar(stat="identity")+
  theme(
    legend.position = "none"
  )

rbind(steph_nat_a$ratings[which(steph_nat_a$ratings$Player ==  FRA.H[1]),],
      steph_nat_a$ratings[which(steph_nat_a$ratings$Player ==  FRA.H[6]),])->test.nat
test.nat$Nat<-"FRA"

ggplot(data=test.nat, aes( x = Nat , y = Rating, fill=Player ))+
  geom_bar(stat="identity")


######### base femme #####

demo_course.f <- read.csv2("/Users/ledanois/Downloads/tab_F.csv",sep=';')
demo_course.f[,-1]->demo_course.f

Athlete<-paste(demo_course.f$ATHLETE_FIRST,demo_course.f$ATHLETE_LAST,demo_course.f$NATIONALITY,demo_course.f$ATHLETE_ID)
Race<-paste(demo_course.f$Ville,demo_course.f$Saison)

demo_course.f[,c(3,4,5,6,7,9,12,13,14,15,16,17,18,19,20,21)]->demo_course.f
demo_course.f$Athlete<-Athlete
demo_course.f$Race_name<-Race
rm(Athlete,Race)

colnames(demo_course.f)<-c("Saison","Date_debut","Pays","Ville","Distance","YOB", "NATIONALITY","START_NUMBER" ,
                            "SWIM","T1","BIKE", "T2","RUN","Position","TOTAL_TIME","level","Athlete","Race_name" )
to_sec(demo_course.f$TOTAL_TIME)->demo_course.f$time

demo_course.f<-demo_course.f[,c("Saison","Date_debut","Pays","Ville","Race_name","YOB", "NATIONALITY","Athlete",
                 "START_NUMBER","SWIM","T1","BIKE","T2","RUN","Position","TOTAL_TIME","level","time","Distance" )]      

demo_course.f$Distance<-NA
for( i in unique(demo_course.f$Race_name)){
  
  if(mean(demo_course.f[which(demo_course.f$Race_name == i),"time"],na.rm = T)/3600 < 1.30 ){
    demo_course.f[which(demo_course.f$Race_name == i),"Distance"]<-"Sprint Distance"
  }else if( mean(demo_course.f[which(demo_course.f$Race_name == i),"time"],na.rm = T)/3600 > 1.30 ){
    demo_course.f[which(demo_course.f$Race_name == i),"Distance"]<-"Standard Distance"
  }
  
}

for(i in c(1:nrow(demo_course.f))){
  if(demo_course.f$Position[i] == "DNS" |
     demo_course.f$Position[i] == "DSQ" |
     demo_course.f$Position[i] == "DNF" |
     demo_course.f$Position[i] == "LAP"){
    
    demo_course.f$Position[i]->demo_course.f$TOTAL_TIME[i]
    demo_course.f$Position[i]<-NA
    demo_course.f$time[i]<-NA
    
  }else{}
    
    
}
as.integer(demo_course.f$Position)->demo_course.f$Position
as.integer(demo_course.f$time)->demo_course.f$time

demo_course.f[order(demo_course.f$Date_debut),]->demo_course.f

demo_duels_F_S <- races_to_duel(demo_course.f[which(demo_course.f$Distance == "Sprint Distance" ),], race_name = T,period=1)
demo_duels_F_M <- races_to_duel(demo_course.f[which(demo_course.f$Distance == "Standard Distance" ),], race_name = T,period=1)

optim_stephenson(demo_duels_F_M,start_validation = 1,end_validation = 70,start_test =71 ,end_test = 105)
optim_stephenson(demo_duels_F_S,start_validation = 1,end_validation = 24,start_test = 25,end_test = 49)

max(as.numeric(demo_duels_F_M$Period))/4


unique(demo_course.f$Athlete[which(str_detect(demo_course.f$Athlete,"FRA"))])->FRA.F


FRA.F[c(19,22)]



test <- read.csv2("/Users/ledanois/Desktop/test.csv",sep=';')

graph_test<-ggplot(data=test, aes( x = Nat , y = Rating, fill=Player ))+
  geom_bar(stat="identity")+
  scale_y_continuous(limits = c( 0,9000), breaks = seq(1500,9000,by=500))+
  scale_x_discrete("Team")+
  theme_classic()+
  theme(
    legend.position = "none",
    text = element_text(color = "#31302E", face = "bold", size = 16),
    plot.background = element_rect(fill = NULL, color = NA), 
    panel.background = element_rect(fill = NULL, color = NA), 
    legend.background = element_rect(fill = "#ffffff", color = NA))
 
sum(test[which(test$Nat == "FRA"),"Rating"])

as.numeric(test$Rating)->test$Rating
