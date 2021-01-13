# Projet ratings Triathlon


Ce package contient les fonctions necessaires à l'étude des ratings pour le triathlon.  
Les fonctions ont été généralisées au maximum pour rendre leur utilisation fonctionnelle pour n'importe quel sport.  
Néanmoins, des modifications du code peuvent être nécessaire pour l'adapter à votre utilisation et vos données.


# Sommaire du Readme
1. [Contenu du package](#package)
    * [races_to_duel](#fonction1)
    * [optim_elo](#fonction2)
    * [optim_glicko](#fonction3)
    * [optim_steph](#fonction4)
    * [ranking_loss_elo](#fonction5)
    * [ranking_loss_glicko](#fonction6)
    * [ranking_loss_steph](#fonction6)

2. [Exemple d'utilisation](#example)



-------------------------------------------------------------



# 1. Contenu du package <a name="package"></a>

Inventaire des fonctions utiles à l'élaboration des ratings et à leur optimisation.

## **races_to_duel** <a name="fonction1"></a>

>### Description
>Cette fonction permet de créer une dataframe d'affrontements de 1vs1 à partir d'une dataframe de résultats de courses.

>### Usage
    dataframe_duels <- races_to_duel(races = dataframe_course, level=False, race_name = False, delta_time=False,period=1)

>### Arguments
>- **races** df : Une dataframe contenant au minimum une variable 'Athlete' qui indique le nom de l'athlète et une variable 'Position' indiquant le résultat de la course. Si un athlète ne termine pas une course, il faut que sa position soit NA, et il est considéré battu par tous les athlètes ayant finit la course.
>- **level** (opt) boolean : Par défaut level=False. Si level=True alors la dataframe_course doit contenir une variable 'Level' qui doit indiquer 'High' si le niveau de la course est élevé et 'Low' sinon. La dataframe_duels retournée contiendra alors une variable supplémentaire 'Coef' avec 2 pour les courses de haut niveau et 1 sinon. Cette option est nécessaire à l'utilisation de Elo_2K.
 >- **race_name** (opt) char : Par défaut race_name=False. Si race_name=True alors la dataframe_course doit contenir une variable 'Race_name' qui doit indiquer le nom de la course. Une variable 'Race_name' sera alors ajoutée à la dataframe retournée. 
 >- **delta_time** (opt) int : Par défaut delta_time=False. Si delta_time=True alors la dataframe_course doit contenir une variable 'Time' qui doit indiquer le temps final lors de la course, en secondes. Une variable 'Delta_time' sera alors ajoutée à la dataframe retournée, indiquant l'écart de temps entre les deux participants du duel. Cette option est nécessaire à l'utilisation de Elo_time.
 >- **period** (opt) int : Cette option necessite une variable 'Date' sous la forme 'yyyy-mm-dd' dans la dataframe de course. Si une période est renseignée, alors une variable 'Period' est ajoutée à la dataframe retournée. Elle indique a quelle période se situe la course. Par exemple si on indique period=3, alors les duels des courses des 3 premiers mois auront pour période 1, les 3 mois suivants auront pour période 2, etc .. Cette option, ne prenant que des entiers, est nécessaire pour l'utilisation de Glicko et de Stephenson.

 >### Value
 >Cette fonction retourne une dataframe de duels contenant 4 variables de base : 'Event_nb','Athlete1','Athlete2','Result'.  
 >- **Event_nb** : le numéro de la course correspondant au duel, 1 pour la première, 2 pour la 2ème, etc..
 >- **Athlete1** : le nom du premier athlète
 >- **Athlete2** : le nom du second athlète
 >- **Result** : 1 si Athlete1 gagne, 0 si Athlete2 gagne

 ## **optim_elo**<a name="fonction2"></a>

>### Description
>Cette fonction permet d'optimiser les parametres de rating Elo. 

>### Usage
    optim_elo(combats_to_analyse=df_duels,start_validation = 5,end_validation = 8,start_test = 9,end_test = 12)
>### Arguments
>- **combats_to_analyse** df : Une dataframe contenant une variable 'Event_nb' indiquant le numéro de la course, une variable 'Athlete1' indiquant le nom de l'athlete 1, 'Athlete2' indiquant le nom de l'athlete 2, une variable 'Result' indiquant 1 pour une victoire de l'athlete 1, 0 pour une victoire de l'athlete 2 et 0.5 pour un match nul.
>- **start_validatio** int : La valeur de 'Event_nb' à laquelle commencer la période de validation. L'optimisation se fait sur cette période de validation. Il faut donc laisser un certain nombre de course avant le début de la validation pour initialiser le rating.
 >- **end_validation** int : La valeur de 'Event_nb' à laquelle se terminer la validation.
 >- **start_test** int : La valeur de 'Event_nb' à laquelle se commence la période de test.
 >- **end_test** int : La valeur de 'Event_nb' à laquelle se temine la période de test.

 >### Value
 >Cette fonction print le parametre K minimisant la fonction d'erreur logloss pendant la période de validation.  
 >Elle print également la valeur du logloss, le pourcentages de duels bien prédits pendant la période de validation, le pourcentage de duels bien prédits pour la période de test, avec le K optimisé.

 ## **optim_glicko**<a name="fonction3"></a>

>### Description
>Cette fonction permet d'optimiser les parametres de rating Glicko. 

>### Usage
    optim_glicko(combats_to_analyse=df_duels,start_validation = 5,end_validation = 8,start_test = 9,end_test = 12)
>### Arguments
>- **combats_to_analyse** df : Une dataframe contenant une variable 'Period' indiquant la période à laquelle appartient le duel, une variable 'Athlete1' indiquant le nom de l'athlete 1, 'Athlete2' indiquant le nom de l'athlete 2, une variable 'Result' indiquant 1 pour une victoire de l'athlete 1, 0 pour une victoire de l'athlete 2 et 0.5 pour un match nul.
>- **start_validatio** int : La valeur de 'Period' à laquelle commencer la période de validation. L'optimisation se fait sur cette période de validation. Il faut donc laisser un certain nombre de course avant le début de la validation pour initialiser le rating.
 >- **end_validation** int : La valeur de 'Period' à laquelle se terminer la validation.
 >- **start_test** int : La valeur de 'Period' à laquelle se commence la période de test.
 >- **end_test** int : La valeur de 'Period' à laquelle se temine la période de test.

 >### Value
 >Cette fonction print les parametres sig_init et c, minimisant la fonction d'erreur logloss pendant la période de validation.  
 >Elle print également la valeur du logloss, le pourcentages de duels bien prédits pendant la période de validation, le pourcentage de duels bien prédits pour la période de test, avec le K optimisé.

 ## **optim_stephenson** <a name="fonction4"></a>

>### Description
>Cette fonction permet d'optimiser les parametres de rating Stephenson. 

>### Usage
    optim_stephenson(combats_to_analyse=df_duels,start_validation = 5,end_validation = 8,start_test = 9,end_test = 12)
>### Arguments
>- **combats_to_analyse** df : Une dataframe contenant une variable 'Period' indiquant la période à laquelle appartient le duel, une variable 'Athlete1' indiquant le nom de l'athlete 1, 'Athlete2' indiquant le nom de l'athlete 2, une variable 'Result' indiquant 1 pour une victoire de l'athlete 1, 0 pour une victoire de l'athlete 2 et 0.5 pour un match nul.
>- **start_validatio** int : La valeur de 'Period' à laquelle commencer la période de validation. L'optimisation se fait sur cette période de validation. Il faut donc laisser un certain nombre de course avant le début de la validation pour initialiser le rating.
 >- **end_validation** int : La valeur de 'Period' à laquelle se terminer la validation.
 >- **start_test** int : La valeur de 'Period' à laquelle se commence la période de test.
 >- **end_test** int : La valeur de 'Period' à laquelle se temine la période de test.

 >### Value
 >Cette fonction print les parametres sig_init,c,beta et lambda, minimisant la fonction d'erreur logloss pendant la période de validation.  
 >Elle print également la valeur du logloss, le pourcentages de duels bien prédits pendant la période de validation, le pourcentage de duels bien prédits pour la période de test, avec le K optimisé.

 ## **ranking_loss_elo** <a name="fonction5"></a>

>### Description
>Cette fonction permet de calculer les métriques d'écart au classement pour les 10 premiers de chaque course dans une période donnée, avec Elo comme système de classement.

>### Usage
    ranking_loss_elo (K,combats=df_duels,courses=df_courses,start_test=9,end_test=12){
>### Arguments
>- **K** numeric : Le parametre K à utiliser pour le classement Elo.
>- **combats** df : La dataframe contenant les duels. Elle doit avoir 5 variables : 'Event_nb','Athlete1','Athlete2','Result' et 'Race_name'. IMPORTANT : chaque course doit avoir un nom de course différent.
 >- **courses** int : Une dataframe comprenant 3 variables : 'Athlete','Position' et 'Race_name'.
 >- **start_test** int : La valeur de 'Event_nb' à laquelle se commence la période de test, sur laquelle on calcule les métriques d'écart au classement.
 >- **end_test** int : La valeur de 'Event_nb' à laquelle se temine la période de test.

 >### Value
 >Cette fonction print la moyenne et la mediane d'écart au classement pour les 10 premiers de chaque courses. 
 >Elle retourne un vecteur comprenant toutes les valeurs d'écart au classement, ce qui permet par exemple d'afficher un histogramme.

 ## **ranking_loss_glicko** <a name="fonction6"></a>

>### Description
>Cette fonction permet de calculer les métriques d'écart au classement pour les 10 premiers de chaque course dans une période donnée, avec Glicko comme système de classement.

>### Usage
    ranking_loss_glicko(params,combats=df_duels,courses=df_courses,start_test=9,end_test=12){
>### Arguments
>- **K** numeric vector : Les parametres à utiliser pour le classement Glicko. Dans l'ordre : RD_init, c.
>- **combats** df : La dataframe contenant les duels. Elle doit avoir 6 variables : 'Event_nb','Period,'Athlete1','Athlete2','Result' et 'Race_name'. IMPORTANT : chaque course doit avoir un nom de course différent.
 >- **courses** int : Une dataframe comprenant 3 variables : 'Athlete','Position' et 'Race_name'.
 >- **start_test** int : La valeur de 'Event_nb' à laquelle se commence la période de test, sur laquelle on calcule les métriques d'écart au classement.
 >- **end_test** int : La valeur de 'Event_nb' à laquelle se temine la période de test.

 >### Value
 >Cette fonction print la moyenne et la mediane d'écart au classement pour les 10 premiers de chaque courses. 
 >Elle retourne un vecteur comprenant toutes les valeurs d'écart au classement, ce qui permet par exemple d'afficher un histogramme.

 ## **ranking_loss_steph** <a name="fonction7"></a>

>### Description
>Cette fonction permet de calculer les métriques d'écart au classement pour les 10 premiers de chaque course dans une période donnée, avec Glicko comme système de classement.

>### Usage
    ranking_loss_steph(params,combats=df_duels,courses=df_courses,start_test=9,end_test=12){
>### Arguments
>- **params** numeric vector : Les parametres à utiliser pour le classement Stephenson. Dans l'ordre : RD_init, c, beta, lambda.
>- **combats** df : La dataframe contenant les duels. Elle doit avoir 6 variables : 'Event_nb','Period,'Athlete1','Athlete2','Result' et 'Race_name'. IMPORTANT : chaque course doit avoir un nom de course différent.
 >- **courses** int : Une dataframe comprenant 3 variables : 'Athlete','Position' et 'Race_name'.
 >- **start_test** int : La valeur de 'Event_nb' à laquelle se commence la période de test, sur laquelle on calcule les métriques d'écart au classement.
 >- **end_test** int : La valeur de 'Event_nb' à laquelle se temine la période de test.

 >### Value
 >Cette fonction print la moyenne et la mediane d'écart au classement pour les 10 premiers de chaque courses. 
 >Elle retourne un vecteur comprenant toutes les valeurs d'écart au classement, ce qui permet par exemple d'afficher un histogramme.

## **classement_stephenson** <a name="fonction7"></a>

>### Description
>Cette fonction permet de construire un classement prévisionnel avant une course.

>### Usage
    classement_stephenson <- function(Participants,Courses_en_stock,sig=61.56,cval=4.649,beta=6.614,lambda=3.716)
>### Arguments
>- **Participants** character vector : La liste des athlètes participants à une course.
>- **Courses_en_stock** df : La dataframe contenant les résultats de course jusqu'à aujourd'hui. Elle doit contenir 3 variables : 'Date','Athlete' et 'Position'.
>- **courses** int : Une dataframe comprenant 3 variables : 'Athlete','Position' et 'Race_name'.
>- **sig** (opt) numeric : RD_initial du classement Stephenson.
>- **cval** (opt) numeric : Parametre c du classement Stephenson.
>- **beta** (opt) numeric : Parametre beta du classement Stephenson.
>- **lambda** (opt) numeric : Parametre lambda du classement Stephenson.

 >### Value
 >Cette fonction retourne une dataframe contenant 2 variables : le nom de l'athlete et son rating stephenson avant la course.

 # 2. Exemple d'utilisation <a name="example"></a>

Vous trouverez dans le git un fichier 'demo_course.csv'. Le code suivant permet d'utiliser les fonctions décrites sur ce petit exemple.
    
    source('Ratings.R')

    demo_course <- read.csv('demo_course.csv',sep=';')
    demo_course$Date <- dmy(demo_course$Date)

    demo_duels <- races_to_duel(demo_course, race_name = T,period=1)
    optim_elo(     demo_duels,  start_validation = 5,end_validation = 8,start_test = 9,end_test = 12)
    optim_glicko(  demo_duels,  start_validation = 3,end_validation = 4,start_test = 5,end_test = 6)
    optim_stephenson(demo_duels,start_validation = 3,end_validation = 4,start_test = 5,end_test = 6)

    hist(ranking_loss_elo(10,demo_duels,demo_course,9,12))
    hist(ranking_loss_glicko(c(56,8),demo_duels,demo_course,9,12))
    hist(ranking_loss_steph(c(61.56,4.649,6.614,3.716),demo_duels,demo_course,9,12))