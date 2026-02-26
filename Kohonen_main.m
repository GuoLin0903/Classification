%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                    %
%                    INSA-Lyon MATEIS CNRS UMR5510                   %
%                        Equipes CERA & ENDV                         %
%                                2011                                %
%                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear outil
disp('***************************************************************************')
disp('*           Classification des données d''émission acoustique              *')         
disp('*                       par une carte de Kohonen                          *')
disp('***************************************************************************')
disp(' ')
disp(' ')
input_rand=input('Souhaitez-vous réorganiser les données dans un ordre aléatoire [o/n] ? ', 's');
if isempty(input_rand)
    rand='n'; 
    input_log='Rangement aléatoire des données : NON';   
    log=str2mat(log,input_log);   
end
if input_rand=='o' | input_rand=='y';
    matrice_localisee=matrice_localisee(randperm(size(matrice_localisee,1)),:);
    
    input_log='Rangement aléatoire des données : OUI';   
    log=str2mat(log,input_log);   
end
clear input_rand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calcul des descripteurs / élimination du bruit                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(2,'***** Calcul de nouveaux descripteurs (18) *****')
disp(' ')
%disp('***** Calcul de nouveaux descripteurs (18) *****')
decay_time=(matrice_localisee(:,nb_param+6) - matrice_localisee(:,nb_param+4));              %calcul du temps d'extinction
matrice_localisee_reduite=matrice_localisee(find(decay_time>0),:); 

%%% matrice_localisee --> matrice_localisee_reduite

%élimination des signaux pour lesquels le temps d'extinction est nul
decay_time=decay_time(find(decay_time>0),:);                            %utilisé pour calculer les descripteurs
% La liste des descripteurs est la suivante:
% 1- temps de montee                   10- temps de montee relatif
% 2- nombre de coups                   11- duree/amplitude
% 3- duree                             12- temps d'extinction
% 4- amplitude                         13- angle de montee
% 5- frequence moyenne                 14- angle de descente
% 6- nombre de coups au pic            15- tps de mont./tps de desc.
% 7- frequence de reverberation        16- energie relative
% 8- frequence de montee               17- nombre de coup au pic relatif
% 9- energie absolue                   18- amplitude/frequence
descripteurs = [ ...
    (matrice_localisee_reduite(:,nb_param+4)) ...
    (matrice_localisee_reduite(:,nb_param+5)) ...
    (matrice_localisee_reduite(:,nb_param+6)) ...
    matrice_localisee_reduite(:,nb_param+7) ...
    matrice_localisee_reduite(:,nb_param+8) ...
    matrice_localisee_reduite(:,nb_param+9) ...
    matrice_localisee_reduite(:,nb_param+10) ...
    matrice_localisee_reduite(:,nb_param+11) ...
    (matrice_localisee_reduite(:,nb_param+12)) ...
    (matrice_localisee_reduite(:,nb_param+4)./matrice_localisee_reduite(:,nb_param+6)) ...
    (matrice_localisee_reduite(:,nb_param+6)./matrice_localisee_reduite(:,nb_param+7)) ...
    (decay_time) ...
    (matrice_localisee_reduite(:,nb_param+7)./matrice_localisee_reduite(:,nb_param+4)) ...
    (matrice_localisee_reduite(:,nb_param+7)./decay_time) ...
    (matrice_localisee_reduite(:,nb_param+4)./decay_time) ...
    (matrice_localisee_reduite(:,nb_param+12)./matrice_localisee_reduite(:,nb_param+7)) ...
    matrice_localisee_reduite(:,nb_param+9)./matrice_localisee_reduite(:,nb_param+5) ...
    (matrice_localisee_reduite(:,nb_param+7)./matrice_localisee_reduite(:,nb_param+8)) ...
    ];
clear matrice_localisee decay_time
disp(' ')
disp('-> Descripteurs calculés')
% Filtrage des Inf/NaN 
[descripteurs_filtres, matrice_localisee_reduite_filtree]=delete_row_isinf(descripteurs, matrice_localisee_reduite);
clear descripteurs matrice_localisee_reduite
matrice_localisee_reduite=matrice_localisee_reduite_filtree;
clear matrice_localisee_reduite_filtree

%%% descripteurs --> descripteurs_filtres

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1er filtrage des signaux isolés qui pourrait perturber le        %
% dendrogramme et l'ACP                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp(' ')
% Affiche des graphes de contrôle
disp('Quels descripteurs souhaitez-vous utiliser pour tracer les graphes ?');
selection_descripteurs=input('Les entrer entre crochets (ex: [2 4 10 13 14 18]) :'); 
nb_d=size(selection_descripteurs,2);
tailleA=int8(ceil(sqrt((nb_d*(nb_d-1))/2)+1));
tailleB=int8(ceil(((nb_d*(nb_d-1))/2))/tailleA);
ref_graphe=1;
figure;
for ref_composante=1:nb_d-1;
    ref_comp_2=ref_composante+1;
    axe1=selection_descripteurs(ref_composante);
    [axis1]=intitule(axe1);
    while ref_comp_2<nb_d+1;
          axe2=selection_descripteurs(ref_comp_2);
          [axis2]=intitule(axe2);
          locate_subplot=['subplot(' num2str(tailleB) ',' num2str(tailleA) ',' num2str(ref_graphe) ')'];
          eval(locate_subplot);
          gener_graphe=['plot(descripteurs_filtres(:,',num2str(axe1),'),descripteurs_filtres(:,',num2str(axe2),'),''.''); xlabel(''',axis1,'''), ylabel(''',axis2,''')'];
          eval(gener_graphe);
          ref_graphe = ref_graphe + 1;
          ref_comp_2=ref_comp_2+1;
    end
end
% Filtrage
filtr=input('Souhaitez-vous réaliser un filtrage des données éloignées [o/n] ? ', 's');
if isempty(filtr)
    filtr='n'; 
    [m,n]=size(descripteurs_filtres);
    descript=descripteurs_filtres;
    matrice_b1=ones(1,m);
    nb_filtr=0;
end
if filtr=='o' | filtr=='y';
[m,n]=size(descripteurs_filtres);
nb_fil=1;
matrice_temp=[];
for i=1:1:m
matrice_temp(i)=1;
end
[matrice_b1,descript,nb_filtr,log]=filtr_1(descripteurs_filtres,nb_d,tailleA,tailleB,nb_fil,matrice_temp,selection_descripteurs,log); 
else
[m,n]=size(descripteurs_filtres);
matrice_b1=ones(1,m);
descript=descripteurs_filtres;
nb_filtr=0;
end
input_log=['Nombre de filtrage avant ACP : ',num2str(nb_filtr)];
log=str2mat(log,input_log);
clear nb_d tailleA tailleB nb_filtr nb_fil ref_composante ref_comp_2

%%% descripteurs_filtres --> descript

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TRACE DU DENDROGRAMME - CHOIX DES DESCRIPTEURS DISCRIMINANTS       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure;
Parametres_normalises=zscore(descript);                % normalisation des paramètres
DEND=dendrog(Parametres_normalises,'cor');
disp(' ')
selection_descripteurs=input('Selection du jeu de parametres par defaut [2 4 10 13 14 18]? o/n [n] ', 's');
if isempty(selection_descripteurs), selection_descripteurs='n'; end
if selection_descripteurs=='o' | selection_descripteurs=='y';
    grandeurs_non_correlees=Parametres_normalises(:,[2 4 10 13 14 18]);
    disp('!!! Utilisation des descripteurs par défaut !!!')
    selection_descripteurs=[2 4 10 13 14 18];
    input_log=['Paramètres carte : [2 4 10 13 14 18]'];
    log=str2mat(log,input_log);
else selection_descripteurs=='n';
    selection_descripteurs=input('Entrer les n° des parametres explicites sous forme de vecteur (entre crochets []): \n');
    grandeurs_non_correlees=Parametres_normalises(:,selection_descripteurs);
    input_log=vect2str(selection_descripteurs, 'formatstring', '%1.0f');
    input_log=['Paramètres carte : ',input_log];
    log=str2mat(log,input_log);
end
clear DEND 
disp(' ')

%%% paramètres_normalises --> grandeurs_non_correlees

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%              CALCUL DE LA MATRICE DES POIDS DES NEURONES             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(2,'***** Construction de la carte auto-organisatrice *****')
%disp('***** Construction de la carte auto-organisatrice *****')
disp(' ')
disp(' ')
m=input('Quelle est la taille de la carte souhaitée [1024] ?   ');
if isempty(m), m=1024; end
disp(' ')
nb_pass=input('Quelle est le nombre de passages à effectuer [15] ?   ');
if isempty(nb_pass), nb_pass=1024; end
disp(' ')
r_ini=input('Quelle est le rayon initial du voisinage [8] ?   ');
if isempty(r_ini), r_ini=8; end
disp(' ')
gain=input('Quelle est le gain initial [1] ?   ');
if isempty(gain), gain=1; end
disp(' ')
dimigain=input('Quel est le coefficient de décroissance à appliquer au gain [0.95] ?   ');
if isempty(dimigain), dimigain=0.95; end
disp(' ')
disp('Calculs en cours ...')
% Création de la carte et phase d'apprentissage
poids=kohonen(grandeurs_non_correlees,m,nb_pass,r_ini,gain,dimigain,selection_descripteurs);
clear selection_descripteurs
disp(' ')
disp('Matrice poids construite ')
disp(' ')
fprintf(2,'***** Tracé des frontières de la carte *****')
%disp('***** Tracé des frontières de la carte *****')
disp(' ')
disp(' ')
nb_voisins=input('Quel est le nombre de voisins à utiliser [4] ?   ');
if isempty(nb_voisins), nb_voisins=4; end
disp(' ')
moy=input('Calculer les distances maxi [0] ou moyennes [1]?   ');
if isempty(moy), moy=0; end
disp(' ')

trans=np_som(poids,nb_voisins,moy);
clear nb_voisins moy




